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
abort 'shadowrocket-away.conf: OpenBot and node domains must use always-real-ip' unless content.include?('always-real-ip = *.openbot.run, *.openbot.site, *.aws-agent.org')
abort 'shadowrocket-away.conf: [Host] must be used for proxy connections (use-local-host-item-for-proxy = true)' unless content.match?(/^use-local-host-item-for-proxy = true$/)
general = content.split('[General]', 2).last.split('[Host]', 2).first
skip_proxy = general.lines.find { |line| line.start_with?('skip-proxy =') }.to_s
tun_excluded_routes = general.lines.find { |line| line.start_with?('tun-excluded-routes =') }.to_s
abort 'shadowrocket-away.conf: tailnet routes must not bypass the built-in Tailscale module' if skip_proxy.include?('100.64.0.0/10') || skip_proxy.include?('*.ts.net') || tun_excluded_routes.include?('100.64.0.0/10')
%w[180.188.20.131 119.147.195.213 58.247.187.127 223.5.5.5 119.29.29.29].each do |ip|
  abort "shadowrocket-away.conf: #{ip} must bypass the tunnel" unless content.include?(ip) && content.match?(/^tun-excluded-routes = .*#{Regexp.escape(ip)}/)
end

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
abort "shadowrocket-away.conf: rule count must be 284 (found #{rule_lines.size})" unless rule_lines.size == 284
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
app_store_rules = [
  'DOMAIN-SUFFIX,apps.apple.com,DIRECT',
  'DOMAIN-SUFFIX,itunes.apple.com,DIRECT',
  'DOMAIN-SUFFIX,mzstatic.com,DIRECT'
].freeze
validate_apple_routes = lambda do |file, rules|
  apple_tv_rules.each do |rule|
    abort "#{file}: Apple TV route missing #{rule}" unless rules.include?(rule)
    abort "#{file}: Apple TV route must precede App Store iTunes direct" unless rules.index(rule) < rules.index('DOMAIN-SUFFIX,itunes.apple.com,DIRECT').to_i
  end
  abort "#{file}: App Store must use DIRECT" unless app_store_rules.all? { |rule| rules.include?(rule) }
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
quic_rule = 'AND,((NETWORK,UDP),(DST-PORT,443)),REJECT'
quic_index = rule_lines.index(quic_rule)
abort 'shadowrocket-away.conf: Tailscale rules must precede the QUIC reject rule' unless tailscale_rules.all? { |rule| rule_lines.index(rule) < quic_index }
first_service_rule_index = rule_lines.index('DOMAIN-SUFFIX,infura.io,XM-Web3')
abort 'shadowrocket-away.conf: QUIC reject rule must precede service-domain rules' unless quic_index < first_service_rule_index
abort 'shadowrocket-away.conf: must end with FINAL,XM-日常上网' unless rule_lines.last == 'FINAL,XM-日常上网'
abort 'shadowrocket-away.conf: must have GEOIP,CN,DIRECT before FINAL' unless rule_lines[-2] == 'GEOIP,CN,DIRECT'
abort 'shadowrocket-away.conf: must have QUIC reject rule' unless quic_index

home_path = File.join(root, 'shadowrocket-home.conf')
abort 'shadowrocket-home.conf missing' unless File.exist?(home_path)
home_content = File.read(home_path)
home_active_lines = home_content.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort 'shadowrocket-home.conf must not reference TAILSCALE policy or [Tailscale] section' if home_active_lines.any? { |l| l.match?(/,TAILSCALE(?:\b|$)/) || l.match?(/^\[Tailscale\]/i) }
home_rules = home_content.split('[Rule]')[1].lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort "shadowrocket-home.conf: rule count must be 283 (found #{home_rules.size})" unless home_rules.size == 283
validate_apple_routes.call('shadowrocket-home.conf', home_rules)
abort 'shadowrocket-home.conf: must route 100.64.0.0/10 to DIRECT' unless home_rules.include?('IP-CIDR,100.64.0.0/10,DIRECT,no-resolve')
abort 'shadowrocket-home.conf: must preserve FINAL,XM-日常上网' unless home_rules.last == 'FINAL,XM-日常上网'

puts 'Validated shadowrocket-away.conf (7 proxy groups, 284 rules, built-in Tailscale routing) and shadowrocket-home.conf (283 rules).'
