# iOS Clash 使用说明（Clash - 基于规则的网络代理工具）

配置文件（独立于 Mac，不共用）：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash-iOS.yaml

## 和 Mac / Shadowrocket 的关系

- 六个分组、规则（域名、目标组、先后顺序）与 Mac 的 `XM-ClashVerge-Routing.yaml` 完全一致，Apple TV 视频、App Store、iCloud、微信 QQ 等照样直连；CI 会校验两边规则一字不差。
- 区别：Mac 的分组是 select，由本地同步程序选节点；这个 App 跑不了同步程序，所以这里改成自动测速：
  - XM-Google、XM-AI、XM-Meta、XM-Web3、XM-日常上网：`url-test`，每 900 秒测速，快超过 20ms 才切换，超时 5 秒。
  - XM-Bybit：`fallback`，台湾 08 家宽优先，08 失败才用 09。
- 节点不写在文件里：用 `proxy-providers` 里名为 `MESL` 的节点集加载 MESL 订阅，各组按节点名正则（与 Mac 相同）从中筛选。节点集不加前缀，节点名保持 MESL 原样。
- DNS：`223.5.5.5`、`119.29.29.29`，fake-ip；IPv6 关闭。不写 TUN、端口、控制器（App 用 Apple Packet Tunnel 自己管理）。

## 首次导入（按 clash.md 文档的步骤）

订阅地址等同密码，只填在手机里，不要提交到仓库。仓库里 `url` 是占位文字，不填会没有节点。

1. 用代理（例如先用小火箭或蜂窝网络）打开上面的配置链接，把 `XM-Clash-iOS.yaml` 存到"文件"App。raw.githubusercontent.com 在大陆直连通常打不开。
2. 在 Clash 的配置页导入这个本地文件：首页顶部点当前配置名称 → 添加配置（Add Profile）→ 配置文件。
3. 点这个配置后面的感叹号，选"编辑源码"，搜索 `proxy-providers`，把 `MESL` 下 `url` 双引号里的占位文字换成你的 MESL Clash 订阅地址（保留双引号），保存。
4. 回到配置列表选中这个配置，出站模式选"规则（Rule）"，从首页连接。首次会下载节点，稍慢。
5. 到"代理（Proxies）"确认六个组都有节点。

文档出处：
- 导入本地文件、编辑源码、把订阅填进 proxy-providers：https://clash.md/zh/guide/config/best-practice
- 配置列表、添加配置、Rule 模式、代理页、连接页：https://clash.md/zh/guide/ios
- 节点集字段：https://clash.md/zh/guide/config/proxy-providers
- iOS 平台差异（不能按进程分流）：https://clash.md/zh/guide/config/apple-platforms

## 以后更新规则

本地导入的配置不会自动跟随仓库。规则有变化时，重新下载导入新文件，再按第 3 步填一次订阅地址。不建议用"配置地址"导入后再编辑源码：文档没有说明更新远程配置时是否保留手动修改，订阅地址可能被仓库版本覆盖。

## 注意

- 如果 MESL 改了节点名，分组可能筛不到节点，需要改正则（与 Mac 一起改）。
- 检查是否生效：工具（Utilities）→ Current Session → 连接（Connections），看新连接命中的规则和出站组。
