# Tailscale 与 Clash Verge

## 用途

macOS（Apple Silicon / Intel）使用 Homebrew 命令行版 Tailscale 访问家庭内网，
外出时 Clash Verge Rev 开启 TUN 和系统代理，负责 Google/Codex 等公网访问；
回家后优先使用 OpenWrt 的透明代理。默认不选择 Tailscale 出口节点。
当前 Tailscale 后台服务的登录、控制与 HTTP 中继连接使用 Clash 本地代理。

家庭配置：`home.k4i.top`，DNS `192.168.31.2`，子网 `192.168.31.0/24` 与
`192.168.5.0/24`。代理端口默认 `7897`。不保存 Clash 订阅、密码或 Tailscale
登录凭据。

## 文档归属

本页记录这台 Mac 的客户端安装、Clash 共存以及在家／外出的切换操作。
家庭网络拓扑、OpenWrt 子网路由、Exit Node、Peer Relay 和 Split DNS 的
权威记录在 `~/repos/home-lab/docs/tailscale/`，不要在两个仓库重复维护服务端配置：

- [家庭 Tailscale 文档](../../repos/home-lab/docs/tailscale/README.md)
- [家庭网络拓扑](../../repos/home-lab/docs/network/README.md)
- [家庭 Exit Node 与 OpenClash](../../repos/home-lab/docs/tailscale/04-exit-node-openclash.md)

以上相对链接按当前 `~/.dotfiles` 与 `~/repos/home-lab` 布局提供；移动仓库后
按对应路径打开。本文的操作针对 Homebrew 命令行版，不依赖 Tailscale 菜单栏应用。

## 在家／外出切换

| 场景 | Clash Verge | Tailscale | 公网出口 |
| --- | --- | --- | --- |
| 在家，日常使用 | 关闭 TUN、系统代理并退出 | `tailscale down` | 家庭 OpenWrt 透明分流 |
| 外出，访问家庭服务 | 开启 TUN 与系统代理 | 开启、接受子网路由、不选 Exit Node | Clash 公网分流，家庭服务走 Tailscale |
| 在家，仍需 Tailnet 访问 | 保留核心运行，关闭 TUN 与系统代理 | 开启、不选 Exit Node；可关闭子网路由 | 家庭 OpenWrt；Tailscale 后台 HTTP 连接仍用本地 Clash |

### 回家：使用家庭 OpenWrt

1. 连接家庭 Wi-Fi，在本机真实终端执行：

   ```sh
   sudo tailscale set --exit-node=
   sudo tailscale down
   ```

   `down` 断开 Tailnet，保留登录与偏好设置，不执行 logout，也不卸载服务。
   该操作会断开经 Tailscale 访问这台电脑的连接，不能在依赖该连接的远程终端中执行。
2. 在 Clash Verge 主界面关闭 **TUN Mode / 虚拟网卡模式** 和
   **System Proxy / 系统代理**，再从菜单栏图标菜单选择 **Quit / 退出**。
   关闭窗口不等于退出，切换后以实际路由和系统代理状态为准。
3. 确认 Wi-Fi 网关为 `192.168.31.2`。在 macOS 系统设置 → Wi-Fi →
   当前网络的“详细信息” → DNS 中，将家庭 DNS 设为 `192.168.31.2`。
   也可在本机终端执行：

   ```sh
   sudo networksetup -setdnsservers "Wi-Fi" 192.168.31.2
   ```

   若网络服务名称不同，先用 `networksetup -listallnetworkservices` 查询再替换。
   此设置作用于 Wi-Fi 网络服务，外出前必须恢复自动 DNS，不能把家庭 DNS
   留在无法访问家庭 LAN 的网络中。
4. 按下面的“在家验证”检查。公网请求应无需显式代理；家庭 NAS 走物理 LAN。

### 外出：Clash 公网代理 + Tailscale 家庭服务

1. 将 Wi-Fi DNS 恢复为 DHCP 自动分配，再连接外部 Wi-Fi 或手机热点：

   ```sh
   sudo networksetup -setdnsservers "Wi-Fi" Empty
   ```

2. 打开 Clash Verge，选择可用配置与节点，开启 TUN 和系统代理，先确认公网可用。
3. 在本机终端执行：

   ```sh
   tailscale-travel
   ```

   命令会启用 Tailscale、接受子网路由与 Split DNS、取消 Exit Node，识别当前
   Tailscale 网卡，备份并刷新 Clash 的家庭分流脚本、热加载配置，在 TUN
   重建后重新安装家庭路由，最后验证 DNS、Flame 直连／经 Clash 访问和公网 HTTPS。
   保留当前 Clash 的 TUN 开关和代理选择；系统代理按第 2 步在应用内开启。
   命令会短暂重建 TUN 和家庭路由，应在这台 Mac 本机运行。
4. 输出应包含五项 `OK`。重启电脑、切换 VPN、Clash 重建 TUN 或家庭访问异常时，
   再运行同一命令，不需要手工寻找 `utun` 编号或复制脚本。

当前守护进程配置依赖 Clash 的 `7897` 端口，所以应先启动 Clash。
首次登录另按“新电脑设置”执行；日常切换不需要重新登录。
命令不持久修改 Wi-Fi DNS；外出前仍须完成第 1 步。

#### 命令安装、检查与备份

[`travel.py`](../config/tailscale/travel.py) 随 `setup.sh` 部署为
`~/.local/bin/tailscale-travel`，Zsh 已将该目录加入 PATH。已有电脑只部署此命令：

```sh
ln -s "$HOME/.dotfiles/config/tailscale/travel.py" "$HOME/.local/bin/tailscale-travel"
tailscale-travel --check
```

若目标文件已存在，先核对其来源，不覆盖未知文件。`--check` 只检查保存的分流
绑定和三个家庭目标的实际路由，不修改配置、不执行端到端测试；不匹配时返回非零。
不带参数会修复并执行完整访问测试。命令使用 Python 3、macOS 自带的 Ruby/Psych
安全解析 YAML，以及本机 Clash Unix socket，无需安装 Python 包。

每次修改前将原始 `profiles/Script.js` 和生成配置 `clash-verge.yaml` 保存到
`~/.local/state/dotfiles-backups/<时间>-tailscale-travel/`，文件权限为 `0600`。
生成配置可能含代理凭据，备份不进 Git，不粘贴完整内容到日志或聊天。
现有全局脚本保留，命令仅添加／刷新带标记的分流段。Clash 拒绝热加载时自动
恢复原文件并尝试重新加载原配置，同时保留热加载前 GUI 的实时 mode/TUN 开关；
服务 socket 失效时继续尝试配置中的自定义 socket。访问测试失败时保留已应用的修复并报告失败项。

如需手工回退，先退出 Clash，将备份目录中的 `Script.js` 复制回应用数据目录
的 `profiles/Script.js`，将 `clash-verge.yaml` 复制回应用数据目录，再启动 Clash。
应用数据目录为 `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/`。

### 在家仍需保持 Tailscale 在线

关闭 Clash 的 TUN 和系统代理，但保留其核心和 `127.0.0.1:7897` 监听，
然后运行：

```sh
sudo tailscale set --exit-node= --accept-routes=false
sudo tailscale up --timeout=30s
```

关闭接受子网路由可避免家庭网段绕经远端路由器，仍保留 Tailnet 设备访问。
Split DNS 可以继续使用。离家后按上一节恢复 `--accept-routes=true`。

如果要彻底退出 Clash 又保持 Tailscale 在线，需要先移除后台服务 plist 中
由 `configure-proxy.py` 写入的代理环境并重启服务，再验证控制／中继连接。
当前脚本只有设置代理功能，没有清除代理模式；不要仅在 shell 中 `unset`
变量，后台服务不会因此改变。本页默认用 `tailscale down` 避免这一依赖。

### 可选：外出全部公网流量经家庭 Exit Node

这与“只访问家庭子网”不同。服务端前置条件见 home-lab 的 Exit Node 指南。
先用 `tailscale status` 核对 `openwrt-pve` 在线且提供出口，再执行：

```sh
sudo tailscale set --exit-node=openwrt-pve --exit-node-allow-lan-access=false
```

关闭 Clash TUN 和系统代理，让默认公网路由由 Tailscale 接管；但当前后台
代理配置仍要求保留 Clash 核心。未清除该配置前，不能直接退出 Clash。
此 Mac 的 Exit Node 模式尚未实测，应检查国内站点、代理站点、家庭服务及
OpenClash 连接日志。无需访问外部 Wi-Fi 的本地设备时保持 LAN access 关闭。
取消出口并恢复常用外出模式：

```sh
sudo tailscale set --exit-node= --accept-routes=true --accept-dns=true
```

随后重新开启 Clash TUN 和系统代理。`tailscale switch` 是切换账号的命令，
不用于在家／外出网络切换。

## 新电脑设置

需要 Homebrew 和 Python 3（仓库的 Xcode / mise 环境均提供）。软件包已列入
`Brewfile`；若尚未安装，在普通终端（tmux 外）执行：

```sh
brew install --formula tailscale
brew install --cask clash-verge-rev
```

1. 打开 Clash Verge，导入自己的代理配置，确认公网代理可用，开启 TUN 和系统代理。
2. 启动 Tailscale、配置登录代理，然后用原来的账号完成浏览器登录：

   ```sh
   cd ~/.dotfiles
   sudo brew services start tailscale
   sudo python3 config/tailscale/configure-proxy.py --apply
   sudo tailscale up --timeout=30s
   sudo tailscale set --accept-routes=true
   ```

   如果 Clash 端口不同，在 configure-proxy 命令中添加
   `--proxy-url http://127.0.0.1:实际端口`。不加 `--apply` 时只检查；应用前
   自动备份服务配置，重启失败自动恢复。sudo 密码只在本人终端输入。

3. 完成 `setup.sh` 部署后，运行 `tailscale-travel` 自动安装分流并验证。
   如尚未部署命令，可运行 `python3 ~/.dotfiles/config/tailscale/travel.py`。
   全局脚本需要已有 `function main(config)` 入口，Clash 默认即提供此入口。

   手工维护扩展脚本时，仍可生成这台电脑的脚本并复制：

   ```sh
   python3 config/tailscale/render-clash.py --output /tmp/tailscale-clash.js
   pbcopy < /tmp/tailscale-clash.js
   ```

   在 Clash Verge → Profiles → Global Extend Script → 右键 Edit File，
   粘贴并保存。已有自定义脚本时先合并，不直接覆盖。

生成器自动识别 Tailscale 接口和 MagicDNS 域名，并确认家庭路由确实走
Tailscale；路由丢失时先用 `tailscale-travel` 修复，生成器本身只读。
分流脚本让家庭 DNS 和内网请求通过 Tailscale 接口，保留原有公网代理规则；
家庭/Tailscale 网段排除在 Clash TUN 外。
[`clash-verge.js`](../config/tailscale/clash-verge.js) 是模板，使用生成结果。

## 验证

### 在家验证

```sh
tailscale status
networksetup -getdnsservers "Wi-Fi"
route -n get default
route -n get 1.1.1.1
route -n get 192.168.31.248
scutil --proxy
dscacheutil -q host -a name nas.home.k4i.top
curl --noproxy '*' -fsSL --connect-timeout 10 --max-time 30 \
  -o /dev/null -w '%{http_code}\n' https://chatgpt.com/codex/install.sh
```

默认在家模式下 Tailscale 显示已停止；DNS 为 `192.168.31.2`，公网路由的
网关为 `.2`、接口为 Wi-Fi（通常 `en0`），NAS 走物理 LAN；系统代理未启用。
NAS 解析为 `192.168.31.248`，安装脚本下载应返回 `200`。
若公网仍走 `198.18.0.1` / Clash 的 `utun`，说明本地 TUN 尚未退出。
若仍解析到 fake-IP，先确认 DNS 与 TUN 状态，避免把本地 fake-IP 交给 OpenWrt。

### 外出验证

```sh
tailscale-travel --check
tailscale status
dig +short @100.100.100.100 flame.nas.home.k4i.top
curl -sS -L -o /dev/null -w '%{http_code}\n' --proxy http://127.0.0.1:7897 --max-time 15 https://flame.nas.home.k4i.top/
curl -sS -o /dev/null -w '%{http_code}\n' --proxy http://127.0.0.1:7897 --max-time 15 https://www.google.com/
```

预期：检查通过，Tailscale 显示在线设备，Flame 解析为 `192.168.31.248`，两次 HTTPS
检查均返回 `200`。代理端口不同则同步替换验证命令。
macOS 的普通 `dig 域名` 不按系统域名专用 resolver 选择 Split DNS，故这里明确
查询 Tailscale DNS；应用实际解析路径由 HTTPS 直连检查覆盖。

2026-10-29 已在外部网络实际验证：Tailscale 使用 `utun0`，旧 Clash 家庭分流却
绑定 `utun7`（当时已变成 Clash TUN），同时 `192.168.31.0/24` 路由丢失。
重建家庭路由后 DNS 与 Flame 直连恢复；刷新绑定并在 TUN 重建后恢复路由后，
Flame 经 Clash 和公网 Google 均返回 `200`。客户端已接受路由、服务端已批准路由，
不代表本机路由表一定仍有对应条目。

## 后续维护

- 重启或其他 VPN 改变接口编号后，运行 `tailscale-travel` 自动刷新和验证。
- Homebrew 升级或重建 Tailscale 服务后，重新应用 `configure-proxy.py`。
- 外出时内网不可达，先运行 `tailscale-travel --check`，再用 `tailscale-travel` 修复。
  若路由仍无法安装，到 Tailscale 后台确认家庭两个网段的批准状态；若需要登录或
  管理权限，按提示在本机真实终端处理，不向脚本或聊天提供密码。
- Clash 升级后提示找不到控制接口，确认核心已启动；命令支持新版 service socket
  和旧版生成配置中的 Unix socket。全局脚本标记损坏或 fake-IP 使用其他过滤模式时
  命令会停止，先人工检查，避免覆盖现有特殊配置。
- 回家后公网异常，先确认本地 TUN／系统代理已经关闭，网关与 DNS 指向家庭 OpenWrt。
- 退出 Clash 后 Tailscale 控制／中继连接失败，检查后台服务的代理依赖；不要把退出
  Clash 当成同时清除了 tailscaled 的代理配置。

## 官方资料

[Tailscale macOS / Homebrew](https://github.com/tailscale/tailscale/wiki/Tailscaled-on-macOS) ·
[Tailscale CLI](https://tailscale.com/docs/reference/tailscale-cli) ·
[Tailscale Exit Nodes](https://tailscale.com/docs/features/exit-nodes) ·
[Clash Verge 扩展配置](https://www.clashverge.dev/guide/extend.html) ·
[Mihomo 本地 API](https://wiki.metacubex.one/api/) ·
[Mihomo DNS](https://wiki.metacubex.one/config/dns/) ·
[Mihomo TUN](https://wiki.metacubex.one/config/inbound/tun/)
