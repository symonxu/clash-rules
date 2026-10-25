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
| **“添加/修改某条分流规则”** | 1. 同时修改 [`XM-Clash-JSY.yaml`](XM-Clash-JSY.yaml)（极速云）和 [`XM-Clash-HY.yaml`](XM-Clash-HY.yaml)（花云），两份 rules 部分必须逐字节一致（CI 校验） 并严格遵守下述规则红线；<br>2. **强制校验**：自动在后台运行 `ruby scripts/validate_rules.rb`，若报错则自动修正直到 100% 通过；<br>3. 自动将进展写入 [`TASKS.md`](TASKS.md)。 |
| **“保存进度” / “同步到 GitHub” / “完工交接”** | 1. 自动运行 `ruby scripts/validate_rules.rb` 确保 100% 校验通过；<br>2. 自动更新 [`TASKS.md`](TASKS.md) 中的进度与交接记录；<br>3. 由于 `main` 分支受保护，AI 自动新建分支推送并通过 `gh pr create` + `gh pr merge` 完成合并上传至 GitHub (`https://github.com/symonxu/clash-rules`)。 |

---

## 2. 🛡️ 项目核心安全与规则红线（AI 严禁突破）

1. **严禁包含敏感信息与非白名单链接**：
   - 本仓库为 Public 公开仓库，**绝不能出现任何机场订阅地址、节点 IP/密码或私有凭据**。
   - `scripts/validate_urls.rb` 会扫描仓库内所有文件的网址链接，**严禁在任何文件中写入白名单以外的 URL**。
2. **规则结构与顺序红线**：
   - 维护两份并行规则文件：`XM-Clash-JSY.yaml`（极速云）与 `XM-Clash-HY.yaml`（花云），rules 部分逐字节一致；都不含 `proxies`、`proxy-providers`、`rule-providers`。
   - 七个分组（`XM-Google`, `XM-AI`, `XM-Web3`, `XM-Bybit`, `XM-日常上网`, `XM-Apple`, `XM-Anki`）名称与顺序固定。`XM-Anki` 两份都是手动 select 组（花云 日本高级 1–3，极速云 日本_01–03，用户手动固定节点，无 url/interval/timeout/tolerance，validator 精确校验节点），只用于 `ankiweb.net`、`ankiuser.net`，须排在 `GEOIP,CN` 之前（CI 校验）。其余六组：花云六个组全部 url-test（300 秒 / 10ms），每组同地区高级 1–3 + 标准（日本/美国标准 1–4，台湾标准 1–3）；XM-Web3 例外，只用韩国标准 1–2、越南标准 1、印尼标准 1（Hyperliquid HIP-4 限制新加坡/台湾，日本隐藏预测市场），不用实验性和香港节点，validator 精确校验节点集合；极速云保持 900 秒 / 20ms，XM-Bybit 为 fallback。
   - `XM-Apple` 只用于 Apple TV（`tv.apple.com`、`pancake.apple.com` 及其 `itunes.apple.com` 流媒体子域名）；App Store 不得走 `XM-Apple`（CI 校验）。Apple TV 视频 CDN（`vod-*-aoc.tv.apple.com`）直连（`DIRECT`），鉴权、片单域名仍走 `XM-Apple`；须排在 `tv.apple.com` 之前（CI 校验）。
   - 局域网直连规则之后的第一条必须是 `AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`（屏蔽 QUIC，让流量回落 TCP 走域名规则），不得删除或后移（CI 校验）。
   - 规则不得重复，不得被排在前面的更宽泛 `DOMAIN-SUFFIX` 规则遮蔽；`gemini.google.com` 等 AI 域名必须排在 `google.com` 之前；最后两条必须固定为 `GEOIP,CN,DIRECT` 与 `MATCH,XM-日常上网`。
3. **每次修改必跑校验**：
   - 修改任何文件后必须自动运行 `ruby scripts/validate_rules.rb`。

- Notion 全家（notion.so/.com/.site/.new、notion-static.com、notionusercontent.com、makenotion.com、Notion Calendar 旧域 cron.com，以及文件存储 `prod-files-secure.s3.us-west-2.amazonaws.com` 精确匹配）走 XM-AI，排在 GEOIP,CN 之前，CI 校验。
