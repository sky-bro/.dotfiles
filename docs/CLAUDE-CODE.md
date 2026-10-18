# Claude Code 与 DeepSeek

## 个人约定

- Claude Code 使用 Anthropic 官方原生安装器，安装于 `~/.local/bin/claude`。原生安装会在后台自动更新，不再通过 npm 或 Homebrew 安装第二份。
- API 后端使用 DeepSeek 官方 Anthropic 兼容端点 `https://api.deepseek.com/anthropic`，默认模型为价格较低的 `deepseek-flash`。Opus、Sonnet、Haiku 别名和子代理也映射到 Flash，避免 Claude Code 自动选择更贵的 `deepseek-v4-pro`。
- DeepSeek 官方建议 Claude Code 使用 `deepseek-flash[1m]`、`max` effort 和 786432 token 自动压缩窗口，本配置遵循该组合。较长上下文和 Web Search 仍会增加 token 消耗；测试时使用小任务并在 DeepSeek 控制台查看余额。
- API Key 不进入仓库、shell profile 或 Claude settings。它保存在 macOS 登录钥匙串中，Claude Code 通过 `apiKeyHelper` 读取并以 `X-Api-Key` 发送；DeepSeek 的 Anthropic 兼容接口支持该 header。
- 由 Sesswitch 安装器单独生成的用户级 Claude hooks 把 session 生命周期、状态和可验证的终端坐标发送给 `~/repos/sesswitch/bin/sesswitch`。hook 不读取 prompt、工具参数或 transcript 内容；Sesswitch 仅保存 session ID、cwd、可选标题、状态和进程/终端坐标。

## 安装与应用

从官方原生安装器安装 Claude Code：

```sh
curl -fsSL https://claude.ai/install.sh | bash
claude --version
```

先审查 dotfiles 将发生的变化，再应用 Claude settings 和密钥录入脚本：

```sh
./setup.sh --check
./setup.sh --apply
```

在真实终端录入或替换 DeepSeek API Key。`security` 自己读取密钥，输入不会回显，密钥不会出现在命令参数中：

```sh
store-deepseek-key
```

Sesswitch hooks 含本机可执行文件的绝对路径，不放入可复用的 settings 模板。
先应用 dotfiles，再在已构建 Sesswitch 的机器上安装 hooks：

```sh
cd ~/repos/sesswitch
make install-claude-hook
```

安装器会备份 settings，并将其写为包含 hooks 的本机文件；再次运行 setup 时
应审查该文件的替换提示，应用后重新运行 hook 安装器。

## 验证

```sh
claude --version
claude doctor
security find-generic-password -a "$USER" \
  -s com.sky.dotfiles.deepseek-api >/dev/null
claude -p "只回复：DeepSeek Claude Code 配置成功"
~/repos/sesswitch/bin/sesswitch list --json | jq '[.[] | select(.provider == "claude")]'
```

`claude -p` 命令会产生少量 API 费用。正常响应表示 Claude Code 已通过 DeepSeek Anthropic 兼容接口调用 Flash。首次交互式运行仍可能显示工作区信任或 API Key 使用确认；按屏幕说明确认即可。进入 Claude Code 后可用 `/status` 检查设置来源与模型。
运行一次 Claude 会话后，Sesswitch 列表应出现 `claude:<session-id>`；在 tmux 或 WezTerm CLI 中运行时还应带有 `location`。

## 费用控制

DeepSeek 按输入和输出 token 扣费，并区分缓存命中、缓存未命中以及峰谷时段。`deepseek-flash` 明显低于 Pro，且 Claude Code 的重复系统提示可受益于缓存。余额较少时：

- 优先提出边界明确的小任务，完成后使用 `/clear` 开始新任务；
- 避免无必要的 Web Search，搜索结果总结会产生额外模型调用；
- 不把默认模型切换成 Opus 或 `deepseek-v4-pro`；
- 在 DeepSeek 控制台定期检查余额和调用明细。

## 故障排查

- `claude: command not found`：确认 `~/.local/bin` 在 PATH 中，重新打开终端；必要时重新运行官方安装器。
- `apiKeyHelper` 失败或返回 401：重新运行 `store-deepseek-key`，再用上面的 `security find-generic-password` 检查条目是否存在。不要把密钥粘贴到日志或聊天中。
- 请求仍然访问 Anthropic：运行 `/status` 检查加载的 user settings，并确认 `~/.claude/settings.json` 指向仓库配置。
- 余额消耗过快：退出长会话，检查是否触发 Web Search 或大规模子代理任务，并在 DeepSeek 控制台核对 token 用量。
- 临时改回 Anthropic：先移除或覆盖用户 settings 中的 DeepSeek endpoint 与模型配置，再按 Claude Code 官方登录流程认证。保留钥匙串条目不会自行触发调用。
- Sesswitch 没有 Claude 条目：确认 `~/repos/sesswitch/bin/sesswitch` 已构建且可执行，随后在 Claude Code 中用 `/hooks` 检查用户级 hooks。Claude 历史目前不会被扫描，只有安装 hooks 后启动或恢复过的 session 会进入列表。

## 官方资料

- [Claude Code quickstart](https://code.claude.com/docs/en/quickstart)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Claude Code authentication](https://code.claude.com/docs/en/authentication)
- [DeepSeek 接入 Claude Code](https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code/)
- [DeepSeek Anthropic API](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api/)
- [DeepSeek 模型与价格](https://api-docs.deepseek.com/zh-cn/quick_start/pricing/)
