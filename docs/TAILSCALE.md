# Tailscale 与 Clash Verge

## 用途

macOS（Apple Silicon / Intel）使用 Homebrew 命令行版 Tailscale 访问家庭内网，
Clash Verge Rev 保持 TUN 和系统代理开启，负责 Google/Codex 等公网访问。
Tailscale 不选择出口节点；登录与中继连接使用 Clash 本地代理。

家庭配置：`home.k4i.top`，DNS `192.168.31.2`，子网 `192.168.31.0/24` 与
`192.168.5.0/24`。代理端口默认 `7897`。不保存 Clash 订阅、密码或 Tailscale
登录凭据。

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

3. 生成这台电脑的 Clash 分流脚本并复制：

   ```sh
   python3 config/tailscale/render-clash.py --output /tmp/tailscale-clash.js
   pbcopy < /tmp/tailscale-clash.js
   ```

   在 Clash Verge → Profiles → Global Extend Script → 右键 Edit File，
   粘贴并保存。已有自定义脚本时先合并，不直接覆盖。

生成器自动识别 Tailscale 接口和 MagicDNS 域名，并确认家庭路由确实走
Tailscale。分流脚本让家庭 DNS 和内网请求通过 Tailscale 接口，保留原有
公网代理规则；家庭/Tailscale 网段排除在 Clash TUN 外。
[`clash-verge.js`](../config/tailscale/clash-verge.js) 是模板，使用生成结果。

## 验证

```sh
tailscale status
dig +short nas.home.k4i.top
curl -sS -L -o /dev/null -w '%{http_code}\n' --proxy http://127.0.0.1:7897 --max-time 15 https://nas.home.k4i.top/
curl -sS -o /dev/null -w '%{http_code}\n' --proxy http://127.0.0.1:7897 --max-time 15 https://www.google.com/
```

预期：Tailscale 显示在线设备，NAS 解析为 `192.168.31.248`，两次 HTTPS
检查均返回 `200`。代理端口不同则同步替换验证命令。

## 后续维护

- 重启或其他 VPN 改变接口编号后，重新生成分流脚本并在 Clash 保存。
- Homebrew 升级或重建 Tailscale 服务后，重新应用 `configure-proxy.py`。
- 内网不可达时，确认 `--accept-routes=true`、Clash 正在运行且分流脚本已保存。

## 官方资料

[Tailscale macOS / Homebrew](https://github.com/tailscale/tailscale/wiki/Tailscaled-on-macOS) ·
[Tailscale CLI](https://tailscale.com/docs/reference/tailscale-cli) ·
[Clash Verge 扩展配置](https://www.clashverge.dev/guide/extend.html) ·
[Mihomo DNS](https://wiki.metacubex.one/config/dns/) ·
[Mihomo TUN](https://wiki.metacubex.one/config/inbound/tun/)
