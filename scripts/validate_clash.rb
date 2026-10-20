#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# XM-Clash-JSY.yaml（极速云）与 XM-Clash-HY.yaml（花云）：Clash App（clash.md，iPhone / iPad / Mac）用的规则配置，节点来自 App 里另外导入的订阅。
# 两份文件的 rules 部分（从「# 规则从上到下匹配」到文件末尾）必须逐字节一致；两家节点命名不同，分组筛选各用一套虚构样例检查。
# 不含节点、订阅或占位；各组用 include-all + filter + exclude-filter 筛选并自动测速。
FILES = ['XM-Clash-JSY.yaml', 'XM-Clash-HY.yaml'].freeze
GROUP_NAMES = ['XM-Google', 'XM-AI', 'XM-Web3', 'XM-Bybit', 'XM-日常上网', 'XM-Apple'].freeze
TEST_URL = 'https://www.gstatic.com/generate_204'.freeze

# 任何分组都不得包含香港节点。每组必须有 exclude-filter，且它要能剔除下面这些（虚构的）香港节点名；
# 另外把每个预期节点名套上香港前缀 / 后缀做成对抗样本，确认 filter 选中后也会被剔除。
HK_SAMPLES = ['🇭🇰 香港 01', '🇭🇰 香港_03', '🇭🇰 香港HKT家宽1', 'HK 01', 'hk-02', 'Hong Kong 03', 'HongKong 04', 'hong kong 05', '🇭🇰 Test'].freeze
HK_RE = /香港|hk|hong ?kong|🇭🇰/i
def hk_variants(name)
  ["🇭🇰 香港 #{name}", "HK #{name}", "Hong Kong #{name}", name.sub(/\A\S+ /, '🇭🇰 '), "香港中转 #{name}"]
end

# 节点名形如「🇯🇵 日本_05」「🇸🇬 新加坡_02」（以下全是虚构样例，不是真实节点）；另有「剩余流量」「套餐到期」等信息条目，必须被排除。
jp = (1..12).map { |n| '🇯🇵 日本_%02d' % n }
JSY_EXPECTED = {
  'XM-Google' => jp, 'XM-AI' => jp, 'XM-日常上网' => jp,
  'XM-Web3' => ['🇲🇾 马来西亚', '🇵🇭 菲律宾', '🇻🇳 越南'] + (1..12).map { |n| '🇸🇬 新加坡_%02d' % n },
  'XM-Bybit' => (1..12).map { |n| '🇹🇼 台湾_%02d' % n },
  'XM-Apple' => (1..3).map { |n| '🇺🇸 美国_%02d' % n }
}.freeze
JSY_SAMPLES = (1..12).flat_map { |n| ['🇯🇵 日本_%02d', '🇺🇸 美国_%02d', '🇭🇰 香港_%02d', '🇹🇼 台湾_%02d', '🇸🇬 新加坡_%02d', '🇰🇷 韩国%02d'].map { |f| f % n } } +
  (1..6).map { |n| '🇭🇰 香港HKT家宽%d' % n } +
  ['🇯🇵 日本', '🇺🇸 美国', '🇲🇾 马来西亚', '🇵🇭 菲律宾', '🇻🇳 越南', '🇹🇼 台湾', '🇯🇵 日本_01 [0.5X]',
   '剩余流量：100.00 GB', '套餐到期：长期有效', '官网：example', '距离下次重置剩余：30 天', '订阅更新时间', '剩余流量 日本_01', '套餐到期 台湾_01', '官网 新加坡_01', '过期时间 日本_02']

# 花云：节点名形如「🇯🇵 日本高级 IEPL 专线 1」「🇨🇳 台湾标准 IEPL 专线 2」，信息条目为英文「Traffic: … | …」「Expire: …」（以下全是虚构样例）。
# 花云版 filter 同时兼容「日本_01」写法，所以样例也包含极速云风格。
TIERS = ['高级', '实验性', '标准'].freeze
hy = ->(flag, place, ns) { TIERS.flat_map { |t| ns.map { |n| "#{flag} #{place}#{t} IEPL 专线 #{n}" } } }
hy_jp = hy.call('🇯🇵', '日本', 1..9)
hy_sea = hy.call('🇸🇬', '新加坡', 1..9) + hy.call('🇲🇾', '马来西亚', 1..2) + hy.call('🇵🇭', '菲律宾', 1..2) + hy.call('🇻🇳', '越南', 1..2)
hy_tw = (1..5).map { |n| "🇨🇳 台湾高级 IEPL 专线 #{n}" }
hy_tw_other = (1..5).flat_map { |n| ["🇨🇳 台湾标准 IEPL 专线 #{n}", "🇨🇳 台湾实验性 IEPL 专线 #{n}"] }
hy_jp_pick = (1..3).map { |n| "🇯🇵 日本高级 IEPL 专线 #{n}" } + ['🇯🇵 日本实验性 IEPL 专线 1']
hy_sea_pick = (1..3).map { |n| "🇸🇬 新加坡高级 IEPL 专线 #{n}" } + ['🇲🇾 马来西亚标准 IEPL 专线 1', '🇵🇭 菲律宾标准 IEPL 专线 1', '🇻🇳 越南标准 IEPL 专线 1']
HY_EXPECTED = {
  # 花云每组只留 4–6 个：日本高级 1–3 + 日本实验性 1；新加坡高级 1–3 + 马来西亚/菲律宾/越南标准 1。
  'XM-Google' => hy_jp_pick, 'XM-AI' => hy_jp_pick, 'XM-日常上网' => hy_jp_pick,
  'XM-Web3' => hy_sea_pick,
  'XM-Bybit' => JSY_EXPECTED['XM-Bybit'] + hy_tw,
  'XM-Apple' => (1..3).map { |n| "🇺🇸 美国高级 IEPL 专线 #{n}" }
}.freeze
HY_SAMPLES = JSY_SAMPLES + hy_jp + hy_sea + hy_tw + hy_tw_other + hy.call('🇺🇸', '美国', 1..9) + hy.call('🇭🇰', '香港', 1..9) + hy.call('🇰🇷', '韩国', 1..3) +
  hy.call('🇹🇭', '泰国', 1..2) + hy.call('🇮🇩', '印尼', 1..2) +
  ['Traffic: 0.08 GB | 150 GB', 'Expire: 2030-01-01', 'traffic 日本高级 IEPL 专线 1', 'EXPIRE 台湾高级 IEPL 专线 1', 'Traffic 新加坡标准 IEPL 专线 1']
INFO = ['剩余流量：100.00 GB', '套餐到期：长期有效', '官网：example'].freeze
PROFILES = {
  'XM-Clash-JSY.yaml' => { expected: JSY_EXPECTED, samples: JSY_SAMPLES, info: INFO,
                           bybit_order: [['🇹🇼 台湾_01'], ['🇹🇼 台湾_02']] },
  'XM-Clash-HY.yaml' => { expected: HY_EXPECTED, samples: HY_SAMPLES, info: INFO + ['Traffic: 1 GB | 100 GB', 'Expire: 2030-01-01', 'TRAFFIC 1 GB'],
                          bybit_order: nil }
}.freeze

def check_file(root, file)
  prof = PROFILES.fetch(file)
  clash = YAML.safe_load(File.read(File.join(root, file)))
  abort "#{file}: unexpected top-level fields" unless clash.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-groups rules].sort
  abort "#{file}: must not contain nodes or subscriptions" if %w[proxies proxy-providers rule-providers].any? { |k| clash.key?(k) }
  abort "#{file}: mode must be rule and IPv6 off" unless clash['mode'] == 'rule' && clash['ipv6'] == false
  dns = clash.fetch('dns')
  abort "#{file}: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off" unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]
  groups = clash.fetch('proxy-groups')
  abort "#{file}: groups must be exactly the six XM groups in order" unless groups.map { |g| g['name'] } == GROUP_NAMES
  allowed_keys = %w[name type include-all filter exclude-filter url interval tolerance timeout]
  samples = prof[:samples] + HK_SAMPLES + prof[:expected].values.flatten.uniq.flat_map { |n| hk_variants(n) }
  hk_direct = HK_SAMPLES + (1..15).flat_map { |n| ['🇭🇰 香港 %02d' % n, '🇭🇰 香港_%02d' % n, '🇭🇰 香港HKT家宽%d' % n] + TIERS.map { |t| "🇭🇰 香港#{t} IEPL 专线 #{n}" } }
  groups.each do |g|
    name = g['name']
    abort "#{file}: #{name} has unexpected keys #{(g.keys - allowed_keys).inspect}" unless (g.keys - allowed_keys).empty?
    abort "#{file}: #{name} must take nodes via include-all + filter only" unless g['include-all'] == true && g['filter'].is_a?(String)
    abort "#{file}: #{name} must have exclude-filter" unless g['exclude-filter'].is_a?(String)
    excl = Regexp.new(g['exclude-filter'])
    abort "#{file}: #{name} exclude-filter must remove every Hong Kong node" unless HK_SAMPLES.all? { |n| excl.match?(n) }
    abort "#{file}: #{name} exclude-filter must remove info nodes" unless prof[:info].all? { |n| excl.match?(n) }
    abort "#{file}: #{name} wrong test options" unless g['url'] == TEST_URL && g['interval'] == 900 && g['timeout'] == 5000
    if name == 'XM-Bybit'
      abort "#{file}: XM-Bybit must be fallback" unless g['type'] == 'fallback' && !g.key?('tolerance')
    else
      abort "#{file}: #{name} must be url-test with 20ms tolerance" unless g['type'] == 'url-test' && g['tolerance'] == 20
    end
    regs = g.fetch('filter').split('`').map { |re| Regexp.new(re) }
    hk_hit = regs.flat_map { |re| hk_direct.grep(re) }
    abort "#{file}: #{name} filter itself matches Hong Kong nodes #{hk_hit.uniq.inspect}" unless hk_hit.empty?
    # mihomo 的 filter 用反引号分隔多个正则，按顺序拼接结果（XM-Bybit 靠它保证优先级）；exclude-filter 再剔除。
    selected = regs.flat_map { |re| samples.select { |n| re.match?(n) } }.uniq
    selected.reject! { |n| excl.match?(n) }
    abort "#{file}: #{name} would contain Hong Kong nodes #{selected.grep(HK_RE).inspect}" unless selected.grep(HK_RE).empty?
    abort "#{file}: #{name} selects no nodes" if selected.empty?
    want = prof[:expected][name]
    ok = selected.sort == want.sort
    if ok && name == 'XM-Bybit' && prof[:bybit_order]
      # fallback 顺序：1 号在前、2 号其次、其余在后。
      first, second = prof[:bybit_order]
      n1 = first.size
      n2 = second.size
      ok = selected.first(n1).sort == first.sort && selected[n1, n2].sort == second.sort
    end
    abort "#{file}: #{name} filter selects #{selected.inspect}" unless ok
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
  # 美区 App Store / Apple TV 走 XM-Apple；iCloud、推送、系统更新必须保持直连。
  apple = %w[apps.apple.com itunes.apple.com mzstatic.com cdn-apple.com tv.apple.com]
  abort 'Clash: App Store / Apple TV must use XM-Apple' unless apple.all? { |d| rules.include?("DOMAIN-SUFFIX,#{d},XM-Apple") }
  direct = %w[DOMAIN-SUFFIX,icloud.com DOMAIN-SUFFIX,icloud-content.com DOMAIN-SUFFIX,push.apple.com DOMAIN,swcdn.apple.com DOMAIN,swdist.apple.com DOMAIN,swscan.apple.com DOMAIN,mesu.apple.com DOMAIN,appldnld.apple.com DOMAIN-SUFFIX,aaplimg.com]
  abort 'Clash: iCloud / push / system updates must stay DIRECT' unless direct.all? { |d| rules.include?("#{d},DIRECT") }
  # 后面的后缀规则不能被前面更宽的后缀规则遮住（否则永远匹配不到）。
  suffixes = []
  rules.each do |r|
    type, value = r.split(',')
    next unless %w[DOMAIN DOMAIN-SUFFIX].include?(type)
    shadow = suffixes.find { |s| value == s || value.end_with?(".#{s}") }
    abort "Clash: #{r} is shadowed by DOMAIN-SUFFIX,#{shadow}" if shadow
    suffixes << value if type == 'DOMAIN-SUFFIX'
  end
  rules.size
end

counts = FILES.map { |f| check_file(root, f) }
marker = "\n# 规则从上到下匹配"
texts = FILES.map { |f| File.read(File.join(root, f)) }
abort 'Clash: rules marker missing' unless texts.all? { |t| t.scan(marker).size == 1 }
abort "Clash: #{FILES[1]} rules section must be byte-identical to #{FILES[0]}" unless texts.map { |t| t.split(marker, 2)[1] }.uniq.size == 1
puts "Validated #{FILES.join(' + ')} (identical rules): 5 url-test groups + XM-Bybit fallback each (include-all + filter + exclude-filter, no HK, no nodes or subscriptions), #{counts.first} rules."
