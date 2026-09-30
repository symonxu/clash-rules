# Shadowrocket iOS 专用分流

固定远程模块：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-iOS.sgmodule`

这是个人分流模块，不是节点订阅，也不是完整配置。Mac 仍使用原 V1.3 策略源和本机同步任务，iOS 独立维护此模块，不要求两端策略逐项一致。

## 保留 MESL DNS 的使用方法

设备反馈已确认：单独启用原模块后，代理分组页面仍只有 MESL 原始组，五个 XM 组未出现。原来仅靠模块新增分组的操作方案不成立，不再推荐。

分组扩展配置：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf`

1. 保留已导入且正常使用的 MESL 官方本地配置 `get.conf`，不要删除或改名。文件名来自设备截图；其他文件名需修改扩展配置的 include。
2. 在“配置”页右上角 + 添加上面的 `.conf` 链接，下载后选择新文件“使用配置”。这是配置文件，不能导入到“模块”。
3. 首页全局路由选择“配置”，下拉进入代理分组，先确认五个 XM 组出现且有节点，再启用原 XM iOS 模块并对新配置重新“使用配置”。
4. 按需选择各组节点，检查实际请求命中及 Google、AI、Meta、Bybit、Web3、国内服务。若组不存在、为空或服务异常，停用 XM 模块并切回 `get.conf`。

扩展配置只设置 include、自己的公开更新地址和五个分组，不写 DNS、节点、规则或 FINAL。通过 include 继承本地 MESL 配置；模块提供 107 条个人域名规则。配置继承方式由社区原始手册和示例说明，并非开发者官网的正式文档。新方案仍需设备确认编译后的 DNS、分组和实际路由，不将静态校验视为 iPhone 验证。

MESL 基础配置仍按其官方要求更新；扩展配置和模块可分别更新。不要删除 `get.conf`，不要把私有订阅链接提交到 GitHub。

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
