#!/usr/bin/env ruby
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
root = File.expand_path('..', __dir__)
away_path = File.join(root, 'shadowrocket-away.conf')
abort 'shadowrocket-away.conf missing' unless File.exist?(away_path)

content = File.read(away_path)
abort 'shadowrocket-away.conf: [General] section missing' unless content.include?('[General]')
abort 'shadowrocket-away.conf: [Host] section missing' unless content.include?('[Host]')
abort 'shadowrocket-away.conf: [Proxy Group] section missing' unless content.include?('[Proxy Group]')
abort 'shadowrocket-away.conf: [Rule] section missing' unless content.include?('[Rule]')
expected_real_ip = 'always-real-ip = *.openbot.run, *.openbot.site, *.aws-agent.org, *.mzstatic.com, *.itunes.apple.com, captive.apple.com, *.cdn-apple.com, swcdn.apple.com, swdist.apple.com, swscan.apple.com, ocsp2.apple.com, *.aaplimg.com, *.akadns.net, *.akamaiedge.net, *.ks-cdn.com, *.ksyuncdn.com, *.alikunlun.com'
abort 'shadowrocket-away.conf: always-real-ip must cover OpenBot, node, Apple, and CN CDN domains (without time.apple.com)' unless content.include?(expected_real_ip)
abort 'shadowrocket-away.conf: [Host] must be used for proxy connections (use-local-host-item-for-proxy = true)' unless content.match?(/^use-local-host-item-for-proxy = true$/)
general = content.split('[General]', 2).last.split('[Host]', 2).first
skip_proxy = general.lines.find { |line| line.start_with?('skip-proxy =') }.to_s
tun_excluded_routes = general.lines.find { |line| line.start_with?('tun-excluded-routes =') }.to_s
abort 'shadowrocket-away.conf: tailnet routes must not bypass the built-in Tailscale module' if skip_proxy.include?('100.64.0.0/10') || skip_proxy.include?('*.ts.net') || tun_excluded_routes.include?('100.64.0.0/10')
away_active_lines = content.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort 'shadowrocket-away.conf: dead Guangzhou IP 119.147.195.213 and Shanghai IP 180.188.20.131 must be removed' if away_active_lines.any? { |l| l.include?('119.147.195.213') || l.include?('180.188.20.131') }
%w[58.247.187.127 223.5.5.5 223.6.6.6 1.12.12.12 119.29.29.29].each do |ip|
  abort "shadowrocket-away.conf: #{ip} must bypass the tunnel" unless skip_proxy.include?(ip) && tun_excluded_routes.include?(ip)
end
# 2026-11-23：阿里双路纯 IP DoH（223.5.5.5 + 223.6.6.6），省去 DoH 域名引导并避免 1.12.12.12 高延迟与单点超时，同时防明文劫持与 App Store 坏 IP。
abort 'shadowrocket-away.conf: dns-server must use dual pure-IP DoH (223.5.5.5 + 223.6.6.6)' unless content.include?('dns-server = https://223.5.5.5/dns-query, https://223.6.6.6/dns-query')
# 2026-11-20：QUIC 屏蔽只封代理连接，直连（App Store / iCloud 等）保留 HTTP/3，避免每次连接先重试 QUIC 再回退 TCP。
abort 'shadowrocket-away.conf: QUIC block must be all-proxy (DIRECT connections keep HTTP/3)' unless content.match?(/^block-quic = all-proxy$/)

hy_path = File.join(root, 'XM-Clash-HY.yaml')
abort 'XM-Clash-HY.yaml missing' unless File.exist?(hy_path)
hy_hosts = File.read(hy_path).scan(/^\s+([0-9a-z.-]+\.aws-agent\.org):\s+(\d+\.\d+\.\d+\.\d+)\s*$/)
abort "XM-Clash-HY.yaml: expected the three current Flower hosts, found #{hy_hosts.size}" unless hy_hosts.size == 3
hy_hosts.each do |name, ip|
  abort "shadowrocket-away.conf: host #{name} must match HY (#{ip})" unless content.include?("#{name} = #{ip}")
end

expected_groups = ['XM-AI工具', 'XM-Web3', 'XM-Bybit', 'XM-日常上网', 'XM-Apple', 'XM-Anki', 'XM-系统更新'].freeze
groups = content.scan(/^([A-Za-z0-9\u4e00-\u9fa5-]+)\s*=\s*(select|url-test|fallback)/).map(&:first)
abort "shadowrocket-away.conf: groups must match expected 7 groups (found #{groups.inspect})" unless groups == expected_groups

lines = content.lines.map(&:strip)
# 2026-11-19：AI工具与日常上网统一为同样的 7 个手动节点（2 日本 + 2 台湾 + 2 美国 + 1 韩国）。
AI_GROUP_REGEX = '^(?!.*(香港|HK|Hong ?Kong|🇭🇰|实验性|备用|只有备用|剩余|流量|套餐|到期|官网)).*(日本(标准 IEPL 专线 1|标准 IEPL 专线 3)|台湾(高级 IEPL 专线 2|高级 IEPL 专线 3)|美国(标准 IEPL 专线 6|标准 IEPL 专线 7)|韩国标准 IEPL 专线 2)$'.freeze
japan = lines.find { |l| l.start_with?('XM-AI工具 =') }
abort 'XM-AI工具 must be a manual select with the seven 2026-11-19 nodes, without hardcoded emoji names' unless japan == "XM-AI工具 = select, policy-regex-filter=#{AI_GROUP_REGEX}"
daily = lines.find { |l| l.start_with?('XM-日常上网 =') }
abort 'XM-日常上网 must be a manual select with the same seven nodes as XM-AI工具' unless daily == "XM-日常上网 = select, policy-regex-filter=#{AI_GROUP_REGEX}"

bybit_line = lines.find { |l| l.start_with?('XM-Bybit =') }
abort 'XM-Bybit must be fallback' unless bybit_line&.include?('= fallback,')

anki_line = lines.find { |l| l.start_with?('XM-Anki =') }
abort 'XM-Anki must be select' unless anki_line&.include?('= select,')

sys_line = lines.find { |l| l.start_with?('XM-系统更新 =') }
abort 'XM-系统更新 must be select with DIRECT only (no auto nodes)' unless sys_line&.strip == 'XM-系统更新 = select, DIRECT'

web3_line = lines.find { |l| l.start_with?('XM-Web3 =') }
abort 'XM-Web3 regex must exclude HK/TW/SG/US' unless web3_line&.include?('香港') && web3_line&.include?('台湾') && web3_line&.include?('新加坡') && web3_line&.include?('美国')

rule_lines = content.split('[Rule]')[1].lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort "shadowrocket-away.conf: rule count must be 288 (found #{rule_lines.size})" unless rule_lines.size == 288
apple_tv_api_rules = [
  'DOMAIN-SUFFIX,tv.apple.com,XM-Apple',
  'DOMAIN-SUFFIX,pancake.apple.com,XM-Apple',
  'DOMAIN,uts-api.itunes.apple.com,XM-Apple'
].freeze
apple_tv_vod_rules = [
  'DOMAIN-SUFFIX,vod-ap-aoc.tv.apple.com,DIRECT',
  'DOMAIN-SUFFIX,vod-ap2-aoc.tv.apple.com,DIRECT',
  'DOMAIN-SUFFIX,vod-ak-aoc.tv.apple.com,DIRECT',
  'DOMAIN-SUFFIX,vod-fa-aoc.tv.apple.com,DIRECT',
  'DOMAIN-KEYWORD,-aoc.tv.apple.com,DIRECT',
  'DOMAIN,play-edge.itunes.apple.com,DIRECT',
  'DOMAIN,hls.itunes.apple.com,DIRECT',
  'DOMAIN,np-edge.itunes.apple.com,DIRECT'
].freeze
apple_tv_rules = apple_tv_api_rules + apple_tv_vod_rules
app_store_direct_rules = [
  'DOMAIN-SUFFIX,apps.apple.com,DIRECT',
  'DOMAIN-SUFFIX,itunes.apple.com,DIRECT'
].freeze
app_store_itunes_proxy_rules = [
  'DOMAIN,bag.itunes.apple.com,XM-日常上网',
  'DOMAIN,sf-api-token-service.itunes.apple.com,XM-日常上网'
].freeze
app_store_apps_proxy_rules = [
  'DOMAIN,amp-api-edge.apps.apple.com,XM-日常上网',
  'DOMAIN,amp-api.apps.apple.com,XM-日常上网',
  'DOMAIN,amp-api-search-edge.apps.apple.com,XM-日常上网'
].freeze
validate_apple_routes = lambda do |file, rules|
  apple_tv_rules.each do |rule|
    abort "#{file}: Apple TV route missing #{rule}" unless rules.include?(rule)
    abort "#{file}: Apple TV route must precede App Store iTunes direct" unless rules.index(rule) < rules.index('DOMAIN-SUFFIX,itunes.apple.com,DIRECT').to_i
  end
  abort "#{file}: App Store downloads must stay DIRECT" unless app_store_direct_rules.all? { |rule| rules.include?(rule) }
  app_store_itunes_proxy_rules.each do |rule|
    abort "#{file}: #{rule} must precede itunes.apple.com" unless rules.include?(rule) && rules.index(rule) < rules.index('DOMAIN-SUFFIX,itunes.apple.com,DIRECT').to_i
  end
  app_store_apps_proxy_rules.each do |rule|
    abort "#{file}: #{rule} must precede apps.apple.com" unless rules.include?(rule) && rules.index(rule) < rules.index('DOMAIN-SUFFIX,apps.apple.com,DIRECT').to_i
  end
  abort "#{file}: mzstatic.com icons/assets must use XM-日常上网" unless rules.include?('DOMAIN-SUFFIX,mzstatic.com,XM-日常上网')
  abort "#{file}: only Apple TV catalog/auth domains may use XM-Apple" unless rules.select { |rule| rule.end_with?(',XM-Apple') }.sort == apple_tv_api_rules.sort
end
validate_apple_routes.call('shadowrocket-away.conf', rule_lines)
tailscale_rules = [
  'DOMAIN-SUFFIX,tailscale.com,DIRECT',
  'DOMAIN-SUFFIX,tailscale.io,DIRECT',
  'IP-CIDR,100.64.0.0/10,TAILSCALE,no-resolve',
  'DOMAIN-SUFFIX,ts.net,TAILSCALE'
].freeze
tailscale_rules.each do |rule|
  abort "shadowrocket-away.conf: missing built-in Tailscale rule #{rule}" unless rule_lines.include?(rule)
end
abort 'shadowrocket-away.conf: global QUIC REJECT rule must be removed (use [General] block-quic = all-proxy)' if rule_lines.any? { |l| l.include?('DST-PORT,443)),REJECT') }
first_service_rule_index = rule_lines.index('DOMAIN-SUFFIX,infura.io,XM-Web3')
abort 'shadowrocket-away.conf: Tailscale rules must precede service-domain rules' unless tailscale_rules.all? { |rule| rule_lines.index(rule) < first_service_rule_index }
abort 'shadowrocket-away.conf: must end with FINAL,XM-日常上网' unless rule_lines.last == 'FINAL,XM-日常上网'
abort 'shadowrocket-away.conf: must have GEOIP,CN,DIRECT before FINAL' unless rule_lines[-2] == 'GEOIP,CN,DIRECT'

home_path = File.join(root, 'shadowrocket-home.conf')
abort 'shadowrocket-home.conf missing' unless File.exist?(home_path)
home_content = File.read(home_path)
home_active_lines = home_content.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort 'shadowrocket-home.conf must not reference TAILSCALE policy or [Tailscale] section' if home_active_lines.any? { |l| l.match?(/,TAILSCALE(?:\b|$)/) || l.match?(/^\[Tailscale\]/i) }
home_rules = home_content.split('[Rule]')[1].lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort "shadowrocket-home.conf: rule count must be 287 (found #{home_rules.size})" unless home_rules.size == 287
validate_apple_routes.call('shadowrocket-home.conf', home_rules)
abort 'shadowrocket-home.conf: must route 100.64.0.0/10 to DIRECT' unless home_rules.include?('IP-CIDR,100.64.0.0/10,DIRECT,no-resolve')
abort 'shadowrocket-home.conf: must preserve FINAL,XM-日常上网' unless home_rules.last == 'FINAL,XM-日常上网'

# home 配置同样必须使用双路纯 IP DoH、补齐 always-real-ip 与旁路 IP，且不得残留全局 QUIC REJECT 规则。
home_general = home_content.split('[General]', 2).last.split('[Host]', 2).first
home_skip_proxy = home_general.lines.find { |line| line.start_with?('skip-proxy =') }.to_s
home_tun_excluded = home_general.lines.find { |line| line.start_with?('tun-excluded-routes =') }.to_s
abort 'shadowrocket-home.conf: dead Guangzhou IP 119.147.195.213 and Shanghai IP 180.188.20.131 must be removed' if home_active_lines.any? { |l| l.include?('119.147.195.213') || l.include?('180.188.20.131') }
%w[58.247.187.127 223.5.5.5 223.6.6.6 1.12.12.12 119.29.29.29].each do |ip|
  abort "shadowrocket-home.conf: #{ip} must bypass the tunnel" unless home_skip_proxy.include?(ip) && home_tun_excluded.include?(ip)
end
abort 'shadowrocket-home.conf: always-real-ip must cover OpenBot, node, Apple, and CN CDN domains (without time.apple.com)' unless home_content.include?(expected_real_ip)
abort 'shadowrocket-home.conf: dns-server must use dual pure-IP DoH (223.5.5.5 + 223.6.6.6)' unless home_content.include?('dns-server = https://223.5.5.5/dns-query, https://223.6.6.6/dns-query')
abort 'shadowrocket-home.conf: QUIC block must be all-proxy (DIRECT connections keep HTTP/3)' unless home_content.match?(/^block-quic = all-proxy$/)
abort 'shadowrocket-home.conf: global QUIC REJECT rule must be removed' if home_rules.any? { |l| l.include?('DST-PORT,443)),REJECT') }

puts 'Validated shadowrocket-away.conf (7 proxy groups, 288 rules, encrypted DNS, all-proxy QUIC block, built-in Tailscale routing) and shadowrocket-home.conf (287 rules).'
