# Shadowrocket 个人分流配置

供 Mac 与 iOS 的 Shadowrocket 使用。MESL 提供节点与基础配置，GitHub 维护个人分组和域名规则。

固定配置链接：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Groups.conf

仓库地址保留原名，以保证已导入的配置链接继续有效。

| 分组 | 节点范围（每组六个，手动选择） |
| --- | --- |
| XM-Google | 日本普通 02–04、家宽 08–10 |
| XM-AI | 日本普通 02–04、家宽 08–10 |
| XM-Meta | 美国普通 01–03、家宽 10–12 |
| XM-Web3（含 Bybit） | 日本普通 02–04、家宽 08–10 |
| XM-日常上网 | 日本普通 02–04、家宽 08–10 |

保留设备上的 MESL 官方 `get.conf` 和节点订阅，导入并使用上述 XM 配置。XM 配置通过 `include = get.conf` 继承基础配置的 DNS 与策略，个人规则写在 XM 文件中。中国大陆 IP 直连，未命中此前规则的请求由日常上网组兜底。

更新个人规则时，更新 XM 配置并重新使用配置；节点订阅与 MESL 基础配置分别按客户端和服务商提供的方式更新。旧 XM 模块已停用，仅保留文件供兼容，无需重复启用。

[Mac 与 iOS 使用说明](Shadowrocket-iOS.md)

本地静态校验：

```sh
ruby scripts/validate_shadowrocket.rb
```

校验覆盖配置结构、分组与规则引用、固定更新地址和公开链接。线路可用性与实际规则命中以客户端运行结果为准。不要提交私有订阅地址或节点凭据。
