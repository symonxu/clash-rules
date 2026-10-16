#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# iOS Clash（clash.md App）独立规则配置：不含节点、订阅或占位；节点来自 App 里另外导入的 MESL 节点来源，分组自动测速，规则与 Mac 完全一致。
ios = YAML.safe_load(File.read(File.join(root, 'XM-Clash-iOS.yaml')))
mac = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml')))
abort 'iOS Clash: unexpected top-level fields' unless ios.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-groups rules].sort
abort 'iOS Clash: must not contain nodes or subscriptions' if %w[proxies proxy-providers rule-providers].any? { |k| ios.key?(k) }
abort 'iOS Clash: mode must be rule and IPv6 off' unless ios['mode'] == 'rule' && ios['ipv6'] == false
dns = ios.fetch('dns')
abort 'iOS Clash: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off' unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]
mac_groups = mac.fetch('proxy-groups')
groups = ios.fetch('proxy-groups')
abort 'iOS Clash: groups must match Mac names and order' unless groups.map { |g| g['name'] } == mac_groups.map { |g| g['name'] }
url = 'https://www.gstatic.com/generate_204'
groups.zip(mac_groups).each do |g, m|
  abort "iOS Clash: #{g['name']} must take nodes via include-all + filter only" unless g['include-all'] == true && !g.key?('proxies') && !g.key?('use')
  abort "iOS Clash: #{g['name']} wrong test options" unless g['url'] == url && g['interval'] == 900 && g['timeout'] == 5000
  if g['name'] == 'XM-Bybit'
    abort 'iOS Clash: XM-Bybit must be fallback 台湾 08 then 09 家宽' unless g['type'] == 'fallback' && g['filter'] == '(^| )台湾 08 家宽$`(^| )台湾 09 家宽$' && !g.key?('tolerance')
  else
    abort "iOS Clash: #{g['name']} must be url-test with Mac filter" unless g['type'] == 'url-test' && g['tolerance'] == 20 && g['filter'] == m['filter']
  end
end
abort 'iOS Clash: rules must equal Mac rules (same targets and order)' unless ios.fetch('rules') == mac.fetch('rules')
puts "Validated iOS Clash: 5 url-test groups + XM-Bybit fallback taking nodes from the app's node sources (no subscription in file), #{ios['rules'].size} rules identical to Mac."
