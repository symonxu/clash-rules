# Shadowrocket Mac 与 iOS 使用说明

固定远程配置：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf

Mac 与 iOS 使用同一份个人配置，包含五个手动选择组和 120 条个人域名规则。Bybit 与 Web3 共用日本节点组。用户已在两端使用，Mac 切换后反馈运行稳定；后续线路情况仍以设备实际测试为准。

## 导入与更新

1. 保留本地 MESL 官方 `get.conf` 和节点订阅。不要删除或改名 `get.conf`。
2. 在“配置”中导入上述链接并使用 XM 配置。它通过 `include = get.conf` 继承 MESL 的 DNS 与基础策略。
3. 在“配置 → 模块”停用旧 XM 模块，避免重复规则。完整 XM 配置已包含个人分组和规则，无需再添加模块。
4. 首页全局路由选择“配置”，分别选择五个组的节点并测试服务。
5. GitHub 个人规则变化后，在配置页更新 XM 文件并重新“使用配置”。节点订阅更新与 `get.conf` 更新分别进行；更新 XM 文件不会更新本地 `get.conf`。

XM 文件没有 DNS 或节点定义。DNS 继续继承 MESL 基础配置，私有订阅地址与节点凭据只保留在设备中。

## 分组与规则

| 用途 | 分组与节点 |
| --- | --- |
| Google | XM-Google：日本普通 02–04、家宽 08–10 |
| AI | XM-AI：日本普通 02–04、家宽 08–10 |
| Meta / Instagram / Threads | XM-Meta：美国普通 01–03、家宽 10–12 |
| Web3 交易、Bybit 与 RPC | XM-Web3：日本普通 02–04、家宽 08–10 |
| 日常上网兜底 | XM-日常上网：日本普通 02–04、家宽 08–10 |

每组范围为六个节点，三个普通、三个家宽。日本普通 01 不纳入。筛选依赖节点名称；其他订阅中同名节点也可能被纳入，请确认组成员。

个人域名规则顺序为 RPC → Bybit → Web3 → AI → Google → Meta，随后为 `GEOIP,CN,DIRECT` 和 `FINAL,XM-日常上网`。日常上网是未命中此前规则时的兜底；被包含的 MESL 基础配置仍可能提供专门服务规则，实际优先级和命中需在客户端确认。

配置中的 `update-url` 保持固定。以后个人规则与分组直接维护 `XM-Shadowrocket-Groups.conf`；旧 `XM-Shadowrocket-iOS.sgmodule` 仅保留兼容，不需要启用。说明文件保留原文件名供已有链接继续访问。

## 文档来源与验证范围

- 开发者网站：https://shadowlaunch.com/ 。此前通过 App Store 开发者网站链接核实；网站未提供完整配置语法手册。
- MESL Shadowrocket 教程：https://dash.mesurl.com/#/docs/10 。此前核实官方配置与节点导入流程。
- 配置示例与手册维护者仓库：https://github.com/LOWERTOP/Shadowrocket 。这是第三方文档，提供 select、policy-regex-filter 与 include 示例。

GitHub 静态检查验证结构、规则引用、固定更新地址及没有额外 DNS 或节点项；不能代替实际连接测试。发生异常可切回保留的 `get.conf`，记录请求、规则命中与最终节点后再排查。
