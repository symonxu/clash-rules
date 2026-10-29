# 📋 TASKS.md — XM 个人分流规则 (clash-rules) 进度与双端交接看板

> 💬 **零终端使用方式（直接对 Cursor 或 Antigravity 说话即可）**：
> - 说 **“读取最新进展”**：AI 自动同步 GitHub 最新代码并读取本看板。
> - 说 **“帮我把 XXX 域名加到 AI / Web3 分流里”**：AI 自动同时修改 `XM-Clash-JSY.yaml` 与 `XM-Clash-HY.yaml`（rules 保持一致） 并自动运行 Ruby 校验脚本。
> - 说 **“保存并同步到 GitHub”**：AI 自动更新本看板并上传到 GitHub (`https://github.com/symonxu/clash-rules`)。

---

## 🤝 双端 AI 交接上下文 (Antigravity ⇄ Cursor)

- **最近更新端**：`OpenBot clash-rules` (2026-10-28)
- **GitHub 仓库**：`https://github.com/symonxu/clash-rules` (Public, 分支 `main`)
- **当前运行状态**：极速云 `XM-Clash-JSY.yaml`、花云 `XM-Clash-HY.yaml`、MESL `XM-Clash-MESL.yaml` 与 Boost `XM-Clash-BOOST.yaml` 的 rules 保持逐字节一致。DNS 分两套：花云那份是 `redir-host` + 加密 DoH/DoT（doh.pub / dns.alidns.com，fallback 1.1.1.1 / 8.8.8.8，`fallback-filter: geoip CN`），其余三份仍是 fake-ip + 明文国内 DNS。`XM-Clash-MULTI.yaml` 的 rules 与它们相同，只多两条 OpenBot 的 UDP 拒绝规则；它的 `XM-OpenBot` 走极速云日本（01→07→05→08→06→04→02→03，UDP 被规则拒掉走 TCP），`XM-Web3` 极速云优先、花云整组垫底。OpenBot（`openbot.run`、`openbot.site`）走 `XM-OpenBot`（极速云 fallback：日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03）；Notion 全家域名在 `GEOIP,CN` 之前走 `XM-AI`；X / Twitter 在 `GEOIP,CN` 之前走 `XM-日常上网`。Apple OTA 域名走 `XM-系统更新`（默认 DIRECT，可切日本）。

---

## 🔥 进行中 / 待办事项 (Backlog)

- [ ] 日常按需增补 Web3、AI、Google 等分流域名规则。

---

## ✅ 最近已完成 (Recently Completed)

- [x] **2026-10-29**：新增三文鱼（SWY）配置 `XM-Clash-SWY.yaml` 与小火箭配置文件 `XM-Shadowrocket.conf`。
  - 适配三文鱼订阅（swywl.com）全部 54 个节点：日本-1–6、台湾家宽|1.5X|-1、美国-1–6、韩国、印度、德国、英国、加拿大等；严格排除香港节点（CI 禁止）、只有备用及信息条目。
  - `XM-Shadowrocket.conf`：标准小火箭 `.conf` 格式，支持 `[General]`（本地 DNS 223.5.5.5 / 119.29.29.29、skip-proxy、tun-excluded-routes）、`[Proxy Group]`（九大分流策略组，通过 `policy-regex-filter` 自动匹配节点）、`[Rule]`（全量 234 条分流规则 + QUIC 拦截 + FINAL 收尾）。
  - `XM-Clash-SWY.yaml`：遵循 Clash 规范，与其他四份 rules 逐字节完全一致，9 个固定分组。
  - 校验：新增 `scripts/validate_shadowrocket.rb`，更新 `scripts/validate_clash.rb`、`scripts/validate_urls.rb`、`scripts/validate_rules.rb`，本地及 CI 100% 通过。
  - 回滚：删掉 `XM-Clash-SWY.yaml`、`XM-Shadowrocket.conf` 和 `scripts/validate_shadowrocket.rb`，并从 `scripts/validate_clash.rb`、`scripts/validate_urls.rb`、`scripts/validate_rules.rb`、README、AGENTS 移除 SWY 和 Shadowrocket 相关条目。
- [x] **2026-10-29**：花云 `XM-Clash-HY.yaml` 的 DNS 从 fake-ip 改成 `redir-host` + 加密 DNS（用户指定，只改这一份）：`enhanced-mode: redir-host`，`nameserver` 为 `https://doh.pub/dns-query`、`tls://dns.alidns.com`，`fallback` 为 `tls://1.1.1.1`、`https://8.8.8.8/dns-query`，`fallback-filter: {geoip: true, geoip-code: CN}`，`default-nameserver` 保留 223.5.5.5 / 119.29.29.29 只做主机名引导，`nameserver-policy`（Apple OTA 走 DoH）保留。redir-host 下 fake-ip-range / fake-ip-filter 无效，已从该文件删掉。分组、节点、234 条 rules 一个字没动，其余三份配置和 MULTI 都没动。`scripts/validate_clash.rb` 改为按文件校验两套 DNS（花云 redir-host + 加密服务器，其余 fake-ip，且真解析服务器不允许明文 53）；`scripts/validate_urls.rb` 白名单加了 `https://8.8.8.8/dns-query`。本机 mihomo 1.19.32 起实例实测：`api.openbot.run` 返回 172.67.136.14 / 104.21.46.68，`turn.openbot.run` 返回 95.216.243.233，都是真实地址（不是 198.18.x）。回滚：把 `XM-Clash-HY.yaml` 的 dns 段换回 fake-ip 那套（含 fake-ip-range 与 20 条 fake-ip-filter），`validate_clash.rb` 去掉 HY 分支，`validate_urls.rb` 删掉 8.8.8.8 那条。
- [x] **2026-10-29**：花云全部节点健康检查失败（花云 90 个节点全挂，7 个日本 + 韩/越/印尼都不 alive），`XM-OpenBot` 和 `XM-Web3` 同时失效，OpenBot 实时连接断。MULTI 改成极速云为主：① `XM-OpenBot` 回到极速云日本 fallback（日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03；02/04 当前是死的，放备份位），UDP 拒绝那两条规则保留，OpenBot 走 TCP；② `XM-Web3` 改成极速云优先（日本_01–08 → 马来西亚 → 菲律宾 → 越南），花云韩国标准 1–2、越南标准 1、印尼标准 1、马来西亚标准 1、菲律宾标准 1、泰国标准 1 整组垫底，花云恢复后会自动接管。校验脚本的 `MULTI_WEB3` 期望和 Web3 禁用地区断言同步改（MULTI 的 Web3 现在允许日本，仍禁止美国/香港/新加坡/台湾，并断言极速云日本在前、花云在后）。四份单订阅配置一个字没动。回滚：把 `XM-OpenBot` 和 `XM-Web3` 的 proxies 换回 PR #89 的花云版本，`scripts/validate_clash.rb` 的 `MULTI_EXPECTED` / `MULTI_WEB3` 一起改回，Web3 禁用地区断言加回 `日本`。
- [x] **2026-10-29**：修 `XM-Clash-MULTI.yaml` 的手机掉线。极速云 AnyTLS 的 UDP 撑不住 TURN：连续 15 次 STUN 到 `turn.openbot.run:3478`、间隔 2.5 秒，9 次成功 6 次超时，连接表里该 UDP 会话字节数冻住后 socket 直接消失（同配置 TCP 一直通）。改成 OpenBot 走 TCP：① `XM-OpenBot` 由「极速云 8 个日本」换成花云 日本高级 IEPL 专线 1→2→3 + 日本标准 IEPL 专线 1→2→3→4，仍是 fallback（无 tolerance）；② rules 在 `DOMAIN-SUFFIX,openbot.run,XM-OpenBot` 之前插入 `AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.run)),REJECT` 和 `AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.site)),REJECT`，让客户端立刻退到 TURN 的 TCP 443。这两条只有 MULTI 有，另外四份 rules 仍逐字节一致；`scripts/validate_clash.rb` 的 MULTI 断言从「逐字节相同」放宽为「234 条相同 + 恰好这两条，且排在 QUIC 之后、openbot 域名规则之前」，四份单订阅的校验没动。其余分组、`fake-ip-filter`、`nameserver-policy` 都没改。回滚：把 `XM-OpenBot` 的 proxies 换回极速云 日本_01→07→05→08→06→04→02→03，删掉那两条 AND 规则，并把 validator 里 `MULTI_ONLY_RULES` 改回空、`MULTI_EXPECTED['XM-OpenBot']` 改回 `JSY_JP`。
- [x] **2026-10-29**：`XM-Clash-MULTI.yaml` 改为纯规则方案。去掉节点集合和 19 段规则集，234 条规则与四份逐字节内联。分组直接写极速云、花云的显示名：OpenBot 只走极速云日本 fallback（01→07→05→08→06→04→02→03）；Web3 走花云韩国标准 1–2、越南标准 1、印尼标准 1，失败再用马来西亚/菲律宾/泰国；其余组花云优先、极速云垫底。订阅地址不进仓库。删掉 `rules/`、`scripts/build_multi.rb`，并删掉本机带订阅地址的 `local/XM-Clash-MULTI.yaml`。回滚：回到 `3e90e034b3ead807ff2e92f6b493991163295682` 上的这些文件。不要动四份原规则。
- [x] **2026-10-29**：新增多订阅模板 `XM-Clash-MULTI.yaml`（仓库内只有占位符，没有订阅地址）。OpenBot 只走极速云日本 fallback（01→07→05→08→06→04→02→03）；Web3 走花云韩国/越南/印尼，失败再用马来西亚/菲律宾/泰国；其余组花云优先、极速云垫底。234 条规则拆成 19 个 classical 规则集（GEOIP 和 MATCH 留在主配置里），因为内核一条 RULE-SET 只认一个策略，而且 GEOIP 放进规则集会被丢掉。本机可导入文件是 gitignore 的 `local/XM-Clash-MULTI.yaml`。回滚：删掉 `XM-Clash-MULTI.yaml`、`rules/`、`scripts/build_multi.rb` 和 `.gitignore`，并撤回 `scripts/validate_clash.rb`、`scripts/validate_urls.rb`、README、AGENTS 里的 MULTI 条目。不要动四份原规则。
- [x] **2026-10-28**：新增 `XM-Clash-BOOST.yaml`。节点名不带国旗。Google / AI / 日常上网 / OpenBot 用日本1–8；Web3 再加马来西亚-3倍率；Bybit 台湾1–4 fallback；Apple 美国1–3；Anki 与系统更新备用日本1–3。香港、新加坡和其余倍率节点不进组。回滚：删除该文件，并从 `scripts/validate_clash.rb`、`scripts/validate_urls.rb`、README、AGENTS 去掉 Boost 条目。
- [x] **2026-10-28**：极速云 `XM-OpenBot` 改为日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03。02/03/04 在家里宽带上刚测是死的，放到备份位。花云、MESL 和 rules 未改。回滚：把 `XM-Clash-JSY.yaml` 的 filter 和 `scripts/validate_clash.rb` 里 JSY 的 `XM-OpenBot` 期望改回日本_02 → 03 → 04。
- [x] **2026-10-28**：新增 `XM-OpenBot` fallback 组（排在 `XM-AI` 之后）。极速云 日本_02 → 03 → 04，花云 日本高级 1 → 2 → 3，MESL 日本 02 → 03 → 04。`openbot.run` / `openbot.site` 改走该组，不跟 XM-AI 测速绑定。回滚：删掉三份 YAML 的 `XM-OpenBot`，两条域名规则改回 `XM-AI`，`scripts/validate_clash.rb` 的分组名单和校验一并改回。
- [x] **2026-10-28**：新增 `XM-Clash-MESL.yaml`。八个分组与另外两份相同，rules 逐字节一致；只按 MESL 节点名筛选（日本 02–07 与 08–12 家宽、Web3 不用新加坡/台湾/香港、Bybit 从台湾 02 起 fallback、美国 01–03、Anki/系统更新备用日本 02–04）。带 `[0.3X]` 的节点不进组。回滚时删除该文件，并从校验脚本、README、AGENTS 去掉 MESL 条目即可。
- [x] **2026-10-28**：`fake-ip-filter` 增加 `+.openbot.run`、`+.openbot.site`（两份 YAML，紧跟 `+.akamaiedge.net`）。TURN/WebRTC 拿到真实 IP，分流规则仍走 `XM-AI`。回滚时从两份 YAML 的 `fake-ip-filter` 删掉这两行即可，rules 不变。
- [x] **2026-10-28**：将 OpenBot 域名（`openbot.run` 含 api / analytics，以及 `openbot.site`）接入 `XM-AI`，排在 `GEOIP,CN` 之前（两份配置的 rules 同步及 CI 校验）。回滚时从两份 YAML 与 `scripts/validate_clash.rb` 移除上述 2 条规则即可，未命中流量将恢复落入 `MATCH,XM-日常上网`。
- [x] **2026-10-27**：回滚 #78 的 itunes/mzstatic 直连（直连超时、App Store 更新卡住），恢复走 XM-日常上网，长期保留。

- [x] **2026-10-27**：全面梳理：极速云 XM-Web3 去掉新加坡（CI 禁止新加坡/台湾）；fake-ip-filter 补 ocsp2/akadns/akamaiedge；geox-url 用 jsDelivr 镜像；X 补 pscp.tv/periscope.tv/twittercdn.com；注释与文档更新。旧 PR #5 已关闭，移出待办。

- [x] **2026-10-27**：新增 `XM-系统更新` select 组（DIRECT 默认 + 日本 1–3），Apple OTA 域名全部走该组（#74）。
- [x] **2026-10-25**：将 Notion 全家域名（`notion.so`、`notion.com`、`notion.site`、`notion.new`、`notion-static.com`、`notionusercontent.com`、`makenotion.com`、`cron.com` 及 `prod-files-secure.s3.us-west-2.amazonaws.com`）接入 `XM-AI` 分组并排在 `GEOIP,CN` 之前（两份配置的 rules 同步及 CI 校验，任务 23 / `#72`）。回滚时从两份 YAML 与 `scripts/validate_clash.rb` 移除上述 9 条 Notion 规则即可，未命中流量将恢复落入后续规则或 `MATCH,XM-日常上网`。
- [x] **2026-10-25**：在 `GEOIP,CN` 之前为 x.com、twitter.com、twimg.com、t.co 增加 `DOMAIN-SUFFIX` → `XM-日常上网`（两份配置的 rules 同步，任务 22）。回滚时删掉这四条即可，未命中的流量仍按原顺序落到 `GEOIP,CN,DIRECT` 或 `MATCH,XM-日常上网`。
- [x] **2026-10-17**：配置独立自治的 **「Cursor ⇄ Antigravity 零终端全自动规则 (`AGENTS.md` & `.cursor/rules`)」** 与进度看板 (`TASKS.md`)。
- [x] **2026-10-16**：精简为单一配置，删除旧同步程序，校验改为独立检查 (`#46`)。
