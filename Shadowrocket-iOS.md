# Shadowrocket iOS 专用分流

固定远程配置：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf`

这是包含 `get.conf` 的个人分流配置，包含四个组和个人域名规则。Bybit 与 Web3 共用日本节点组。旧模块链接保留兼容，不需要再启用。Mac 仍使用原 V1.3 策略源和本机同步任务，iOS 独立维护此配置，不要求两端策略逐项一致。

## 保留 MESL DNS 的使用方法

设备已确认：原模块无法单独新增分组；`XM-Shadowrocket-Groups.conf` 能显示个人组。107 条个人规则也已并入该配置，以后只维护一个链接。

1. 保留 MESL 官方 `get.conf`。在“配置”中使用 `XM-Shadowrocket-Groups.conf`；它通过 `include = get.conf` 继承 MESL 的 DNS 与基础策略。
2. 在“配置 → 模块”停用原 XM iOS 模块；无需删除，避免新旧规则重复。回到新配置，更新配置并点击“使用配置”。
3. 首页全局路由选择“配置”。确认四个 XM 组有节点，分别检查 Google、AI、Meta、Bybit、Web3 及国内服务的实际规则命中。Bybit 应命中 XM-Web3；若合并后异常，切回 `get.conf` 并反馈。

配置自身只有 include、公开更新地址、四个分组、个人域名规则，没有 DNS、节点、GEOIP 或 FINAL 项。基础配置按 MESL 官方方式维护。不要删除或改名 `get.conf`，也不要把私有订阅链接提交到 GitHub。

合并后的规则仍需 iPhone 端复核；GitHub 静态校验无法证明手机实际流量命中。`XM-Shadowrocket-Groups.conf` 文件名保持原样，避免用户更换导入链接。

## 与 Mac 的差异

| 用途 | iOS 配置 |
| --- | --- |
| Google | XM-Google：日本普通 01–03、家宽 08–10，手动选择 |
| AI | XM-AI：日本普通 01–03、家宽 08–10，手动选择 |
| Meta / Instagram / Threads | XM-Meta：美国普通 01–03、家宽 10–12，手动选择 |
| Bybit | XM-Web3：与 Web3 共用所选日本节点 |
| Web3 交易与 RPC | XM-Web3：日本普通 01–03、家宽 08–10，手动选择 |
| 日常上网、国内直连、Apple、兜底 | 沿用 MESL 基础配置 |

长期测试版固定每组为六个节点范围（三个普通、三个家宽），不添加国家切换层级或定时测速。编号筛选兼容日本 01 的倍率备注；其他编号不纳入。这里的稳定版指固定策略范围，不代表已长期验证线路质量。筛选条件使用节点名称中的文字，不依赖国旗显示；其他订阅中同名节点也可能被纳入，应确认成员均来自 MESL。

域名规则最初来自现有六个个人规则集，顺序为 RPC → Bybit → Web3 → AI → Google → Meta，共 107 条，写在本配置中。以后直接修改此文件；Mac 的 YAML 不会自动覆盖 iOS 配置。需要立即更新时在配置页更新本文件，再“使用配置”。

## 核实来源与验证范围

开发者官网为 `https://shadowlaunch.com/`，由 App Store 开发者网站链接确认；官网未提供完整配置语法手册。

- MESL 官方 Shadowrocket 教程：`https://dash.mesurl.com/#/docs/10`，核实先使用官方配置再导入节点的流程。
- `https://github.com/LOWERTOP/Shadowrocket` 为配置示例作者及手册维护者的原始仓库，**不是开发者官方文档**。其原始配置示例提供 select、policy-regex-filter 和 include 写法；手册说明包含配置的优先级。

项目校验确认配置结构、规则策略引用及未定义 DNS、节点或通用兜底。分组已在 iPhone 显示；合并规则后的命中仍需设备验证。
