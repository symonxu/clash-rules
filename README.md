# XM 个人分流规则（Clash App）

本仓库只维护一份规则配置 `XM-Clash.yaml`，给 Clash App（「Clash - 基于规则的网络代理工具」，clash.md）在 iPhone、iPad 和 Mac 上共用。

配置链接：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash.yaml

**仓库里绝不能出现订阅地址、节点信息或任何凭据。** 文件只有分组、规则和 DNS；节点来自在 App 里单独添加的 MESL 订阅。CI 会拦截白名单以外的链接。

## 在 App 里怎么用

节点和规则分开导入，再组合成一份配置：

1. **添加 MESL 订阅**：配置（Profiles）→ 添加配置（Add Profile）→ 配置链接，粘贴 MESL 的 Clash 订阅地址。先选中它、出站模式选"规则"并连接，下一步才能打开 GitHub（raw.githubusercontent.com 在大陆直连通常打不开）。
2. **添加规则配置**：同样"添加配置 → 配置链接"，粘贴上面的配置链接。若有"同时登记它的规则"开关，保持打开；它会作为规则方案出现在规则库里。这份配置自己没有节点，不要单独选中使用。
3. **组合**：把 MESL 配置的规则方案换成 `XM-Clash`（"更换规则方案"），或新建配置时"选择节点来源和规则方案"：节点来源选 MESL，规则方案选 `XM-Clash`。
4. 选中组合后的配置，出站模式选"规则（Rule）"，连接；在"代理（Proxies）"里确认六个组都有节点。
5. 检查分流：iPhone 在 工具（Utilities）→ Current Session → 连接（Connections），Mac 在侧边栏 Session → Connections，看新连接命中的规则和出站组。

仓库更新后，App 按配置链接自动更新规则；想立刻生效，可在规则库对该方案点"刷新规则"，或在配置列表对它点更新。MESL 节点照常在 MESL 配置里更新。

入口和模式的说明见 clash.md 文档：iPhone https://clash.md/zh/guide/ios ，Mac https://clash.md/zh/guide/macos 。节点来源与规则方案的组合方式以 App 开源代码为准：https://github.com/ProjectClash/Clash-Client 。

Mac 上不要同时开着 Clash App 和其他代理软件的 TUN（例如 Clash Verge），两个都会接管系统流量。

## 分组

各组用 `include-all: true` 引入节点来源里的全部节点，再按节点名正则 `filter` 筛选：

| 分组 | 节点 | 类型 |
| --- | --- | --- |
| XM-Google | 日本 02–07 | url-test |
| XM-AI | 日本 02–07 | url-test |
| XM-Meta | 美国 01–03、美国 10–12 家宽 | url-test |
| XM-Web3 | 马来西亚 01、03 家宽，菲律宾 01、菲律宾 02 家宽，越南家宽，香港 14 家宽 | url-test |
| XM-Bybit | 台湾 08 家宽（主）→ 台湾 09 家宽（备） | fallback |
| XM-日常上网 | 日本 02–07 | url-test |

- url-test：用 `https://www.gstatic.com/generate_204` 每 900 秒测速，超时 5 秒，新节点快超过 20ms 才切换。
- XM-Bybit：fallback，同样 900 秒 / 5 秒；08 可用就一直用 08，失败才用 09，固定出口 IP 更稳。
- MESL 如果改了节点名，对应分组会筛不到节点，需要改 `filter`。

## DNS

`223.5.5.5`、`119.29.29.29`，fake-ip（局域网、captive.apple.com、time.apple.com、微软联网检测不走 fake-ip）；IPv6 关闭。不写 TUN、端口和控制器，由 App 自己管理。iOS 不能按进程分流（见 https://clash.md/zh/guide/config/apple-platforms ），规则只用域名和 IP。

## 主要分流

规则从上到下匹配，第一条命中即生效：

1. 局域网域名和私有地址直连。
2. **XM-Web3**：常用链上 RPC（Infura、Alchemy、Ankr、LlamaRPC、BlockPI、BlastAPI、Omnia Tech、Stackup、Arbitrum 等公链 RPC）、钱包（MetaMask、Phantom、WalletConnect 等）、DEX 与交易站（Uniswap、Jupiter、pump.fun、Bitget、PancakeSwap、Hyperliquid、Polymarket、Across、CoinGecko 等）。
3. **XM-Bybit**：bybit.com、bybit.biz、byabcde.com、bycsi.com。
4. **XM-AI**：ChatGPT / OpenAI、Claude、Perplexity、Cursor、OpenRouter、Grok / x.ai、grokbot.com、Gemini / AI Studio（排在 Google 之前）、Slack，以及 Apple 隐私中继和 Siri 相关域名。
5. **XM-Google**：Google、Gmail、YouTube 等。
6. **XM-Meta**：Facebook、Instagram、Threads、Messenger、WhatsApp、Meta AI、muse.ai。
7. **直连**：App Store（国区、美区）、软件下载与系统更新、iCloud、Apple 地图、Game Center、Apple 推送、Apple TV 视频（tv.apple.com、sps-media.apple.com）、微信、QQ。
8. 中国大陆 IP（`GEOIP,CN`）直连。
9. 其余流量走 **XM-日常上网**。

## 修改规则

1. 新建分支，修改 `XM-Clash.yaml`。
2. 本地校验：

   ```sh
   ruby scripts/validate_rules.rb
   ```

   校验内容：
   - 文件不含 `proxies`、`proxy-providers`、`rule-providers`。
   - 六个分组的名称、顺序、类型、测速参数，以及各组 `filter` 选中的节点。
   - DNS。
   - 规则语法、目标只能是六个组或 DIRECT / REJECT、无重复、不被前面的后缀规则遮住、最后两条为 `GEOIP,CN,DIRECT` 和 `MATCH,XM-日常上网`。
   - 公开链接白名单。
3. 开 PR。GitHub Actions 自动跑同样的校验，通过后合并到 main，App 按链接更新即可生效。
