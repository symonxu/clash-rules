# 📋 TASKS.md — XM 个人分流规则 (clash-rules) 进度与双端交接看板

> 💬 **零终端使用方式（直接对 Cursor 或 Antigravity 说话即可）**：
> - 说 **“读取最新进展”**：AI 自动同步 GitHub 最新代码并读取本看板。
> - 说 **“帮我把 XXX 域名加到 AI / Web3 分流里”**：AI 自动同时修改 `XM-Clash-JSY.yaml` 与 `XM-Clash-HY.yaml`（rules 保持一致） 并自动运行 Ruby 校验脚本。
> - 说 **“保存并同步到 GitHub”**：AI 自动更新本看板并上传到 GitHub (`https://github.com/symonxu/clash-rules`)。

---

## 🤝 双端 AI 交接上下文 (Antigravity ⇄ Cursor)

- **最近更新端**：`Cursor` (2026-10-27)
- **GitHub 仓库**：`https://github.com/symonxu/clash-rules` (Public, 分支 `main`)
- **当前运行状态**：极速云 `XM-Clash-JSY.yaml` 与花云 `XM-Clash-HY.yaml` 的 rules 保持逐字节一致。Notion 全家域名在 `GEOIP,CN` 之前走 `XM-AI`；X / Twitter 在 `GEOIP,CN` 之前走 `XM-日常上网`。Apple OTA 域名走 `XM-系统更新`（默认 DIRECT，可切日本）。

---

## 🔥 进行中 / 待办事项 (Backlog)

- [ ] 日常按需增补 Web3、AI、Google 等分流域名规则。

---

## ✅ 最近已完成 (Recently Completed)

- [x] **2026-10-27**：全面梳理：极速云 XM-Web3 去掉新加坡（CI 禁止新加坡/台湾）；itunes/mzstatic 恢复直连；fake-ip-filter 补 ocsp2/akadns/akamaiedge；geox-url 用 jsDelivr 镜像；X 补 pscp.tv/periscope.tv/twittercdn.com；注释与文档更新。旧 PR #5 已关闭，移出待办。

- [x] **2026-10-27**：新增 `XM-系统更新` select 组（DIRECT 默认 + 日本 1–3），Apple OTA 域名全部走该组（#74）。
- [x] **2026-10-25**：将 Notion 全家域名（`notion.so`、`notion.com`、`notion.site`、`notion.new`、`notion-static.com`、`notionusercontent.com`、`makenotion.com`、`cron.com` 及 `prod-files-secure.s3.us-west-2.amazonaws.com`）接入 `XM-AI` 分组并排在 `GEOIP,CN` 之前（两份配置的 rules 同步及 CI 校验，任务 23 / `#72`）。回滚时从两份 YAML 与 `scripts/validate_clash.rb` 移除上述 9 条 Notion 规则即可，未命中流量将恢复落入后续规则或 `MATCH,XM-日常上网`。
- [x] **2026-10-25**：在 `GEOIP,CN` 之前为 x.com、twitter.com、twimg.com、t.co 增加 `DOMAIN-SUFFIX` → `XM-日常上网`（两份配置的 rules 同步，任务 22）。回滚时删掉这四条即可，未命中的流量仍按原顺序落到 `GEOIP,CN,DIRECT` 或 `MATCH,XM-日常上网`。
- [x] **2026-10-17**：配置独立自治的 **「Cursor ⇄ Antigravity 零终端全自动规则 (`AGENTS.md` & `.cursor/rules`)」** 与进度看板 (`TASKS.md`)。
- [x] **2026-10-16**：精简为单一配置，删除旧同步程序，校验改为独立检查 (`#46`)。
