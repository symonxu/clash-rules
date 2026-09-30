#!/usr/bin/env ruby
require 'yaml'
root = File.expand_path('..', __dir__)
routing = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml')))
abort 'Unexpected routing fields' unless routing.keys.sort == %w[proxy-groups rule-providers rules].sort
abort 'Initial routing must use inline rules' unless routing['rule-providers'] == {}
groups = routing.fetch('proxy-groups')
expected = %w[XM-Google XM-AI XM-Meta XM-Web3 XM-日常上网]
abort 'Expected five manual groups' unless groups.map { |g| g['name'] }.sort == expected.sort && groups.all? { |g| g['type'] == 'select' && g['include-all'] == true && g['exclude-type'] == 'direct' }
nodes = (1..15).flat_map { |n| ["🇯🇵 日本 %02d" % n, "🇯🇵 日本 %02d 家宽" % n, "🇺🇸 美国 %02d" % n, "🇺🇸 美国 %02d 家宽" % n] }
groups.each do |group|
  selected = nodes.select { |n| Regexp.new(group.fetch('filter')).match?(n) }
  country, ordinary, residential = group['name'] == 'XM-Meta' ? ['🇺🇸 美国', (1..3), (10..12)] : ['🇯🇵 日本', (2..4), (8..10)]
  wanted = ordinary.map { |n| "#{country} %02d" % n } + residential.map { |n| "#{country} %02d 家宽" % n }
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
abort 'Bybit must use Web3' unless rules.include?('DOMAIN-SUFFIX,bybit.com,XM-Web3')
abort 'AI Google domains must precede Google' unless rules.index('DOMAIN-SUFFIX,gemini.google.com,XM-AI') < rules.index('DOMAIN-SUFFIX,google.com,XM-Google')
puts "Validated Clash Verge: five manual groups, six nodes each, #{rules.size} inline rules."
