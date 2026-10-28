#!/usr/bin/env ruby
require 'set'
root = File.expand_path('..', __dir__)
# Public repository must not introduce private subscription endpoints.
allowed_urls = Set.new([
  'https://github.com/symonxu/clash-rules',
  'https://www.gstatic.com/generate_204',
  'https://223.5.5.5/dns-query',
  'https://doh.pub/dns-query',
  'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat',
  'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat',
  'https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-JSY.yaml',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-HY.yaml',
  'https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-MESL.yaml',
  'https://clash.md/zh/guide/ios',
  'https://clash.md/zh/guide/macos',
  'https://github.com/ProjectClash/Clash-Client',
  'https://clash.md/zh/guide/config/apple-platforms'
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
