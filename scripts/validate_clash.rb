#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# Clash App（clash.md，iOS 与 Mac 通用）独立规则配置：不含节点、订阅或占位；节点来自 App 里另外导入的 MESL 节点来源，分组自动测速，规则与 Mac 完全一致。
clash = YAML.safe_load(File.read(File.join(root, 'XM-Clash.yaml')))
mac = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml')))
abort 'Clash App: unexpected top-level fields' unless clash.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-groups rules].sort
abort 'Clash App: must not contain nodes or subscriptions' if %w[proxies proxy-providers rule-providers].any? { |k| clash.key?(k) }
abort 'Clash App: mode must be rule and IPv6 off' unless clash['mode'] == 'rule' && clash['ipv6'] == false
dns = clash.fetch('dns')
abort 'Clash App: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off' unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]
mac_groups = mac.fetch('proxy-groups')
groups = clash.fetch('proxy-groups')
abort 'Clash App: groups must match Clash Verge names and order' unless groups.map { |g| g['name'] } == mac_groups.map { |g| g['name'] }
url = 'https://www.gstatic.com/generate_204'
groups.zip(mac_groups).each do |g, m|
  abort "Clash App: #{g['name']} must take nodes via include-all + filter only" unless g['include-all'] == true && !g.key?('proxies') && !g.key?('use')
  abort "Clash App: #{g['name']} wrong test options" unless g['url'] == url && g['interval'] == 900 && g['timeout'] == 5000
  if g['name'] == 'XM-Bybit'
    abort 'Clash App: XM-Bybit must be fallback 台湾 08 then 09 家宽' unless g['type'] == 'fallback' && g['filter'] == '(^| )台湾 08 家宽$`(^| )台湾 09 家宽$' && !g.key?('tolerance')
  else
    abort "Clash App: #{g['name']} must be url-test with Clash Verge filter" unless g['type'] == 'url-test' && g['tolerance'] == 20 && g['filter'] == m['filter']
  end
end
abort 'Clash App: rules must equal Clash Verge rules (same targets and order)' unless clash.fetch('rules') == mac.fetch('rules')
puts "Validated Clash App: 5 url-test groups + XM-Bybit fallback taking nodes from the app's node sources (no subscription in file), #{clash['rules'].size} rules identical to Clash Verge."
