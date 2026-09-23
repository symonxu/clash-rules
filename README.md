# clash-rules

个人 Clash / Hako 规则仓库。

当前采用 **节点库与规则库分离** 的架构：

- **节点库**：MESL 节点订阅，由 Hako 独立管理。
- **规则库**：从本仓库导入 `XM-Personal-V1.1.yaml`。
- **个人配置**：Hako 将所选节点库与规则库组合使用；个人配置本身不是第三个远程订阅源。

本仓库不保存 MESL 订阅地址、节点密码、认证信息或其他私密凭据。

## 当前正式入口

`XM-Personal-V1.1.yaml`

Raw：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Personal-V1.1.yaml`

该文件负责 DNS、策略组、Rule Provider 定义和规则顺序，不直接包含代理节点。

## 当前目录

```text
clash-rules/
├── README.md
├── XM-Personal-V1.1.yaml
└── rules/
    ├── web3-rpc.yaml
    ├── web3.yaml
    ├── ai.yaml
    ├── google.yaml
    ├── meta.yaml
    ├── apple-proxy.yaml
    └── apple-direct.yaml
```

规则模块用途：

- `web3-rpc.yaml`：Web3 RPC、链上数据相关域名。
- `web3.yaml`：钱包、DEX、交易平台等 Web3 业务域名。
- `ai.yaml`：AI 服务相关域名。
- `google.yaml`：Google 服务相关域名。
- `meta.yaml`：Facebook、Instagram、Threads、Messenger、Muse 及共享 Meta 账户/基础设施域名。
- `apple-proxy.yaml`：需要通过日常代理访问的 Apple / App Store 例外域名。
- `apple-direct.yaml`：适合直连的 Apple 服务。

中国大陆域名与 IP 规则由 `XM-Personal-V1.1.yaml` 直接引用 Loyalsoldier 规则集，不在本仓库重复维护。

## 更新方式

- 修改 `rules/*.yaml`：对应 Rule Provider 远程刷新即可。
- 修改 `XM-Personal-V1.1.yaml`：在 Hako 更新“规则库”，现有个人配置会继续从该规则库取得策略组、Rule Provider 和 rules 结构；不把个人配置当作独立远程订阅。
- MESL 节点变化：只更新节点库，与本 GitHub 仓库独立。

## 当前版本

**XM-Personal-V1.1**

这是当前已验证使用的稳定基线。没有明确故障证据时，不重构整体架构。
