# Shadowrocket iOS 专用分流

固定远程模块：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-iOS.sgmodule`

这是个人分流模块，不是节点订阅，也不是完整配置。Mac 仍使用原 V1.3 策略源和本机同步任务，iOS 独立维护此模块，不要求两端策略逐项一致。

## 保留 MESL DNS 的使用方法

1. 在 MESL 官网开启订阅窗口，先导入官方“Shadowrocket 分流配置”，点击“使用配置”，再导入或更新 MESL 节点订阅。订阅开放窗口为 10 分钟。
2. 确认使用 MESL 原始配置时国内网站、Google、ChatGPT 等正常。
3. 在 Shadowrocket 的“配置 → 模块 → +”中填入上方链接，下载并启用模块。不要把它作为节点订阅或独立完整配置使用。
4. 全局路由使用“配置”。进入“代理分组”，确认五个 XM 组都有节点，按需手动选择。Google 组仅匹配日本 08 家宽；其他组允许在限定地区中选择。
5. 检查实际请求的规则命中与策略节点；确认 Google、AI、Meta、Bybit、Web3 和国内服务均正常。若模块无法识别代理组或出现空组，停用模块并反馈，基础 MESL 配置可继续使用。

模块没有 `[General]`、`[Host]`、`[Proxy]`、`[MITM]` 或脚本，不设置 DNS、节点凭据、国内通用规则或 FINAL 兜底。MESL 基础配置的 DNS 及未命中模块的分流继续生效。其更新也需按 MESL 官网要求进行，不从 Mac 的 Clash 配置复制 DNS。

## 与 Mac 的差异

| 用途 | iOS 模块 |
| --- | --- |
| Google | XM-Google：日本 08 家宽 |
| AI | XM-AI：日本 08–10 家宽，手动选择 |
| Meta / Instagram / Threads | XM-Meta：美国节点，手动选择 |
| Bybit | XM-Bybit：澳大利亚或格鲁吉亚，手动选择 |
| Web3 交易与 RPC | XM-Web3：日本 08–10 家宽或日本 01–03，合并为一个手动组 |
| 日常上网、国内直连、Apple、兜底 | 沿用 MESL 基础配置 |

不添加 Mac 的国家切换层级或定时测速，减少手机侧设置。筛选条件使用节点名称中的文字，不依赖国旗显示；其他订阅中同名节点也可能被纳入，应确认成员均来自 MESL。

域名规则最初来自现有六个个人规则集，规则顺序为 RPC → Bybit → Web3 → AI → Google → Meta。规则直接写在模块里，只有 107 条，不需要下载额外规则集。以后直接修改本文件即可；Mac 的 YAML 不会自动覆盖 iOS 模块。客户端的模块自动更新可按需求开启，更新周期和执行时机受客户端及 iOS 后台调度影响，不承诺 Mac 式 15 分钟更新。需要立即更新时在模块菜单手动更新并重新使用/编译配置。

## 核实来源与验证范围

开发者官网为 `https://shadowlaunch.com/`，由 App Store 开发者网站链接确认；官网未提供完整配置语法手册。

- MESL 官方 Shadowrocket 教程：`https://dash.mesurl.com/#/docs/10`，核实先使用官方配置再导入节点的流程。
- `https://github.com/LOWERTOP/Shadowrocket` 为配置示例作者及手册维护者的原始仓库，**不是开发者官方文档**。其原始配置示例提供 select 与 policy-regex-filter 写法，手册说明模块规则优先于基础配置及模块自动更新。

项目校验只确认模块结构、规则策略引用、DNS/节点/通用兜底不被定义，以及当前 MESL 节点名筛选结果。尚未在 iPhone Shadowrocket 编译或验证真实网络路由；首次使用以设备验证为准，勿将静态校验视为 iOS 端测试通过。
