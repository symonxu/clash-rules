# 3.2 → Clash Verge Rev / Clash Hako

以 `个人网络分流3.2.stoverride`（提交 `6243135cc6a6f2ac930dcc0d86088c8d36cc3c1d`）为基准。原 Stash 文件保持原样，随时可回退。这里提供公共配置源和私有导入文件生成器，不修改当前运行中的客户端。

## 配置归属

- `common.yaml`：两端共用的 DNS、9 个策略组、MESL Provider 和分流入口。含明确不可用的订阅占位符，不能直接当成可联网订阅导入。
- `rules/XM32-*.yaml`：从 3.2 按连续策略目标拆出的 8 个 classical 规则集。展开后的内容与顺序严格等于原 153 条规则，包括原有末尾 MATCH；没有额外兜底。
- 原中国大陆 domain/ipcidr Provider 继续使用原来的 Loyalsoldier 地址，均保持 86400 秒更新。
- MESL 只作为 `proxy-providers.MESL-Nodes` 读取节点，21600 秒更新。即使 MESL 返回完整配置，其策略组/DNS/rules 也不会接管个人配置。
- MESL URL 与节点缓存、生成文件均只在本机 `.private/`；禁止提交或放进公开 URL。GitHub 仅保存非敏感公共内容。
- macOS 生成文件仅增加 `mixed-port: 7890`、`allow-lan: false`。Verge 的系统代理、TUN、控制器由客户端管理；iOS 通过 NetworkExtension 接入，不加入桌面 TUN 配置。

## 迁移差异

| 3.2 Stash | 公共 Mihomo/Hako 配置 |
| --- | --- |
| `name/category/desc`、`#!replace` | 去掉元数据和合并指令，生成完整 YAML |
| 父 select 组 `interval: -1` | `interval: 0`，不设置测试 URL，避免注册全量节点测试 |
| Provider `benchmark-url/benchmark-timeout` | 不使用；自动组显式采用旧主配置的 `http://www.apple.com` 测试 URL |
| Stash 各组独立调度 | Mihomo 单 Provider 合并测试任务：Provider 基础 URL 为空、基础检查关闭，自动组注册带筛选的测试任务；统一 300 秒、Provider `lazy: false`。只覆盖日本 01–03、08–10 家宽及新加坡 01–03，全部节点组仍可手动选择其他节点 |
| 日常优选原 600 秒 | 随共用 Provider 改为 300 秒，这是明确的调度差异，不承诺与 Stash 内存/能耗相同 |
| 空筛选组可能采用默认兼容出站 | 设 `empty-fallback: REJECT`；生成前检查各筛选组非空，不因订阅改名而静默直连 |

Web3 家宽 fallback 的订阅顺序不变，普通日本节点仍是第二层备用；AI 仍仅限日本家宽；RPC 和交易分组保持分离。故障切换仍不保证固定出口 IP。测试 URL 只检查连通性，不证明业务地区、登录或交易可用。

## 生成与更新

需要 Python 3 和 PyYAML；建议在独立虚拟环境中安装 `pyyaml`。在本仓库运行：

```sh
python clash/scripts/verify.py
python clash/scripts/build.py --provider /私有路径/provider.json --nodes /私有路径/mesl.yaml --ref feat/mihomo-hako-3.2 --output /私有路径/import
```

`provider.json` 仅在本机保存，例如 `{"url":"真实的 HTTPS MESL 地址","user-agent":"Stash/3.2.0"}`。`mesl.yaml` 是 MESL 返回的含 `proxies` 列表的 YAML，用于检查节点名；生成文件只引用远程 Provider，不嵌入这些节点。脚本不请求订阅、不输出 URL，也不把旧缓存核验当成当前订阅成功。使用服务商确认支持的请求标识；不要将 403 自动归因于 token 失效。

预览分支使用 `--ref feat/mihomo-hako-3.2`；合并后生成时用 `--ref main`。分支被删除之前，先让两端改用 main 生成的文件。公共规则地址含分支名称，与该参数一致。

1. Mac：将 `XM-Clash-macOS.yaml` 作为独立本地配置导入 Verge；不要将 MESL 的完整订阅设为这个配置的更新源。检查合并后的实际配置没有旧全局脚本/覆写覆盖 DNS、策略组或 rules，再选择 Rule 模式。当前任务不会自动切换在用配置。
2. iPhone：Clash 首页顶部当前配置 → 添加配置 → 文件，导入 `XM-Clash-iOS.yaml`。这是私有文件，请通过可信设备间方式传输；不要上传公开仓库。选择 Rule 模式。
3. 新建连接后核对：Hyperliquid → Web3交易；Solana RPC → Web3链上数据；ChatGPT/Gemini → AI工具；普通 Google → Google服务；App Store/系统更新/抖音 → DIRECT。

**同步有明确层次：**MESL 节点由 Provider 更新；公共规则由 GitHub 规则集更新；DNS、策略组、Provider 参数改变时，两端重新生成/导入完整文件。GitHub 提交不会即时推送，更新间隔也不保证 iOS 挂起期间执行。未建立私有配置托管服务，因此不宣称整份主配置可通过公开 URL 自动更新。

规则顺序由 `common.yaml` 固定；只在既有段内增删规则时可仅更新对应规则集；跨策略边界调整要更新模板并重新生成。以后改动要同时维护基准核验：现有 verify 明确锁定 3.2 的精确等价性，不能静默绕过失败。

## 回退

保留原 Stash 主配置及 3.2 覆写，重新选择原配置即可。两端切换新配置会影响已有连接，实际启用应避开交易/下载过程。删除新导入项不会改变原配置；本次未写入客户端设置，也未修改 MESL 订阅内容。

## 已验证与未验证（2026-09-21）

- GitHub 当前主分支基准为 `6243135`；仓库未包含 XM-Stash 私有主配置。旧 README 描述的马来西亚 Web3 并非当前 3.2。
- 153 条规则展开后逐条、逐序一致；9 组名称、类型、筛选、依赖与分流边界核验通过；DNS 原有服务器及 Fake-IP 例外保留。
- 12 个关键域名的静态首匹配检查、空池拒绝、引用/依赖检查通过。
- 本机 Mihomo v1.19.29 对两份生成配置执行 `-t`，结果记录见 `verification.json`。测试使用本地缓存及规则集，不接管系统网络。
- 隔离启动的 Mihomo 使用仅指向本机的模拟节点：10 个规则集全部加载，分组筛选及 Web3 依赖顺序核验通过；没有通过真实节点发起业务请求。
- MESL 当前请求返回 HTTP 403。筛选计数使用 2026-09-20 缓存的 172 个节点：日常 6、Google 3、AI 3、Web3 家宽 3、普通 3、链上 6。这些计数不是当前订阅状态。
- Hako 按官方兼容文档及其 Mihomo 架构设计，尚未进行 iPhone 真机导入、真实出口、故障切换或内存验证；也未验证当前 MESL 地址能够在两端刷新。确认订阅恢复、组非空及上述实际连接分流后再正式切换。

## 官方依据

- [Hako 内核及平台边界](https://clash.md/zh/hako)
- [Clash 的 Stash 迁移说明](https://clash.md/zh/guide/compatibility/stash)
- [Clash Provider 字段](https://clash.md/zh/guide/config/proxy-providers)
- [iPhone 导入与连接核验](https://clash.md/zh/guide/ios)
- [Mihomo 策略组](https://wiki.metacubex.one/config/proxy-groups/)
- [Mihomo v1.19.29 测试任务注册实现](https://github.com/MetaCubeX/mihomo/blob/v1.19.29/adapter/outboundgroup/parser.go)
- [Mihomo v1.19.29 Provider 测试筛选实现](https://github.com/MetaCubeX/mihomo/blob/v1.19.29/adapter/provider/healthcheck.go)
