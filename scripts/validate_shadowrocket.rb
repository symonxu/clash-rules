#!/usr/bin/env ruby
root = File.expand_path('..', __dir__)
conf_path = File.join(root, 'XM-Shadowrocket.conf')
abort 'XM-Shadowrocket.conf missing' unless File.exist?(conf_path)

content = File.read(conf_path)
abort 'XM-Shadowrocket.conf: [General] section missing' unless content.include?('[General]')
abort 'XM-Shadowrocket.conf: [Host] section missing' unless content.include?('[Host]')
abort 'XM-Shadowrocket.conf: [Proxy Group] section missing' unless content.include?('[Proxy Group]')
abort 'XM-Shadowrocket.conf: [Rule] section missing' unless content.include?('[Rule]')
abort 'XM-Shadowrocket.conf: OpenBot domains must use always-real-ip' unless content.include?('always-real-ip = *.openbot.run, *.openbot.site')

hy_path = File.join(root, 'XM-Clash-HY.yaml')
abort 'XM-Clash-HY.yaml missing' unless File.exist?(hy_path)
hy_hosts = File.read(hy_path).scan(/^\s+([0-9a-z.-]+\.aws-agent\.org):\s+(\d+\.\d+\.\d+\.\d+)\s*$/)
abort "XM-Clash-HY.yaml: expected 3 aws-agent.org hosts, found #{hy_hosts.size}" unless hy_hosts.size == 3
hy_hosts.each do |name, ip|
  abort "XM-Shadowrocket.conf: host #{name} must match HY (#{ip})" unless content.include?("#{name} = #{ip}")
end

expected_groups = ['XM-Google', 'XM-AI', 'XM-OpenBot', 'XM-Web3', 'XM-Bybit', 'XM-日常上网', 'XM-Apple', 'XM-Anki', 'XM-系统更新'].freeze
groups = content.scan(/^([A-Za-z0-9\u4e00-\u9fa5-]+)\s*=\s*(select|url-test|fallback)/).map(&:first)
abort "XM-Shadowrocket.conf: groups must match expected 9 groups (found #{groups.inspect})" unless groups == expected_groups

lines = content.lines.map(&:strip)
openbot_line = lines.find { |l| l.start_with?('XM-OpenBot =') }
abort 'XM-OpenBot must be fallback' unless openbot_line&.include?('= fallback,')
abort 'XM-OpenBot regex must keep 花云 IEPL and 极速云 日本_ nodes' unless openbot_line&.include?('日本高级 IEPL 专线 [1-3]') && openbot_line&.include?('日本标准 IEPL 专线 [1-4]') && openbot_line&.include?('日本_[0-9]+')

bybit_line = lines.find { |l| l.start_with?('XM-Bybit =') }
abort 'XM-Bybit must be fallback' unless bybit_line&.include?('= fallback,')

anki_line = lines.find { |l| l.start_with?('XM-Anki =') }
abort 'XM-Anki must be select' unless anki_line&.include?('= select,')

sys_line = lines.find { |l| l.start_with?('XM-系统更新 =') }
abort 'XM-系统更新 must be select with DIRECT' unless sys_line&.include?('= select, DIRECT,')

web3_line = lines.find { |l| l.start_with?('XM-Web3 =') }
abort 'XM-Web3 regex must exclude HK/TW/SG/US' unless web3_line&.include?('香港') && web3_line&.include?('台湾') && web3_line&.include?('新加坡') && web3_line&.include?('美国')

rule_lines = content.split('[Rule]')[1].lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort "XM-Shadowrocket.conf: rule count must be 236 (found #{rule_lines.size})" unless rule_lines.size == 236
abort 'XM-Shadowrocket.conf: must end with FINAL,XM-日常上网' unless rule_lines.last == 'FINAL,XM-日常上网'
abort 'XM-Shadowrocket.conf: must have GEOIP,CN,DIRECT before FINAL' unless rule_lines[-2] == 'GEOIP,CN,DIRECT'
abort 'XM-Shadowrocket.conf: must have QUIC reject rule' unless rule_lines.include?('AND,((NETWORK,UDP),(DST-PORT,443)),REJECT')

puts 'Validated XM-Shadowrocket.conf (9 proxy groups, 236 rules, regex filtering, correct types).'
