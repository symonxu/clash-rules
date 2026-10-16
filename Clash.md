# Clash App 使用说明（Clash - 基于规则的网络代理工具，iOS 与 Mac 通用）

规则配置链接（iPhone、iPad 和 Mac 上的 Clash App 共用这一份；与 Clash Verge 的文件分开）：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Clash.yaml

## 思路：节点和规则分开导入

- **MESL 订阅**在 App 里单独添加，作为"节点来源"，订阅地址只存在手机上。
- **本文件**用配置链接导入，作为"规则方案"。文件里只有分组、规则和 DNS，没有节点、订阅地址或要手动改的占位，App 按链接更新，仓库改了会自动同步。
- 两者在 App 里组合成一份配置：节点来源选 MESL，规则方案选本文件。

App 的组合方式（以 App 开源代码 https://github.com/ProjectClash/Clash-Client 为准，clash.md 文档页还没写这部分）：规则方案里 `include-all: true` 的分组会引入所选节点来源的全部节点，再按 `filter` 筛选。

## 和 Clash Verge / Shadowrocket 的关系

- 六个分组、规则（域名、目标组、先后顺序）与 Clash Verge 的 `XM-ClashVerge-Routing.yaml` 完全一致，Apple TV 视频、App Store、iCloud、微信 QQ 等照样直连；CI 会校验两边规则一字不差。
- 分组的节点筛选正则与 Clash Verge 相同。Clash Verge 的分组是 select，由本地同步程序选节点；Clash App 不用同步程序，所以这里改成自动测速：
  - XM-Google、XM-AI、XM-Meta、XM-Web3、XM-日常上网：`url-test`，每 900 秒测速，快超过 20ms 才切换，超时 5 秒。
  - XM-Bybit：`fallback`，台湾 08 家宽优先，08 失败才用 09。
- DNS：`223.5.5.5`、`119.29.29.29`，fake-ip；IPv6 关闭。不写 TUN、端口、控制器（App 用 Apple Packet Tunnel 自己管理）。

## 首次设置（iPhone / iPad；Mac 步骤相同，入口见下）

1. **添加 MESL 订阅**：首页顶部点当前配置名称 → 添加配置（Add Profile）→ 配置链接，粘贴 MESL 的 Clash 订阅地址。选中它、出站模式选"规则"并连接（让下一步能打开 GitHub）。
2. **添加规则配置**：同样"添加配置 → 配置链接"，粘贴上面的规则配置链接。若出现"同时登记它的规则"开关，保持打开。App 会把它登记为一个规则方案（规则库里可见）。这份配置单独用时没有节点，不要单独选中它。
3. **组合**：打开 MESL 这份配置的详情，把规则方案换成 `XM-Clash`（"更换规则方案"）；或新建配置时"选择节点来源和规则方案"：节点来源选 MESL，规则方案选 `XM-Clash`。
4. 选中组合后的配置，出站模式选"规则（Rule）"，连接。到"代理（Proxies）"确认六个组都有节点。
5. 查看是否生效：工具（Utilities）→ Current Session → 连接（Connections），看新连接命中的规则和出站组。

Mac 上从侧边栏进入"配置（Profiles）"→"添加配置（Add Profile）"，连接记录在侧边栏 Session → Connections。

第 1、4、5 步出自 clash.md 文档：iOS https://clash.md/zh/guide/ios ，Mac https://clash.md/zh/guide/macos 。第 2、3 步的按钮名称来自 App 开源代码中的中文界面文字，实际位置以手机上的 App 为准。

## 以后更新

- 仓库规则更新后，App 按配置链接更新这份规则配置；需要立即生效时，在规则库对该方案点"刷新规则"，或在配置列表对它点更新。
- MESL 节点照常在 MESL 那份配置里更新。

## 注意

- 订阅地址等同密码，不要提交到仓库，也不要截图外发。
- raw.githubusercontent.com 在大陆直连通常打不开，导入或更新规则配置时要先连着 MESL。
- 如果 MESL 改了节点名，分组可能筛不到节点，需要改正则（与 Clash Verge 一起改）。
- Mac 上不要同时开着 Clash App 和 Clash Verge 的 TUN，两个都会接管系统流量。
- iOS 不能按进程分流：https://clash.md/zh/guide/config/apple-platforms
