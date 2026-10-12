#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
routing = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml')))
abort 'Unexpected routing fields' unless routing.keys.sort == %w[proxy-groups rule-providers rules].sort
abort 'Initial routing must use inline rules' unless routing['rule-providers'] == {}
groups = routing.fetch('proxy-groups')
expected = %w[XM-Google XM-AI XM-Meta XM-Web3 XM-Bybit XM-日常上网]
abort 'Expected six manual groups' unless groups.map { |g| g['name'] }.sort == expected.sort && groups.all? { |g| g['type'] == 'select' && g['include-all'] == true && g['exclude-type'] == 'direct' }
nodes = (1..15).flat_map { |n| ["🇯🇵 日本 %02d" % n, "🇯🇵 日本 %02d 家宽" % n, "🇺🇸 美国 %02d" % n, "🇺🇸 美国 %02d 家宽" % n, "🇲🇾 马来西亚 %02d" % n, "🇲🇾 马来西亚 %02d 家宽" % n, "🇵🇭 菲律宾 %02d" % n, "🇵🇭 菲律宾 %02d 家宽" % n] } + (1..15).map { |n| "🇭🇰 香港 %02d" % n } + (13..15).map { |n| "🇭🇰 香港 %02d 家宽" % n } + (1..6).map { |n| "🇨🇳 台湾 %02d" % n } + (7..10).map { |n| "🇨🇳 台湾 %02d 家宽" % n } + ['🇨🇳 台湾 01 [0.3X]', '🇨🇳 台湾 08', '🇯🇵 日本 01 [0.3X]', '🇭🇰 香港 03 [0.3X]', '🇯🇵 日本 05 [0.3X]', '🇻🇳 越南', '🇻🇳 越南 家宽', '🇲🇾 马来西亚', '🇵🇭 菲律宾']
web3 = ['🇲🇾 马来西亚 01 家宽', '🇲🇾 马来西亚 03 家宽', '🇵🇭 菲律宾 01', '🇵🇭 菲律宾 02 家宽', '🇻🇳 越南 家宽', '🇭🇰 香港 14 家宽']
groups.each do |group|
  selected = nodes.select { |n| Regexp.new(group.fetch('filter')).match?(n) }
  country, ordinary, residential = group['name'] == 'XM-Meta' ? ['🇺🇸 美国', (1..3), (10..12)] : ['🇯🇵 日本', [2, 3, 5, 6, 7], [9]]
  wanted = ordinary.map { |n| "#{country} %02d" % n } + residential.map { |n| "#{country} %02d 家宽" % n }
  wanted = web3 if group['name'] == 'XM-Web3'
  wanted = ['🇨🇳 台湾 08 家宽', '🇨🇳 台湾 09 家宽'] if group['name'] == 'XM-Bybit'
  abort 'Unexpected node range' unless selected.sort == wanted.sort
end
rules = routing.fetch('rules')
# Match the initial port from the retained iOS configuration; future edits remain independent.
abort 'Missing China or daily fallback' unless rules.last(2) == ['GEOIP,CN,DIRECT', 'MATCH,XM-日常上网']
rules.each do |rule|
  fields = rule.split(',')
  target = fields.last == 'no-resolve' ? fields[-2] : fields.last
  abort 'Invalid rule target' unless (expected + ['DIRECT', 'REJECT']).include?(target)
  abort 'Invalid rule type' unless %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD IP-CIDR IP-CIDR6 GEOIP MATCH].include?(fields.first)
end
abort 'Bybit must use XM-Bybit' unless %w[bybit.com bybit.biz byabcde.com bycsi.com].all? { |d| rules.include?("DOMAIN-SUFFIX,#{d},XM-Bybit") } && rules.none? { |r| r.match?(/by(bit|abcde|csi)/) && !r.end_with?(',XM-Bybit') }
abort 'AI Google domains must precede Google' unless rules.index('DOMAIN-SUFFIX,gemini.google.com,XM-AI') < rules.index('DOMAIN-SUFFIX,google.com,XM-Google')
puts "Validated Clash Verge: six manual groups (XM-Bybit 2 nodes, others 6), #{rules.size} inline rules."
