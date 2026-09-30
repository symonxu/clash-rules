#!/usr/bin/env ruby
# Requires Ruby 2.6+; only the explicit CLI performs any local operation.
require 'yaml'
require 'json'
require 'digest'
require 'socket'
require 'timeout'
require 'open3'
require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'uri'
require 'ipaddr'
require 'cgi'

module XMClashSync
  SOURCE = 'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml'.freeze
  LABEL = 'com.xumeng.clash-personal-sync'.freeze
  LEGACY_LABEL = 'com.xumeng.clash-verge-routing-sync'.freeze
  KEYS = %w[proxy-groups rule-providers rules].freeze
  GROUPS = %w[XM-Google XM-AI XM-Meta XM-Web3 XM-日常上网].freeze
  CLIENT_DNS_ADDITIONS = %w[ipv6 fake-ip-range6].freeze
  MESSAGES = {
    'download' => '无法取得 GitHub 最新策略；现有配置保留，缓存如被使用会标明。',
    'invalid' => '策略格式、规则或六节点分组校验失败；现有配置保留。',
    'core_test' => 'Mihomo 配置校验失败；现有配置保留。',
    'apply' => '应用失败，已恢复本次应用前的配置。',
    'rollback' => '应用失败且回退未完整完成，请在 Clash 中重新激活 MESL。',
    'pending' => '客户端配置尚未反映最新 MESL 节点或 DNS；等待客户端完成更新。',
    'local' => '本地配置不可读取或结构不兼容，请检查 Clash 与 MESL 订阅。',
    'binding' => '找不到绑定的 MESL 订阅；删除重导后需卸载并重新安装同步任务。',
    'busy' => '客户端配置正在变化，本轮延期。',
    'install' => '安装或卸载任务失败，请检查终端提示及当前用户权限。',
    'internal' => '同步遇到未分类错误；详细配置未输出，请查看状态并重新尝试。'
  }.freeze
  class Fault < StandardError
    attr_reader :code
    def initialize(code)
      @code = code.to_s
      super(MESSAGES.fetch(@code, MESSAGES['internal']))
    end
  end
  def self.parse(text)
    raise Fault.new('invalid') if text.bytesize > 1_048_576
    if RUBY_VERSION.split('.').first.to_i < 3
      YAML.safe_load(text, [], [], false)
    else
      YAML.safe_load(text, permitted_classes: [], permitted_symbols: [], aliases: false)
    end
  rescue Psych::Exception, ArgumentError
    raise Fault.new('invalid')
  end
  def self.hash(value)
    Digest::SHA256.hexdigest(value.is_a?(String) ? value : JSON.generate(value))
  end
  def self.atomic(path, bytes)
    FileUtils.mkdir_p(File.dirname(path), mode: 0700)
    tmp = Tempfile.new('.xm-', File.dirname(path))
    tmp.chmod(0600)
    tmp.write(bytes)
    tmp.close
    File.rename(tmp.path, path)
  ensure
    tmp.close! if tmp
  end
  def self.json(path, fallback = {})
    File.file?(path) ? JSON.parse(File.read(path)) : fallback
  rescue JSON::ParserError
    raise Fault.new('local')
  end
  def self.filename(value)
    raise Fault.new('local') unless value.is_a?(String) && !value.empty? && File.basename(value) == value && !%w[. ..].include?(value)
    value
  end
  def self.extension(routing)
    "// XM managed routing: MESL DNS and nodes remain local.\nconst personalRouting = #{JSON.pretty_generate(routing)};\nfunction main(config) {\n  if (!config.dns || !config.dns.nameserver || !config.dns.nameserver.length) throw new Error('MESL DNS missing');\n  config['proxy-groups'] = personalRouting['proxy-groups'];\n  config['rule-providers'] = personalRouting['rule-providers'];\n  config.rules = personalRouting.rules;\n  config.profile = Object.assign({}, config.profile, {'store-selected': true});\n  return config;\n}\n"
  end
  def self.validate(routing, runtime)
    raise Fault.new('invalid') unless routing.is_a?(Hash) && routing.keys.sort == KEYS.sort && routing['rule-providers'] == {}
    groups, rules = routing.values_at('proxy-groups', 'rules')
    raise Fault.new('invalid') unless groups.is_a?(Array) && groups.size == 5 && groups.all? { |g| g.is_a?(Hash) && g['name'].is_a?(String) } && groups.map { |g| g['name'] }.sort == GROUPS.sort
    nodes = runtime['proxies']
    raise Fault.new('local') unless nodes.is_a?(Array) && nodes.all? { |n| n.is_a?(Hash) && n['name'].is_a?(String) }
    raise Fault.new('invalid') unless nodes.map { |n| n['name'] }.uniq.size == nodes.size
    members = {}
    groups.each do |g|
      raise Fault.new('invalid') unless (g.keys - %w[name type include-all exclude-type filter]).empty? && g['type'] == 'select' && g['include-all'] == true && g['exclude-type'] == 'direct' && g['filter'].is_a?(String)
      filter = Regexp.new(g['filter'])
      members[g['name']] = nodes.select { |n| n['type'] != 'direct' && filter.match?(n['name']) }.map { |n| n['name'] }
      raise Fault.new('invalid') unless members[g['name']].size == 6
    end
    raise Fault.new('invalid') unless rules.is_a?(Array) && rules.last == 'MATCH,XM-日常上网' && rules.count { |r| r.is_a?(String) && r.start_with?('MATCH,') } == 1
    rules.each do |rule|
      raise Fault.new('invalid') unless rule.is_a?(String)
      fields = rule.split(',', -1)
      modifier = fields.last == 'no-resolve'
      target = modifier ? fields[-2] : fields.last
      raise Fault.new('invalid') unless (GROUPS + %w[DIRECT REJECT REJECT-DROP]).include?(target)
      case fields.first
      when 'DOMAIN', 'DOMAIN-SUFFIX', 'DOMAIN-KEYWORD'
        raise Fault.new('invalid') unless fields.size == 3 && fields[1].match?(/\A[a-zA-Z0-9._-]+\z/)
      when 'IP-CIDR', 'IP-CIDR6'
        raise Fault.new('invalid') unless fields.size == (modifier ? 4 : 3) && fields[1].include?('/')
        ip = IPAddr.new(fields[1])
        raise Fault.new('invalid') unless fields.first == (ip.ipv4? ? 'IP-CIDR' : 'IP-CIDR6')
      when 'GEOIP'
        raise Fault.new('invalid') unless fields.size == (modifier ? 4 : 3) && fields[1].match?(/\A[A-Z]{2}\z/)
      when 'MATCH'
        raise Fault.new('invalid') unless fields.size == 2
      else
        raise Fault.new('invalid')
      end
    end
    members
  rescue RegexpError, IPAddr::Error, TypeError, ArgumentError
    raise Fault.new('invalid')
  end

  class Paths
    attr_reader :home, :app, :state, :agent, :legacy_agent, :core
    def initialize(home)
      @home = File.expand_path(home)
      @app = File.join(@home, 'Library/Application Support/io.github.clash-verge-rev.clash-verge-rev')
      @state = File.join(@home, 'Library/Application Support/XM-ClashVerge-RoutingSync')
      @agent = File.join(@home, "Library/LaunchAgents/#{LABEL}.plist")
      @legacy_agent = File.join(@home, "Library/LaunchAgents/#{LEGACY_LABEL}.plist")
      @core = '/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo'
    end
    def binding; File.join(state, 'binding.json'); end
    def status; File.join(state, 'auto-state.json'); end
    def cache; File.join(state, 'validated-routing.yaml'); end
    def installed; File.join(state, 'sync-routing.rb'); end
    def journal; File.join(state, 'transaction.json'); end
  end

  class System
    def now; Time.now.to_i; end
    def mac?; RUBY_PLATFORM.include?('darwin'); end
    def running?(_paths)
      # A service socket alone is insufficient: an orphaned core can outlive
      # the desktop client. Check the current user's GUI executable as well.
      Open3.capture3('/usr/bin/pgrep', '-u', Process.uid.to_s, '-i', '-x', '(clash-verge|clash-verge-rev|Clash Verge)')[2].success?
    rescue StandardError
      false
    end
    def socket(runtime)
      requested = runtime['external-controller-unix']
      service = "/var/run/clash-verge-service/users/#{Process.uid}/verge-mihomo.sock"
      [requested, service].compact.find { |path| File.socket?(path) && File.stat(path).uid == Process.uid }
    end
    def identity(runtime)
      path = socket(runtime)
      path ? "#{File.stat(path).ino}:#{File.stat(path).mtime.to_f}" : nil
    end
    def api(runtime, method, route, body = nil)
      Timeout.timeout(15) do
        path = socket(runtime)
        raise Fault.new('local') unless path
        sock = UNIXSocket.new(path)
        payload = body ? JSON.generate(body) : ''
        secret = runtime['secret'].to_s
        raise Fault.new('local') if secret.match?(/[\r\n]/)
        sock.write("#{method} #{route} HTTP/1.1\r\nHost: localhost\r\nAuthorization: Bearer #{secret}\r\nContent-Type: application/json\r\nContent-Length: #{payload.bytesize}\r\nConnection: close\r\n\r\n#{payload}")
        response = sock.read
        headers, data = response.split("\r\n\r\n", 2)
        raise Fault.new('local') unless headers && headers.split[1].to_i.between?(200, 299)
        if headers.downcase.include?('transfer-encoding: chunked')
          decoded = +''
          until data.empty?
            line, data = data.split("\r\n", 2)
            size = Integer(line.split(';').first, 16)
            break if size.zero?
            decoded << data.byteslice(0, size)
            data = data.byteslice(size + 2..-1)
          end
          data = decoded
        end
        data && !data.empty? ? JSON.parse(data.force_encoding(Encoding::UTF_8)) : {}
      ensure
        sock.close if sock
      end
    rescue Fault
      raise
    rescue StandardError
      raise Fault.new('local')
    end
    def live(runtime)
      api(runtime, 'GET', '/version')
      {
        'proxies' => api(runtime, 'GET', '/proxies').fetch('proxies'),
        'rules' => api(runtime, 'GET', '/rules').fetch('rules')
      }
    rescue KeyError
      raise Fault.new('local')
    end
    def reload(runtime, payload)
      api(runtime, 'PUT', '/configs', {'payload' => payload})
    end
    def select(runtime, group, name)
      route = '/proxies/' + URI.encode_www_form_component(group).gsub('+', '%20')
      api(runtime, 'PUT', route, {'name' => name})
    end
    def check(paths, candidate)
      temp = Tempfile.new(['.xm-check-', '.yaml'], paths.app)
      temp.chmod(0600)
      temp.write(candidate)
      temp.close
      pid = Process.spawn(paths.core, '-t', '-d', paths.app, '-f', temp.path, out: File::NULL, err: File::NULL)
      begin
        _pid, status = Timeout.timeout(45) { Process.wait2(pid) }
      rescue Timeout::Error
        Process.kill('KILL', pid) rescue Errno::ESRCH
        Process.wait(pid) rescue Errno::ECHILD
        raise Fault.new('core_test')
      end
      raise Fault.new('core_test') unless status.success?
    rescue Errno::ENOENT
      raise Fault.new('core_test')
    ensure
      temp.close! if temp
    end
    def fetch(paths, runtime, etag)
      attempts = []
      port = runtime['mixed-port']
      if port.is_a?(Integer) && port.between?(1, 65_535)
        attempts << ['--proxy', URI::HTTP.build(host: '127.0.0.1', port: port).to_s]
      end
      attempts << ['--noproxy', '*']
      attempts.each do |transport|
        body = Tempfile.new('.xm-download-', paths.state)
        headers = Tempfile.new('.xm-headers-', paths.state)
        body.chmod(0600); headers.chmod(0600)
        body.close; headers.close
        args = ['/usr/bin/curl', '-q', '--fail', '--silent', '--show-error', '--connect-timeout', '5', '--max-time', '12', '--max-filesize', '1048576', '--proto', '=https', '--proto-redir', '=https', '--output', body.path, '--dump-header', headers.path, '--write-out', '%{http_code}'] + transport
        args += ['--header', "If-None-Match: #{etag}"] if etag.is_a?(String) && etag.bytesize <= 200 && !etag.match?(/[\r\n]/)
        output, _error, status = Open3.capture3(*(args + [SOURCE]))
        next unless status.success? && %w[200 304].include?(output)
        tag = File.read(headers.path)[/^etag:\s*([^\r\n]+)/i, 1]
        return {'body' => output == '304' ? nil : File.read(body.path), 'etag' => tag || etag}
      ensure
        body.close! if body
        headers.close! if headers
      end
      raise Fault.new('download')
    rescue Fault
      raise
    rescue StandardError
      raise Fault.new('download')
    end
    def notify(code)
      message = MESSAGES.fetch(code, MESSAGES['internal'])
      # Notifications contain only fixed text, never parser/core/remote output.
      Open3.capture3('/usr/bin/osascript', '-e', "display notification #{JSON.generate(message)} with title \"Clash 个人策略\"")
    rescue StandardError
      nil
    end
    def loaded?(label)
      Open3.capture3('/bin/launchctl', 'print', "gui/#{Process.uid}/#{label}")[2].success?
    end
    def unload(label)
      return unless loaded?(label)
      raise Fault.new('install') unless Open3.capture3('/bin/launchctl', 'bootout', "gui/#{Process.uid}/#{label}")[2].success?
    end
    def load_agent(path)
      raise Fault.new('install') unless Open3.capture3('/bin/launchctl', 'bootstrap', "gui/#{Process.uid}", path)[2].success?
    end
  end

  class Runner
    RULE_TYPES = {'DOMAIN' => 'Domain', 'DOMAIN-SUFFIX' => 'DomainSuffix', 'DOMAIN-KEYWORD' => 'DomainKeyword', 'IP-CIDR' => 'IPCIDR', 'IP-CIDR6' => 'IPCIDR', 'GEOIP' => 'GeoIP', 'MATCH' => 'Match'}.freeze
    attr_reader :paths, :system
    def initialize(paths, system = System.new)
      @paths, @system = paths, system
    end
    def read_binding
      binding = XMClashSync.json(paths.binding)
      raise Fault.new('binding') unless binding['uid'].is_a?(String) && binding['source'] == SOURCE
      binding
    end
    def snapshot(binding)
      profiles_path = File.join(paths.app, 'profiles.yaml')
      files = {profiles_path => File.read(profiles_path)}
      profiles = XMClashSync.parse(files[profiles_path])
      items = profiles.fetch('items')
      current = items.find { |i| i['uid'] == binding['uid'] }
      raise Fault.new('binding') unless current
      return nil unless profiles['current'] == binding['uid']
      script_id = current.fetch('option').fetch('script')
      script_item = items.find { |i| i['uid'] == script_id && i['type'] == 'script' }
      raise Fault.new('local') unless script_item
      raw_path = File.join(paths.app, 'profiles', XMClashSync.filename(current.fetch('file')))
      script_path = File.join(paths.app, 'profiles', XMClashSync.filename(script_item.fetch('file')))
      runtime_path = File.join(paths.app, 'clash-verge.yaml')
      [raw_path, script_path, runtime_path].each do |path|
        raise Fault.new('local') if File.symlink?(path)
        files[path] = File.read(path)
      end
      raw, runtime = [raw_path, runtime_path].map { |path| XMClashSync.parse(files[path]) }
      raise Fault.new('local') unless raw.is_a?(Hash) && runtime.is_a?(Hash)
      {'files' => files, 'raw_path' => raw_path, 'script_path' => script_path, 'runtime_path' => runtime_path, 'runtime' => runtime, 'raw' => raw}
    rescue Fault
      raise
    rescue StandardError
      raise Fault.new('local')
    end
    def unchanged?(snapshot)
      snapshot['files'].all? { |path, bytes| File.file?(path) && File.read(path) == bytes }
    end
    def ready?(snapshot, live)
      raw, runtime = snapshot.values_at('raw', 'runtime')
      return false unless raw['dns'].is_a?(Hash) && raw['dns']['nameserver'].is_a?(Array) && !raw['dns']['nameserver'].empty?
      # Verge adds IPv6 defaults even when DNS override is disabled. All MESL
      # fields must still match; only those known extra client fields are allowed.
      dns = runtime['dns']
      return false unless dns.is_a?(Hash) && raw['dns'].all? { |key, value| dns.key?(key) && dns[key] == value }
      return false unless (dns.keys - raw['dns'].keys - CLIENT_DNS_ADDITIONS).empty?
      return false unless raw['proxies'] == runtime['proxies'] && raw.fetch('proxy-providers', {}) == runtime.fetch('proxy-providers', {})
      names = raw.fetch('proxies', []).map { |n| n['name'] }
      names.all? { |name| live['proxies'].key?(name) }
    end
    def loaded?(routing, members, live)
      groups_ok = members.all? do |name, nodes|
        group = live['proxies'][name]
        group && group['type'] == 'Selector' && group['all'].is_a?(Array) && group['all'].sort == nodes.sort
      end
      actual = live['rules'].map { |r| [r['type'], r['payload'].to_s.downcase, r['proxy']] }
      expected = routing['rules'].map do |rule|
        f = rule.split(',')
        target = f.last == 'no-resolve' ? f[-2] : f.last
        [RULE_TYPES.fetch(f.first), f.first == 'MATCH' ? '' : f[1].downcase, target]
      end
      groups_ok && actual == expected
    end
    def selections(live)
      live['proxies'].select { |_name, group| group['type'] == 'Selector' }.transform_values { |g| g['now'] }
    end
    def restore_choices(runtime, choices, live)
      choices.each do |name, choice|
        group = live['proxies'][name]
        next unless group && group['type'] == 'Selector' && group.fetch('all', []).include?(choice)
        system.select(runtime, name, choice)
      end
    end
    def recover(binding)
      return unless File.file?(paths.journal)
      journal = XMClashSync.json(paths.journal)
      snap = snapshot(binding)
      raise Fault.new('busy') unless snap && XMClashSync.hash(snap['files'][snap['raw_path']]) == journal['raw_hash'] && XMClashSync.hash(snap['files'][File.join(paths.app, 'profiles.yaml')]) == journal['profiles_hash']
      raise Fault.new('busy') unless journal['script_path'] == snap['script_path'] && journal['runtime_path'] == snap['runtime_path']
      backup = File.join(paths.state, 'last-backup')
      old_runtime, old_script = %w[runtime.yaml script.js].map { |name| File.read(File.join(backup, name)) }
      runtime_bytes, script_bytes = snap['files'].values_at(snap['runtime_path'], snap['script_path'])
      raise Fault.new('busy') unless [XMClashSync.hash(old_runtime), journal['new_runtime_hash']].include?(XMClashSync.hash(runtime_bytes)) && [XMClashSync.hash(old_script), journal['new_script_hash']].include?(XMClashSync.hash(script_bytes))
      XMClashSync.atomic(snap['script_path'], old_script)
      XMClashSync.atomic(snap['runtime_path'], old_runtime)
      runtime = XMClashSync.parse(old_runtime)
      system.reload(runtime, old_runtime)
      restored = system.live(runtime)
      raise Fault.new('rollback') unless runtime_loaded?(runtime, restored)
      restore_choices(runtime, journal.fetch('choices', {}), restored)
      File.unlink(paths.journal)
    rescue Fault => e
      raise e if e.code == 'busy'
      raise Fault.new('rollback')
    rescue StandardError
      raise Fault.new('rollback')
    end
    def runtime_loaded?(runtime, live)
      expected = runtime.fetch('rules').map do |r|
        f = r.split(',')
        # Unknown original MESL rule types are checked by count; known types
        # are compared at their positions, including every managed XM rule.
        next nil unless RULE_TYPES.key?(f.first)
        [RULE_TYPES[f.first], f.first == 'MATCH' ? '' : f[1].downcase, f.last == 'no-resolve' ? f[-2] : f.last]
      end
      actual = live.fetch('rules').map { |r| [r['type'], r['payload'].to_s.downcase, r['proxy']] }
      actual.size == expected.size && expected.zip(actual).all? { |e, a| e.nil? || e == a }
    end
    def apply(snapshot, routing, members, live)
      runtime = snapshot['runtime']
      candidate = runtime.merge(routing)
      candidate['profile'] = runtime.fetch('profile', {}).merge('store-selected' => true)
      protected = runtime.keys - KEYS - ['profile']
      raise Fault.new('invalid') unless protected.all? { |key| candidate[key] == runtime[key] }
      candidate_bytes, new_script = YAML.dump(candidate), XMClashSync.extension(routing)
      system.check(paths, candidate_bytes)
      raise Fault.new('busy') unless unchanged?(snapshot)
      # Refresh choices immediately before the transaction, rather than before download.
      choices = selections(system.live(runtime))
      raise Fault.new('busy') unless unchanged?(snapshot)
      backup = File.join(paths.state, 'last-backup')
      XMClashSync.atomic(File.join(backup, 'runtime.yaml'), snapshot['files'][snapshot['runtime_path']])
      XMClashSync.atomic(File.join(backup, 'script.js'), snapshot['files'][snapshot['script_path']])
      journal = {'raw_hash' => XMClashSync.hash(snapshot['files'][snapshot['raw_path']]), 'profiles_hash' => XMClashSync.hash(snapshot['files'][File.join(paths.app, 'profiles.yaml')]), 'script_path' => snapshot['script_path'], 'runtime_path' => snapshot['runtime_path'], 'new_runtime_hash' => XMClashSync.hash(candidate_bytes), 'new_script_hash' => XMClashSync.hash(new_script), 'choices' => choices}
      XMClashSync.atomic(paths.journal, JSON.generate(journal))
      begin
        XMClashSync.atomic(snapshot['script_path'], new_script)
        XMClashSync.atomic(snapshot['runtime_path'], candidate_bytes)
        system.reload(runtime, candidate_bytes)
        after = system.live(runtime)
        raise Fault.new('apply') unless loaded?(routing, members, after)
        restore_choices(runtime, choices, after)
        expected = snapshot['files'].merge(snapshot['script_path'] => new_script, snapshot['runtime_path'] => candidate_bytes)
        raise Fault.new('busy') unless expected.all? { |path, bytes| File.read(path) == bytes }
        File.unlink(paths.journal)
      rescue StandardError => original
        begin
          recover(read_binding)
        rescue Fault => rollback
          raise Fault.new('rollback') if rollback.code == 'busy'
          raise rollback
        end
        raise original if original.is_a?(Fault) && original.code == 'busy'
        raise Fault.new('apply')
      end
    end
    def failure(state, code, now)
      count = state['error'] == code ? state.fetch('failures', 0) + 1 : 1
      delay = [60 * (2 ** [count - 1, 4].min), 900].min
      unless state['notified_error'] == code
        system.notify(code)
        state['notified_error'] = code
      end
      state.merge!('error' => code, 'failures' => count, 'retry_at' => now + delay, 'status' => 'error', 'last_event_at' => now)
    end
    def tick(force: false)
      FileUtils.mkdir_p(paths.state, mode: 0700)
      File.chmod(0700, paths.state)
      File.open(File.join(paths.state, 'sync.lock'), File::RDWR | File::CREAT, 0600) do |lock|
        return 'locked' unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        state = XMClashSync.json(paths.status)
        now = system.now
        begin
          binding = read_binding
          return 'disabled' unless binding['enabled'] || force
          snap = snapshot(binding)
          if !snap || !system.running?(paths) || !system.socket(snap['runtime'])
            state.merge!('status' => 'inactive', 'last_event_at' => now)
            return persist(state, 'inactive')
          end
          previous_inactive = state['status'] == 'inactive'
          recover(binding)
          snap = snapshot(binding)
          live = system.live(snap['runtime'])
          unless ready?(snap, live)
            state['pending_since'] ||= now
            failure(state, 'pending', now) if now - state['pending_since'] >= 300
            state['status'] = 'waiting_client'
            return persist(state, 'waiting_client')
          end
          state.delete('pending_since')
          return persist(state, 'backoff') if !force && !previous_inactive && state.fetch('retry_at', 0) > now && state.fetch('last_event_at', 0) <= now
          raw_hash = XMClashSync.hash(snap['files'][snap['raw_path']])
          identity = system.identity(snap['runtime'])
          cache_body = File.file?(paths.cache) ? File.read(paths.cache) : nil
          due = force || previous_inactive || !cache_body || state['base_hash'] != raw_hash || state['core_identity'] != identity || state.fetch('next_check_at', 0) <= now || state.fetch('last_checked_at', 0) > now
          stale = false
          fetched = nil
          body = cache_body
          if due
            begin
              fetched = system.fetch(paths, snap['runtime'], cache_body ? state['etag'] : nil)
              body = fetched['body'] || cache_body
              raise Fault.new('download') unless body
            rescue Fault => e
              raise unless e.code == 'download' && cache_body
              stale = true
              body = cache_body
            end
          end
          routing = XMClashSync.parse(body)
          members = XMClashSync.validate(routing, snap['runtime'])
          same_runtime = KEYS.all? { |key| snap['runtime'][key] == routing[key] }
          same_script = snap['files'][snap['script_path']] == XMClashSync.extension(routing)
          applied = !(same_runtime && same_script && loaded?(routing, members, live))
          apply(snap, routing, members, live) if applied
          # Cache is committed only after successful core validation/loading or known matching live state.
          XMClashSync.atomic(paths.cache, body) if fetched && fetched['body'] && cache_body != body
          state.merge!('base_hash' => raw_hash, 'core_identity' => identity, 'routing_hash' => XMClashSync.hash(routing), 'last_event_at' => now)
          state['last_applied_at'] = now if applied
          if stale
            failure(state, 'download', now)
            state['status'] = 'cached_latest_unconfirmed'
          else
            if due
              state.merge!('last_checked_at' => now, 'next_check_at' => now + 300, 'etag' => fetched && fetched['etag'])
            end
            %w[error notified_error failures retry_at].each { |key| state.delete(key) }
            state['status'] = 'current'
          end
          persist(state, applied ? 'applied' : (stale ? 'cached' : 'unchanged'))
        rescue Fault => e
          if e.code == 'busy'
            if File.file?(paths.journal)
              failure(state, 'rollback', now)
            else
              state.merge!('status' => 'deferred', 'last_event_at' => now)
            end
          else
            failure(state, e.code, now)
          end
          persist(state, e.code)
        rescue StandardError
          failure(state, 'internal', now)
          persist(state, 'internal')
        end
      end
    end
    def persist(state, result)
      XMClashSync.atomic(paths.status, JSON.pretty_generate(state))
      result
    end
  end

  class Installer
    def initialize(paths, system = System.new)
      @paths, @system = paths, system
    end
    def install(source_file)
      raise Fault.new('install') unless @system.mac?
      FileUtils.mkdir_p(@paths.state, mode: 0700)
      File.chmod(0700, @paths.state)
      File.open(File.join(@paths.state, 'sync.lock'), File::RDWR | File::CREAT, 0600) do |lock|
        raise Fault.new('busy') unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        profiles = XMClashSync.parse(File.read(File.join(@paths.app, 'profiles.yaml')))
        binding = XMClashSync.json(@paths.binding)
        if binding['uid']
          item = profiles.fetch('items').find { |i| i['uid'] == binding['uid'] }
          raise Fault.new('binding') unless item
        else
          matches = profiles.fetch('items').select { |i| i['name'] == 'MESL' && i['type'] == 'remote' }
          item = matches.find { |i| i['uid'] == profiles['current'] } || (matches.size == 1 ? matches.first : nil)
          raise Fault.new('binding') unless item
        end
        script = profiles.fetch('items').find { |i| i['uid'] == item.fetch('option')['script'] && i['type'] == 'script' }
        raise Fault.new('local') unless script
        [item, script].each do |entry|
          path = File.join(@paths.app, 'profiles', XMClashSync.filename(entry.fetch('file')))
          raise Fault.new('local') unless File.file?(path) && !File.symlink?(path)
        end
        bytes = File.read(source_file)
        parent = File.join(@paths.state, 'installer-backup')
        FileUtils.mkdir_p(parent, mode: 0700)
        backup = Dir.mktmpdir("#{@system.now}-", parent)
        old_files = [@paths.installed, @paths.agent, @paths.legacy_agent, @paths.binding].each_with_object({}) { |file, result| result[file] = File.file?(file) ? File.read(file) : nil }
        old_loaded = [LABEL, LEGACY_LABEL].select { |label| @system.loaded?(label) }
        old_files.each do |file, content|
          XMClashSync.atomic(File.join(backup, File.basename(file)), content) if content
        end
        begin
          @system.unload(LEGACY_LABEL)
          @system.unload(LABEL)
          File.unlink(@paths.legacy_agent) if File.file?(@paths.legacy_agent)
          XMClashSync.atomic(@paths.installed, bytes)
          File.chmod(0700, @paths.installed)
          manifest = {'uid' => item['uid'], 'source' => SOURCE, 'enabled' => true, 'schema' => 1}
          XMClashSync.atomic(@paths.binding, JSON.pretty_generate(manifest))
          XMClashSync.atomic(@paths.agent, plist)
          @system.load_agent(@paths.agent)
        rescue StandardError
          begin
            @system.unload(LABEL)
            old_files.each do |file, content|
              content ? XMClashSync.atomic(file, content) : (File.unlink(file) if File.file?(file))
            end
            File.chmod(0700, @paths.installed) if File.file?(@paths.installed)
            old_loaded.each { |label| @system.load_agent(label == LABEL ? @paths.agent : @paths.legacy_agent) }
          rescue StandardError
            # The private installer-backup remains available for manual repair.
          end
          raise Fault.new('install')
        end
      end
      'installed'
    rescue Fault
      raise
    rescue StandardError
      raise Fault.new('install')
    end
    def uninstall
      raise Fault.new('install') unless @system.mac?
      FileUtils.mkdir_p(@paths.state, mode: 0700)
      File.open(File.join(@paths.state, 'sync.lock'), File::RDWR | File::CREAT, 0600) do |lock|
        raise Fault.new('busy') unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        @system.unload(LABEL)
        File.unlink(@paths.agent) if File.file?(@paths.agent)
        if File.file?(@paths.binding)
          XMClashSync.atomic(File.join(@paths.state, 'previous-binding.json'), File.read(@paths.binding))
          File.unlink(@paths.binding)
        end
      end
      'uninstalled; current routing, backups and tool retained'
    rescue Fault
      raise
    rescue StandardError
      raise Fault.new('install')
    end
    def plist
      escaped = CGI.escapeHTML(@paths.installed)
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\"><dict>\n<key>Label</key><string>#{LABEL}</string>\n<key>ProgramArguments</key><array><string>/usr/bin/ruby</string><string>#{escaped}</string><string>--tick</string></array>\n<key>RunAtLoad</key><true/>\n<key>StartInterval</key><integer>60</integer>\n<key>ProcessType</key><string>Background</string>\n</dict></plist>\n"
    end
    def status
      binding = XMClashSync.json(@paths.binding)
      state = XMClashSync.json(@paths.status)
      {'installed' => File.file?(@paths.installed), 'enabled' => binding['enabled'] == true, 'agent_loaded' => @system.mac? && @system.loaded?(LABEL), 'status' => state['status'] || 'not_yet_checked', 'last_checked_at' => state['last_checked_at'], 'last_applied_at' => state['last_applied_at'], 'retry_at' => state['retry_at'], 'error' => state['error'] && MESSAGES.fetch(state['error'], MESSAGES['internal'])}
    end
  end

  def self.cli(args)
    paths = Paths.new(Dir.home)
    installer = Installer.new(paths)
    case args
    when ['--install']
      puts installer.install(__FILE__)
    when ['--uninstall']
      puts installer.uninstall
    when ['--status']
      puts JSON.pretty_generate(installer.status)
    when ['--once'], ['--tick']
      result = Runner.new(paths).tick(force: args == ['--once'])
      puts result if args == ['--once']
      return %w[download invalid core_test apply rollback binding local internal].include?(result) ? 1 : 0
    else
      puts 'Usage: ruby sync-routing.rb --install | --uninstall | --status | --once'
      return 2
    end
    0
  rescue Fault => e
    warn "#{e.code}: #{e.message}"
    1
  rescue StandardError
    warn MESSAGES['internal']
    1
  end
end
exit XMClashSync.cli(ARGV) if __FILE__ == $0
