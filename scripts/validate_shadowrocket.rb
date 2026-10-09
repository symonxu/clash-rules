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
abort 'Expected five Shadowrocket groups' unless groups.keys.sort == %w[XM-Google XM-AI XM-Meta XM-Web3 XM-日常上网].sort
count = 0
rule_text.each_line do |line|
  next if line.strip.empty? || line.start_with?('#')
  fields = line.strip.split(',')
  abort 'Only domain rules are allowed in iOS module' unless fields.length == 3 && %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD].include?(fields[0])
  abort 'Invalid domain or policy' unless fields[1].match?(/\A[a-zA-Z0-9._-]+\z/) && groups.key?(fields[2])
  count += 1
end
abort 'Empty iOS rules' if count.zero?
abort 'Bybit must share Web3 policy' unless rule_text.lines.any? { |line| line.strip == 'DOMAIN-SUFFIX,bybit.com,XM-Web3' }
puts "Validated Shadowrocket module: #{groups.size} groups, #{count} domain rules; no DNS or fallback override."

extension = File.read(File.join(root, 'XM-Shadowrocket-Groups.conf'))
abort 'Invalid extension sections' unless extension.scan(/^\[([^\]]+)\]$/).flatten == ['General', 'Proxy Group', 'Rule']
general, extension_rest = extension.split('[General]', 2).last.split('[Proxy Group]', 2)
extension_groups, extension_rules = extension_rest.split('[Rule]', 2)
expected = ["include = get.conf", "update-url = https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf"]
abort 'Unexpected general setting' unless general.lines.map(&:strip).reject(&:empty?) == expected
abort 'Extension groups differ from rule policies' unless extension_groups.strip == group_text.strip
personal_lines = rule_text.lines.map(&:strip).reject { |line| line.empty? || line.start_with?('#') }
extension_lines = extension_rules.lines.map(&:strip).reject { |line| line.empty? || line.start_with?('#') }
abort 'Extension personal rules or fallback order differ' unless extension_lines == personal_lines + ['GEOIP,CN,DIRECT', 'FINAL,XM-日常上网']
abort 'Unexpected DNS or node section' if extension.match?(/^\[(DNS|Host|Proxy|MITM)\]$/)
puts "Validated Shadowrocket: five groups, #{personal_lines.size} personal domains, CN direct and daily fallback; DNS inherited."

# Public configuration must not introduce private subscription endpoints.
allowed_urls = Set.new([
  'https://github.com/symonxu/clash-rules',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-iOS.sgmodule',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml',
  'https://www.clashverge.dev/guide/extend.html',
  'https://www.clashverge.dev/guide/script.html',
  'https://www.gstatic.com/generate_204',
  'https://github.com/MetaCubeX/mihomo/blob/v1.19.31/adapter/outboundgroup/urltest.go#L110-L131',
  'https://shadowlaunch.com/',
  'https://dash.mesurl.com/#/docs/10',
  'https://github.com/LOWERTOP/Shadowrocket'
])
Dir.chdir(root) do
  tracked_files = IO.popen(['git', 'ls-files', '-z'], &:read).split("\0")
  tracked_files.each do |file|
    next unless File.file?(file)
    content = File.read(file, encoding: 'UTF-8')
    abort "Non-text tracked file: #{file}" unless content.valid_encoding? && !content.include?("\0")
    content.scan(%r{https?://[^\s<>"'`)\]，。；]+}).each do |url|
      abort "Unexpected public URL in #{file}" unless allowed_urls.include?(url)
    end
  end
end
puts 'Validated public URL allowlist.'
