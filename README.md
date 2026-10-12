# Mac / iOS 个人分流配置

本仓库只保留两套当前在用的配置：

- **Mac**：Clash Verge Rev + `XM-ClashVerge-Routing.yaml` + 本地自动同步程序 `tools/clash-sync`
- **iOS**：Shadowrocket + `XM-Shadowrocket-Slim.conf`

节点统一来自 MESL 订阅，订阅保留在各自 App 里更新；GitHub 只维护分组和规则，不含节点、私有订阅地址或凭据。

## Mac：Clash Verge Rev

策略链接（不是节点订阅，由本地同步程序接入 MESL 订阅）：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml

五个分组（Google、AI、Meta、Web3、日常上网），每组六个节点，由本地程序每十五分钟测速择优，比当前节点快超过 20ms 才切换。DNS、TUN、系统代理由你在客户端里自行设置，程序不改动。

详见：[Mac 接入与回退说明](ClashVerge-Mac.md)、[自动同步程序安装说明](tools/clash-sync/README.md)

## iOS：Shadowrocket

配置链接：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Slim.conf

- 独立配置，不再 include MESL 的 `get.conf`。
- 五个分组与 Mac 端完全一致：**XM-Google**、**XM-AI**、**XM-日常上网** 用日本 02、03、05、06、07 和日本 09 家宽；**XM-Web3** 用马来西亚 01、03 家宽、菲律宾 01、菲律宾 02 家宽、越南家宽、香港 14 家宽；**XM-Meta** 用美国 01、02、03 和美国 10、11、12 家宽。
- 每组都是 url-test 类型：每 900 秒（15 分钟）测速一次，新节点快超过 20ms 才切换，和 Mac 同步程序的择优逻辑相同。
- 分流规则与 Mac 的 `XM-ClashVerge-Routing.yaml` 保持同样的域名、目标组和先后顺序（AI 相关的 Google 域名排在通用 Google 之前）；兜底 `FINAL` 走 XM-日常上网。中国大陆、局域网、微信、Apple 国内服务直连；广告、隐私追踪、劫持域名拦截。
- DNS：`223.5.5.5`、`119.29.29.29`，备用 `system`；IPv6 关闭。
- 首页保留 MESL 订阅，节点从订阅里来。
- **注意**：各组里写的是节点完整名称（如 `🇯🇵 日本 08 家宽`）。MESL 如果改了节点名，需要同步修改配置文件，否则对应节点会失效。

详见：[iOS 使用说明](Shadowrocket-iOS.md)

## 本地校验

```sh
ruby scripts/validate_rules.rb
```

校验 iOS 配置结构（五个 url-test 组及成员、规则只指向五个组/DIRECT/REJECT、域名规则与 Mac 一致）、Mac 策略文件、自动同步程序的离线测试，以及公开链接白名单（防止误提交私有订阅地址）。GitHub Actions 在每个 PR 上自动运行同样的校验。线路是否可用以客户端实际运行为准。

Apple 直连：App Store（国区和美区）、软件下载和系统更新域名直连，与 Mac 规则顺序一致；Siri 和 iCloud 专用代理仍走 XM-AI。
