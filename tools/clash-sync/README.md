# Clash 个人策略自动同步

MESL 节点订阅由 Clash Verge Rev 更新；本程序只下载 GitHub 的公开个人策略，使用设备上的 MESL 节点和 DNS 合成配置。安装及本机验收由你执行。开发和 GitHub 测试不会连接你的真实内核、修改 VPN 或读取私有订阅。

固定策略入口保持不变：

https://raw.githubusercontent.com/symonxu/clash-rules/main/XM-ClashVerge-Routing.yaml

该入口只有分组和规则，不能作为普通节点订阅导入。现有五组及 Shadowrocket 的配置与入口均不改变。

## 一次安装

适用当前 macOS Clash Verge Rev 布局：应用在 `/Applications/Clash Verge.app`，配置目录为 `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev`，MESL 是内嵌节点的远程订阅，并有订阅专用扩展脚本。使用系统 `/usr/bin/ruby`（Ruby 2.6 及以上），无需安装第三方库。不兼容的目录、缺失脚本或节点范围会停止应用并提示，不猜测其他客户端的配置。

1. 从 [本仓库](https://github.com/symonxu/clash-rules) 的 Code → Download ZIP 下载并解压。以后需要升级程序时，重新下载并执行安装即可；程序不会自动下载执行远程代码。
2. 自行启动 Clash Verge 并激活现有 MESL 订阅。保持你已验证可用的 TUN、系统代理及 DNS 设置；本程序不切换这些设置。
3. 在终端进入解压目录，例如 `cd ~/Downloads/clash-rules-main`，执行：

```sh
/usr/bin/ruby tools/clash-sync/sync-routing.rb --install
```

安装会识别并绑定 MESL 的本地 UID，将程序复制到 Application Support，备份已有工具与任务文件，停用旧的 `com.xumeng.clash-verge-routing-sync` 任务，再注册唯一的新 LaunchAgent。首次同步在登录任务启动后的检查中进行。不会修改私有订阅地址或代替 Clash 下载 MESL。

安装成功后检查：

```sh
/usr/bin/ruby "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/sync-routing.rb" --status
```

`enabled` 和 `agent_loaded` 应为 `true`。首轮处理完成后，`status` 应为 `current`；`last_checked_at` 是最近成功取得 GitHub 策略的 Unix 时间，`last_applied_at` 是最近实际加载的时间。安装后可删除下载包及桌面的旧手动更新入口，已安装任务仍独立运行；不要删除 Application Support 内的程序和状态目录。

## 更新方式

- 登录后每分钟检查一次；Clash 未运行或当前订阅不是绑定的 MESL 时跳过，不启动客户端、不切换订阅。
- MESL 本地订阅变化时，先等运行配置的节点及 DNS 与新订阅一致，再检查 GitHub 最新策略。Clash 自身生成配置时也会继续执行已保存的个人扩展。
- DNS 检查要求 MESL 提供的每个字段一致；允许 Clash 额外补入 `ipv6` 和 `fake-ip-range6`，并保留其现有值。其他未知 DNS 覆盖仍等待客户端处理。
- GitHub 策略每五分钟检查一次，有效内容变化才应用。无变化时不写扩展脚本或运行配置，不重载内核。
- Clash 重启、重新登录或唤醒后，在下一次检查补做同步。睡眠期间不会运行，也不会阻止整机睡眠。
- 保留仍在候选列表中的组内手动选择，同时设置 `profile.store-selected: true`。只替换 `proxy-groups`、`rule-providers`、`rules`；保留节点、DNS、TUN、模式、端口及其他运行字段。

需要立即检查时，由你执行：

```sh
/usr/bin/ruby "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/sync-routing.rb" --once
```

每组必须恰好匹配六个节点。Google、AI、Web3、日常上网使用日本普通 02–04、家宽 08–10；Meta 使用美国普通 01–03、家宽 10–12。筛选结果不足或超过六个都拒绝应用。当前版本只支持已有三字段结构、空 `rule-providers` 和内联 DOMAIN、DOMAIN-SUFFIX、DOMAIN-KEYWORD、IP-CIDR、IP-CIDR6、GEOIP、MATCH 规则；若以后改为远程规则集，需要先升级程序的校验逻辑。

## 状态与失败处理

| status | 含义 |
| --- | --- |
| current | 最近一次 GitHub 检查成功，个人策略与已加载内核一致 |
| inactive | Clash 未运行，或当前使用其他订阅 |
| waiting_client | MESL 更新尚未完整反映到运行配置，等待下一轮 |
| deferred | 检查期间本地文件变化，本轮未覆盖并发修改 |
| cached_latest_unconfirmed | 下载失败，沿用最近成功策略，尚未取得最新版本 |
| error | 未应用候选策略，或回退仍需处理；查看固定错误提示 |
| not_yet_checked | 尚未完成首轮检查 |

下载、解析、成员筛选和 Mihomo 校验失败都不应用候选策略。离线时可继续使用已成功加载的缓存，状态明确标为未确认最新。重试从一分钟逐步延长到最多十五分钟，成功后恢复每五分钟检查。同一故障首次通知，持续失败不重复提醒，正常运行保持安静。

内核加载失败会恢复此前扩展脚本和运行配置，并恢复仍有效的选择。事务记录用于下次检查继续处理未完成的回退。回退时若发现订阅或配置已被其他操作改动，不覆盖新配置，并提示你重新激活 MESL。

若提示“回退未完整完成”，先在 Clash 中自行重新激活 MESL 并确认连接。若恢复连接后状态仍报回退故障，可暂停任务，保留事务记录供排查，再重新安装：

```sh
/usr/bin/ruby "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/sync-routing.rb" --uninstall
# 仅在已经重新激活 MESL、确认连接正常后，保留并移出旧事务记录。
mv "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/transaction.json" \
   "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/transaction.saved.json"
# 在最新下载包的根目录重新安装。
/usr/bin/ruby tools/clash-sync/sync-routing.rb --install
```

事务文件不存在时无需执行 `mv`。这个恢复步骤由你决定和操作，程序不会自动覆盖存在并发变化的配置。

## 暂停、卸载与恢复

```sh
/usr/bin/ruby "$HOME/Library/Application Support/XM-ClashVerge-RoutingSync/sync-routing.rb" --uninstall
```

停止并移除新 LaunchAgent，解除 MESL UID 绑定；当前个人扩展和已加载路由继续保留，缓存、私有备份及程序也保留。重复执行安全。再次 `--install` 可恢复自动同步；MESL 被删除再重新导入导致 UID 改变时，也先卸载再安装。任务忙于同步时卸载会延期，请稍后再执行。

状态目录：`~/Library/Application Support/XM-ClashVerge-RoutingSync`。`last-backup` 保存最近一次应用前的运行配置和脚本；`installer-backup` 保存旧工具与任务文件；`validated-routing.yaml` 保存最近成功策略。目录权限为 700，写入的状态、缓存和备份权限为 600。旧桌面更新工具不要与自动任务同时使用。

如果要恢复 MESL 服务商原分组及规则，需要你在 Clash 中将 MESL 的订阅扩展脚本恢复为 `function main(config) { return config; }`，然后重新激活 MESL。卸载自动任务本身不会撤销已经使用的个人规则。

程序不上传本机文件，网络请求只访问上述公开策略地址；内核控制只通过本机 Unix socket。状态与通知不输出 URL、密钥、节点凭据或原始错误正文。客户端配置和私有回退副本不要提交 GitHub，也不要直接分享。

## 离线测试与本机验收

在仓库根目录执行：

```sh
ruby scripts/validate_rules.rb
# 或只执行同步程序的隔离测试：
ruby tools/clash-sync/test_sync.rb
```

测试使用临时 HOME、假节点、模拟内核/下载/LaunchAgent；HTTP 协议测试仅连接临时模拟 Unix socket。Mihomo 校验进程和 curl 被替换，不启动真实内核、不访问 MESL、不注册系统任务。覆盖节点变化、策略变化、同时变化、无变化、断网缓存、空组、非法规则、校验失败、加载与回退失败、并发修改、暂停恢复、睡眠时间跨度、安装卸载幂等性和安装失败恢复。现有 GitHub 校验任务在普通及无 UTF-8 区域设置的后台环境分别执行同一套测试；配置和脚本始终明确按 UTF-8 读取。

发布完成不代表本机验收通过。由你验证：

1. 安装后自动同步启用，五个 XM 组出现，每组六个节点。
2. 在 Clash 更新 MESL 后，五组保留，节点和 DNS 使用更新后的 MESL，手动选择仍有效。
3. 修改 GitHub 的一条个人规则后，正常联网时通常五分钟内应用，无需刷新节点或点击桌面文件；失败重试时可能更久。
4. 实测 Google、AI、Meta、Bybit/Web3、国内及普通海外网站，检查规则命中和最终节点。
5. 重启 Clash、重新登录、唤醒后继续同步，下载失败保持现有连接。

本程序不调整电源设置；合盖期间持续联网与唤醒后重连须另外验收。

实现依据：[官方订阅扩展](https://www.clashverge.dev/guide/extend.html)、[官方脚本限制](https://www.clashverge.dev/guide/script.html)。脚本不支持网络和文件 IO，所以公开策略由本地程序下载并校验，再生成保存到订阅扩展中的脚本。
