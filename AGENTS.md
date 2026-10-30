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
   - 维护五份并行规则文件：`XM-Clash-JSY.yaml`（极速云）、`XM-Clash-HY.yaml`（花云）、`XM-Clash-MESL.yaml`（MESL）、`XM-Clash-BOOST.yaml`（Boost）与 `XM-Clash-SWY.yaml`（三文鱼），以及一份 Shadowrocket 配置文件 `XM-Shadowrocket.conf`，五份单订阅配置的 rules 部分逐字节一致。只有 `XM-Clash-MULTI.yaml` 包含两条 OpenBot 的 UDP 拒绝规则（`AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.run|openbot.site)),REJECT`，排在对应 `DOMAIN-SUFFIX,...,XM-OpenBot` 之前、QUIC 之后），强制客户端在极速云专线 NAT 穿透遇阻时快速回退 TCP 443。花云 `XM-Clash-HY.yaml` 不加这两条。都不含 `proxies`、`proxy-providers`、`rule-providers`。花云可以有且仅有 `hosts`：把订阅里的 3 个 `*.aws-agent.org` 写成国内入口 IP（入口 IP 变了要一起改）。`XM-Clash-MULTI.yaml` 是独立的规则方案，不进单订阅 FILES 列表。订阅由 App「添加代理来源」挂上极速云和 Flower_SS / Flower_Trojan。改四份 rules 后，把同一段 rules 原样拷进 MULTI，再把这四条 openbot 规则按原顺序补上，再跑校验。MULTI 的 `XM-OpenBot` 用极速云日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03：极速云 AnyTLS 的 UDP 转发撑不住 TURN（连续 15 次 STUN 掉 6 次），靠上面那两条 REJECT 让客户端改走 TURN 的 TCP 443，只借用极速云的 TCP 线路。MULTI 的 `XM-Web3` 是极速云 日本_01–08 + 马来西亚/菲律宾/越南优先、花云整组垫底（花云全部节点健康检查失败过一次，导致 OpenBot 和 Web3 一起断）。MESL 节点名形如「日本 02」「马来西亚 01 家宽」；带 `[0.3X]` 的节点不进任何组。Google / AI / 日常上网用日本 02–07 与日本 08–12 家宽；Web3 用马来西亚家宽、菲律宾、越南家宽、韩国、印度尼西亚（禁止新加坡/台湾/香港）；Bybit 为 fallback，台湾 02 起；Apple 用美国 01–03；Anki 与系统更新备用节点为日本 02–04。测速 300 秒 / 10ms。三文鱼（SWY）节点名形如「日本-1」「台湾家宽|1.5X|-1」「韩国」；香港及备用节点不进任何组。Google / AI / 日常上网用日本-1–6；OpenBot fallback 为日本-1–6 加【V6】日本-7/8；Web3 为日本-1–6 加韩国/印度/德国/英国/加拿大；Bybit 为台湾家宽 fallback；Apple 为美国-1–3；Anki 与系统更新备用为日本-1–3。测速 300 秒 / 10ms。 Boost 节点名不带国旗（日本1–8、台湾1–4、美国1–3、马来西亚-3倍率）；香港、新加坡和其余倍率节点不进组。Google / AI / 日常上网 / OpenBot 用日本1–8；Web3 再加马来西亚-3倍率；Bybit 为 fallback，台湾1 起；Apple 用美国1–3；Anki 与系统更新备用为日本1–3。测速 300 秒 / 10ms。
   - 九个分组（`XM-Google`, `XM-AI`, `XM-OpenBot`, `XM-Web3`, `XM-Bybit`, `XM-日常上网`, `XM-Apple`, `XM-Anki`, `XM-系统更新`）名称与顺序固定。`XM-OpenBot` 是 fallback（无 tolerance）：极速云 日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03（900 秒；02/03/04 家里宽带刚测是死的，放备份位），花云 日本高级 1 → 2 → 3 → 日本标准 1 → 2 → 3 → 4（300 秒），MESL 日本 02 → 03 → 04（300 秒，不要 01 和家宽）。失败才换，不跟 XM-AI 的 url-test 绑定。只用于 `openbot.run`、`openbot.site`。`XM-Anki` 两份都是手动 select 组（花云 日本高级 1–3，极速云 日本_01–03，用户手动固定节点，无 url/interval/timeout/tolerance，validator 精确校验节点），只用于 `ankiweb.net`、`ankiuser.net`，须排在 `GEOIP,CN` 之前（CI 校验）。其余六组：花云六个组全部 url-test（300 秒 / 10ms），每组同地区高级 1–3 + 标准（日本/美国标准 1–4，台湾标准 1–3）；XM-Web3 例外，只用韩国标准 1–2、越南标准 1、印尼标准 1；极速云 XM-Web3 只用马来西亚/菲律宾/越南（两家都禁止新加坡/台湾，CI 校验）（Hyperliquid HIP-4 限制新加坡/台湾，日本隐藏预测市场），不用实验性和香港节点，validator 精确校验节点集合；极速云保持 900 秒 / 20ms，XM-Bybit 为 fallback。
   - `XM-Apple` 只用于 Apple TV（`tv.apple.com`、`pancake.apple.com` 及其 `itunes.apple.com` 流媒体子域名）；App Store 不得走 `XM-Apple`（CI 校验）。Apple TV 视频 CDN（`vod-*-aoc.tv.apple.com`）直连（`DIRECT`），鉴权、片单域名仍走 `XM-Apple`；须排在 `tv.apple.com` 之前（CI 校验）。
   - **DNS 采用 fake-ip**：`XM-Clash-JSY.yaml` / `XM-Clash-MESL.yaml` / `XM-Clash-BOOST.yaml` / `XM-Clash-SWY.yaml`（以及 `XM-Clash-MULTI.yaml`）使用明文国内 DNS 223.5.5.5 / 119.29.29.29。花云 `XM-Clash-HY.yaml` 的 `nameserver` 必须是 `tls://223.5.5.5`、`https://dns.alidns.com/dns-query`，`proxy-server-nameserver` 是明文 `223.5.5.5`、`119.29.29.29`，`default-nameserver` 仍是明文 223.5.5.5 / 119.29.29.29，`use-hosts: true`，fake-ip-filter 额外包含 `+.apt-agent.org`。`hosts` 把 3 个 `*.aws-agent.org` 写成国内入口 IP，不要写成另一个域名。五份都是 `enhanced-mode: fake-ip`，fake-ip-filter 包含 `+.openbot.run` 与 `+.openbot.site`；`nameserver-policy`（Apple 系统更新走 DoH）统一保留。
   - `XM-系统更新`：两份都是 select，`proxies: [DIRECT]` 在前作默认，再 include-all 日本节点（花云 日本高级 1–3，极速云 日本_01–03），无 url/interval/timeout。用于 Apple OTA：`DOMAIN-SUFFIX,cdn-apple.com` 以及 appldnld/sw*/mesu/gdmf(+ados)/gs(+ra)/gg/ig/skl/xp/configuration/oscdn/osrecovery/cds/download.info.apple.com、ocsp2.apple.com（CI 精确白名单）。DNS：`nameserver-policy` 把 cdn-apple.com/swcdn/swdist/swscan/ocsp2/aaplimg/akadns/akamaiedge/ks-cdn/ksyuncdn/alikunlun 交给 `['https://223.5.5.5/dns-query', 'https://doh.pub/dns-query']`（不要用 system：TUN 下回环到 mihomo），并加入 fake-ip-filter（CI 精确校验，只允许这两个 DoH URL）。须排在 `GEOIP,CN` 之前；`cdn-apple.com` 不得再走 XM-日常上网。不吞 Apple TV / App Store（itunes、mzstatic、apps）规则。
   - 局域网直连规则之后的第一条必须是 `AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`（屏蔽 QUIC，让流量回落 TCP 走域名规则），不得删除或后移（CI 校验）。
   - 规则不得重复，不得被排在前面的更宽泛 `DOMAIN-SUFFIX` 规则遮蔽；`gemini.google.com` 等 AI 域名必须排在 `google.com` 之前；最后两条必须固定为 `GEOIP,CN,DIRECT` 与 `MATCH,XM-日常上网`。
3. **每次修改必跑校验**：
   - 修改任何文件后必须自动运行 `ruby scripts/validate_rules.rb`。

- Notion 全家（notion.so/.com/.site/.new、notion-static.com、notionusercontent.com、makenotion.com、Notion Calendar 旧域 cron.com，以及文件存储 `prod-files-secure.s3.us-west-2.amazonaws.com` 精确匹配）走 XM-AI，排在 GEOIP,CN 之前，CI 校验。
- OpenBot（openbot.run 含 api / analytics，以及 openbot.site）走 XM-OpenBot（fallback，不跟 XM-AI 测速绑定），排在 GEOIP,CN 之前，CI 校验。只有 `XM-Clash-MULTI.yaml` 里这两条域名之前包含两条 UDP REJECT（`AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.run))` 和 `...openbot.site`），让客户端在极速云专线 NAT 下遇到 UDP 穿透故障时快速回退到 TCP 443。花云不加这两条。
