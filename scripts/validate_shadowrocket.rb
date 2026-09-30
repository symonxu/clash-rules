#!/usr/bin/env ruby
require 'set'
root = File.expand_path('..', __dir__)
path = File.join(root, 'XM-Shadowrocket-iOS.sgmodule')
text = File.read(path)
sections = text.scan(/^\[([^\]]+)\]$/).flatten
abort 'iOS module must only contain Proxy Group and Rule sections' unless sections == ['Proxy Group', 'Rule']
group_text, rule_text = text.split('[Proxy Group]', 2).last.split('[Rule]', 2)
groups = {}
group_text.each_line do |line|
  next if line.strip.empty? || line.start_with?('#')
  match = line.strip.match(/\A([^=]+) = select,policy-regex-filter=(.+)\z/)
  abort 'Invalid Shadowrocket group format' unless match
  name, filter = match.captures
  abort 'Duplicate group' if groups.key?(name)
  groups[name] = Regexp.new(filter)
end
abort 'Expected five iOS service groups' unless groups.keys.sort == %w[XM-Google XM-AI XM-Meta XM-Bybit XM-Web3].sort
count = 0
rule_text.each_line do |line|
  next if line.strip.empty? || line.start_with?('#')
  fields = line.strip.split(',')
  abort 'Only domain rules are allowed in iOS module' unless fields.length == 3 && %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD].include?(fields[0])
  abort 'Invalid domain or policy' unless fields[1].match?(/\A[a-zA-Z0-9._-]+\z/) && groups.key?(fields[2])
  count += 1
end
abort 'Empty iOS rules' if count.zero?
puts "Validated Shadowrocket module: #{groups.size} groups, #{count} domain rules; no DNS or fallback override."

extension = File.read(File.join(root, 'XM-Shadowrocket-Groups.conf'))
abort 'Invalid extension sections' unless extension.scan(/^\[([^\]]+)\]$/).flatten == ['General', 'Proxy Group', 'Rule']
general, extension_rest = extension.split('[General]', 2).last.split('[Proxy Group]', 2)
extension_groups, extension_rules = extension_rest.split('[Rule]', 2)
expected = ["include = get.conf", "update-url = https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf"]
abort 'Unexpected general setting' unless general.lines.map(&:strip).reject(&:empty?) == expected
abort 'Extension groups differ from rule policies' unless extension_groups.strip == group_text.strip
abort 'Extension rules differ from validated personal rules' unless extension_rules.strip == rule_text.strip
abort 'Unexpected DNS or node section' if extension.match?(/^\[(DNS|Host|Proxy|MITM)\]$/)
puts 'Validated iOS extension: get.conf inheritance, five groups and 107 personal rules; no explicit DNS, nodes or fallback.'
