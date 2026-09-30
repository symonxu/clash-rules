# Clash Verge Rev：MESL 与个人策略

固定策略入口：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml

此链接只提供 proxy-groups、rule-providers、rules，不包含节点或 DNS。保留 MESL 订阅，通过本机手动同步工具写入该订阅的扩展脚本。不能把此链接当作完整节点订阅导入。

## 分组与规则

Google、AI、Web3（含 Bybit 与 RPC）、日常上网使用日本普通 02–04、家宽 08–10；Meta 使用美国普通 01–03、家宽 10–12。五组均手动选择，每组匹配六个节点。没有自动测速或国家子组。

局域网直连 → 107 条个人域名规则（RPC、Bybit、Web3、AI、Google、Meta）→ 中国大陆 IP 直连 → 日常上网兜底。AI 专用 Google 域名优先于一般 Google 域名。MESL 原分组和分流规则被替换，DNS、节点和私有订阅保留。初版全部规则直接写在策略文件中，rule-providers 为空。

## 更新

1. 启动 Clash Verge，激活 MESL 订阅；选择规则模式。首次切换先断开 Mac Shadowrocket。
2. 双击桌面的“更新 Clash 个人规则.command”。工具下载公开 YAML，校验分组、规则与 Mihomo 配置后应用，并保留仍有效的组内选择。
3. GitHub 修改策略后再次点击更新；没有后台定时更新个人策略。MESL 节点订阅更新独立进行，生成配置时继续应用已保存的个人扩展。
4. 使用系统代理，首次 TUN 与 DNS 覆写关闭。TUN 是否需要以后按实际应用覆盖范围决定。

同步工具要求当前 MESL 节点名匹配每组六个节点。节点改名、缺失、多出同名候选、下载失败、配置并发变化或校验失败时不应用。内核加载失败恢复原脚本和运行配置；恢复重载失败会明确提示重新激活 MESL。

## 回退与验证

本机同步状态目录为 ~/Library/Application Support/XM-ClashVerge-RoutingSync，最近应用前备份位于 last-backup。该目录及客户端配置含私有数据，不上传 GitHub。恢复备份扩展脚本后重新激活 MESL；恢复服务商原分流则将扩展脚本改回 function main(config) { return config; }。

逐项验证 Google、AI、Meta、Bybit/Web3、国内网站和普通海外网站，查看实际规则命中与最终节点。重启客户端以及更新 MESL 订阅后，五组应继续保留。GitHub 静态检查不能证明目标服务登录或所有线路可用。

合盖持续联网与唤醒重连需要单独验证，本配置不调整 Mac 电源设置。

实现依据：[Clash Verge 扩展配置](https://www.clashverge.dev/guide/extend.html)、[订阅扩展脚本](https://www.clashverge.dev/guide/script.html)。
