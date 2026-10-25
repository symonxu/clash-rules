# 📋 TASKS.md — XM 个人分流规则 (clash-rules) 进度与双端交接看板

> 💬 **零终端使用方式（直接对 Cursor 或 Antigravity 说话即可）**：
> - 说 **“读取最新进展”**：AI 自动同步 GitHub 最新代码并读取本看板。
> - 说 **“帮我把 XXX 域名加到 AI / Web3 分流里”**：AI 自动修改 `XM-Clash-JSY.yaml` 并自动运行 Ruby 校验脚本。
> - 说 **“保存并同步到 GitHub”**：AI 自动更新本看板并上传到 GitHub (`https://github.com/symonxu/clash-rules`)。

---

## 🤝 双端 AI 交接上下文 (Antigravity ⇄ Cursor)

- **最近更新端**：`Cursor` (2026-10-25)
- **GitHub 仓库**：`https://github.com/symonxu/clash-rules` (Public, 分支 `main`)
- **当前运行状态**：极速云 `XM-Clash-JSY.yaml` 与花云 `XM-Clash-HY.yaml` 的 rules 保持逐字节一致。X / Twitter（x.com、twitter.com、twimg.com、t.co）在 `GEOIP,CN` 之前走 `XM-日常上网`。

---

## 🔥 进行中 / 待办事项 (Backlog)

- [ ] 审阅并决定是否关闭 GitHub 上的旧分支 PR `#5 Add Hako V1.3 test profile with protected exits`（因仓库现已精简为单一配置 `XM-Clash-JSY.yaml`）。
- [ ] 日常按需增补 Web3、AI、Google 等分流域名规则。

---

## ✅ 最近已完成 (Recently Completed)

- [x] **2026-10-25**：在 `GEOIP,CN` 之前为 x.com、twitter.com、twimg.com、t.co 增加 `DOMAIN-SUFFIX` → `XM-日常上网`（两份配置的 rules 同步，任务 22）。回滚时删掉这四条即可，未命中的流量仍按原顺序落到 `GEOIP,CN,DIRECT` 或 `MATCH,XM-日常上网`。
- [x] **2026-10-17**：配置独立自治的 **「Cursor ⇄ Antigravity 零终端全自动规则 (`AGENTS.md` & `.cursor/rules`)」** 与进度看板 (`TASKS.md`)。
- [x] **2026-10-16**：精简为单一配置，删除旧同步程序，校验改为独立检查 (`#46`)。
