#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
# iOS Clash（clash.md App）独立配置：节点只来自 MESL proxy-provider 占位，分组自动测速，规则与 Mac 完全一致。
ios = YAML.safe_load(File.read(File.join(root, 'XM-Clash-iOS.yaml')))
mac = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml')))
abort 'iOS Clash: unexpected top-level fields' unless ios.keys.sort == %w[mode log-level ipv6 unified-delay tcp-concurrent profile dns proxy-providers proxy-groups rules].sort
abort 'iOS Clash: must not contain nodes' if ios.key?('proxies')
abort 'iOS Clash: mode must be rule and IPv6 off' unless ios['mode'] == 'rule' && ios['ipv6'] == false
dns = ios.fetch('dns')
abort 'iOS Clash: DNS must be 223.5.5.5 / 119.29.29.29 with IPv6 off' unless dns['enable'] == true && dns['ipv6'] == false && dns['nameserver'] == %w[223.5.5.5 119.29.29.29] && dns['default-nameserver'] == %w[223.5.5.5 119.29.29.29]
providers = ios.fetch('proxy-providers')
abort 'iOS Clash: exactly one MESL provider' unless providers.keys == ['MESL']
mesl = providers['MESL']
abort 'iOS Clash: MESL url must stay the placeholder (never commit a real subscription)' unless mesl['type'] == 'http' && mesl['url'] == '在这里粘贴MESL的Clash订阅地址'
abort 'iOS Clash: MESL must not rename nodes' if mesl.key?('override') || mesl.key?('filter') || mesl.key?('exclude-filter')
mac_groups = mac.fetch('proxy-groups')
groups = ios.fetch('proxy-groups')
abort 'iOS Clash: groups must match Mac names and order' unless groups.map { |g| g['name'] } == mac_groups.map { |g| g['name'] }
url = 'https://www.gstatic.com/generate_204'
groups.zip(mac_groups).each do |g, m|
  abort "iOS Clash: #{g['name']} must use only MESL" unless g['use'] == ['MESL'] && !g.key?('proxies') && !g.key?('include-all')
  abort "iOS Clash: #{g['name']} wrong test options" unless g['url'] == url && g['interval'] == 900 && g['timeout'] == 5000
  if g['name'] == 'XM-Bybit'
    abort 'iOS Clash: XM-Bybit must be fallback 台湾 08 then 09 家宽' unless g['type'] == 'fallback' && g['filter'] == '(^| )台湾 08 家宽$`(^| )台湾 09 家宽$' && !g.key?('tolerance')
  else
    abort "iOS Clash: #{g['name']} must be url-test with Mac filter" unless g['type'] == 'url-test' && g['tolerance'] == 20 && g['filter'] == m['filter']
  end
end
abort 'iOS Clash: rules must equal Mac rules (same targets and order)' unless ios.fetch('rules') == mac.fetch('rules')
puts "Validated iOS Clash: 5 url-test groups + XM-Bybit fallback via MESL provider placeholder, #{ios['rules'].size} rules identical to Mac."
