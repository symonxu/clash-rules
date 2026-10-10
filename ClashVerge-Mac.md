# Clash Verge Rev：MESL 与个人策略

固定策略入口：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml

链接只提供 proxy-groups、rule-providers、rules，不包含节点或 DNS，不能作为普通节点订阅导入。MESL 提供本机节点与 DNS，GitHub 独立维护个人分组和路由。

## 分组与规则

Google、AI、Web3（含 Bybit 与 RPC）、日常上网使用日本普通 02–04、家宽 08–10；Meta 使用美国普通 01–03、家宽 10–12。五组各匹配六个节点，由新版本地同步程序自动择优：每五分钟测速，当前节点比最快节点慢超过 20ms 才切换；差 10ms 或恰好 20ms 都保持。当前节点测速失败而其他候选有效时允许故障切换；全组失败则保持原选择。

组类型继续为 `select`，由本地接口控制选择。原生 `url-test` 在当前版本有候选顺序影响容差的边界，因此本程序直接比较整数延迟，保证严格的 20ms 阈值。客户端中显示“手动选择”是组接口类型，自动管理由程序承担；只导入 YAML 而未升级程序时仍是手动选择。

局域网直连 → 120 条个人域名规则（RPC、Bybit、Web3、AI、Google、Meta）→ 中国大陆 IP 直连 → 日常上网兜底。AI 专用 Google 域名优先于一般 Google 域名。MESL 原分组和分流规则被替换，DNS、节点和私有订阅保留。当前全部规则直接写在策略文件中，rule-providers 为空。

## 自动同步

[程序与中文安装说明](tools/clash-sync/README.md) 提供 `--install`、`--uninstall`、`--status`、`--once` 四个入口。由你在 Mac 上安装一次；之后无需保留桌面手动更新文件。

Clash 自行更新 MESL 节点；本地任务每分钟检查客户端与订阅变化，每五分钟检查 GitHub 个人策略并测速。节点变化时等待客户端完成生成，再检查最新个人策略。有效变化才应用；Clash 未运行或当前不是绑定的 MESL 时跳过。个人扩展已保存到订阅，每次生成配置继续应用。重载时先恢复有效选择，再按阈值择优；你的手动选择也会在下一轮测速中参与比较。

使用规则模式，保持你已经验证的系统代理、TUN 与 DNS 设置。程序不切换这些开关，不启动客户端，不额外下载私有订阅，不上传本机配置。DNS 覆写保持由你控制。

## 回退与验证

下载、格式、六节点筛选或 Mihomo 校验失败不应用候选配置；内核加载失败恢复此次应用前的脚本和配置，回退失败明确提示重新激活 MESL。断网使用已验证缓存时状态标为未取得最新策略；正常运行安静，重复故障退避重试。

本机状态目录为 `~/Library/Application Support/XM-ClashVerge-RoutingSync`，最近应用前备份位于 `last-backup`。此目录及客户端配置含私有数据，不上传 GitHub。详细的暂停、回退与卸载步骤见安装说明。

逐项验证 Google、AI、Meta、Bybit/Web3、国内网站和普通海外网站，查看实际规则命中与最终节点。重启客户端及更新 MESL 后，五组应继续保留。GitHub 隔离测试不能证明本机接口兼容、目标服务登录或线路可用性。

合盖联网与唤醒重连单独验收，本程序不调整 Mac 电源设置。iOS 使用独立的 `XM-Shadowrocket-Slim.conf`（单一 XM-日本 组），与 Mac 的五组策略互不影响，见 [iOS 使用说明](Shadowrocket-iOS.md)。

实现依据：[Clash Verge 扩展配置](https://www.clashverge.dev/guide/extend.html)、[订阅扩展脚本](https://www.clashverge.dev/guide/script.html)。
