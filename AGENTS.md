# 🌐 AGENTS.md — XM 个人分流规则 (clash-rules) 零终端全自动维护规范

本文件是 **XM 个人分流规则 (`symonxu/clash-rules`)** 的跨 AI 工具（**Google Antigravity** & **Cursor**）统一指令总纲。

> 🚨 **核心交互铁律（面向代码小白用户 — 零终端模式）**：
> 用户不熟悉命令行操作。**无论是 Antigravity 还是 Cursor，严禁要求用户手动打开终端或输入任何命令！**
> 所有的拉取更新（`git pull`）、运行 Ruby 规则校验（`ruby scripts/validate_rules.rb`）、更新 [`TASKS.md`](TASKS.md) 与推送到 GitHub（`git push`），**必须 100% 由 AI Agent 自动在后台调用工具完成**，并用通俗易懂的中文向用户汇报。

---

## 1. 🗣️ 用户自然语言指令映射（AI 自动执行协议）

| 用户在聊天框说的话 | AI Agent 必须在后台全自动执行的动作 |
| :--- | :--- |
| **“读取最新进展” / “看看当前任务” / “继续工作”** | 1. 自动在后台执行 `git pull --ff-only` 同步 GitHub 最新代码；<br>2. 自动读取 [`TASKS.md`](TASKS.md) 与 [`README.md`](README.md)；<br>3. 用大白话向用户汇报上次完成的内容与当前待办事项，并直接推进工作。 |
| **“添加/修改某条分流规则”** | 1. 同时修改 [`XM-Clash-JSY.yaml`](XM-Clash-JSY.yaml)（极速云）、[`XM-Clash-HY.yaml`](XM-Clash-HY.yaml)（花云）、[`XM-Clash-MESL.yaml`](XM-Clash-MESL.yaml)（MESL）、[`XM-Clash-BOOST.yaml`](XM-Clash-BOOST.yaml)（Boost）与 [`XM-Clash-SWY.yaml`](XM-Clash-SWY.yaml)（三文鱼），各份 Clash rules 部分必须逐字节一致（CI 校验） 并严格遵守下述规则红线；<br>2. **强制校验**：自动在后台运行 `ruby scripts/validate_rules.rb`，若报错则自动修正直到 100% 通过；<br>3. 自动将进展写入 [`TASKS.md`](TASKS.md)。 |
| **“保存进度” / “同步到 GitHub” / “完工交接”** | 1. 自动运行 `ruby scripts/validate_rules.rb` 确保 100% 校验通过；<br>2. 自动更新 [`TASKS.md`](TASKS.md) 中的进度与交接记录；<br>3. 由于 `main` 分支受保护，AI 自动新建分支推送并通过 `gh pr create` + `gh pr merge` 完成合并上传至 GitHub (`https://github.com/symonxu/clash-rules`)。 |

---

## 2. 🛡️ 项目核心安全与规则红线（AI 严禁突破）

1. **严禁包含敏感信息与非白名单链接**：
   - 本仓库为 Public 公开仓库，**绝不能出现任何机场订阅地址、节点 IP/密码或私有凭据**。
   - `scripts/validate_urls.rb` 会扫描仓库内所有文件的网址链接，**严禁在任何文件中写入白名单以外的 URL**。
2. **规则结构与顺序红线**：
   - 维护两份并行规则文件：`XM-Clash-JSY.yaml`（极速云）、`XM-Clash-HY.yaml`（花云），以及一份 Shadowrocket 配置文件 `XM-Shadowrocket-HY.conf`，两份单订阅配置的 rules 部分逐字节一致。都不含 `proxies`、`proxy-providers`、`rule-providers`。花云全局 TCP 保活是 `keep-alive-idle: 30`、`keep-alive-interval: 15`、`disable-keep-alive: false`（不是规则，也不进策略组）。花云可以有且仅有 `hosts`：把订阅里正在用的 `*.aws-agent.org` 写成还能连上的国内入口 IP（2026-11-22 起为 `e3585sh2-3ad5.aws-agent.org` → `58.247.187.127`、`fd025gz0-c617.aws-agent.org` → `58.247.187.127`、`0bc52bj8-10e0.aws-agent.org` → `58.247.187.127`；不要再写已拒绝连接的 `116.242.224.8` 或已超时的 `119.147.195.213`、`180.188.20.131`）。`XM-Shadowrocket-HY.conf` 的 `[Host]` 必须与这些条目相同，并在 `[General]` 用 `always-real-ip` 覆盖 `*.openbot.run, *.openbot.site, *.aws-agent.org, *.mzstatic.com, *.itunes.apple.com, captive.apple.com, *.cdn-apple.com, swcdn.apple.com, swdist.apple.com, swscan.apple.com, ocsp2.apple.com, *.aaplimg.com, *.akadns.net, *.akamaiedge.net, *.ks-cdn.com, *.ksyuncdn.com, *.alikunlun.com`（TURN / WebRTC、节点域名和直连 CDN/门户都不能用假 IP；不写 `time.apple.com`，避免 NTP UDP/123 落入代理）。小火箭默认只用 DNS 解析节点域名、不拿 `[Host]` 去连节点，所以 `[General]` 必须有 `use-local-host-item-for-proxy = true`，否则节点会去连 `147.90.*`，延迟测试全部超时。花云入口 `58.247.187.127` 以及 `223.5.5.5`、`223.6.6.6`、`1.12.12.12`、`119.29.29.29` 必须写进 `skip-proxy` 和 `tun-excluded-routes`，否则手机上节点连接或 DoH 上游被吸进隧道，延迟测试会超时。花云 Clash 的 `XM-AI工具` 是 select，成员按顺序写死为日本标准 1、日本标准 3、台湾高级 2、台湾高级 3、美国标准 6、美国标准 7、韩国标准 2（2026-11-19：日本出口访问谷歌主站/YouTube/账号全部超时、美国节点正常，故加入 2 条美国 + 1 条韩国供手动切换；台湾两条保留待入口修复后再用）。小火箭同一组也是 select，但用节点名正则匹配这 7 条，不要把带国旗的节点名写进配置（写死后小火箭对不上订阅，整份会连不上）。Google、AI、OpenBot 的域名都走这一组。OpenCode（`opencode.ai`、`models.dev`）和它文档里的第三方模型接口（Groq、Mistral、DeepSeek、Together、Hugging Face 等）也走这一组；国内模型端点和客户自建云地址不写进这组。极速云同名组是 url-test，筛选 `日本_*`。
   - 七个分组（`XM-AI工具`, `XM-Web3`, `XM-Bybit`, `XM-日常上网`, `XM-Apple`, `XM-Anki`, `XM-系统更新`）名称与顺序固定。花云 `XM-AI工具` 是 select，7 个节点（日本标准 1/3、台湾高级 2/3、美国标准 6/7、韩国标准 2）；花云 `XM-日常上网` 也是 select，节点与此完全一致，方便两组一起切换出口。极速云 `XM-AI工具` 是 url-test（900 秒 / 20ms），筛选 `日本_*`。Google、AI、OpenBot 域名都走 `XM-AI工具`。`XM-Anki` 两份都是手动 select 组（花云 日本高级 1–3，极速云 日本_01–03，用户手动固定节点，无 url/interval/timeout/tolerance，validator 精确校验节点），只用于 `ankiweb.net`、`ankiuser.net`，须排在 `GEOIP,CN` 之前（CI 校验）。其余组：花云 `XM-Web3`、`XM-Bybit`、`XM-Apple` 是 url-test（300 秒 / 10ms），每组同地区高级 1–3 + 标准（日本/美国标准 1–4，台湾标准 1–3）；XM-Web3 例外，只用韩国标准 1–2、越南标准 1、印尼标准 1；极速云 XM-Web3 只用马来西亚/菲律宾/越南（两家都禁止新加坡/台湾，CI 校验）（Hyperliquid HIP-4 限制新加坡/台湾，日本隐藏预测市场），不用实验性和香港节点，validator 精确校验节点集合；极速云保持 900 秒 / 20ms，XM-Bybit 为 fallback。
   - `XM-Apple` 用于 Apple TV（App Store 不得走 `XM-Apple`，CI 校验）。Clash（`XM-Clash-HY.yaml`）将 Apple TV 目录、鉴权与视频流 CDN（`vod-*.tv.apple.com`、`-aoc.tv.apple.com`、`play-edge`/`hls`/`np-edge.itunes.apple.com`、`tv.apple.com`、`pancake.apple.com`、`uts-api.itunes.apple.com`）统一走 `XM-Apple` 保流畅（会消耗节点流量）；小火箭两份配置保持视频流 CDN 走 `DIRECT` 省流量、仅目录与鉴权走 `XM-Apple`。相关规则须排在 App Store 的 `itunes.apple.com` 直连规则之前（CI 校验）。
   - **DNS 采用 fake-ip**：`XM-Clash-JSY.yaml` 使用明文国内 DNS 223.5.5.5 / 119.29.29.29。花云 `XM-Clash-HY.yaml` 的 `nameserver` 必须是 `tls://223.5.5.5`、`https://dns.alidns.com/dns-query`，`proxy-server-nameserver` 是明文 `223.5.5.5`、`119.29.29.29`，`default-nameserver` 仍是明文 223.5.5.5 / 119.29.29.29，`use-hosts: true`，fake-ip-filter 额外包含 `+.apt-agent.org`。`hosts` 只写订阅里正在用的 `*.aws-agent.org`，并写成还能连上的国内入口 IP，不要写成另一个域名，也不要写已拒绝连接的 `116.242.224.8`。两份都是 `enhanced-mode: fake-ip`，fake-ip-filter 包含 `+.openbot.run`、`+.openbot.site` 与 `+.ts.net`；`nameserver-policy` 统一保留 Apple 系统更新走 DoH 与 `+.ts.net` 走 `100.100.100.100`（Tailscale MagicDNS）；`tun.route-exclude-address` 固定放行 `100.64.0.0/10`（仅用于 Clash YAML 配合官方 Tailscale App；小火箭内置模块不得旁路该网段）。
   - `XM-系统更新`：两份都是 select，`proxies` **只写 DIRECT 一项**（不得 include-all 或写入任何日本节点——客户端 `store-selected` 会把手动选过的日本节点记住，导致后续更新走代理卡住；后期如需代理救急，手动往这个组加节点即可），无 url/interval/timeout。用于 Apple OTA：`DOMAIN-SUFFIX,cdn-apple.com` 以及 appldnld/sw*/mesu/gdmf(+ados)/gs(+ra)/gg/ig/skl/xp/configuration/oscdn/osrecovery/cds/download.info.apple.com、ocsp2.apple.com（CI 精确白名单）。DNS：`nameserver-policy` 把 cdn-apple.com/swcdn/swdist/swscan/ocsp2/aaplimg/akadns/akamaiedge/ks-cdn/ksyuncdn/alikunlun 交给 `['https://223.5.5.5/dns-query', 'https://doh.pub/dns-query']`（不要用 system：TUN 下回环到 mihomo），并加入 fake-ip-filter（CI 精确校验，只允许这两个 DoH URL）。须排在 `GEOIP,CN` 之前；`cdn-apple.com` 不得再走 XM-日常上网。不吞 Apple TV / App Store（itunes、mzstatic、apps）规则。
   - Tailscale 必须按客户端区分路由：Clash YAML 配合官方 Tailscale App 时，QUIC 拒绝规则后紧跟 macOS 官方客户端两条精确 `PROCESS-NAME` 直连（`io.tailscale.ipn.macsys.network-extension`、`Tailscale`；不得写通配/正则进程规则，iOS 端会安全跳过精确匹配）、控制面与 `100.64.0.0/10` 按 DIRECT 处理并使用 `tun.route-exclude-address`。Shadowrocket 使用内置 Tailscale 模块：第一条业务规则前依次配置 `DOMAIN-SUFFIX,tailscale.com,DIRECT`、`DOMAIN-SUFFIX,tailscale.io,DIRECT`、`IP-CIDR,100.64.0.0/10,TAILSCALE,no-resolve`、`DOMAIN-SUFFIX,ts.net,TAILSCALE`；`100.64.0.0/10` 和 `*.ts.net` 不得加入小火箭的 `skip-proxy` / `tun-excluded-routes`，CI 校验。小火箭配置关闭 IPv6，因此使用 IPv4 Tailnet 地址。
   - QUIC 屏蔽按客户端区分：Clash YAML 必须保留紧跟局域网直连规则的 `AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`，且位于第一条业务分流之前（CI 校验），屏蔽 UDP/443 让流量回落 TCP 以命中域名规则。小火箭两份配置（2026-11-27 更新）使用 `[General] block-quic = all`，全局封 UDP/443，直连与代理都回落 TCP（弱网下抖音/微信直连卡在 QUIC 重试、阿里 DoH 被 alt-svc 升级成 h3 同样受累，故不再只封代理）；规则段不得再有全局 QUIC REJECT（CI 校验）。代价是 App Store 首屏可能短暂变慢，若明显再评估。Tailscale 内置模块规则仍须位于第一条业务规则之前。
   - 小火箭 DNS（2026-11-23）：`dns-server = https://223.5.5.5/dns-query, https://223.6.6.6/dns-query`（阿里双路纯 IP DoH，省去 DoH 域名引导查询并防单点超时，避免 `1.12.12.12` 高延迟/断开），不得用明文 `223.5.5.5, 119.29.29.29`；直连域名由本地加密 DNS 解析，避免 UDP/53 被劫持或拿到苹果 CDN 池里的不可达 IP 导致 App Store 卡首屏。`skip-proxy` / `tun-excluded-routes` 须放行 `223.5.5.5`、`223.6.6.6`、`1.12.12.12`、`119.29.29.29`（CI 校验）。
   - 规则不得重复，不得被排在前面的更宽泛 `DOMAIN-SUFFIX` 规则遮蔽；`gemini.google.com` 等 AI 域名必须排在 `google.com` 之前；Clash 结尾三条固定为 `GEOSITE,CN,DIRECT`、`GEOIP,CN,DIRECT` 与 `MATCH,XM-日常上网`（小火箭不支持 `GEOSITE`，结尾两条为 `GEOIP,CN,DIRECT` 与 `FINAL,XM-日常上网`）。
   - `Clash.app` 入口监控面板模块位于 `modules/flower-entry-monitor.sgmodule`（搭配 `modules/flower-entry-monitor.js`），可在客户端「配置库 › 模块」通过链接添加并在模块本地设置填入外部控制器密钥，定时/切网通过本机 `127.0.0.1:9090` 实测花云代表节点真实延迟与入口解析，并在异常时发送系统通知。
3. **每次修改必跑校验**：
   - 修改任何文件后必须自动运行 `ruby scripts/validate_rules.rb`。

- Notion 全家（notion.so/.com/.site/.new/.ai、notion-static.com、notion-status.com、notionusercontent.com、makenotion.com、Notion Calendar 旧域 cron.com，以及文件存储 `prod-files-secure.s3.us-west-2.amazonaws.com` 精确匹配）走 XM-AI，排在 GEOIP,CN 之前，CI 校验。
- OpenBot（openbot.run 含 api / analytics，以及 openbot.site）、Google 与 AI 域名都走 XM-AI工具。花云该组是 select，7 个节点（2 日本 + 2 台湾 + 2 美国 + 1 韩国）；极速云该组是 url-test。排在 GEOIP,CN 之前，CI 校验。
