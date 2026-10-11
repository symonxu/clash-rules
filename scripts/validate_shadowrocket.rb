#!/usr/bin/env ruby
require 'set'
root = File.expand_path('..', __dir__)

# Slim iOS config: standalone (no include), five url-test groups mirroring the Mac routing.
require 'yaml'
slim = File.read(File.join(root, 'XM-Shadowrocket-Slim.conf'))
abort 'Slim must not include get.conf' if slim.match?(/^include\s*=/)
abort 'Slim must not use MESL DNS' if slim.lines.any? { |l| l.start_with?('dns-server') && l.include?('rlose.com') }
jp = ['🇯🇵 日本 02', '🇯🇵 日本 03', '🇯🇵 日本 04', '🇯🇵 日本 08 家宽', '🇯🇵 日本 09 家宽', '🇯🇵 日本 10 家宽']
us = ['🇺🇸 美国 01', '🇺🇸 美国 02', '🇺🇸 美国 03', '🇺🇸 美国 10 家宽', '🇺🇸 美国 11 家宽', '🇺🇸 美国 12 家宽']
w3 = ['🇲🇾 马来西亚 01 家宽', '🇲🇾 马来西亚 02 家宽', '🇲🇾 马来西亚 03 家宽', '🇵🇭 菲律宾 01', '🇵🇭 菲律宾 02 家宽', '🇻🇳 越南 家宽']
wanted_groups = { 'XM-Google' => jp, 'XM-AI' => jp, 'XM-Meta' => us, 'XM-Web3' => w3, 'XM-日常上网' => jp }
group_opts = %w[url=https://www.gstatic.com/generate_204 interval=900 tolerance=20 timeout=5]
slim_groups = slim.split('[Proxy Group]', 2).last.split('[Rule]', 2).first.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
parsed = slim_groups.to_h { |l| name, spec = l.split(' = ', 2); [name, spec.to_s.split(',')] }
abort 'Slim must have exactly the five XM groups' unless slim_groups.size == 5 && parsed.keys.sort == wanted_groups.keys.sort
parsed.each do |name, fields|
  abort "#{name} must be url-test" unless fields.first == 'url-test'
  abort "#{name} has wrong members" unless fields[1..].reject { |f| f.include?('=') } == wanted_groups[name]
  abort "#{name} has wrong test options" unless fields.select { |f| f.include?('=') }.sort == group_opts.sort
end
slim_rules = slim.split('[Rule]', 2).last.split(/^\[/, 2).first.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
slim_rules.each do |line|
  policy = line.start_with?('FINAL,') ? line.split(',')[1] : line.split(',')[2]
  abort "Slim rule uses unknown policy: #{line}" unless (wanted_groups.keys + %w[DIRECT REJECT]).include?(policy)
end
abort 'Slim must end with GEOIP,CN,DIRECT then FINAL,XM-日常上网' unless slim_rules.last(2) == ['GEOIP,CN,DIRECT', 'FINAL,XM-日常上网']
# Every Mac domain rule must appear on iOS with the same target, in the same relative order.
mac_domain = YAML.safe_load(File.read(File.join(root, 'XM-ClashVerge-Routing.yaml'))).fetch('rules').grep(/^DOMAIN(-SUFFIX|-KEYWORD)?,/)
mac_domain.each { |r| abort "Slim missing Mac rule #{r}" unless slim_rules.include?(r) }
abort 'Slim domain rule order differs from Mac' unless slim_rules.select { |r| mac_domain.include?(r) } == mac_domain
abort 'AI Google domains must precede Google' unless slim_rules.index('DOMAIN-SUFFIX,gemini.google.com,XM-AI') < slim_rules.index('DOMAIN-SUFFIX,google.com,XM-Google')
puts "Validated Shadowrocket Slim: 5 url-test groups, #{slim_rules.size} rules, consistent with Mac."

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

