#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# XM-Clash-JSY.yaml：Clash App（clash.md，iPhone / iPad / Mac）用的规则配置，节点来自 App 里另外导入的极速云订阅。
# 不含节点、订阅或占位；各组用 include-all + filter + exclude-filter 筛选并自动测速。
FILE = 'XM-Clash-JSY.yaml'.freeze
GROUP_NAMES = ['XM-Google', 'XM-AI', 'XM-Web3', 'XM-Bybit', 'XM-日常上网'].freeze
TEST_URL = 'https://www.gstatic.com/generate_204'.freeze

# 任何分组都不得包含香港节点。每组必须有 exclude-filter，且它要能剔除下面这些（虚构的）香港节点名；
# 另外把每个预期节点名套上香港前缀 / 后缀做成对抗样本，确认 filter 选中后也会被剔除。
HK_SAMPLES = ['🇭🇰 香港 01', '🇭🇰 香港_03', '🇭🇰 香港HKT家宽1', 'HK 01', 'hk-02', 'Hong Kong 03', 'HongKong 04', 'hong kong 05', '🇭🇰 Test'].freeze
HK_RE = /香港|hk|hong ?kong|🇭🇰/i
INFO_SAMPLES = ['剩余流量：100.00 GB', '套餐到期：长期有效', '官网：example'].freeze
def hk_variants(name)
  ["🇭🇰 香港 #{name}", "HK #{name}", "Hong Kong #{name}", name.sub(/\A\S+ /, '🇭🇰 '), "香港中转 #{name}"]
end

# 节点名形如「🇯🇵 日本_05」「🇸🇬 新加坡_02」（以下全是虚构样例，不是真实节点）；另有「剩余流量」「套餐到期」等信息条目，必须被排除。
jp = (1..12).map { |n| '🇯🇵 日本_%02d' % n }
EXPECTED = {
  'XM-Google' => jp, 'XM-AI' => jp, 'XM-日常上网' => jp,
  'XM-Web3' => ['🇲🇾 马来西亚', '🇵🇭 菲律宾', '🇻🇳 越南'] + (1..12).map { |n| '🇸🇬 新加坡_%02d' % n },
  'XM-Bybit' => (1..12).map { |n| '🇹🇼 台湾_%02d' % n }
}.freeze
SAMPLES = (1..12).flat_map { |n| ['🇯🇵 日本_%02d', '🇺🇸 美国_%02d', '🇭🇰 香港_%02d', '🇹🇼 台湾_%02d', '🇸🇬 新加坡_%02d', '🇰🇷 韩国%02d'].map { |f| f % n } } +
  (1..6).map { |n| '🇭🇰 香港HKT家宽%d' % n } +
  ['🇯🇵 日本', '🇺🇸 美国', '🇲🇾 马来西亚', '🇵🇭 菲律宾', '🇻🇳 越南', '🇹🇼 台湾', '🇯🇵 日本_01 [0.5X]',
   '剩余流量：100.00 GB', '套餐到期：长期有效', '官网：example', '距离下次重置剩余：30 天', '订阅更新时间', '剩余流量 日本_01', '套餐到期 台湾_01', '官网 新加坡_01', '过期时间 日本_02']

clash = YAML.safe_load(File.read(File.join(root, FILE)))
abort "#{FILE}: unexpected top-level fields" unless clash.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-groups rules].sort
abort "#{FILE}: must not contain nodes or subscriptions" if %w[proxies proxy-providers rule-providers].any? { |k| clash.key?(k) }
abort "#{FILE}: mode must be rule and IPv6 off" unless clash['mode'] == 'rule' && clash['ipv6'] == false
dns = clash.fetch('dns')
abort "#{FILE}: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off" unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]
groups = clash.fetch('proxy-groups')
abort "#{FILE}: groups must be exactly the five XM groups in order" unless groups.map { |g| g['name'] } == GROUP_NAMES
allowed_keys = %w[name type include-all filter exclude-filter url interval tolerance timeout]
samples = SAMPLES + HK_SAMPLES + EXPECTED.values.flatten.uniq.flat_map { |n| hk_variants(n) }
hk_direct = HK_SAMPLES + (1..15).flat_map { |n| ['🇭🇰 香港 %02d' % n, '🇭🇰 香港_%02d' % n, '🇭🇰 香港HKT家宽%d' % n] }
groups.each do |g|
  name = g['name']
  abort "#{FILE}: #{name} has unexpected keys #{(g.keys - allowed_keys).inspect}" unless (g.keys - allowed_keys).empty?
  abort "#{FILE}: #{name} must take nodes via include-all + filter only" unless g['include-all'] == true && g['filter'].is_a?(String)
  abort "#{FILE}: #{name} must have exclude-filter" unless g['exclude-filter'].is_a?(String)
  excl = Regexp.new(g['exclude-filter'])
  abort "#{FILE}: #{name} exclude-filter must remove every Hong Kong node" unless HK_SAMPLES.all? { |n| excl.match?(n) }
  abort "#{FILE}: #{name} exclude-filter must remove info nodes" unless INFO_SAMPLES.all? { |n| excl.match?(n) }
  abort "#{FILE}: #{name} wrong test options" unless g['url'] == TEST_URL && g['interval'] == 900 && g['timeout'] == 5000
  if name == 'XM-Bybit'
    abort "#{FILE}: XM-Bybit must be fallback" unless g['type'] == 'fallback' && !g.key?('tolerance')
  else
    abort "#{FILE}: #{name} must be url-test with 20ms tolerance" unless g['type'] == 'url-test' && g['tolerance'] == 20
  end
  regs = g.fetch('filter').split('`').map { |re| Regexp.new(re) }
  hk_hit = regs.flat_map { |re| hk_direct.grep(re) }
  abort "#{FILE}: #{name} filter itself matches Hong Kong nodes #{hk_hit.uniq.inspect}" unless hk_hit.empty?
  # mihomo 的 filter 用反引号分隔多个正则，按顺序拼接结果（XM-Bybit 靠它保证优先级）；exclude-filter 再剔除。
  selected = regs.flat_map { |re| samples.select { |n| re.match?(n) } }.uniq
  selected.reject! { |n| excl.match?(n) }
  abort "#{FILE}: #{name} would contain Hong Kong nodes #{selected.grep(HK_RE).inspect}" unless selected.grep(HK_RE).empty?
  abort "#{FILE}: #{name} selects no nodes" if selected.empty?
  want = EXPECTED[name]
  ok = name == 'XM-Bybit' ? selected == want : selected.sort == want.sort
  abort "#{FILE}: #{name} filter selects #{selected.inspect}" unless ok
end

# 规则：语法、目标、顺序与重复检查。
rules = clash.fetch('rules')
policies = GROUP_NAMES + %w[DIRECT REJECT]
domain_types = %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD]
ip_types = %w[IP-CIDR IP-CIDR6]
seen = {}
rules.each_with_index do |rule, i|
  abort "Clash: rule must be a string: #{rule.inspect}" unless rule.is_a?(String) && rule == rule.strip && !rule.include?(' ')
  fields = rule.split(',', -1)
  abort "Clash: empty field in #{rule}" if fields.any?(&:empty?)
  type = fields.first
  if type == 'MATCH'
    abort 'Clash: MATCH must be the last rule' unless i == rules.size - 1 && fields.size == 2
    condition, target = nil, fields[1]
  elsif domain_types.include?(type)
    abort "Clash: bad domain rule #{rule}" unless fields.size == 3 && fields[1].match?(/\A[a-z0-9.-]+\z/) && !fields[1].start_with?('.') && !fields[1].end_with?('.')
    condition, target = fields[1], fields[2]
  elsif ip_types.include?(type)
    abort "Clash: bad IP rule #{rule}" unless [3, 4].include?(fields.size) && (fields.size == 3 || fields[3] == 'no-resolve')
    require 'ipaddr'
    begin
      ip = IPAddr.new(fields[1])
    rescue IPAddr::Error
      abort "Clash: bad CIDR in #{rule}"
    end
    abort "Clash: #{type} family mismatch in #{rule}" unless (type == 'IP-CIDR') == ip.ipv4?
    condition, target = fields[1], fields[2]
  elsif type == 'GEOIP'
    abort "Clash: bad GEOIP rule #{rule}" unless fields.size == 3 && fields[1].match?(/\A[A-Z]{2}\z/)
    condition, target = fields[1], fields[2]
  else
    abort "Clash: unsupported rule type in #{rule}"
  end
  abort "Clash: unknown policy #{target} in #{rule}" unless policies.include?(target)
  key = [type, condition]
  abort "Clash: duplicate condition #{rule} (first: #{seen[key]})" if seen.key?(key)
  seen[key] = rule
end
abort 'Clash: must end with GEOIP,CN,DIRECT then MATCH,XM-日常上网' unless rules.last(2) == ['GEOIP,CN,DIRECT', 'MATCH,XM-日常上网']
abort 'Clash: LAN ranges must be direct first' unless rules.first(11).all? { |r| r.match?(/\A(DOMAIN(-SUFFIX)?,(localhost|local|lan)|IP-CIDR6?,.*),DIRECT(,no-resolve)?\z/) }
abort 'Clash: Bybit must use XM-Bybit' unless %w[bybit.com bybit.biz byabcde.com bycsi.com].all? { |d| rules.include?("DOMAIN-SUFFIX,#{d},XM-Bybit") } && rules.none? { |r| r.match?(/by(bit|abcde|csi)/) && !r.end_with?(',XM-Bybit') }
abort 'Clash: AI Google domains must precede Google' unless rules.index('DOMAIN-SUFFIX,gemini.google.com,XM-AI') < rules.index('DOMAIN-SUFFIX,google.com,XM-Google')
# 后面的后缀规则不能被前面更宽的后缀规则遮住（否则永远匹配不到）。
suffixes = []
rules.each do |r|
  type, value = r.split(',')
  next unless %w[DOMAIN DOMAIN-SUFFIX].include?(type)
  shadow = suffixes.find { |s| value == s || value.end_with?(".#{s}") }
  abort "Clash: #{r} is shadowed by DOMAIN-SUFFIX,#{shadow}" if shadow
  suffixes << value if type == 'DOMAIN-SUFFIX'
end
puts "Validated #{FILE}: 4 url-test groups + XM-Bybit fallback (include-all + filter + exclude-filter, no HK, no nodes or subscriptions), #{rules.size} rules."
