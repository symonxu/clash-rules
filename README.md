# clash-rules

个人 Clash Verge Rev 分流策略与远程规则仓库。

## 当前 Mac 使用方式

- **MESL 完整订阅**：提供节点与升级所需的专用 DNS。Clash Verge Rev 的全局与订阅 DNS 覆写均保持关闭。
- **本 GitHub 仓库**：提供个人策略组、Rule Provider 和 rules。
- **本机同步程序**：每 15 分钟读取固定 V1.3 Raw 文件，只提取 `proxy-groups`、`rule-providers`、`rules`，校验后更新 MESL 订阅扩展脚本并重新加载内核。

同步程序是本机另行安装的任务，不是 Clash Verge Rev 内置远程扩展功能。仅在客户端运行且当前订阅为 MESL 时应用；下载或校验失败时保留当前策略。MESL 订阅地址和 DNS 不受 GitHub 策略更新影响。

本仓库不保存 MESL 订阅地址、节点密码、认证信息或其他私密凭据。

## 当前正式策略入口

`XM-Personal-V1.3.yaml`

Raw：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Personal-V1.3.yaml`

该文件目前作为 Clash Verge Rev 的个人分流策略源使用。其中 DNS 等非路由字段保留为历史完整配置兼容内容，**本机同步程序不会读取或应用这些字段**。不要直接将本文件作为 MESL 完整订阅导入，也不要以它覆写 MESL 专用 DNS。

个人策略与 Shadowrocket 对齐为五个手动组：日常上网、Google、AI、Meta、Web3。Meta 使用美国普通 01–03、家宽 10–12；其余四组使用日本普通 02–04、家宽 08–10。Bybit 与 Web3 交易、RPC 共用 Web3 组，不再使用独立 Bybit 或 Web3 子组。没有定时测速或自动换节点；节点失败时需手动选择。

国内域名及中国大陆 IP 直连，其他未匹配请求走日常上网。固定 V1.3 地址及 MESL 节点/DNS 不变。首次从旧版切换时，请重新确认五组所选节点。

## 当前目录

```text
clash-rules/
├── README.md
├── XM-Personal-V1.3.yaml
└── rules/
    ├── web3-rpc.yaml
    ├── web3.yaml
    ├── ai.yaml
    ├── google.yaml
    ├── meta.yaml
    └── bybit.yaml
```

规则模块用途：

- `web3-rpc.yaml`：Web3 RPC、链上数据相关域名。
- `web3.yaml`：钱包、DEX、交易平台等 Web3 业务域名。
- `ai.yaml`：AI 服务相关域名。
- `google.yaml`：Google 服务相关域名。
- `meta.yaml`：Facebook、Instagram、Threads、Messenger、Muse 及共享 Meta 账户/基础设施域名。
- `bybit.yaml`：Bybit 网站及其 `bybit.com` 子域名，走 `💰 Web3交易` 选择组；与 Web3 共用日本普通 02–04、家宽 08–10。

中国大陆域名规则由 `XM-Personal-V1.3.yaml` 直接引用 Loyalsoldier 规则集；中国大陆 IP 归属由 Clash 内核的 `GEOIP,CN` 规则与自动更新的 GeoIP 数据负责，不额外维护 IP Rule Provider。

V1.3 不定义 Apple 专属路由或 Apple 专属 fake-IP DNS 例外；Apple 流量按通用规则顺序处理，具体走向由域名规则、GeoIP 规则和最终规则决定。

## 更新方式

- 修改 `XM-Personal-V1.3.yaml` 的策略组、Rule Provider 定义或规则顺序：合并到 `main` 后，本机同步任务每 15 分钟检查；通过成员引用、过滤结果和 Mihomo 配置校验后自动加载。休眠或退出客户端期间不立即更新。
- 修改 `rules/*.yaml` 的域名：Mihomo 按对应 Rule Provider 周期刷新，个人规则通常 1 小时、中国大陆域名 24 小时；不保证在上述 15 分钟内刷新域名内容。
- MESL 节点或 DNS 更新：更新 MESL 完整订阅，与本仓库策略同步独立。按 MESL 官网要求，更新前开启订阅的 10 分钟有效窗口。
- 本机扩展只负责个人分流，不设置或修改 DNS。

历史 Hako 使用节点库注入的组合方式。Mac 迁移到 Clash Verge Rev 后，应采用上述完整 MESL 订阅加个人分流扩展的方式。

## 提交校验

Pull Request 和 `main` 更新会检查 YAML、规则引用及仓库中的 URL。新增公开 URL 前，应核对来源并更新 `scripts/validate_rules.rb` 中的允许清单。私有订阅地址不得推送到公开分支；GitHub Actions 在推送后运行，无法撤销已公开的内容。

## 当前版本

**XM-Personal-V1.3**

当前 Mac 使用 Clash Verge Rev，V1.3 固定地址作为个人分流策略源。历史 V1.1 已退役。中国大陆 IP 由 Clash 内核 GeoIP 数据及 `GEOIP,CN,DIRECT` 处理；Apple 使用通用分流规则，DNS 例外由 MESL 原始订阅保留。

## iOS / Shadowrocket

Mac 与 iOS 可分别维护：iOS 使用 MESL 官方 `get.conf` 并通过 [Shadowrocket 个人分流配置](Shadowrocket-iOS.md) 继承其 DNS 和基础策略。固定入口为 `XM-Shadowrocket-Groups.conf`，内含五个手动选择组与个人规则及日常海外兜底；Bybit 共用 XM-Web3 日本节点。旧模块应停用。合并后的 Bybit 命中仍需设备复核。Mac 原 V1.3 地址不变。
