# XM 个人分流规则（Clash App）

本仓库维护五份并行的 Clash 规则配置与一份 Shadowrocket（小火箭）规则配置，给 Clash App（「Clash - 基于规则的网络代理工具」，clash.md）在 iPhone、iPad 和 Mac 上共用。四份文件的 DNS、分组和**规则完全相同**，只有各组筛选节点的正则不同（各家节点命名不一样）：

| 组合 | 节点来源 | 规则方案 | 配置链接 |
| --- | --- | --- | --- |
| 极速云 | 极速云订阅 | `XM-Clash-JSY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-JSY.yaml |
| 花云 | 花云订阅 | `XM-Clash-HY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-HY.yaml |
| MESL | MESL 订阅 | `XM-Clash-MESL` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-MESL.yaml |
| Boost | Boost 订阅 | `XM-Clash-BOOST` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-BOOST.yaml |
| 三文鱼（SWY） | 三文鱼订阅 | `XM-Clash-SWY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-SWY.yaml |
| 小火箭（Shadowrocket） | 任意订阅 | `XM-Shadowrocket` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket.conf |

五个 Clash 组合可以同时存在，哪家出问题就切到另一个组合；小火箭用户可直接使用 `XM-Shadowrocket.conf`。

另有一份规则方案 `XM-Clash-MULTI.yaml`：OpenBot 走极速云日本节点（OpenBot 的 UDP 在规则里直接拒绝，客户端走 TURN 的 TCP 443），Web3 极速云优先、花云整组垫底，其余组优先花云、极速云垫底。文件里没有订阅地址。用法见下方「一个配置挂两家订阅」。

**仓库里绝不能出现订阅地址、节点信息或任何凭据。** 文件只有分组、规则和 DNS；CI 会拦截白名单以外的链接。

## 在 App 里怎么用

节点和规则分开导入，再组合成一份配置（以极速云为例；花云、MESL、Boost 相同，把订阅换成对应机场、配置链接和规则方案换成 `XM-Clash-HY`、`XM-Clash-MESL` 或 `XM-Clash-BOOST`）：

1. **添加订阅**：配置（Profiles）→ 添加配置（Add Profile）→ 配置链接，粘贴极速云的 Clash 订阅地址。先选中它、出站模式选"规则"并连接，下一步才能打开 GitHub（raw.githubusercontent.com 在大陆直连通常打不开）。
2. **添加规则配置**：同样"添加配置 → 配置链接"，粘贴对应的配置链接。若有"同时登记它的规则"开关，保持打开；它会作为规则方案出现在规则库里。这份配置自己没有节点，不要单独选中使用。
3. **组合**：把极速云配置的规则方案换成 `XM-Clash-JSY`（"更换规则方案"），或新建配置时"选择节点来源和规则方案"：节点来源选极速云，规则方案选 `XM-Clash-JSY`。花云则是节点来源选花云、规则方案选 `XM-Clash-HY`。MESL 则是节点来源选 MESL、规则方案选 `XM-Clash-MESL`。Boost 则是节点来源选该订阅、规则方案选 `XM-Clash-BOOST`。不要用机场自带的分组和规则。
4. 选中组合后的配置，出站模式选"规则（Rule）"，连接；在"代理（Proxies）"里确认九个组都有节点。
5. 检查分流：iPhone 在 工具（Utilities）→ Current Session → 连接（Connections），Mac 在侧边栏 Session → Connections，看新连接命中的规则和出站组。

仓库更新后，App 按配置链接自动更新规则；想立刻生效，可在规则库对该方案点"刷新规则"，或在配置列表对它点更新。节点照常在各自的订阅配置里更新。

入口和模式的说明见 clash.md 文档：iPhone https://clash.md/zh/guide/ios ，Mac https://clash.md/zh/guide/macos 。节点来源与规则方案的组合方式以 App 开源代码为准：https://github.com/ProjectClash/Clash-Client 。

Mac 上不要同时开着 Clash App 和其他代理软件的 TUN（例如 Clash Verge），两个都会接管系统流量。

## 在小火箭（Shadowrocket）里怎么用

小火箭支持标准的 `.conf` 远程规则配置文件。本仓库提供 `XM-Shadowrocket.conf`，内置九大分流策略组与全部 234 条分流规则。各策略组使用 `policy-regex-filter` 自动匹配三文鱼（SWY）等订阅中的节点：

配置链接：https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket.conf

使用步骤：
1. **添加节点订阅**：在小火箭主界面点击右上角 `+`，类型选择 `Subscribe`（订阅），粘贴三文鱼或其他机场的订阅地址，保存并更新出节点列表。
2. **添加配置**：点击底部「配置」标签页，右上角点击 `+`。
3. **输入配置链接**：在 URL 框中粘贴上面的规则链接，点击「下载」。
4. **启用配置**：在「远程文件」中点击刚刚下载的 `XM-Shadowrocket.conf`，选择「使用配置」使其变为勾选状态。
5. **开启代理**：返回主界面，全局路由选择「配置」（Config），开启小火箭主开关即可。

## 一个配置挂两家订阅

`XM-Clash-JSY` / `HY` / `MESL` / `BOOST` 仍是「一个订阅 + 一份规则方案」。多订阅是另一份规则方案，不要拿它替换那四份，也不要只挂到其中一家订阅上。

配置链接：https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-MULTI.yaml

文件里 234 条规则与另外四份相同，另外多两条 OpenBot 的 UDP 拒绝规则（只有这一份有），分组直接写节点显示名。订阅地址不在文件里。Clash App 把每份配置记成「一个规则方案 + 若干代理来源」，来源由 App 自己下载和更新。

Mac 和 iPhone 步骤相同：

1. 配置 → 添加配置 → 添加配置链接，粘贴上面的链接。若添加时出现「选择节点来源（可多选）」，选节点库里的「极速云」（配置列表里叫极速云-XM）和「Flower_SS」。
2. 打开这份新配置，点「添加代理来源」，把上面两个已导入的来源都加上（只加一个的话，另一家的节点名解析不到，配置起不来）。不要选 BoostNet 或 MESL。
3. 两个来源都加好之后，要点「使用此配置」才会把流量切过来。不点就保持当前正在用的配置。出站模式选规则。不要关 TUN。

分组（fallback 按书写顺序，前一个不可用才换下一个；XM-Anki 是手动 select）：

| 分组 | 去向 |
| --- | --- |
| XM-OpenBot | 只使用极速云：日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03（fallback，02/04 放备份位）。`openbot.run` / `openbot.site` 的 UDP 在规则里直接 REJECT，客户端走 TURN 的 TCP 443 |
| XM-Web3 | 极速云 日本_01–08，然后极速云马来西亚/菲律宾/越南；再后面是花云韩国标准 1–2、越南标准 1、印尼标准 1、马来西亚 1、菲律宾 1、泰国 1（花云整组垫底，恢复后自动接管）。不用美国、香港、新加坡、台湾 |
| XM-Google / XM-AI / XM-日常上网 | 花云日本（高级 1–3 + 标准 1–4）优先，整组失败才换极速云日本（顺序同 OpenBot） |
| XM-Apple | 花云美国（高级 1–3 + 标准 1–4）优先，失败再换极速云美国_01–03 |
| XM-Bybit | 花云台湾（高级 1–3 + 标准 1–3，显示名带 🇨🇳）优先，失败再换极速云台湾_01–05 |
| XM-Anki | 手动选择。候选顺序是花云日本高级 1–3，然后极速云日本_01–03 |
| XM-系统更新 | fallback：花云日本高级 1–3，然后极速云日本_01–03，最后 DIRECT（与另外四份的「默认 DIRECT」不同） |

## 分组

各组用 `include-all: true` 引入订阅里的全部节点，按节点名正则 `filter` 筛选，再用 `exclude-filter` 剔除香港节点（`香港|HK|Hong Kong|🇭🇰`，不区分大小写）和「剩余流量」「套餐到期」「官网」等信息条目：

| 分组 | 极速云（`XM-Clash-JSY.yaml`） | 花云（`XM-Clash-HY.yaml`） | MESL（`XM-Clash-MESL.yaml`） | Boost（`XM-Clash-BOOST.yaml`） | 三文鱼（`XM-Clash-SWY.yaml`） | 类型 |
| --- | --- | --- | --- | --- | --- |
| XM-Google | 日本_* | 日本高级 IEPL 专线 1–3 + 日本标准 1–4（7 个；不用实验性） | 日本 02–07 + 日本 08–12 家宽（不含 01 [0.3X]） | 日本1–日本8 | 日本-1–6 | url-test |
| XM-AI | 日本_* | 同上 | 同上 | 同上 | 日本-1–6 | url-test |
| XM-OpenBot | 日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03（02/03/04 家里宽带刚测是死的，放备份） | 日本高级 IEPL 专线 1 → 2 → 3 | 日本 02 → 03 → 04（不要 01 [0.3X]，不要家宽） | 日本1 → 日本8 | 日本-1 → 6 → 【V6】日本-7/8 | fallback（失败才换，不跟 XM-AI 测速绑定） |
| XM-Web3 | 马来西亚、菲律宾、越南、新加坡_* | 韩国标准 IEPL 专线 1–2 + 越南标准 1 + 印尼标准 1（4 个；新加坡/台湾被 Hyperliquid HIP-4 限制，日本隐藏预测市场） | 马来西亚家宽、菲律宾、越南家宽、韩国、印度尼西亚（不含新加坡/台湾/香港/日本） | 日本1–8 + 马来西亚-3倍率（不含新加坡/台湾/香港/美国） | 日本-1–6 + 韩国/印度/德国/英国/加拿大（不含新/台/港/美） | url-test |
| XM-Bybit | 台湾_01 → 台湾_02 → 其余台湾_* | 台湾高级 IEPL 专线 1–3 + 台湾标准 1–3（6 个） | 台湾 02 → 03 → 04/05 → 家宽 06–10（不含 01 [0.3X]） | 台湾1 → 台湾2 → 台湾3 → 台湾4 | 台湾家宽\|1.5X\|-1 → 【V6】台湾家宽\|1.5X\|-2 | 极速云、MESL、Boost、SWY fallback；花云 url-test |
| XM-日常上网 | 日本_* | 同 XM-Google | 同 XM-Google | 同 XM-Google | 日本-1–6 | url-test |
| XM-Apple | 美国_01–03（3 个） | 美国高级 IEPL 专线 1–3 + 美国标准 1–4（7 个） | 美国 01–03 | 美国1–美国3（不要美国4） | 美国-1–3 | url-test |
| XM-Anki | 日本_01 / 日本_02 / 日本_03 | 日本高级 IEPL 专线 1 / 2 / 3 | 日本 02 / 03 / 04 | 日本1 / 日本2 / 日本3 | 日本-1 / 日本-2 / 日本-3 | select（手动选一个固定节点，避免同步中途切换） |
| XM-系统更新 | DIRECT（默认）+ 日本_01–03 | DIRECT（默认）+ 日本高级 IEPL 专线 1–3 | DIRECT（默认）+ 日本 02–04 | DIRECT（默认）+ 日本1–日本3 | DIRECT（默认）+ 日本-1–3 | select（系统更新默认直连走大陆 CDN，失败可手动切日本） |

花云版多数组 6–7 个节点（XM-Web3 4 个，XM-Anki 3 个，XM-系统更新 DIRECT + 3 个）（同地区高级 + 标准），不用实验性节点；信息条目另外排除英文的 `Traffic` / `Expire`。

- url-test：用 `https://www.gstatic.com/generate_204` 测速，超时 5 秒。极速云每 900 秒测速、快超过 20ms 才切换；花云和 MESL 每 300 秒测速、快超过 10ms 就切换。
- XM-Anki（三份都有）：手动 select 组，只有三个日本节点（花云 日本高级 1–3，极速云 日本_01–03，MESL 日本 02–04），在 App 里自己选一个固定使用，不测速、不自动切换；只用于 AnkiWeb 同步（`ankiweb.net`、`ankiuser.net`）。
- 极速云 XM-Bybit：fallback，900 秒 / 5 秒；排第一的节点可用就一直用它，失败才往后切，固定出口 IP 更稳。MESL 的 XM-Bybit 同样是 fallback（300 秒），从台湾 02 开始。
- **XM-OpenBot**：fallback。极速云顺序是日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03（02/03/04 在家里宽带上刚测是死的，所以放在备份位；回滚时把 filter 和校验期望改回 02 → 03 → 04）。花云仍是日本高级 1 → 2 → 3，MESL 仍是日本 02 → 03 → 04，Boost 是日本1 → 日本8。排第一的节点可用就一直用它，失败才换，不跟 XM-AI 的 url-test 绑定。只用于 `openbot.run`、`openbot.site`。
- **MULTI 的 XM-OpenBot 例外**：用极速云日本_01 → 07 → 05 → 08 → 06 → 04 → 02 → 03，并且 rules 里比另外四份多两条 `AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.run|openbot.site)),REJECT`。原因是极速云 AnyTLS 的 UDP 转发撑不住 TURN（连续 15 次 STUN 掉了 6 次），把 UDP 拒掉后客户端改走 TURN 的 TCP 443，只借用极速云的 TCP 线路。花云故障期间 OpenBot 和 Web3 曾经全废（花云节点健康检查全挂），所以 MULTI 的两个组都以极速云为主、花云垫底。
- 三文鱼（SWY）节点名形如：日本-1–6、台湾家宽|1.5X|-1、美国-1–6、韩国、印度、德国、英国、加拿大。香港节点及只有备用/信息节点不进任何组。规则链接：https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-SWY.yaml
- Boost 节点名不带国旗：日本1–8、台湾1–4、美国1–4、马来西亚-3倍率。香港1–12、新加坡1–8，以及英国/土耳其/阿根廷/澳洲倍率节点不进任何组。规则链接：https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-BOOST.yaml
- **任何分组都不用香港节点**（Google 对香港 IP 不提供 Gemini 等服务）。CI 会检查每组都有香港排除，且 `filter` 本身也不能匹配香港节点名。
- 机场如果改了节点名，对应分组会筛不到节点，需要改对应文件的 `filter`。

## DNS

`223.5.5.5`、`119.29.29.29`，fake-ip（局域网、captive.apple.com、time.apple.com、微软联网检测不走 fake-ip）；IPv6 关闭。**花云 `XM-Clash-HY.yaml` 例外**：`enhanced-mode: redir-host`（不用 fake-ip，全部返回真实 IP），`nameserver` 是加密 DNS `https://doh.pub/dns-query` 和 `tls://dns.alidns.com`，`fallback` 是 `tls://1.1.1.1` 和 `https://8.8.8.8/dns-query`，`fallback-filter` 为 `geoip: CN`（国内 DNS 给出中国 IP 就不再用 fallback）；`default-nameserver` 仍保留明文 IP 223.5.5.5 / 119.29.29.29，只用来引导解析上面那些 DoH/DoT 主机名。redir-host 下没有假地址，所以那份文件不再需要 fake-ip-range 和 fake-ip-filter。另外三份（极速云 / MESL / Boost）仍是上面的 fake-ip 方案，CI 分别校验两套形态。Apple 系统更新相关域名（cdn-apple.com、swcdn/swdist/swscan/ocsp2、aaplimg、akadns、akamaiedge 及 CDN 落点 ks-cdn/ksyuncdn/alikunlun）用 `nameserver-policy` 走 DoH（`https://223.5.5.5/dns-query`、`https://doh.pub/dns-query`）并跳过 fake-ip；TUN 下不要用 `system`（会回环到 mihomo）。`+.openbot.run` 和 `+.openbot.site` 跳过 fake-ip（返回真实 IP），规则走 XM-OpenBot。原因是 TURN/WebRTC 不能用 198.18.0.0/16 假地址。GEOIP 数据库（`geox-url`）用 jsDelivr 镜像 `testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release`，大陆可下载。不写 TUN、端口和控制器，由 App 自己管理。iOS 不能按进程分流（见 https://clash.md/zh/guide/config/apple-platforms ），规则只用域名和 IP。

## 主要分流

规则从上到下匹配，第一条命中即生效：

1. 局域网域名和私有地址直连。
   - 紧接着屏蔽 QUIC：`AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`。没开嗅探时 UDP 只能按 IP 匹配（会误走 GEOIP,CN 直连或兜底直连），屏蔽后 App 回落到 TCP，域名规则才生效（CI 校验它是局域网规则后的第一条）。
2. **XM-Web3**：常用链上 RPC（Infura、Alchemy、Ankr、LlamaRPC、BlockPI、BlastAPI、Omnia Tech、Stackup、Arbitrum 等公链 RPC）、钱包（MetaMask、Phantom、WalletConnect 等）、DEX 与交易站（Uniswap、Jupiter、pump.fun、Bitget、PancakeSwap、Hyperliquid、Polymarket、Across、CoinGecko 等）。
3. **XM-Bybit**：bybit.com、bybit.biz、byabcde.com、bycsi.com。
4. **XM-AI**：ChatGPT / OpenAI、Claude、Perplexity、Cursor、OpenRouter、Grok / x.ai、grokbot.com、Gemini / AI Studio（排在 Google 之前）、Notion（`notion.so` / `.com` / `.site` / `.new`、`notion-static.com`、`notionusercontent.com`、`makenotion.com`、`cron.com` 及 `prod-files-secure.s3.us-west-2.amazonaws.com`）、Slack，以及 Apple 隐私中继和 Siri 相关域名。
   - **XM-OpenBot**：`openbot.run`、`openbot.site`（含 api / analytics）。fallback，三家各自固定三个日本节点，失败才换，不跟 XM-AI 测速绑定。排在 `GEOIP,CN` 之前。`XM-Clash-MULTI.yaml` 里这条组是极速云日本（01→07→05→08→06→04→02→03），并且前面多两条 `AND,((NETWORK,UDP),(DOMAIN-SUFFIX,openbot.*)),REJECT`，强制走 TCP。
5. **XM-Google**：Google、Gmail、YouTube 等，以及 `.goog` 域名和 Antigravity 自动更新服务。
6. **XM-日常上网**（显式规则）：Facebook、Instagram、Threads、Messenger、WhatsApp、Meta AI、muse.ai，以及 X / Twitter（`x.com`、`twitter.com`、`twimg.com`、`t.co`、`pscp.tv`、`periscope.tv`、`twittercdn.com`，排在 `GEOIP,CN` 之前，域名命中后不再按 IP 判断）。
   - **XM-Anki**：`ankiweb.net`、`ankiuser.net`（Anki 同步，固定日本节点，排在 `GEOIP,CN` 之前；CI 校验只有这两条走 XM-Anki）。
7. **直连**：App Store 商店页（apps.apple.com）、iCloud、Apple 地图、Game Center、Apple 推送、Apple TV 视频（tv.apple.com、sps-media.apple.com）、微信、QQ。
8. **XM-Apple**（仅 Apple TV，美国节点）：`tv.apple.com`、`pancake.apple.com`（Apple TV 配置），以及 `play-edge` / `hls` / `np-edge` / `uts-api.itunes.apple.com`（排在 `itunes.apple.com` 之前）。Apple TV 视频 CDN（`vod-ap-aoc` / `vod-ap2-aoc` / `vod-ak-aoc.tv.apple.com`）排在 `tv.apple.com` 之前，直连（DIRECT）；鉴权、片单等域名仍走 XM-Apple。App Store 不走美国节点；iCloud、推送、CloudKit（`apple-cloudkit.com`、`apple-livephotoskit.com`，Notability 等 App 的 iCloud 同步）、`aaplimg.com` 等仍直连，系统更新走 XM-系统更新（CI 校验）。
   - App Store：`mzstatic.com`、`itunes.apple.com` 走 **XM-日常上网**（#53；#78 试过改回直连，TUN 下 apps/is1-ssl.mzstatic.com、osxapps.itunes.apple.com 超时，App Store 更新卡住，所以保留代理）；`apps.apple.com` 直连。`cdn-apple.com` 已改走 XM-系统更新。
   - **XM-系统更新**（iOS/macOS OTA，参考 Apple 企业网络 Software updates）：`cdn-apple.com`（DOMAIN-SUFFIX，含 updates*/fcs-keys 等）、`appldnld`、`swcdn`、`swdist`、`swdownload`、`swscan`、`swquery`、`swpost`、`mesu`、`gdmf`、`gdmf-ados`、`gs`、`gsra`、`gg`、`ig`、`skl`、`xp`、`configuration`、`oscdn`、`osrecovery`、`cds`、`download.info.apple.com`、`ocsp2.apple.com`； DNS：这些 Apple 下载域名用 nameserver-policy （含 CNAME 落点 ks-cdn/ksyuncdn/alikunlun）走 DoH `https://223.5.5.5/dns-query` + `https://doh.pub/dns-query` 并跳过 fake-ip（TUN 下 system 会回环到 mihomo，明文 UDP 223/119 对这些域名超时/SERVFAIL）；默认 DIRECT（整条同出口，避免校验卡住），失败可手动切日本。不影响 XM-Apple / Apple TV。
9. 中国大陆 IP（`GEOIP,CN`）直连。
10. 其余流量走 **XM-日常上网**。

## 修改规则

1. 新建分支修改规则。**改规则（`rules`）时，`XM-Clash-JSY.yaml`、`XM-Clash-HY.yaml`、`XM-Clash-MESL.yaml` 和 `XM-Clash-BOOST.yaml` 必须做完全相同的修改**：四份文件从「# 规则从上到下匹配」到末尾必须逐字节一致，CI 会检查。只改某家的节点筛选时，只改对应文件的 `proxy-groups`。
2. 本地校验：

   ```sh
   ruby scripts/validate_rules.rb
   ```

   校验内容：
   - 四份文件的规则部分逐字节一致。
   - 四份文件都不含 `proxies`、`proxy-providers`、`rule-providers`。
   - 九个分组的名称、顺序、类型、测速参数；各组 `filter` / `exclude-filter` 对虚构样例节点名（不含真实节点）选中的结果，每组非空、排除香港节点和信息条目。
   - DNS。
   - 规则语法、目标只能是九个组或 DIRECT / REJECT、无重复、不被前面的后缀规则遮住、最后两条为 `GEOIP,CN,DIRECT` 和 `MATCH,XM-日常上网`。
   - 公开链接白名单。
3. 开 PR。GitHub Actions 自动跑同样的校验，通过后合并到 main，App 按链接更新即可生效。

- Notion 全家（notion.so/.com/.site/.new、notion-static.com、notionusercontent.com、makenotion.com、Notion Calendar 旧域 cron.com，以及文件存储 `prod-files-secure.s3.us-west-2.amazonaws.com` 精确匹配）走 XM-AI，排在 GEOIP,CN 之前，CI 校验。
- OpenBot（`openbot.run` 含 api / analytics，以及 `openbot.site`）走 XM-OpenBot（fallback，三家各自三个日本节点，不跟 XM-AI 测速绑定），排在 GEOIP,CN 之前，CI 校验。MULTI 里这组是极速云日本，且这两条域名之前另有两条 UDP 拒绝规则（TURN 会先用 UDP，极速云的 UDP 转发撑不住，先拒掉让它走 TCP）；CI 只允许 MULTI 有这两条，四份单订阅配置的 rules 仍逐字节一致。
