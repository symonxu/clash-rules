#!/usr/bin/env ruby
# Offline only: all OS, download and core operations are replaced by FakeSystem.
require 'minitest/autorun'
require 'tmpdir'
require 'rexml/document'
require_relative 'sync-routing'

class FakeSystem
  attr_accessor :clock, :running, :core_identity, :body, :download_error,
                :check_error, :reload_failures, :on_check, :bad_loaded_state, :agent_load_failures
  attr_reader :fetches, :reloads, :checks, :notices, :selected, :agents, :unloads
  def initialize(runtime, body)
    @clock, @running, @core_identity = 1000, true, 'mock-core-1'
    @body, @fetches, @reloads, @checks = body, [], [], []
    @notices, @selected, @agents, @unloads = [], [], {}, []
    @reload_failures = 0
    @agent_load_failures = 0
    reflect(runtime)
  end
  def now; clock; end
  def mac?; true; end
  def running?(_paths); running; end
  def socket(_runtime); running ? 'mock-socket' : nil; end
  def identity(_runtime); core_identity; end
  def live(_runtime); Marshal.load(Marshal.dump(@live)); end
  def choose(group, node); @live['proxies'].fetch(group)['now'] = node; end
  def reflect(runtime)
    proxies = runtime.fetch('proxies').each_with_object({}) { |n, result| result[n['name']] = {'type' => 'AnyTLS'} }
    runtime.fetch('proxy-groups').each do |g|
      all = g['proxies'] || runtime['proxies'].select { |n| Regexp.new(g.fetch('filter')).match?(n['name']) }.map { |n| n['name'] }
      proxies[g['name']] = {'type' => 'Selector', 'all' => all, 'now' => all.first}
    end
    # Mihomo uses IPCIDR for both IP families and lower-case GeoIP payloads.
    types = {'DOMAIN' => 'Domain', 'DOMAIN-SUFFIX' => 'DomainSuffix', 'DOMAIN-KEYWORD' => 'DomainKeyword', 'IP-CIDR' => 'IPCIDR', 'IP-CIDR6' => 'IPCIDR', 'GEOIP' => 'GeoIP', 'MATCH' => 'Match'}
    rules = runtime.fetch('rules').map do |r|
      f = r.split(',')
      {'type' => types.fetch(f.first), 'payload' => f.first == 'MATCH' ? '' : f[1].downcase, 'proxy' => f.last == 'no-resolve' ? f[-2] : f.last}
    end
    @live = {'proxies' => proxies, 'rules' => rules}
  end
  def fetch(_paths, _runtime, etag)
    @fetches << etag
    raise XMClashSync::Fault.new('download') if download_error
    {'body' => body, 'etag' => 'mock-etag'}
  end
  def check(_paths, bytes)
    @checks << bytes
    on_check.call if on_check
    raise XMClashSync::Fault.new('core_test') if check_error
  end
  def reload(_runtime, bytes)
    @reloads << bytes
    if reload_failures > 0
      @reload_failures -= 1
      raise XMClashSync::Fault.new('local')
    end
    reflect(XMClashSync.parse(bytes))
    @live['rules'] = [] if bad_loaded_state
  end
  def select(_runtime, group, node)
    @selected << [group, node]
    choose(group, node)
  end
  def notify(code); @notices << code; end
  def loaded?(label); @agents.key?(label); end
  def unload(label); @unloads << label; @agents.delete(label); end
  def load_agent(path)
    if agent_load_failures > 0
      @agent_load_failures -= 1
      raise XMClashSync::Fault.new('install')
    end
    @agents[File.basename(path, '.plist')] = path
  end
end

class SyncTest < Minitest::Test
  def setup
    @home = Dir.mktmpdir('xm-offline-')
    @paths = XMClashSync::Paths.new(@home)
    FileUtils.mkdir_p(File.join(@paths.app, 'profiles'))
    @routing = XMClashSync.parse(File.read(File.expand_path('../../XM-ClashVerge-Routing.yaml', __dir__)))
    nodes = (1..15).flat_map do |n|
      ["🇯🇵 日本 %02d" % n, "🇯🇵 日本 %02d 家宽" % n, "🇺🇸 美国 %02d" % n, "🇺🇸 美国 %02d 家宽" % n].map do |name|
        {'name' => name, 'type' => 'anytls', 'server' => 'node.invalid', 'port' => 443, 'password' => 'PRIVATE-NODE-CANARY'}
      end
    end
    @raw = {'proxies' => nodes, 'dns' => {'enable' => true, 'nameserver' => ['PRIVATE-DNS-CANARY']}, 'proxy-groups' => [{'name' => 'MESL-original', 'type' => 'select', 'proxies' => [nodes.first['name']]}], 'rules' => ['MATCH,MESL-original']}
    @runtime = @raw.merge('secret' => 'PRIVATE-API-CANARY', 'tun' => {'enable' => true}, 'mixed-port' => 7897, 'mode' => 'rule', 'ipv6' => true, 'profile' => {'store-fake-ip' => true})
    @profiles = {'current' => 'mesl-uid', 'items' => [{'uid' => 'mesl-uid', 'name' => 'MESL', 'type' => 'remote', 'file' => 'mesl.yaml', 'url' => 'PRIVATE-SUBSCRIPTION-CANARY', 'option' => {'script' => 'script-uid'}}, {'uid' => 'script-uid', 'type' => 'script', 'file' => 'script.js'}]}
    write_profiles
    write_raw
    write_runtime(@runtime)
    XMClashSync.atomic(script_path, "function main(config) { return config; }\n")
    XMClashSync.atomic(@paths.binding, JSON.generate('uid' => 'mesl-uid', 'source' => XMClashSync::SOURCE, 'enabled' => true))
    @system = FakeSystem.new(@runtime, YAML.dump(@routing))
    @runner = XMClashSync::Runner.new(@paths, @system)
  end
  def teardown; FileUtils.remove_entry(@home); end
  def raw_path; File.join(@paths.app, 'profiles/mesl.yaml'); end
  def script_path; File.join(@paths.app, 'profiles/script.js'); end
  def runtime_path; File.join(@paths.app, 'clash-verge.yaml'); end
  def write_profiles; XMClashSync.atomic(File.join(@paths.app, 'profiles.yaml'), YAML.dump(@profiles)); end
  def write_raw; XMClashSync.atomic(raw_path, YAML.dump(@raw)); end
  def write_runtime(value); XMClashSync.atomic(runtime_path, YAML.dump(value)); end
  def state; XMClashSync.json(@paths.status); end
  def config_bytes; [File.read(runtime_path), File.read(script_path)]; end
  def policy_change
    @routing['rules'].insert(-2, 'DOMAIN-SUFFIX,new-rule.invalid,XM-日常上网')
    @system.body = YAML.dump(@routing)
  end
  def node_change(generate: true)
    @raw['proxies'][0]['password'] = 'PRIVATE-NEW-NODE-CANARY'
    @raw['dns']['nameserver'] = ['PRIVATE-NEW-DNS-CANARY']
    write_raw
    return unless generate
    generated = XMClashSync.parse(File.read(runtime_path)).merge('proxies' => @raw['proxies'], 'dns' => @raw['dns'])
    write_runtime(generated)
    @system.reflect(generated)
  end
  def initial; assert_equal 'applied', @runner.tick; end

  def test_initial_apply_preserves_every_non_routing_field
    before = XMClashSync.parse(File.read(runtime_path))
    initial
    after = XMClashSync.parse(File.read(runtime_path))
    (before.keys - XMClashSync::KEYS - ['profile']).each { |k| assert_equal before[k], after[k], k }
    assert_equal true, after['profile']['store-selected']
    assert_equal true, after['profile']['store-fake-ip']
    assert_equal 5, after['proxy-groups'].size
    members = XMClashSync.validate(@routing, after)
    assert members.values.all? { |list| list.size == 6 }
    refute members['XM-Google'].include?('🇯🇵 日本 01')
    assert_equal YAML.dump(@routing), File.read(@paths.cache)
    refute File.exist?(@paths.journal)
  end
  def test_unchanged_does_not_write_config_or_reload
    initial
    before, times = config_bytes, [File.mtime(runtime_path), File.mtime(script_path)]
    @system.clock += 60
    assert_equal 'unchanged', @runner.tick
    assert_equal before, config_bytes
    assert_equal times, [File.mtime(runtime_path), File.mtime(script_path)]
    assert_equal 1, @system.fetches.size
    assert_equal 1, @system.reloads.size
  end
  def test_policy_update_without_subscription_download
    initial
    policy_change
    @system.clock += 300
    assert_equal 'applied', @runner.tick
    assert_equal @raw['proxies'], XMClashSync.parse(File.read(runtime_path))['proxies']
    assert_equal 'mock-etag', @system.fetches.last
    assert_includes XMClashSync.parse(File.read(runtime_path))['rules'], 'DOMAIN-SUFFIX,new-rule.invalid,XM-日常上网'
  end
  def test_node_update_checks_policy_before_five_minutes
    initial
    node_change
    @system.clock += 60
    assert_equal 'unchanged', @runner.tick
    assert_equal 2, @system.fetches.size
    assert_equal @raw['dns'], XMClashSync.parse(File.read(runtime_path))['dns']
    assert_equal 1, @system.reloads.size
  end
  def test_nodes_and_policy_update_together
    initial
    node_change
    policy_change
    @system.clock += 60
    assert_equal 'applied', @runner.tick
    current = XMClashSync.parse(File.read(runtime_path))
    assert_equal @raw['dns'], current['dns']
    assert_equal @raw['proxies'], current['proxies']
    assert_equal @routing['rules'], current['rules']
  end
  def test_client_not_finished_is_deferred_until_nodes_and_dns_match
    initial
    node_change(generate: false)
    before = config_bytes
    @system.clock += 60
    assert_equal 'waiting_client', @runner.tick
    assert_equal before, config_bytes
    assert_equal 1, @system.fetches.size
    node_change
    @system.clock += 60
    assert_equal 'unchanged', @runner.tick
    assert_equal 2, @system.fetches.size
  end
  def test_client_ipv6_dns_defaults_are_preserved_without_false_wait
    generated = Marshal.load(Marshal.dump(@runtime))
    generated['dns'].merge!('ipv6' => true, 'fake-ip-range6' => 'fc00::/18')
    write_runtime(generated)
    @system.reflect(generated)
    initial
    assert_equal generated['dns'], XMClashSync.parse(File.read(runtime_path))['dns']
    assert_equal 'current', state['status']
  end
  def test_unrecognized_dns_overlay_still_waits_for_client
    generated = Marshal.load(Marshal.dump(@runtime))
    generated['dns']['nameserver-policy'] = {'unknown.invalid' => 'OTHER-DNS-CANARY'}
    write_runtime(generated)
    @system.reflect(generated)
    before = config_bytes
    assert_equal 'waiting_client', @runner.tick
    assert_equal before, config_bytes
    assert_equal [], @system.fetches
  end
  def test_stuck_generation_notifies_only_once
    node_change(generate: false)
    assert_equal 'waiting_client', @runner.tick
    4.times { @system.clock += 300; @runner.tick }
    assert_equal ['pending'], @system.notices
    assert_equal 0, @system.reloads.size
  end
  def test_download_failure_without_cache_keeps_current_files
    @system.download_error = true
    before = config_bytes
    assert_equal 'download', @runner.tick
    assert_equal before, config_bytes
    assert_equal [], @system.reloads
    assert_equal ['download'], @system.notices
  end
  def test_download_failure_cache_is_explicit_and_retry_recovers
    initial
    @system.download_error = true
    @system.clock += 300
    assert_equal 'cached', @runner.tick
    assert_equal 'cached_latest_unconfirmed', state['status']
    assert_equal 1000, state['last_checked_at']
    @system.clock += 30
    assert_equal 'backoff', @runner.tick
    assert_equal 'cached_latest_unconfirmed', state['status']
    @system.clock += 30
    @system.download_error = false
    assert_equal 'unchanged', @runner.tick
    assert_equal 'current', state['status']
    refute state.key?('error')
  end
  def test_offline_cache_can_restore_missing_personal_routing
    initial
    write_runtime(@runtime)
    @system.reflect(@runtime)
    @system.download_error = true
    @system.clock += 300
    assert_equal 'applied', @runner.tick
    assert_equal 'cached_latest_unconfirmed', state['status']
    assert_equal @routing['rules'], XMClashSync.parse(File.read(runtime_path))['rules']
  end
  def test_repeated_faults_back_off_and_do_not_repeat_notification
    @system.download_error = true
    4.times { @runner.tick; @system.clock = state['retry_at'] }
    assert_equal ['download'], @system.notices
    assert_equal 4, @system.fetches.size
    assert_equal 480, state['retry_at'] - state['last_event_at']
  end
  def test_empty_group_rejected_without_changes
    @routing['proxy-groups'].first['filter'] = '^NO-NODES$'
    @system.body = YAML.dump(@routing)
    before = config_bytes
    assert_equal 'invalid', @runner.tick
    assert_equal before, config_bytes
    assert_equal 0, @system.checks.size
  end
  def test_wrong_member_count_rejected
    @raw['proxies'].reject! { |p| p['name'] == '🇯🇵 日本 02' }
    write_raw
    @runtime['proxies'] = @raw['proxies']
    write_runtime(@runtime)
    @system.reflect(@runtime)
    assert_equal 'invalid', @runner.tick
    assert_equal [], @system.reloads
  end
  def test_invalid_rule_and_unknown_reference_rejected
    ['SCRIPT,evil,XM-AI', 'DOMAIN-SUFFIX,example.invalid,Missing', 'IP-CIDR,garbage,DIRECT', 'DOMAIN-SUFFIX,example.invalid,XM-AI,no-resolve'].each do |rule|
      invalid = Marshal.load(Marshal.dump(@routing))
      invalid['rules'].insert(-2, rule)
      error = assert_raises(XMClashSync::Fault) { XMClashSync.validate(invalid, @runtime) }
      assert_equal 'invalid', error.code
    end
  end
  def test_remote_dns_or_code_data_is_not_allowed
    invalid = @routing.merge('dns' => {'enable' => false})
    assert_raises(XMClashSync::Fault) { XMClashSync.validate(invalid, @runtime) }
    assert_raises(XMClashSync::Fault) { XMClashSync.parse('--- !ruby/object:Object {}') }
    assert_raises(XMClashSync::Fault) { XMClashSync.parse("x: &x [*x]\n") }
    invalid = Marshal.load(Marshal.dump(@routing))
    invalid['proxy-groups'].first.delete('name')
    assert_equal 'invalid', assert_raises(XMClashSync::Fault) { XMClashSync.validate(invalid, @runtime) }.code
  end
  def test_invalid_download_does_not_replace_last_good_cache
    initial
    old_cache, before = File.read(@paths.cache), config_bytes
    @system.body = 'invalid: true'
    @system.clock += 300
    assert_equal 'invalid', @runner.tick
    assert_equal old_cache, File.read(@paths.cache)
    assert_equal before, config_bytes
  end
  def test_mihomo_validation_failure_keeps_files
    @system.check_error = true
    before = config_bytes
    assert_equal 'core_test', @runner.tick
    assert_equal before, config_bytes
    refute File.exist?(@paths.cache)
    refute File.exist?(@paths.journal)
  end
  def test_load_failure_restores_script_and_runtime
    before = config_bytes
    @system.reload_failures = 1
    assert_equal 'apply', @runner.tick
    assert_equal before, config_bytes
    assert_equal 2, @system.reloads.size
    refute File.exist?(@paths.journal)
    assert_equal ['apply'], @system.notices
  end
  def test_rollback_failure_keeps_journal_and_notifies_reactivate
    before = config_bytes
    @system.reload_failures = 2
    assert_equal 'rollback', @runner.tick
    assert_equal before, config_bytes
    assert File.exist?(@paths.journal)
    assert_equal ['rollback'], @system.notices
    @system.clock += 60
    assert_equal 'applied', @runner.tick
    refute File.exist?(@paths.journal)
  end
  def test_wrong_live_rules_trigger_rollback
    before = config_bytes
    @system.bad_loaded_state = true
    assert_equal 'rollback', @runner.tick
    assert_equal before, config_bytes
  end
  def test_concurrent_change_before_transaction_does_not_overwrite
    @system.on_check = proc { XMClashSync.atomic(script_path, '// concurrent manual change') }
    before_runtime = File.read(runtime_path)
    assert_equal 'busy', @runner.tick
    assert_equal before_runtime, File.read(runtime_path)
    assert_equal '// concurrent manual change', File.read(script_path)
    assert_equal [], @system.reloads
    @system.on_check = nil
    assert_equal 'applied', @runner.tick
  end
  def test_valid_manual_choices_survive_reload
    initial
    @system.choose('XM-Google', '🇯🇵 日本 03')
    policy_change
    @system.clock += 300
    assert_equal 'applied', @runner.tick
    assert_equal '🇯🇵 日本 03', @system.live(nil)['proxies']['XM-Google']['now']
  end
  def test_stopped_clash_and_restart
    initial
    @system.running = false
    @system.clock += 60
    assert_equal 'inactive', @runner.tick
    assert_equal 1, @system.fetches.size
    @system.running = true
    @system.core_identity = 'mock-core-2'
    @system.clock += 60
    assert_equal 'unchanged', @runner.tick
    assert_equal 2, @system.fetches.size
  end
  def test_changed_active_subscription_skips_and_resume_syncs
    initial
    @profiles['current'] = 'another-uid'
    write_profiles
    @system.clock += 60
    assert_equal 'inactive', @runner.tick
    assert_equal 1, @system.reloads.size
    @profiles['current'] = 'mesl-uid'
    write_profiles
    @system.clock += 60
    assert_equal 'unchanged', @runner.tick
    assert_equal 2, @system.fetches.size
  end
  def test_binding_removed_does_not_rebind_silently
    @profiles['items'].reject! { |i| i['uid'] == 'mesl-uid' }
    write_profiles
    assert_equal 'binding', @runner.tick
    assert_equal [], @system.fetches
    assert_equal [], @system.reloads
  end
  def test_sleep_jump_and_backward_clock_check_latest
    initial
    @system.clock += 7200
    assert_equal 'unchanged', @runner.tick
    @system.clock -= 8000
    assert_equal 'unchanged', @runner.tick
    assert_equal 3, @system.fetches.size
  end
  def test_force_once_bypasses_five_minute_check_interval
    initial
    @system.clock += 1
    assert_equal 'unchanged', @runner.tick(force: true)
    assert_equal 2, @system.fetches.size
  end
  def test_etag_not_modified_uses_validated_cache
    initial
    before = config_bytes
    @system.body = nil
    @system.clock += 300
    assert_equal 'unchanged', @runner.tick
    assert_equal before, config_bytes
    assert_equal 'mock-etag', @system.fetches.last
    assert_equal 'current', state['status']
  end
  def test_lock_prevents_overlapping_workers
    File.open(File.join(@paths.state, 'sync.lock'), File::RDWR | File::CREAT, 0600) do |lock|
      lock.flock(File::LOCK_EX)
      assert_equal 'locked', @runner.tick
      assert_equal [], @system.fetches
    end
  end
  def test_install_and_uninstall_are_idempotent_and_rebind_after_removal
    XMClashSync.atomic(@paths.legacy_agent, 'legacy')
    @system.agents[XMClashSync::LEGACY_LABEL] = @paths.legacy_agent
    installer = XMClashSync::Installer.new(@paths, @system)
    2.times { assert_equal 'installed', installer.install(File.expand_path('sync-routing.rb', __dir__)) }
    assert_equal [XMClashSync::LABEL], @system.agents.keys
    refute File.exist?(@paths.legacy_agent)
    assert_equal 0700, File.stat(@paths.installed).mode & 0777
    assert_equal 0600, File.stat(@paths.binding).mode & 0777
    plist = REXML::Document.new(File.read(@paths.agent))
    assert_equal '60', REXML::XPath.first(plist, '//integer').text
    assert_equal true, installer.status['enabled']
    before = config_bytes
    2.times { assert_match(/^uninstalled/, installer.uninstall) }
    assert_equal false, installer.status['enabled']
    assert_equal before, config_bytes
    @profiles['items'].first['uid'] = 'mesl-new-uid'
    @profiles['current'] = 'mesl-new-uid'
    write_profiles
    assert_equal 'installed', installer.install(File.expand_path('sync-routing.rb', __dir__))
    assert_equal 'mesl-new-uid', XMClashSync.json(@paths.binding)['uid']
    assert_operator Dir.glob(File.join(@paths.state, 'installer-backup/*')).size, :>=, 2
  end
  def test_install_missing_script_does_not_stop_old_task
    File.unlink(script_path)
    @system.agents[XMClashSync::LEGACY_LABEL] = 'legacy'
    installer = XMClashSync::Installer.new(@paths, @system)
    assert_equal 'local', assert_raises(XMClashSync::Fault) { installer.install(__FILE__) }.code
    assert @system.loaded?(XMClashSync::LEGACY_LABEL)
  end
  def test_install_registration_failure_restores_previous_task
    XMClashSync.atomic(@paths.legacy_agent, 'legacy-plist')
    XMClashSync.atomic(@paths.installed, 'previous-tool')
    @system.agents[XMClashSync::LEGACY_LABEL] = @paths.legacy_agent
    @system.agent_load_failures = 1
    installer = XMClashSync::Installer.new(@paths, @system)
    assert_equal 'install', assert_raises(XMClashSync::Fault) { installer.install(File.expand_path('sync-routing.rb', __dir__)) }.code
    assert_equal 'previous-tool', File.read(@paths.installed)
    assert_equal 'legacy-plist', File.read(@paths.legacy_agent)
    assert @system.loaded?(XMClashSync::LEGACY_LABEL)
    refute File.exist?(@paths.agent)
  end
  def test_existing_private_file_modes_and_old_tool_are_backed_up
    XMClashSync.atomic(@paths.installed, 'previous-tool')
    XMClashSync::Installer.new(@paths, @system).install(File.expand_path('sync-routing.rb', __dir__))
    backup = Dir.glob(File.join(@paths.state, 'installer-backup/*/sync-routing.rb')).first
    assert_equal 'previous-tool', File.read(backup)
    assert_equal 0600, File.stat(backup).mode & 0777
  end
  def test_uninstall_busy_does_not_interrupt_transaction
    installer = XMClashSync::Installer.new(@paths, @system)
    File.open(File.join(@paths.state, 'sync.lock'), File::RDWR | File::CREAT, 0600) do |lock|
      lock.flock(File::LOCK_EX)
      assert_equal 'busy', assert_raises(XMClashSync::Fault) { installer.uninstall }.code
      assert_equal true, XMClashSync.json(@paths.binding)['enabled']
    end
  end
  def test_status_and_fault_text_never_expose_secrets
    @system.download_error = true
    @runner.tick
    output = JSON.generate(XMClashSync::Installer.new(@paths, @system).status) + File.read(@paths.status) + XMClashSync::MESSAGES.values.join
    %w[PRIVATE-SUBSCRIPTION-CANARY PRIVATE-NODE-CANARY PRIVATE-DNS-CANARY PRIVATE-API-CANARY].each { |private_value| refute_includes output, private_value }
    assert_equal 0600, File.stat(@paths.status).mode & 0777
  end
end

class AdapterTest < Minitest::Test
  GoodStatus = Struct.new(:ok) do
    def success?; ok; end
  end
  def setup
    @home = Dir.mktmpdir('xm-adapter-')
    @paths = XMClashSync::Paths.new(@home)
    FileUtils.mkdir_p(@paths.state)
    FileUtils.mkdir_p(@paths.app)
    @adapter = XMClashSync::System.new
  end
  def teardown; FileUtils.remove_entry(@home); end
  def test_unix_http_payload_and_chunked_utf8_response
    path = File.join(@home, 'test.sock')
    server = UNIXServer.new(path)
    thread = Thread.new do
      connection = server.accept
      header = +''
      header << connection.read(1) until header.end_with?("\r\n\r\n")
      body = connection.read(header[/Content-Length: (\d+)/, 1].to_i)
      reply = JSON.generate('ok' => '日本')
      connection.write("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n#{reply.bytesize.to_s(16)}\r\n#{reply}\r\n0\r\n\r\n")
      connection.close
      [header, JSON.parse(body)]
    end
    runtime = {'external-controller-unix' => path, 'secret' => 'MOCK-PRIVATE-TOKEN'}
    assert_equal({'ok' => '日本'}, @adapter.api(runtime, 'PUT', '/configs', {'payload' => 'mock-private-config'}))
    header, payload = thread.value
    assert header.start_with?('PUT /configs HTTP/1.1')
    assert_includes header, 'Authorization: Bearer MOCK-PRIVATE-TOKEN'
    assert_equal({'payload' => 'mock-private-config'}, payload)
    assert_equal path, @adapter.socket(runtime)
  ensure
    server.close if server
    thread.kill if thread && thread.alive?
  end
  def test_curl_only_requests_fixed_public_source_and_etag
    calls = []
    capture = proc do |*args|
      calls << args
      File.write(args[args.index('--output') + 1], 'public-routing')
      File.write(args[args.index('--dump-header') + 1], "HTTP/1.1 200 OK\r\nETag: mock-tag\r\n")
      ['200', '', GoodStatus.new(true)]
    end
    result = Open3.stub(:capture3, capture) { @adapter.fetch(@paths, {'mixed-port' => 7897}, 'old-tag') }
    assert_equal({'body' => 'public-routing', 'etag' => 'mock-tag'}, result)
    assert_equal XMClashSync::SOURCE, calls.first.last
    assert_equal '-q', calls.first[1]
    assert_includes calls.first, 'If-None-Match: old-tag'
    assert_includes calls.first, '--max-time'
    assert_equal [], Dir.glob(File.join(@paths.state, '.xm-download-*'))
  end
  def test_proxy_download_failure_falls_back_to_direct_without_private_subscription
    calls = []
    capture = proc do |*args|
      calls << args
      if calls.size == 1
        ['000', 'MOCK-PRIVATE-error-never-output', GoodStatus.new(false)]
      else
        File.write(args[args.index('--output') + 1], 'public-routing')
        ['200', '', GoodStatus.new(true)]
      end
    end
    result = Open3.stub(:capture3, capture) { @adapter.fetch(@paths, {'mixed-port' => 7897}, nil) }
    assert_equal 'public-routing', result['body']
    assert_equal 2, calls.size
    assert_includes calls.last, '--noproxy'
    assert calls.all? { |args| args.last == XMClashSync::SOURCE }
  end
  def test_failed_download_exposes_only_static_message
    capture = proc { |*_args| ['000', 'MOCK-PRIVATE-ERROR', GoodStatus.new(false)] }
    error = Open3.stub(:capture3, capture) { assert_raises(XMClashSync::Fault) { @adapter.fetch(@paths, {}, nil) } }
    assert_equal 'download', error.code
    refute_includes error.message, 'MOCK-PRIVATE-ERROR'
  end
  def test_client_running_check_is_scoped_to_current_user
    command = nil
    capture = proc { |*args| command = args; ['', '', GoodStatus.new(false)] }
    assert_equal false, Open3.stub(:capture3, capture) { @adapter.running?(@paths) }
    assert_includes command, Process.uid.to_s
    assert_includes command, '-x'
  end
  def test_mihomo_check_uses_private_tempfile_and_cleans_it
    arguments = nil
    spawn = proc do |*args|
      arguments = args
      temp_path = args[args.index('-f') + 1]
      assert_equal 'mock-private-config', File.read(temp_path)
      assert_equal 0600, File.stat(temp_path).mode & 0777
      123456
    end
    Process.stub(:spawn, spawn) do
      Process.stub(:wait2, [123456, GoodStatus.new(true)]) { @adapter.check(@paths, 'mock-private-config') }
    end
    assert_equal @paths.core, arguments.first
    assert_equal [], Dir.glob(File.join(@paths.app, '.xm-check-*'))
  end
  def test_mihomo_check_deadline_kills_only_spawned_mock_pid
    killed = []
    Process.stub(:spawn, 123456) do
      Process.stub(:kill, proc { |signal, pid| killed << [signal, pid] }) do
        Process.stub(:wait, 123456) do
          Timeout.stub(:timeout, proc { |*_args| raise Timeout::Error }) do
            assert_equal 'core_test', assert_raises(XMClashSync::Fault) { @adapter.check(@paths, 'mock') }.code
          end
        end
      end
    end
    assert_equal [['KILL', 123456]], killed
  end
end
