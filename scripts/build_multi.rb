#!/usr/bin/env ruby
# 从四份规则里的那一份（rules 逐字节相同）生成多订阅方案。
# 订阅地址不写进仓库。XM-Clash-MULTI.yaml 里只有占位符，本机副本由本地脚本填。
require 'yaml'
root = File.expand_path('..', __dir__)
rules = YAML.safe_load(File.read(File.join(root, 'XM-Clash-JSY.yaml'))).fetch('rules')
abort 'expected 234 rules' unless rules.size == 234

def target_of(rule)
  fields = rule.split(',')
  return fields[1] if fields[0] == 'MATCH'
  return fields[-2] if fields.last == 'no-resolve'
  fields.last
end

runs = []
rules.each do |rule|
  target = target_of(rule)
  if runs.empty? || runs[-1][0] != target || rule.start_with?('MATCH,')
    runs << [target, [rule]]
  else
    runs[-1][1] << rule
  end
end
abort 'last run must be MATCH' unless runs.last[0] == 'XM-日常上网' && runs.last[1] == ['MATCH,XM-日常上网']
body = runs[0..-2]
# GEOIP 在 classical 规则集里不会被 1.19.32 装入（ruleCount 为 0）。留在主配置。
geoip = body.last
abort 'expected GEOIP segment' unless geoip[1] == ['GEOIP,CN,DIRECT']
body = body[0..-2]
abort 'expected 19 rule-provider segments' unless body.size == 19

def q(s)
  "'" + s.gsub("'", "''") + "'"
end

# mihomo 1.19.32 解析 classical 时 needTarget=false，行尾策略不会被当成 target。
# AND 会因此把 REJECT 拼进条件，GEOIP 会多出一个参数。策略只写在 RULE-SET 上。
def payload_line(rule)
  fields = rule.split(',')
  if fields[0] == 'AND'
    fields[0..-2].join(',')
  elsif fields.last == 'no-resolve'
    (fields[0..-3] + ['no-resolve']).join(',')
  else
    fields[0..-2].join(',')
  end
end

Dir.mkdir(File.join(root, 'rules')) unless Dir.exist?(File.join(root, 'rules'))
body.each_with_index do |(_target, lines), i|
  path = File.join(root, 'rules', format('xm-seg-%02d.yaml', i))
  File.write(path, "payload:\n" + lines.map { |l| "  - #{q(payload_line(l))}\n" }.join)
end
File.write(File.join(root, 'rules', 'xm-rules.yaml'), "payload:\n" + rules.map { |l| "  - #{q(l)}\n" }.join)

excl = '(?i)剩余|流量|套餐|到期|过期|官网|重置|订阅|香港|HK|Hong ?Kong|🇭🇰|Traffic|Expire'
web3_excl = excl + '|美国|新加坡|台湾|日本'
health = <<~YAML
    url: https://www.gstatic.com/generate_204
    interval: 300
    timeout: 5000
YAML
health9 = health.sub('interval: 300', 'interval: 900')

def group(name, type, extra)
  "  - name: #{name}\n    type: #{type}\n#{extra.gsub(/^/, '    ')}"
end

segs = body.each_with_index.map do |(target, _lines), i|
  name = format('xm-seg-%02d', i)
  url = ('https' + '://raw.githubusercontent.com/symonxu/clash-rules/main/rules/xm-seg-%02d.yaml') % i
  <<~YAML
    #{name}:
      type: http
      behavior: classical
      format: yaml
      url: #{q(url)}
      path: ./providers/#{name}.yaml
      interval: 86400
  YAML
end.join

rule_lines = body.each_with_index.map { |(target, _), i| "  - RULE-SET,xm-seg-#{format('%02d', i)},#{target}" }
rule_lines << '  - GEOIP,CN,DIRECT'
rule_lines << '  - MATCH,XM-日常上网'

openbot_filter = '(^| )日本_01$`(^| )日本_07$`(^| )日本_05$`(^| )日本_08$`(^| )日本_06$`(^| )日本_04$`(^| )日本_02$`(^| )日本_03$'
hy_jp = '(^| )日本高级 IEPL 专线 [1-3]$`(^| )日本标准 IEPL 专线 [1-4]$'
jsy_jp = '(^| )日本_[0-9]+$'
hy_web3 = '(^| )韩国标准 IEPL 专线 [12]$`(^| )越南标准 IEPL 专线 1$`(^| )印尼标准 IEPL 专线 1$'
hy_web3_extra = '(^| )马来西亚标准 IEPL 专线 [0-9]+$`(^| )菲律宾标准 IEPL 专线 [0-9]+$`(^| )泰国标准 IEPL 专线 [0-9]+$'
hy_tw = '(^| )台湾高级 IEPL 专线 [1-3]$`(^| )台湾标准 IEPL 专线 [1-3]$'
jsy_tw = '(^| )台湾_01$`(^| )台湾_02$`(^| )台湾_(0[3-9]|[1-9][0-9])$'
hy_us = '(^| )美国高级 IEPL 专线 [1-3]$`(^| )美国标准 IEPL 专线 [1-4]$'
jsy_us = '(^| )美国_0[1-3]$'
anki = '(^| )日本高级 IEPL 专线 1$`(^| )日本高级 IEPL 专线 2$`(^| )日本高级 IEPL 专线 3$`(^| )日本_01$`(^| )日本_02$`(^| )日本_03$'
sys_hy = '(^| )日本高级 IEPL 专线 1$`(^| )日本高级 IEPL 专线 2$`(^| )日本高级 IEPL 专线 3$'
sys_jsy = '(^| )日本_01$`(^| )日本_02$`(^| )日本_03$'

HEALTH = 'https://www.gstatic.com/generate_204'
def health(interval, tolerance = nil)
  lines = ["url: #{HEALTH}", "interval: #{interval}"]
  lines << "tolerance: #{tolerance}" if tolerance
  lines << "timeout: 5000"
  lines.join("\n")
end

def use_group(name, type, providers, filter, excl, test)
  lines = ["  - name: #{name}", "    type: #{type}", "    use: [#{providers.join(', ')}]"]
  lines << "    filter: #{q(filter)}"
  lines << "    exclude-filter: #{q(excl)}"
  unless test.nil? || test.strip.empty?
    test.each_line { |line| lines << "    #{line.strip}" }
  end
  lines.join("\n")
end

text = <<~YAML
  # XM Clash 多订阅方案（模板）。仓库里没有订阅地址。
  # 本机可导入的副本是 local/XM-Clash-MULTI.yaml（不入库）：只把下面两个 PASTE_ 占位符换成极速云、花云的订阅地址。
  # 导入时作为一份独立配置，不要把它当成「规则方案」挂到某一个订阅上，否则 App 只会留下那一家节点。
  # iPhone 不能用 type: file 的外部节点集（Clash 1.0.14 会拒绝）。这里用 type: http。
  # 规则按策略切成 19 个 classical 规则集。mihomo 1.19.32 的一条 RULE-SET 只使用这一条上的策略；AND 的策略不能留在规则集行内；GEOIP 放进规则集会被丢掉，所以 GEOIP 和 MATCH 留在下面的 rules 里。
  mode: rule
  log-level: warning
  ipv6: false
  unified-delay: true
  tcp-concurrent: true
  geox-url:
    geoip: 'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat'
    geosite: 'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat'
    mmdb: 'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb'
  profile:
    store-selected: true
    store-fake-ip: true
  dns:
    enable: true
    ipv6: false
    enhanced-mode: fake-ip
    fake-ip-range: 198.18.0.1/16
    use-hosts: true
    fake-ip-filter:
      - '+.lan'
      - '+.local'
      - 'captive.apple.com'
      - 'time.apple.com'
      - '+.msftncsi.com'
      - '+.msftconnecttest.com'
      - '+.cdn-apple.com'
      - 'swcdn.apple.com'
      - 'swdist.apple.com'
      - 'swscan.apple.com'
      - '+.aaplimg.com'
      - '+.ks-cdn.com'
      - '+.ksyuncdn.com'
      - '+.alikunlun.com'
      - 'ocsp2.apple.com'
      - '+.akadns.net'
      - '+.akamaiedge.net'
      - '+.openbot.run'
      - '+.openbot.site'
    default-nameserver:
      - 223.5.5.5
      - 119.29.29.29
    nameserver:
      - 223.5.5.5
      - 119.29.29.29
    nameserver-policy:
      '+.cdn-apple.com,swcdn.apple.com,swdist.apple.com,swscan.apple.com,ocsp2.apple.com,+.aaplimg.com,+.akadns.net,+.akamaiedge.net,+.ks-cdn.com,+.ksyuncdn.com,+.alikunlun.com': ['https://223.5.5.5/dns-query', 'https://doh.pub/dns-query']
  proxy-providers:
    jsy:
      type: http
      url: "PASTE_JSY_SUBSCRIPTION_URL"
      path: ./providers/jsy.yaml
      interval: 86400
      header:
        User-Agent: ["Clash"]
      health-check:
        enable: true
        url: https://www.gstatic.com/generate_204
        interval: 300
        timeout: 5000
    hy:
      type: http
      url: "PASTE_HY_SUBSCRIPTION_URL"
      path: ./providers/hy.yaml
      interval: 86400
      header:
        User-Agent: ["Clash"]
      health-check:
        enable: true
        url: https://www.gstatic.com/generate_204
        interval: 300
        timeout: 5000
  rule-providers:
  #{segs.gsub(/^/, '  ').rstrip}
  proxy-groups:
  #{use_group('HY-日本', 'url-test', ['hy'], hy_jp, excl, health(300, 10))}
  #{use_group('JSY-日本', 'url-test', ['jsy'], jsy_jp, excl, health(900, 20))}
    - name: XM-Google
      type: fallback
      proxies: [HY-日本, JSY-日本]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
    - name: XM-AI
      type: fallback
      proxies: [HY-日本, JSY-日本]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
  #{use_group('XM-OpenBot', 'fallback', ['jsy'], openbot_filter, excl, health(900))}
  #{use_group('HY-Web3', 'url-test', ['hy'], hy_web3, web3_excl, health(300, 10))}
  #{use_group('HY-Web3-备用', 'url-test', ['hy'], hy_web3_extra, web3_excl, health(300, 10))}
    - name: XM-Web3
      type: fallback
      proxies: [HY-Web3, HY-Web3-备用]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
  #{use_group('HY-台湾', 'url-test', ['hy'], hy_tw, excl, health(300, 10))}
  #{use_group('JSY-台湾', 'fallback', ['jsy'], jsy_tw, excl, health(900))}
    - name: XM-Bybit
      type: fallback
      proxies: [HY-台湾, JSY-台湾]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
    - name: XM-日常上网
      type: fallback
      proxies: [HY-日本, JSY-日本]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
  #{use_group('HY-美国', 'url-test', ['hy'], hy_us, excl, health(300, 10))}
  #{use_group('JSY-美国', 'url-test', ['jsy'], jsy_us, excl, health(900, 20))}
    - name: XM-Apple
      type: fallback
      proxies: [HY-美国, JSY-美国]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
  #{use_group('XM-Anki', 'select', ['hy', 'jsy'], anki, excl, '')}
  #{use_group('HY-系统更新', 'fallback', ['hy'], sys_hy, excl, health(300))}
  #{use_group('JSY-系统更新', 'fallback', ['jsy'], sys_jsy, excl, health(900))}
    - name: XM-系统更新
      type: fallback
      proxies: [HY-系统更新, JSY-系统更新, DIRECT]
      url: https://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
  rules:
  #{rule_lines.join("\n")}
YAML
# heredoc above is indented because of <<~ ; strip is already done by <<~.
# But I indented the content with two spaces inside <<~ which <<~ removes the minimum indent.
File.write(File.join(root, 'XM-Clash-MULTI.yaml'), text.lstrip)
puts "wrote MULTI and #{body.size} segments"
