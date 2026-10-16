#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# XM-Clash.yaml：Clash App（clash.md，iPhone / iPad / Mac）用的规则配置。
# 不含节点、订阅或占位；节点来自 App 里另外导入的 MESL 节点来源，各组用 include-all + filter 筛选并自动测速。
clash = YAML.safe_load(File.read(File.join(root, 'XM-Clash.yaml')))
abort 'Clash: unexpected top-level fields' unless clash.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-groups rules].sort
abort 'Clash: must not contain nodes or subscriptions' if %w[proxies proxy-providers rule-providers].any? { |k| clash.key?(k) }
abort 'Clash: mode must be rule and IPv6 off' unless clash['mode'] == 'rule' && clash['ipv6'] == false
dns = clash.fetch('dns')
abort 'Clash: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off' unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]

# 分组：名称、顺序、筛选结果固定。用 MESL 风格的节点名样本检查每个 filter 选中的节点。
jp = (2..7).map { |n| '🇯🇵 日本 %02d' % n }
us = (1..3).map { |n| '🇺🇸 美国 %02d' % n } + (10..12).map { |n| '🇺🇸 美国 %02d 家宽' % n }
w3 = ['🇲🇾 马来西亚 01 家宽', '🇲🇾 马来西亚 03 家宽', '🇵🇭 菲律宾 01', '🇵🇭 菲律宾 02 家宽', '🇻🇳 越南 家宽', '🇭🇰 香港 14 家宽']
tw = ['🇨🇳 台湾 08 家宽', '🇨🇳 台湾 09 家宽']
expected = { 'XM-Google' => jp, 'XM-AI' => jp, 'XM-Meta' => us, 'XM-Web3' => w3, 'XM-Bybit' => tw, 'XM-日常上网' => jp }
samples = (1..15).flat_map { |n| ['🇯🇵 日本 %02d', '🇯🇵 日本 %02d 家宽', '🇺🇸 美国 %02d', '🇺🇸 美国 %02d 家宽', '🇲🇾 马来西亚 %02d', '🇲🇾 马来西亚 %02d 家宽',
  '🇵🇭 菲律宾 %02d', '🇵🇭 菲律宾 %02d 家宽', '🇭🇰 香港 %02d', '🇭🇰 香港 %02d 家宽', '🇨🇳 台湾 %02d', '🇨🇳 台湾 %02d 家宽'].map { |f| f % n } } +
  ['🇨🇳 台湾 01 [0.3X]', '🇯🇵 日本 01 [0.3X]', '🇭🇰 香港 03 [0.3X]', '🇯🇵 日本 05 [0.3X]', '🇻🇳 越南', '🇻🇳 越南 家宽', '🇲🇾 马来西亚', '🇵🇭 菲律宾']
groups = clash.fetch('proxy-groups')
abort 'Clash: groups must be exactly the six XM groups in order' unless groups.map { |g| g['name'] } == expected.keys
url = 'https://www.gstatic.com/generate_204'
groups.each do |g|
  name = g['name']
  abort "Clash: #{name} must take nodes via include-all + filter only" unless g['include-all'] == true && !g.key?('proxies') && !g.key?('use')
  abort "Clash: #{name} wrong test options" unless g['url'] == url && g['interval'] == 900 && g['timeout'] == 5000
  if name == 'XM-Bybit'
    abort 'Clash: XM-Bybit must be fallback' unless g['type'] == 'fallback' && !g.key?('tolerance')
  else
    abort "Clash: #{name} must be url-test with 20ms tolerance" unless g['type'] == 'url-test' && g['tolerance'] == 20
  end
  # mihomo 的 filter 用反引号分隔多个正则，按顺序拼接结果（XM-Bybit 靠它保证 08 在前）。
  selected = g.fetch('filter').split('`').flat_map { |re| samples.select { |n| Regexp.new(re).match?(n) } }.uniq
  abort "Clash: #{name} filter selects #{selected.inspect}" unless name == 'XM-Bybit' ? selected == tw : selected.sort == expected[name].sort
end

# 规则：语法、目标、顺序与重复检查。
rules = clash.fetch('rules')
policies = expected.keys + %w[DIRECT REJECT]
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
puts "Validated XM-Clash.yaml: 5 url-test groups + XM-Bybit fallback (include-all + filter, no nodes or subscriptions), #{rules.size} rules."
