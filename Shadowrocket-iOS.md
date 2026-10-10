# iOS Shadowrocket 使用说明

配置文件：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-Shadowrocket-Slim.conf

## 首次导入 / 更新

1. **先开全局模式**：raw.githubusercontent.com 在大陆直连通常打不开，在首页把路由改成"全局路由 → 代理"并连接。
2. 进入"配置"页，点右上角 ＋，粘贴上面的链接下载。文件名相同，会直接覆盖旧的同名配置。
3. 点选 `XM-Shadowrocket-Slim.conf` 并"使用配置"。
4. 回到首页，把全局路由改回"配置"。
5. 首次使用时远程规则集（广告拦截、Google、Twitter、Telegram 等）也从 raw.githubusercontent.com 下载，如果下载失败，按第 1 步切全局后再更新一次配置。

以后更新：在"配置"页对该配置点"更新"即可（同样建议先切全局）。

## 检查是否生效

- 首页"代理分组"里应只有一个 **XM-日本**，显示为 `FALLBACK`，当前节点为 **🇯🇵 日本 08 家宽**。
- 08 不可用时会自动显示为日本 02 等后备节点，08 恢复后切回。
- 首页的 MESL 订阅保留并照常更新，节点从这里来。

## 推荐设置

- **设置 → 代理 → UDP**：开启"禁用 STUN"，避免 WebRTC 泄露真实 IP。
- **设置 → DNS 覆写**：保留 `223.5.5.5`、`119.29.29.29` 作为备用，即使配置里的 DNS 被覆盖也能正常解析。
- 旧的 `XM-Shadowrocket-Groups.conf`、`XM-Shadowrocket-iOS.sgmodule` 已从仓库删除；手机上如果还有，可以删掉或停用，不要和新配置同时启用模块。

## 节点改名

XM-日本 组里写的是节点完整名称。MESL 如果改了日本节点的名字，组里会少节点（08 家宽改名则会直接跳到后备节点）。出现这种情况时修改 `XM-Shadowrocket-Slim.conf` 的 `[Proxy Group]` 一行即可。

## 参考

- 开发者网站：https://shadowlaunch.com/
- MESL Shadowrocket 教程：https://dash.mesurl.com/#/docs/10
- 第三方配置手册：https://github.com/LOWERTOP/Shadowrocket
