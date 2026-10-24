# Codex CLI

## 个人约定

- 使用 OpenAI 官方独立安装器，命令入口为 `~/.local/bin/codex`，程序包位于 `~/.codex/packages/standalone/`。
- 不通过 npm、mise 或 Homebrew 安装第二份，避免 Node 切换影响 Codex 或 PATH 选中不同版本。
- 登录、配置、hooks 和会话仍由 Codex 的用户目录管理；迁移不删除 `~/.codex`。
- macOS shell profile 将 `~/.local/bin` 加入 PATH。setup 不自动运行远程安装器，安装与更新是明确的单独步骤。

## 安装与更新

```sh
(
  set -eu
  installer=$(mktemp -t codex-install)
  trap 'rm -f "$installer"' EXIT
  curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 \
    https://chatgpt.com/codex/install.sh -o "$installer"
  sh "$installer"
)
~/.local/bin/codex --version
```

更新使用同一官方安装器。自动化时可使用 `CODEX_NON_INTERACTIVE=1` 跳过提示；它不会自动卸载发现的旧安装。

从 npm 迁移时，先验证独立版，再在原来安装 Codex 的 Node 环境中执行：

```sh
npm uninstall -g @openai/codex
rehash
type -a codex
codex --version
```

mise 管理多个 Node 版本时，npm 全局包属于各自的 Node 安装目录，需按旧安装的实际位置清理。不要删除整个 Node 环境或 Codex 用户目录。

## 验证与故障排查

```sh
~/.local/bin/codex --version
zsh -n ~/.zshrc
type -a codex
codex --version
```

`codex` 应解析为 `~/.local/bin/codex`。若当前 shell 缓存了旧命令，运行 `rehash` 或重新打开终端。

### 更新时 TLS 失败或误报成功

`curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL` 表示 TLS 连接失败，
仅凭这条信息不能认定是证书问题。检查 Clash 是否运行、代理节点及分流是否可用。
macOS 系统代理开启不代表命令行 curl 自动使用它；TUN 可以接管连接，但更新时
家庭 LAN 正常情况下应由 OpenWrt 透明分流，无需设置代理环境变量。
下面的显式代理仅用于应急或对比测试，不是日常更新的前提。
当前端口为 `7897`，实际端口不同时同步替换：

```sh
(
  set -eu
  export https_proxy=http://127.0.0.1:7897
  export http_proxy=http://127.0.0.1:7897
  installer=$(mktemp -t codex-install)
  trap 'rm -f "$installer"' EXIT
  curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 \
    https://chatgpt.com/codex/install.sh -o "$installer"
  CODEX_NON_INTERACTIVE=1 sh "$installer"
)
~/.local/bin/codex --version
```

代理环境只作用于这次更新，也会传给安装器内部的下载命令；不全局改变内网流量。
不要用 `curl -k` 绕过证书验证。安装器会校验程序包的 SHA-256。

旧版自更新使用 `sh -c 'curl ... | sh'` 时，管道默认返回最后一个命令的状态。
curl 下载失败后，sh 执行空输入仍可能返回 0，导致界面显示成功。
上述分步下载会在失败时停止；升级后仍需检查实际版本并重启 CLI。

2026-10-09 排查：原独立版为 `0.160.1`，官方 latest 元数据为 `0.162.0`；
当时直接下载已恢复，通过本地代理下载脚本和版本元数据均返回 HTTP 200。
DNS 返回 `198.18.0.0/15` 中的地址，与 Clash fake-IP 接管相符；原始瞬时失败
未能复现，无法据此确定是节点、TUN 还是上游连接中断。
随后通过上述代理运行官方安装器成功升级到 `0.162.0`；命令路径、current
符号链接与实际版本一致，`zsh -n ~/.zshrc` 通过。

结合 `~/repos/home-lab/docs/network/` 进一步核验：当前 Mac 为
`192.168.31.49`，Wi-Fi 网关是 `192.168.31.2`，但本地 Clash TUN 在
`utun6` 上安装了更具体的公网路由，普通 curl 先进入本地 TUN。Wi-Fi DNS
显式设置为 `114.114.114.114`；公网查询当前被 TUN 接管并返回 fake-IP。
OpenWrt 则运行 `redir-host`，返回真实 IP，且该 Mac 不在绕过列表中。

绑定 `en0`，用 OpenWrt 的 DNS 结果对 `chatgpt.com` 和重定向目标
`releases.openai.com` 同时设置单次 `--resolve`，并用 `--noproxy '*'`
禁用显式代理后，完整安装脚本下载返回 HTTP 200。OpenClash 日志确认
两个域名分别命中 `DomainSuffix(chatgpt.com)` 和 `DomainSuffix(openai.com)`，
均使用 `auto[trojan-us]`。这证明家庭 OpenWrt 透明代理路径可用。

诊断时仅绑定 Wi-Fi、不处理本地 TUN DNS 并不足以隔离路径：本次测试
在重定向后把本地 fake-IP `198.18.0.212` 发给 OpenWrt，出现 TLS 超时。
应同时隔离路由和 DNS；测试用的 `--resolve` 不应固化为长期配置。
普通不设置代理的 curl 也已返回 HTTP 200，但实际来源为本地 TUN
`198.18.0.1`，不能用它证明经过了家庭网关的透明接管。

如需在家庭 LAN 统一由 OpenWrt 接管，先另行确认停止本地 Clash TUN、
关闭系统代理并将 Wi-Fi DNS 交给 `192.168.31.2` 的方案及 Tailscale 共存
需求；具体切换步骤见 [Tailscale 与 Clash](TAILSCALE.md#在家外出切换)。
当前 tailscaled 后台服务可能配置了本地 Clash 代理；在家默认先断开 Tailscale
再退出 Clash，需要保持 Tailnet 在线时则保留 Clash 核心、仅关闭 TUN 和系统代理。
本次排查仅做只读检查，没有修改这些网络设置。离家时仍需可用的本地代理
或家庭 Tailscale Exit Node，单独的家庭子网路由不承载公网出口。

从 Finder 或登录项启动的 Vicinae 不一定继承 `.zshrc` 中的 PATH；独立安装并不自动解决所有 GUI 环境差异。当前可在正常终端运行 `vicinae server --replace`。Sesswitch 的长期方案应统一处理 agent 和宿主工具的可执行文件、PATH 与运行时配置，见 [Vicinae 与 Sesswitch](VICINAE.md)。

## 官方资料

DeepSeek Harness 可通过 pi-ai 的 Codex OAuth 作为主模型接入，或通过官方
Codex 子代理插件调用 app-server；认证、费用区别与安装约定见
[DeepSeek Harness](DSH.md#codex-与订阅)。

- [Codex CLI 安装与使用](https://learn.chatgpt.com/docs/codex/cli)
