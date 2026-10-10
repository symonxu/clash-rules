# Mac / iOS 个人分流配置

本仓库只保留两套当前在用的配置：

- **Mac**：Clash Verge Rev + `XM-ClashVerge-Routing.yaml` + 本地自动同步程序 `tools/clash-sync`
- **iOS**：Shadowrocket + `XM-Shadowrocket-Slim.conf`

节点统一来自 MESL 订阅，订阅保留在各自 App 里更新；GitHub 只维护分组和规则，不含节点、私有订阅地址或凭据。

## Mac：Clash Verge Rev

策略链接（不是节点订阅，由本地同步程序接入 MESL 订阅）：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml

五个分组（Google、AI、Meta、Web3、日常上网），每组六个节点，由本地程序每五分钟测速择优，比当前节点快超过 20ms 才切换。DNS、TUN、系统代理由你在客户端里自行设置，程序不改动。

详见：[Mac 接入与回退说明](ClashVerge-Mac.md)、[自动同步程序安装说明](tools/clash-sync/README.md)

## iOS：Shadowrocket

配置链接：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Slim.conf

- 独立配置，不再 include MESL 的 `get.conf`。
- 只有一个分组 **XM-日本**（fallback 类型）：**日本 08 家宽优先**，08 不通时按顺序切到日本 02、03……，08 恢复后自动切回。每 600 秒检测一次。
- 所有代理规则和兜底 `FINAL` 都走 XM-日本；中国大陆、局域网、微信、Apple 国内服务直连；广告、隐私追踪、劫持域名拦截。
- DNS：`223.5.5.5`、`119.29.29.29`，备用 `system`；IPv6 关闭。
- 首页保留 MESL 订阅，节点从订阅里来。
- **注意**：XM-日本 组里写的是节点完整名称（如 `🇯🇵 日本 08 家宽`），这样才能固定顺序。MESL 如果改了节点名，需要同步修改配置文件，否则对应节点会失效。

详见：[iOS 使用说明](Shadowrocket-iOS.md)

## 本地校验

```sh
ruby scripts/validate_rules.rb
```

校验 iOS 配置结构（单一 XM-日本 组、08 家宽排第一、规则只指向 XM-日本/DIRECT/REJECT）、Mac 策略文件、自动同步程序的离线测试，以及公开链接白名单（防止误提交私有订阅地址）。GitHub Actions 在每个 PR 上自动运行同样的校验。线路是否可用以客户端实际运行为准。
