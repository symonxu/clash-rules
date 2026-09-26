#!/usr/bin/env ruby

require "set"
require "uri"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
CONFIG_PATH = "XM-Personal-V1.1.yaml"
LOCAL_RULE_PREFIX = "/symonxu/clash-rules/main/"
PUBLIC_RULE_PREFIX = "https://raw.githubusercontent.com/symonxu/clash-rules/main/rules/"
PUBLIC_RULE_FILE_URL = %r{\A#{Regexp.escape(PUBLIC_RULE_PREFIX)}[a-z0-9-]+\.yaml\z}
URL_PATTERN = %r{https?://[^\s<>"'\x60)\]]+}

# Any new public endpoint should be reviewed before it enters this public repository.
ALLOWED_PUBLIC_URLS = Set.new([
  "https://dns.alidns.com/dns-query",
  "https://doh.pub/dns-query",
  "https://www.gstatic.com/generate_204",
  "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt",
  "https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Personal-V1.1.yaml",
  "https://github.com/symonxu/clash-rules",
  PUBLIC_RULE_PREFIX
]).freeze

def fail_with(message)
  warn "Rule validation failed: #{message}"
  exit 1
end

def read_yaml(path)
  YAML.safe_load(
    File.read(path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false,
    filename: path
  )
rescue Psych::Exception => error
  fail_with("#{path}: #{error.message}")
end

def allowed_public_url?(url)
  ALLOWED_PUBLIC_URLS.include?(url) || PUBLIC_RULE_FILE_URL.match?(url)
end

Dir.chdir(REPO_ROOT)

tracked_files = IO.popen(["git", "ls-files", "-z"], &:read).split("\0")
tracked_files.each do |path|
  next unless File.file?(path)

  content = File.binread(path).force_encoding(Encoding::UTF_8)
  next if content.include?("\0") || !content.valid_encoding?

  content.each_line.with_index(1) do |line, line_number|
    line.scan(URL_PATTERN).each do |candidate|
      url = candidate.sub(/[.,;:!]+\z/, "")
      fail_with("unapproved URL at #{path}:#{line_number}") unless allowed_public_url?(url)
    end
  end
end

yaml_files = (Dir.glob("*.yaml") + Dir.glob("rules/*.yaml")).sort
yaml_files.each { |path| read_yaml(path) }

config = read_yaml(CONFIG_PATH)
fail_with("#{CONFIG_PATH} must contain a mapping") unless config.is_a?(Hash)
%w[proxies proxy-providers].each do |key|
  fail_with("#{CONFIG_PATH} must not define #{key}; Hako manages nodes") if config.key?(key)
end

providers = config["rule-providers"]
rules = config["rules"]
fail_with("#{CONFIG_PATH} is missing rule-providers or rules") unless providers.is_a?(Hash) && rules.is_a?(Array)

used_provider_names = Set.new
rules.each do |rule|
  next unless rule.is_a?(String) && rule.start_with?("RULE-SET,")

  provider_name = rule.split(",", 3)[1]
  fail_with("malformed RULE-SET entry: #{rule}") if provider_name.nil? || provider_name.empty?

  used_provider_names.add(provider_name)
end

declared_provider_names = Set.new(providers.keys)
missing_providers = used_provider_names - declared_provider_names
unused_providers = declared_provider_names - used_provider_names
unless missing_providers.empty? && unused_providers.empty?
  fail_with("RULE-SET/provider mismatch; missing=#{missing_providers.to_a.sort}, unused=#{unused_providers.to_a.sort}")
end

provider_paths = providers.values.map do |provider|
  fail_with("each rule-provider must be a mapping") unless provider.is_a?(Hash)

  path = provider["path"]
  fail_with("each rule-provider must define a path") unless path.is_a?(String) && !path.empty?
  path
end
duplicate_paths = provider_paths.group_by(&:itself).select { |_path, occurrences| occurrences.length > 1 }.keys
fail_with("duplicate rule-provider paths: #{duplicate_paths.sort}") unless duplicate_paths.empty?

local_rule_files = Dir.glob("rules/*.yaml").sort
referenced_local_files = []
providers.each do |name, provider|
  url = provider["url"]
  fail_with("provider #{name} must use an HTTPS URL") unless url.is_a?(String) && url.start_with?("https://")

  parsed_url = URI.parse(url)
  next unless parsed_url.host == "raw.githubusercontent.com" && parsed_url.path.start_with?("/symonxu/clash-rules/")

  unless parsed_url.path.start_with?(LOCAL_RULE_PREFIX)
    fail_with("provider #{name} must reference the main branch of this repository")
  end

  local_path = parsed_url.path.delete_prefix(LOCAL_RULE_PREFIX)
  fail_with("provider #{name} references missing file #{local_path}") unless File.file?(local_path)

  rule_file = read_yaml(local_path)
  unless rule_file.is_a?(Hash) && rule_file["payload"].is_a?(Array) && !rule_file["payload"].empty?
    fail_with("#{local_path} must contain a non-empty payload array")
  end
  unless rule_file["payload"].all? { |entry| entry.is_a?(String) && !entry.empty? }
    fail_with("#{local_path} payload entries must be non-empty strings")
  end

  referenced_local_files << local_path
end

unreferenced_local_files = local_rule_files - referenced_local_files.uniq
fail_with("unreferenced local rule files: #{unreferenced_local_files}") unless unreferenced_local_files.empty?

puts "Validated #{yaml_files.length} YAML files, #{providers.length} rule providers, and #{local_rule_files.length} local rule modules."
