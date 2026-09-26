#!/usr/bin/env ruby

require "set"
require "uri"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
CONFIG_PATHS = %w[XM-Personal-V1.3.yaml].freeze
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
  "https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Personal-V1.3.yaml",
  "https://github.com/symonxu/clash-rules",
  PUBLIC_RULE_PREFIX
]).freeze

EXPECTED_RULE_ROUTES = {
  "Web3链上" => "⛓️ Web3链上数据",
  "Bybit规则" => "💹 Bybit网络",
  "Web3交易规则" => "💰 Web3交易",
  "AI规则" => "🤖 AI工具",
  "Google规则" => "🔎 Google服务",
  "Meta规则" => "🟦 Meta服务",
  "中国大陆域名" => "DIRECT",
}.freeze

FIXED_EXIT_FILTERS = {
  "🔎 Google服务" => ["^🇯🇵 日本 08 家宽"],
  "🟦 Meta服务" => ["^🇺🇸 美国"],
  "🤖 AI工具" => ["^🇯🇵 日本 (08|09|10) 家宽"],
  "💹 Bybit网络" => ["(?i)(🇦🇺|澳大利亚|澳洲|Australia|🇬🇪|格鲁吉亚|Georgia)"],
  "💰 Web3交易" => ["^🇯🇵 日本 (08|09|10) 家宽", "^🇯🇵 日本 0[1-3]"],
  "⛓️ Web3链上数据" => ["^(🇯🇵 日本 (08|09|10) 家宽|🇯🇵 日本 0[1-3])"]
}.freeze

BROAD_GROUPS = Set.new(["🌐 日常上网", "⚡ 自动选快", "🧭 全部节点"]).freeze

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

def validate_fixed_exit(config_path, groups, root, group_name, visiting = Set.new)
  fail_with("#{config_path}: #{root} reaches a broad group: #{group_name}") if BROAD_GROUPS.include?(group_name)
  group = groups[group_name]
  fail_with("#{config_path}: #{root} references unknown group #{group_name}") unless group
  fail_with("#{config_path}: cycle in #{root} at #{group_name}") if visiting.include?(group_name)
  fail_with("#{config_path}: #{root} uses an unchecked proxy provider") if group.key?("use")

  includes_nodes = %w[include-all include-all-proxies include-all-providers].any? { |key| group[key] == true }
  if includes_nodes
    unless FIXED_EXIT_FILTERS.fetch(root).include?(group["filter"]) && group["exclude-type"] == "direct"
      fail_with("#{config_path}: #{root} has an unapproved node filter in #{group_name}")
    end
  end

  children = group.fetch("proxies", [])
  fail_with("#{config_path}: invalid proxies in #{group_name}") unless children.is_a?(Array)
  fail_with("#{config_path}: #{root} has no eligible nodes in #{group_name}") if children.empty? && !includes_nodes

  visiting.add(group_name)
  children.each do |child|
    fail_with("#{config_path}: #{root} references an unverified node #{child}") unless groups.key?(child)
    validate_fixed_exit(config_path, groups, root, child, visiting)
  end
  visiting.delete(group_name)
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

local_rule_files = Dir.glob("rules/*.yaml").sort
referenced_local_files = []
CONFIG_PATHS.each do |config_path|
  config = read_yaml(config_path)
  fail_with("#{config_path} must contain a mapping") unless config.is_a?(Hash)
  %w[proxies proxy-providers].each do |key|
    fail_with("#{config_path} must not define #{key}; Hako manages nodes") if config.key?(key)
  end

  providers = config["rule-providers"]
  rules = config["rules"]
  groups_list = config["proxy-groups"]
  unless providers.is_a?(Hash) && rules.is_a?(Array) && groups_list.is_a?(Array)
    fail_with("#{config_path} is missing rule-providers, proxy-groups, or rules")
  end

  dns = config["dns"]
  fake_ip_filters = dns.is_a?(Hash) ? dns["fake-ip-filter"] : nil
  if fake_ip_filters.is_a?(Array) && fake_ip_filters.any? { |entry| entry.is_a?(String) && entry.match?(/apple|icloud|itunes|mzstatic/i) }
    fail_with("#{config_path} must not define Apple-specific fake-ip filters")
  end
  if rules.any? { |rule| rule.is_a?(String) && rule.match?(/apple|icloud|itunes|mzstatic/i) }
    fail_with("#{config_path} must not define Apple-specific routing rules")
  end

  group_names = groups_list.map do |group|
    fail_with("#{config_path} contains an invalid proxy group") unless group.is_a?(Hash) && group["name"].is_a?(String)
    group["name"]
  end
  fail_with("#{config_path} has duplicate proxy groups") unless group_names.uniq.length == group_names.length
  groups = groups_list.each_with_object({}) { |group, result| result[group["name"]] = group }

  actual_routes = {}
  rules.each do |rule|
    next unless rule.is_a?(String) && rule.start_with?("RULE-SET,")

    parts = rule.split(",", 4)
    fail_with("#{config_path} has a malformed RULE-SET entry: #{rule}") if parts.length < 3 || parts[1].empty? || parts[2].empty?
    fail_with("#{config_path} routes #{parts[1]} more than once") if actual_routes.key?(parts[1])
    actual_routes[parts[1]] = parts[2]
  end

  declared_provider_names = Set.new(providers.keys)
  used_provider_names = Set.new(actual_routes.keys)
  missing_providers = used_provider_names - declared_provider_names
  unused_providers = declared_provider_names - used_provider_names
  unless missing_providers.empty? && unused_providers.empty?
    fail_with("#{config_path} RULE-SET/provider mismatch; missing=#{missing_providers.to_a.sort}, unused=#{unused_providers.to_a.sort}")
  end
  unless actual_routes == EXPECTED_RULE_ROUTES && actual_routes.keys == EXPECTED_RULE_ROUTES.keys
    fail_with("#{config_path} changed protected rule targets or order")
  end
  fail_with("#{config_path} must end with the daily MATCH rule") unless rules.last == "MATCH,🌐 日常上网"

  FIXED_EXIT_FILTERS.each_key do |root|
    validate_fixed_exit(config_path, groups, root, root)
  end

  provider_paths = providers.values.map do |provider|
    fail_with("#{config_path}: each rule-provider must be a mapping") unless provider.is_a?(Hash)

    path = provider["path"]
    fail_with("#{config_path}: each rule-provider must define a path") unless path.is_a?(String) && !path.empty?
    path
  end
  duplicate_paths = provider_paths.group_by(&:itself).select { |_path, occurrences| occurrences.length > 1 }.keys
  fail_with("#{config_path} has duplicate rule-provider paths: #{duplicate_paths.sort}") unless duplicate_paths.empty?

  providers.each do |name, provider|
    url = provider["url"]
    fail_with("#{config_path}: provider #{name} must use an HTTPS URL") unless url.is_a?(String) && url.start_with?("https://")

    parsed_url = URI.parse(url)
    next unless parsed_url.host == "raw.githubusercontent.com" && parsed_url.path.start_with?("/symonxu/clash-rules/")

    unless parsed_url.path.start_with?(LOCAL_RULE_PREFIX)
      fail_with("#{config_path}: provider #{name} must reference the main branch of this repository")
    end

    local_path = parsed_url.path.delete_prefix(LOCAL_RULE_PREFIX)
    fail_with("#{config_path}: provider #{name} references missing file #{local_path}") unless File.file?(local_path)

    rule_file = read_yaml(local_path)
    unless rule_file.is_a?(Hash) && rule_file["payload"].is_a?(Array) && !rule_file["payload"].empty?
      fail_with("#{local_path} must contain a non-empty payload array")
    end
    unless rule_file["payload"].all? { |entry| entry.is_a?(String) && !entry.empty? }
      fail_with("#{local_path} payload entries must be non-empty strings")
    end

    referenced_local_files << local_path
  end
end

unreferenced_local_files = local_rule_files - referenced_local_files.uniq
fail_with("unreferenced local rule files: #{unreferenced_local_files}") unless unreferenced_local_files.empty?

puts "Validated #{yaml_files.length} YAML files, #{CONFIG_PATHS.length} profiles, and #{local_rule_files.length} local rule modules."
