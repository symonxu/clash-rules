#!/usr/bin/env ruby
root = File.expand_path('..', __dir__)
conf_path = File.join(root, 'XM-Shadowrocket-HY.conf')
abort 'XM-Shadowrocket-HY.conf missing' unless File.exist?(conf_path)

content = File.read(conf_path)
abort 'XM-Shadowrocket-HY.conf: [General] section missing' unless content.include?('[General]')
abort 'XM-Shadowrocket-HY.conf: [Host] section missing' unless content.include?('[Host]')
abort 'XM-Shadowrocket-HY.conf: [Proxy Group] section missing' unless content.include?('[Proxy Group]')
abort 'XM-Shadowrocket-HY.conf: [Rule] section missing' unless content.include?('[Rule]')
abort 'XM-Shadowrocket-HY.conf: OpenBot and node domains must use always-real-ip' unless content.include?('always-real-ip = *.openbot.run, *.openbot.site, *.aws-agent.org')
%w[180.188.20.131 119.147.195.213 223.5.5.5 119.29.29.29].each do |ip|
  abort "XM-Shadowrocket-HY.conf: #{ip} must bypass the tunnel" unless content.include?(ip) && content.match?(/^tun-excluded-routes = .*#{Regexp.escape(ip)}/)
end

hy_path = File.join(root, 'XM-Clash-HY.yaml')
abort 'XM-Clash-HY.yaml missing' unless File.exist?(hy_path)
hy_hosts = File.read(hy_path).scan(/^\s+([0-9a-z.-]+\.aws-agent\.org):\s+(\d+\.\d+\.\d+\.\d+)\s*$/)
abort "XM-Clash-HY.yaml: expected the two current Flower hosts, found #{hy_hosts.size}" unless hy_hosts.size == 2
hy_hosts.each do |name, ip|
  abort "XM-Shadowrocket-HY.conf: host #{name} must match HY (#{ip})" unless content.include?("#{name} = #{ip}")
end

expected_groups = ['XM-AI工具', 'XM-Web3', 'XM-Bybit', 'XM-日常上网', 'XM-Apple', 'XM-Anki', 'XM-系统更新'].freeze
groups = content.scan(/^([A-Za-z0-9\u4e00-\u9fa5-]+)\s*=\s*(select|url-test|fallback)/).map(&:first)
abort "XM-Shadowrocket-HY.conf: groups must match expected 9 groups (found #{groups.inspect})" unless groups == expected_groups

lines = content.lines.map(&:strip)
japan = lines.find { |l| l.start_with?('XM-AI工具 =') }
abort 'XM-AI工具 must be a manual select filtered to the five Japan lines, without hardcoded emoji names' unless japan == 'XM-AI工具 = select, policy-regex-filter=^(?!.*(香港|HK|Hong ?Kong|🇭🇰|实验性|备用|只有备用|剩余|流量|套餐|到期|官网)).*日本(高级 IEPL 专线 2|标准 IEPL 专线 1|标准 IEPL 专线 3|高级 IEPL 专线 3|标准 IEPL 专线 2)$'

bybit_line = lines.find { |l| l.start_with?('XM-Bybit =') }
abort 'XM-Bybit must be fallback' unless bybit_line&.include?('= fallback,')

anki_line = lines.find { |l| l.start_with?('XM-Anki =') }
abort 'XM-Anki must be select' unless anki_line&.include?('= select,')

sys_line = lines.find { |l| l.start_with?('XM-系统更新 =') }
abort 'XM-系统更新 must be select with DIRECT' unless sys_line&.include?('= select, DIRECT,')

web3_line = lines.find { |l| l.start_with?('XM-Web3 =') }
abort 'XM-Web3 regex must exclude HK/TW/SG/US' unless web3_line&.include?('香港') && web3_line&.include?('台湾') && web3_line&.include?('新加坡') && web3_line&.include?('美国')

rule_lines = content.split('[Rule]')[1].lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort "XM-Shadowrocket-HY.conf: rule count must be 276 (found #{rule_lines.size})" unless rule_lines.size == 276
abort 'XM-Shadowrocket-HY.conf: must end with FINAL,XM-日常上网' unless rule_lines.last == 'FINAL,XM-日常上网'
abort 'XM-Shadowrocket-HY.conf: must have GEOIP,CN,DIRECT before FINAL' unless rule_lines[-2] == 'GEOIP,CN,DIRECT'
abort 'XM-Shadowrocket-HY.conf: must have QUIC reject rule' unless rule_lines.include?('AND,((NETWORK,UDP),(DST-PORT,443)),REJECT')

puts 'Validated XM-Shadowrocket-HY.conf (7 proxy groups, 276 rules, regex filtering, correct types).'
