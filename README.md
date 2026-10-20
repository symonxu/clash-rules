# XM 个人分流规则（Clash App）

本仓库维护两份并行的规则配置，给 Clash App（「Clash - 基于规则的网络代理工具」，clash.md）在 iPhone、iPad 和 Mac 上共用。两份文件的 DNS、分组和**规则完全相同**，只有各组筛选节点的正则不同（两家节点命名不一样）：

| 组合 | 节点来源 | 规则方案 | 配置链接 |
| --- | --- | --- | --- |
| 极速云 | 极速云订阅 | `XM-Clash-JSY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-JSY.yaml |
| 花云 | 花云订阅 | `XM-Clash-HY` | https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-HY.yaml |

两个组合可以同时存在，哪家出问题就切到另一个组合。

**仓库里绝不能出现订阅地址、节点信息或任何凭据。** 文件只有分组、规则和 DNS；CI 会拦截白名单以外的链接。

## 在 App 里怎么用

节点和规则分开导入，再组合成一份配置（以极速云为例；花云相同，把订阅换成花云、配置链接和规则方案换成 `XM-Clash-HY`）：

1. **添加订阅**：配置（Profiles）→ 添加配置（Add Profile）→ 配置链接，粘贴极速云的 Clash 订阅地址。先选中它、出站模式选"规则"并连接，下一步才能打开 GitHub（raw.githubusercontent.com 在大陆直连通常打不开）。
2. **添加规则配置**：同样"添加配置 → 配置链接"，粘贴对应的配置链接。若有"同时登记它的规则"开关，保持打开；它会作为规则方案出现在规则库里。这份配置自己没有节点，不要单独选中使用。
3. **组合**：把极速云配置的规则方案换成 `XM-Clash-JSY`（"更换规则方案"），或新建配置时"选择节点来源和规则方案"：节点来源选极速云，规则方案选 `XM-Clash-JSY`。花云则是节点来源选花云、规则方案选 `XM-Clash-HY`。不要用机场自带的分组和规则。
4. 选中组合后的配置，出站模式选"规则（Rule）"，连接；在"代理（Proxies）"里确认六个组都有节点。
5. 检查分流：iPhone 在 工具（Utilities）→ Current Session → 连接（Connections），Mac 在侧边栏 Session → Connections，看新连接命中的规则和出站组。

仓库更新后，App 按配置链接自动更新规则；想立刻生效，可在规则库对该方案点"刷新规则"，或在配置列表对它点更新。节点照常在各自的订阅配置里更新。

入口和模式的说明见 clash.md 文档：iPhone https://clash.md/zh/guide/ios ，Mac https://clash.md/zh/guide/macos 。节点来源与规则方案的组合方式以 App 开源代码为准：https://github.com/ProjectClash/Clash-Client 。

Mac 上不要同时开着 Clash App 和其他代理软件的 TUN（例如 Clash Verge），两个都会接管系统流量。

## 分组

各组用 `include-all: true` 引入订阅里的全部节点，按节点名正则 `filter` 筛选，再用 `exclude-filter` 剔除香港节点（`香港|HK|Hong Kong|🇭🇰`，不区分大小写）和「剩余流量」「套餐到期」「官网」等信息条目：

| 分组 | 极速云（`XM-Clash-JSY.yaml`） | 花云（`XM-Clash-HY.yaml`） | 类型 |
| --- | --- | --- | --- |
| XM-Google | 日本_* | 日本高级 IEPL 专线 1–3、日本实验性 IEPL 专线 1（4 个） | url-test |
| XM-AI | 日本_* | 同上 | url-test |
| XM-Web3 | 马来西亚、菲律宾、越南、新加坡_* | 新加坡高级 IEPL 专线 1–3，马来西亚 / 菲律宾 / 越南标准 IEPL 专线 1（6 个） | url-test |
| XM-Bybit | 台湾_01 → 台湾_02 → 其余台湾_* | 台湾高级 IEPL 专线 1 → 2 → 3 | fallback |
| XM-日常上网 | 日本_* | 同 XM-Google | url-test |
| XM-Apple | 美国_01–03（3 个） | 美国高级 IEPL 专线 1–3（3 个） | url-test |

花云版每组只留 4–6 个节点，XM-Bybit 的筛选兼容「台湾_01」写法；信息条目另外排除英文的 `Traffic` / `Expire`。

- url-test：用 `https://www.gstatic.com/generate_204` 每 900 秒测速，超时 5 秒，新节点快超过 20ms 才切换。
- XM-Bybit：fallback，同样 900 秒 / 5 秒；排第一的节点可用就一直用它，失败才往后切，固定出口 IP 更稳。
- **任何分组都不用香港节点**（Google 对香港 IP 不提供 Gemini 等服务）。CI 会检查每组都有香港排除，且 `filter` 本身也不能匹配香港节点名。
- 机场如果改了节点名，对应分组会筛不到节点，需要改对应文件的 `filter`。

## DNS

`223.5.5.5`、`119.29.29.29`，fake-ip（局域网、captive.apple.com、time.apple.com、微软联网检测不走 fake-ip）；IPv6 关闭。不写 TUN、端口和控制器，由 App 自己管理。iOS 不能按进程分流（见 https://clash.md/zh/guide/config/apple-platforms ），规则只用域名和 IP。

## 主要分流

规则从上到下匹配，第一条命中即生效：

1. 局域网域名和私有地址直连。
   - 紧接着屏蔽 QUIC：`AND,((NETWORK,UDP),(DST-PORT,443)),REJECT`。没开嗅探时 UDP 只能按 IP 匹配（会误走 GEOIP,CN 直连或兜底直连），屏蔽后 App 回落到 TCP，域名规则才生效（CI 校验它是局域网规则后的第一条）。
2. **XM-Web3**：常用链上 RPC（Infura、Alchemy、Ankr、LlamaRPC、BlockPI、BlastAPI、Omnia Tech、Stackup、Arbitrum 等公链 RPC）、钱包（MetaMask、Phantom、WalletConnect 等）、DEX 与交易站（Uniswap、Jupiter、pump.fun、Bitget、PancakeSwap、Hyperliquid、Polymarket、Across、CoinGecko 等）。
3. **XM-Bybit**：bybit.com、bybit.biz、byabcde.com、bycsi.com。
4. **XM-AI**：ChatGPT / OpenAI、Claude、Perplexity、Cursor、OpenRouter、Grok / x.ai、grokbot.com、Gemini / AI Studio（排在 Google 之前）、Slack，以及 Apple 隐私中继和 Siri 相关域名。
5. **XM-Google**：Google、Gmail、YouTube 等，以及 `.goog` 域名和 Antigravity 自动更新服务。
6. **XM-日常上网**（显式规则）：Facebook、Instagram、Threads、Messenger、WhatsApp、Meta AI、muse.ai。
7. **直连**：App Store 商店页（apps.apple.com）、iCloud、Apple 地图、Game Center、Apple 推送、Apple TV 视频（tv.apple.com、sps-media.apple.com）、微信、QQ。
8. **XM-Apple**（仅 Apple TV，美国节点）：`tv.apple.com`、`pancake.apple.com`（Apple TV 配置），以及 `play-edge` / `hls` / `np-edge` / `uts-api.itunes.apple.com`（排在 `itunes.apple.com` 之前）。Apple TV 视频 CDN（`vod-ap-aoc` / `vod-ap2-aoc` / `vod-ak-aoc.tv.apple.com`）排在 `tv.apple.com` 之前，走 XM-日常上网（日本节点）。App Store 不走美国节点；iCloud、推送、系统更新、`aaplimg.com` 等仍直连（CI 校验）。
   - **临时（#53，大陆 DNS 解析 App Store CDN 失败）**：`mzstatic.com`、`itunes.apple.com`、`cdn-apple.com` 走 **XM-日常上网**（日本节点，较慢、耗流量），国内 DNS 恢复后改回直连；`apps.apple.com` 直连。
9. 中国大陆 IP（`GEOIP,CN`）直连。
10. 其余流量走 **XM-日常上网**。

## 修改规则

1. 新建分支修改规则。**改规则（`rules`）时，`XM-Clash-JSY.yaml` 和 `XM-Clash-HY.yaml` 必须做完全相同的修改**：两份文件从「# 规则从上到下匹配」到末尾必须逐字节一致，CI 会检查。只改某家的节点筛选时，只改对应文件的 `proxy-groups`。
2. 本地校验：

   ```sh
   ruby scripts/validate_rules.rb
   ```

   校验内容：
   - 两份文件的规则部分逐字节一致。
   - 两份文件都不含 `proxies`、`proxy-providers`、`rule-providers`。
   - 六个分组的名称、顺序、类型、测速参数；各组 `filter` / `exclude-filter` 对虚构样例节点名（不含真实节点）选中的结果，每组非空、排除香港节点和信息条目。
   - DNS。
   - 规则语法、目标只能是六个组或 DIRECT / REJECT、无重复、不被前面的后缀规则遮住、最后两条为 `GEOIP,CN,DIRECT` 和 `MATCH,XM-日常上网`。
   - 公开链接白名单。
3. 开 PR。GitHub Actions 自动跑同样的校验，通过后合并到 main，App 按链接更新即可生效。
