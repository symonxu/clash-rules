# XM 个人分流规则（Clash App）

本仓库维护两份并行的 Clash 规则配置与一份 Shadowrocket（小火箭）规则配置，给 Clash App（「Clash - 基于规则的网络代理工具」，clash.md）在 iPhone、iPad 和 Mac 上共用。两份单订阅文件的分组和**规则完全相同**，只有各组筛选节点的正则不同：

| 组合 | 节点来源 | 规则方案 | 配置链接 |
| --- | --- | --- | --- |
| 极速云 | 极速云订阅 | `XM-Clash-JSY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-JSY.yaml |
| 花云 | 花云订阅 | `XM-Clash-HY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-HY.yaml |
| 小火箭（Shadowrocket） | 花云订阅 | `XM-Shadowrocket-HY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-HY.conf |

两个 Clash 方案可以同时存在，哪家出问题就切到另一个组合；小火箭用户可直接使用 `XM-Shadowrocket-HY.conf`。

**仓库里绝不能出现订阅地址、节点信息或任何凭据。** 文件只有分组、规则和 DNS；CI 会拦截白名单以外的链接。花云另有全局 TCP 保活：闲置 30 秒后开始探测，之后每 15 秒一次。

## 在 App 里怎么用

节点和规则分开导入，再组合成一份配置（以极速云为例；花云相同，把订阅换成花云订阅、配置链接和规则方案换成 `XM-Clash-HY`）：

1. **添加订阅**：配置（Profiles）→ 添加配置（Add Profile）→ 配置链接，粘贴极速云的 Clash 订阅地址。先选中它、出站模式选"规则"并连接，下一步才能打开 GitHub（raw.githubusercontent.com 在大陆直连通常打不开）。
2. **添加规则配置**：同样"添加配置 → 配置链接"，粘贴对应的配置链接。若有"同时登记它的规则"开关，保持打开；它会作为规则方案出现在规则库里。这份配置自己没有节点，不要单独选中使用。
3. **组合**：把极速云配置的规则方案换成 `XM-Clash-JSY`（"更换规则方案"），或新建配置时"选择节点来源和规则方案"：节点来源选极速云，规则方案选 `XM-Clash-JSY`。花云则是节点来源选花云、规则方案选 `XM-Clash-HY`。不要用机场自带的分组和规则。
4. 选中组合后的配置，出站模式选"规则（Rule）"，连接；在"代理（Proxies）"里确认九个组都有节点。
5. 检查分流：iPhone 在 工具（Utilities）→ Current Session → 连接（Connections），Mac 在侧边栏 Session → Connections，看新连接命中的规则和出站组。

仓库更新后，App 按配置链接自动更新规则；想立刻生效，可在规则库对该方案点"刷新规则"，或在配置列表对它点更新。节点照常在各自的订阅配置里更新。

入口和模式的说明见 clash.md 文档：iPhone https://clash.md/zh/guide/ios ，Mac https://clash.md/zh/guide/macos 。节点来源与规则方案的组合方式以 App 开源代码为准：https://github.com/ProjectClash/Clash-Client 。

Mac 上不要同时开着 Clash App 和其他代理软件的 TUN（例如 Clash Verge），两个都会接管系统流量。

## 在小火箭（Shadowrocket）里怎么用

小火箭支持标准的 `.conf` 远程规则配置文件。本仓库提供 `XM-Shadowrocket-HY.conf`，内置七大分流策略组与全部 280 条分流规则。各策略组使用 `policy-regex-filter` 自动匹配花云订阅中的节点：

配置链接：https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-HY.conf

使用步骤：
1. **添加节点订阅**：在小火箭主界面点击右上角 `+`，类型选择 `Subscribe`（订阅），粘贴花云、极速云或其他机场的订阅地址，保存并更新出节点列表。
2. **添加配置**：点击底部「配置」标签页，右上角点击 `+`。
3. **输入配置链接**：在 URL 框中粘贴上面的规则链接，点击「下载」。
4. **启用配置**：在「远程文件」中点击刚刚下载的 `XM-Shadowrocket-HY.conf`，选择「使用配置」使其变为勾选状态。
5. **启用 Tailscale 模块**：进入「设置 → Tailscale」，填入 Tailscale Auth Key 并启用模块；控制服务器保持默认，出口节点留空。不要同时开启独立的官方 Tailscale App。
6. **开启代理**：返回主界面，全局路由选择「配置」（Config），开启小火箭主开关即可。

`[General]` 里 `always-real-ip` 让 `openbot.run`、`openbot.site`、花云节点域与苹果/国内 CDN、校时及门户域名在假 IP 模式下仍解析成真地址（TURN / WebRTC 不能用 `198.18.0.0/16`，同时与 Clash `fake-ip-filter` 对齐）。`[Host]` 与花云 Clash 的 hosts 相同；小火箭默认不拿 `[Host]` 去连节点，必须配上 `use-local-host-item-for-proxy = true`，节点才会连到国内入口而不是 `147.90.*`。节点入口和公共 DNS IP（`223.5.5.5`、`223.6.6.6`、`1.12.12.12`、`119.29.29.29`）写在 `skip-proxy`、`tun-excluded-routes` 里，避免手机把节点连接或 DoH 上游吸进隧道后超时。TUN 模式下，`100.64.0.0/10` 和 `*.ts.net` 必须留在隧道中，分别由 `TAILSCALE` 规则交给内置模块；不要把它们加入 `skip-proxy` 或 `tun-excluded-routes`。控制面域名 `tailscale.com` / `tailscale.io` 直连。此配置关闭 IPv6，因此按 IPv4 Tailnet 地址连接。`XM-AI工具` 是 select，含 7 个节点（日本标准 1/3、台湾高级 2/3、美国标准 6/7、韩国标准 2），Google、AI、OpenBot 都走这一组；`XM-日常上网` 也是 select，节点完全一致。

## 分组

各组用 `include-all: true` 引入订阅里的全部节点，按节点名正则 `filter` 筛选，再用 `exclude-filter` 剔除香港节点（`香港|HK|Hong Kong|🇭🇰`，不区分大小写）和「剩余流量」「套餐到期」「官网」等信息条目：

| 分组 | 极速云（`XM-Clash-JSY.yaml`） | 花云（`XM-Clash-HY.yaml`） | 类型 |
| --- | --- | --- | --- |
| XM-AI工具 | 日本_*（自动测速） | 日本标准 1/3 + 台湾高级 2/3 + 美国标准 6/7 + 韩国标准 2（手动选，7 个） | 极速云 url-test；花云 select |
| XM-Web3 | 马来西亚、菲律宾、越南、新加坡_* | 韩国标准 IEPL 专线 1–2 + 越南标准 1 + 印尼标准 1（4 个；新加坡/台湾被 Hyperliquid HIP-4 限制，日本隐藏预测市场） | url-test |
| XM-Bybit | 台湾_01 → 台湾_02 → 其余台湾_* | 台湾高级 IEPL 专线 1–3 + 台湾标准 1–3（6 个） | 极速云 fallback；花云 url-test |
| XM-日常上网 | 日本_* | 同 XM-AI工具：日本标准 1/3 + 台湾高级 2/3 + 美国标准 6/7 + 韩国标准 2（7 个） | select（手动选，2026-11-19 起） |
| XM-Apple | 美国_01–03（3 个） | 美国高级 IEPL 专线 1–3 + 美国标准 1–4（7 个） | url-test |
| XM-Anki | 日本_01 / 日本_02 / 日本_03 | 日本高级 IEPL 专线 1 / 2 / 3 | select（手动选一个固定节点，避免同步中途切换） |
| XM-系统更新 | 仅 DIRECT | 仅 DIRECT | select（系统更新只走大陆 CDN 直连；组里只放 DIRECT，避免客户端记住手动选的日本节点导致更新卡住；后期需代理救急再手动加节点） |

花云版多数组 6–7 个节点（XM-Web3 4 个，XM-Anki 3 个，XM-系统更新仅 DIRECT）（同地区高级 + 标准），不用实验性节点；信息条目另外排除英文的 `Traffic` / `Expire`。

- url-test：用 `https://www.gstatic.com/generate_204` 测速，超时 5 秒。极速云每 900 秒测速、快超过 20ms 才切换；花云每 300 秒测速、快超过 10ms 就切换。
- XM-Anki（两份都有）：手动 select 组，只有三个日本节点（花云 日本高级 1–3，极速云 日本_01–03），在 App 里自己选一个固定使用，不测速、不自动切换；只用于 AnkiWeb 同步（`ankiweb.net`、`ankiuser.net`）。
- 极速云 XM-Bybit：fallback，900 秒 / 5 秒；排第一的节点可用就一直用它，失败才往后切，固定出口 IP 更稳
- **XM-AI工具**：Google、AI、OpenBot 合成这一组。花云 Clash 和小火箭是 select，7 个节点（日本标准 1/3、台湾高级 2/3、美国标准 6/7、韩国标准 2），由你手动选。2026-11-19 实测日本出口访问谷歌主站/YouTube/账号全部 TLS 超时、美国节点约 220ms 正常，因此加入美国与韩国节点；若谷歌再卡，把这一组手动切到美国标准 6 或 7。`XM-日常上网` 节点完全相同、同样改为 select，可与本组一起切换。极速云同名组仍是 url-test，自动选 `日本_*`。
- **MULTI 的 XM-OpenBot 例外**：用极速云日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03，并且 rules 里比另外四份多两条 `AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.run|openbot.site)),REJECT`。原因是极速云 AnyTLS 的 UDP 转发撑不住 TURN（连续 15 次 STUN 掉了 6 次），把 UDP 拒掉后客户端改走 TURN 的 TCP 443，只借用极速云的 TCP 线路。花云故障期间 OpenBot 和 Web3 曾经全废（花云节点健康检查全挂），所以 MULTI 的两个组都以极速云为主、花云垫底。
- **任何分组都不用香港节点**（Google 对香港 IP 不提供 Gemini 等服务）。CI 会检查每组都有香港排除，且 `filter` 本身也不能匹配香港节点名。
- 机场如果改了节点名，对应分组会筛不到节点，需要改对应文件的 `filter`。

## DNS

`223.5.5.5`、`119.29.29.29`，极速云与花云两份 Clash 配置全部采用标准 fake-ip 方案（局域网、captive.apple.com、time.apple.com、微软联网检测不走 fake-ip）；IPv6 关闭。Apple 系统更新相关域名（cdn-apple.com、swcdn/swdist/swscan/ocsp2、aaplimg、akadns、akamaiedge 及 CDN 落点 ks-cdn/ksyuncdn/alikunlun）用 `nameserver-policy` 走 DoH（`https://223.5.5.5/dns-query`、`https://doh.pub/dns-query`）并跳过 fake-ip；TUN 下不要用 `system`（会回环到 mihomo）。`+.openbot.run` 和 `+.openbot.site` 跳过 fake-ip（返回真实 IP），规则走 XM-AI工具。原因是 TURN/WebRTC 不能用 198.18.0.0/16 假地址。GEOIP 数据库（`geox-url`）用 jsDelivr 镜像 `testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release`，大陆可下载。Clash YAML 中 `+.ts.net` 跳过 fake-ip 并通过 `nameserver-policy` 交给 Tailscale MagicDNS（`100.100.100.100`），`tun.route-exclude-address` 排除 `100.64.0.0/10`，并在规则段加入两条精确 `PROCESS-NAME` 直连（`io.tailscale.ipn.macsys.network-extension` 与 `Tailscale`，覆盖 macOS 官方 Tailscale 守护进程与 STUN 探针，共 282 条规则）；这些设置用于 Clash YAML 与官方 Tailscale App 共存。小火箭使用内置 Tailscale 模块，应将 tailnet 流量留在 TUN 并交给 `TAILSCALE` 策略，不能沿用上述旁路设置，外出/在家两份分别为 284 / 283 条域名与 IP 规则。iOS 不能按进程分流（见 https://clash.md/zh/guide/config/apple-platforms ），Clash 在 iOS 上会安全跳过精确 `PROCESS-NAME` 规则（不使用通配/正则进程匹配）。

## 主要分流

规则从上到下匹配，第一条命中即生效：

1. 局域网域名和私有地址直连。
   - Clash 紧接着屏蔽 QUIC：`AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`。没开嗅探时 UDP 只能按 IP 匹配（会误走 GEOIP,CN 直连或兜底直连），屏蔽后 App 回落到 TCP，域名规则才生效（CI 校验它是局域网规则后的第一条）。小火箭（2026-11-20）改在 `[General]` 用 `block-quic = all-proxy` 只封走代理的连接，直连域名保留 HTTP/3，避免 App Store 每次连接先重试 QUIC 再回退 TCP 造成首屏卡顿；同时把 `dns-server` 换成双路纯 IP 加密 DoH `https://223.5.5.5/dns-query, https://1.12.12.12/dns-query` 并补齐 `always-real-ip`，省去 DoH 域名引导、避免单点超时与明文 UDP/53 劫持或拿到苹果 CDN 池里的不可达 IP（CI 校验）。
2. **XM-Web3**：常用链上 RPC（Infura、Alchemy、Ankr、LlamaRPC、BlockPI、BlastAPI、Omnia Tech、Stackup、Arbitrum 等公链 RPC）、钱包（MetaMask、Phantom、WalletConnect 等）、DEX 与交易站（Uniswap、Jupiter、pump.fun、Bitget、PancakeSwap、Hyperliquid、Polymarket、Across、CoinGecko 等）。
3. **XM-Bybit**：bybit.com、bybit.biz、byabcde.com、bycsi.com。
4. **XM-AI工具**：Google、Gmail、YouTube、Gemini、Cursor、ChatGPT、Claude、Notion、Slack、Apple 隐私中继，以及 `openbot.run`、`openbot.site`。花云这一组手动选节点。排在 `GEOIP,CN` 之前。
5. **XM-日常上网**（显式规则）：Facebook、Instagram、Threads、Messenger、WhatsApp、Meta AI、muse.ai，以及 X / Twitter（`x.com`、`twitter.com`、`twimg.com`、`t.co`、`pscp.tv`、`periscope.tv`、`twittercdn.com`，排在 `GEOIP,CN` 之前，域名命中后不再按 IP 判断）。
   - **XM-Anki**：`ankiweb.net`、`ankiuser.net`（Anki 同步，固定日本节点，排在 `GEOIP,CN` 之前；CI 校验只有这两条走 XM-Anki）。
7. **直连**：App Store 商店页与下载更新（`apps.apple.com`、`itunes.apple.com`、`mzstatic.com`）、iCloud、Apple 地图、Game Center、Apple 推送、微信、QQ。
8. **XM-Apple**（Apple TV，美国节点）：`tv.apple.com`、`pancake.apple.com`、`uts-api.itunes.apple.com`；Clash（`XM-Clash-HY.yaml`）同时将 Apple TV 视频流 CDN（`vod-ap-aoc` / `vod-ap2-aoc` / `vod-ak-aoc` / `vod-fa-aoc.tv.apple.com`、`-aoc.tv.apple.com`、`play-edge` / `hls` / `np-edge.itunes.apple.com`）统一走 `XM-Apple` 保流畅（消耗花云流量），小火箭两份配置仍保留视频流 CDN 走 `DIRECT` 省流量；相关规则排在宽泛的 `itunes.apple.com` 直连规则之前，保证优先命中。App Store 不走美国节点；iCloud、推送、CloudKit（`apple-cloudkit.com`、`apple-livephotoskit.com`，Notability 等 App 的 iCloud 同步）、`aaplimg.com` 等仍直连，系统更新走 XM-系统更新（CI 校验）。
   - App Store：`apps.apple.com`、`itunes.apple.com`、`mzstatic.com` 均 **DIRECT**（小火箭额外将前端接口 `amp-api-edge.apps.apple.com` 走 `XM-日常上网`，避开国内 CDN 池里的故障 IP，不影响下载与图标直连）；`cdn-apple.com` 走 XM-系统更新。
   - **XM-系统更新**（iOS/macOS OTA，参考 Apple 企业网络 Software updates）：`cdn-apple.com`（DOMAIN-SUFFIX，含 updates*/fcs-keys 等）、`appldnld`、`swcdn`、`swdist`、`swdownload`、`swscan`、`swquery`、`swpost`、`mesu`、`gdmf`、`gdmf-ados`、`gs`、`gsra`、`gg`、`ig`、`skl`、`xp`、`configuration`、`oscdn`、`osrecovery`、`cds`、`download.info.apple.com`、`ocsp2.apple.com`； DNS：这些 Apple 下载域名用 nameserver-policy （含 CNAME 落点 ks-cdn/ksyuncdn/alikunlun）走 DoH `https://223.5.5.5/dns-query` + `https://doh.pub/dns-query` 并跳过 fake-ip（TUN 下 system 会回环到 mihomo，明文 UDP 223/119 对这些域名超时/SERVFAIL）；该组只放 DIRECT（整条同出口，避免校验卡住；客户端 store-selected 若记住手动选过的日本节点会让更新走代理卡住，故不放日本节点，后期需救急再手动加回）。不影响 XM-Apple / Apple TV。
9. 中国大陆域名（Clash 的 `GEOSITE,CN`）与 IP（`GEOIP,CN`）直连（小火箭不支持 `GEOSITE`，仍由 `GEOIP,CN` 兜底）。
10. 其余流量走 **XM-日常上网**。

## Clash.app 入口监控模块

本仓库提供适配 `Clash.app` 模块功能（[模块指南](https://clash.md/zh/guide/modules)）的入口监测与告警模块：

- 模块链接：`https://raw.githubusercontent.com/symonxu/clash-rules/main/modules/flower-entry-monitor.sgmodule`
- 在 `Clash.app` 侧边栏进入 **配置 › 配置库 › 模块**，添加上述链接后，在模块「设置 › 控制密钥」填入 **更多 › 客户端设置 › 外部控制器（本机 127.0.0.1:9090）** 的密钥即可启用：每隔 30 分钟及网络切换时通过本地控制器实测花云代表节点（美6 / 日3 / 台2 / 德1）真实延迟与 `0bc52bj8-10e0` 公网入口解析，发现异常会推送系统通知，也可在模块详情「面板」手动点击刷新测速。

## 修改规则

1. 新建分支修改规则。**改规则（`rules`）时，两份配置（`XM-Clash-JSY.yaml` / `XM-Clash-HY.yaml`）保持逐字节一致**。花云另有 `hosts`（3 个节点域名改写到国内入口）和加密 DNS，只改 `XM-Clash-HY.yaml`。只改某家的节点筛选时，只改对应文件的 `proxy-groups`。
2. 本地校验：

   ```sh
   ruby scripts/validate_rules.rb
   ```

   校验内容：
   - 两份配置的规则部分逐字节一致。
   - 两份文件都不含 `proxies`、`proxy-providers`、`rule-providers`。
   - 七个分组的名称、顺序、类型、测速参数；各组 `filter` / `exclude-filter` 对虚构样例节点名（不含真实节点）选中的结果，每组非空、排除香港节点和信息条目。
   - DNS。
   - 规则语法、目标只能是七个组或 DIRECT / REJECT、无重复、不被前面的后缀规则遮住、最后两条为 `GEOIP,CN,DIRECT` 和 `MATCH,XM-日常上网`。
   - 公开链接白名单。
3. 开 PR。GitHub Actions 自动跑同样的校验，通过后合并到 main，App 按链接更新即可生效。

- Notion 全家（notion.so/.com/.site/.new/.ai、notion-static.com、notion-status.com、notionusercontent.com、makenotion.com、Notion Calendar 旧域 cron.com，以及文件存储 `prod-files-secure.s3.us-west-2.amazonaws.com` 精确匹配）走 XM-AI，排在 GEOIP,CN 之前，CI 校验。
- OpenBot（`openbot.run` 含 api / analytics，以及 `openbot.site`）和 Google、AI 域名走 XM-AI工具，排在 GEOIP,CN 之前，CI 校验。
