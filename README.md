# clash-rules

个人 Clash / Hako 规则方案仓库。

当前采用 **节点源与规则方案分离** 的架构：

- **节点库**：MESL 节点订阅，由 Clash / Hako 客户端独立管理。
- **规则库**：从本仓库导入 `XM-Personal-V1.1.yaml`。
- **实际配置**：在客户端创建配置时，同时选择 MESL 节点源与本仓库规则方案，由客户端组合生成。

本仓库不保存 MESL 订阅地址、节点密码、认证信息或其他私密凭据。

## 当前规则方案

正式入口：

`XM-Personal-V1.1.yaml`

Raw：

`https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Personal-V1.1.yaml`

该文件负责 DNS、策略组、规则顺序以及远程 Rule Provider 定义，不直接包含代理节点。

## 目录

```text
clash-rules/
├── XM-Personal-V1.1.yaml
└── rules/
    ├── web3-rpc.yaml
    ├── web3.yaml
    ├── ai.yaml
    ├── google.yaml
    └── apple-direct.yaml
```

规则模块用途：

- `web3-rpc.yaml`：Web3 RPC、链上数据相关域名。
- `web3.yaml`：钱包、DEX、交易平台等 Web3 业务域名。
- `ai.yaml`：AI 服务相关域名。
- `google.yaml`：Google 服务相关域名。
- `apple-direct.yaml`：适合直连的 Apple 服务；App Store 下载相关域名不强制直连。

中国大陆域名与 IP 规则由 `XM-Personal-V1.1.yaml` 直接引用 Loyalsoldier 规则集，不在本仓库重复维护。

## 更新方式

### 仅修改 rules/ 下的规则

在 Clash / Hako 中更新规则库或远程规则集即可，不需要更新 MESL 节点源，也不需要重新创建组合配置。

### 修改 XM-Personal-V1.1.yaml

如果修改 DNS、策略组、Rule Provider 定义或规则顺序等规则方案结构，应在客户端更新规则方案；必要时重新创建由 **MESL + XM-Personal-V1.1** 组合的实际配置。

### MESL 节点变化

MESL 独立更新，与本 GitHub 仓库无关。

## 当前版本

**XM-Personal-V1.1**

V1.1 为当前稳定基线。没有明确需要时，不修改其整体架构；日常域名增删优先维护 `rules/` 下对应模块。
