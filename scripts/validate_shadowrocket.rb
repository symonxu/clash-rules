#!/usr/bin/env ruby
require 'set'
root = File.expand_path('..', __dir__)

# Slim iOS config: standalone (no include), single Japan fallback group with 08 家宽 first.
slim = File.read(File.join(root, 'XM-Shadowrocket-Slim.conf'))
abort 'Slim must not include get.conf' if slim.match?(/^include\s*=/)
abort 'Slim must not use MESL DNS' if slim.lines.any? { |l| l.start_with?('dns-server') && l.include?('rlose.com') }
slim_groups = slim.split('[Proxy Group]', 2).last.split('[Rule]', 2).first.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
abort 'Slim must have exactly one group XM-日本' unless slim_groups.size == 1 && slim_groups.first.start_with?('XM-日本 = fallback,🇯🇵 日本 08 家宽,🇯🇵 日本 02,')
abort 'Slim fallback members must be Japan nodes' unless slim_groups.first.split(' = ', 2).last.split(',').reject { |f| f.include?('=') || f == 'fallback' }.all? { |n| n.include?('日本') }
slim_rules = slim.split('[Rule]', 2).last.split(/^\[/, 2).first.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
slim_rules.each do |line|
  policy = line.start_with?('FINAL,') ? line.split(',')[1] : line.split(',')[2]
  abort "Slim rule uses unknown policy: #{line}" unless %w[XM-日本 DIRECT REJECT].include?(policy)
end
abort 'Slim must end with FINAL,XM-日本' unless slim_rules.last == 'FINAL,XM-日本'
%w[grokbot.com x.ai].each { |d| abort "Slim missing #{d}" unless slim_rules.include?("DOMAIN-SUFFIX,#{d},XM-日本") }
puts "Validated Shadowrocket Slim: 1 fallback group, #{slim_rules.size} rules."

# Public configuration must not introduce private subscription endpoints.
allowed_urls = Set.new([
  'https://github.com/symonxu/clash-rules',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml',
  'https://www.clashverge.dev/guide/extend.html',
  'https://www.clashverge.dev/guide/script.html',
  'https://www.gstatic.com/generate_204',
  'https://github.com/MetaCubeX/mihomo/blob/v1.19.31/adapter/outboundgroup/urltest.go#L110-L131',
  'https://shadowlaunch.com/',
  'https://dash.mesurl.com/#/docs/10',
  'https://github.com/LOWERTOP/Shadowrocket',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Advertising.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Apple_cn.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Direct.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Google.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Hijacking.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Microsoft_cn.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Other.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Privacy.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Spotify.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Telegram.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Twitter.list',
  'https://raw.githubusercontent.com/meslcloud/Rule/refs/heads/main/Surge/Youtube.list',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Slim.conf',
  'https://www.google.com'
])
Dir.chdir(root) do
  tracked_files = IO.popen(['git', 'ls-files', '-z'], &:read).split("\0")
  tracked_files.each do |file|
    next unless File.file?(file)
    content = File.read(file, encoding: 'UTF-8')
    abort "Non-text tracked file: #{file}" unless content.valid_encoding? && !content.include?("\0")
    content.scan(%r{https?://[^\s<>"'`)\],，。；]+}).each do |url|
      abort "Unexpected public URL in #{file}" unless allowed_urls.include?(url)
    end
  end
end
puts 'Validated public URL allowlist.'

