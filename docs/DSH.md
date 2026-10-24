# DeepSeek Harness（dsh）

## 个人约定

- 使用 DeepSeek 官方 npm 包 `@deepseek-ai/dsh`，安装前缀为 `~/.local`，命令为 `~/.local/bin/dsh`。Node.js 由 mise 管理，不另装运行时。
- dsh 独立安装，不触发整套 setup；尤其保留包含 Sesswitch hooks 的本机 Claude settings。
- dsh 仍为开发预览，升级可能不兼容。先在独立工作目录试用，Web 服务仅监听本机；不自动启用后台服务。
- 凭据和会话保留在 dsh 用户目录，不加入 dotfiles。不要复制 Codex token 到仓库或聊天。

## 安装与更新

```sh
node --version
npm install --global --prefix "$HOME/.local" @deepseek-ai/dsh@0.2.1-rc.2 \
  --registry=https://registry.npmjs.org
rehash
dsh --version
dsh --help
```

npm 11 若提示安装脚本被跳过，先核对提示的包，再为已安装的原生依赖完成初始化；不全局关闭脚本限制：

```sh
npm rebuild --global --prefix "$HOME/.local" \
  @deepseek-ai/dsh-subprocess-local koffi node-pty protobufjs \
  --allow-scripts=@deepseek-ai/dsh-subprocess-local,koffi,node-pty,protobufjs
```

`@google/genai` 的 preinstall 仅为 no-op，本次未放行。

2026-10-19 查询的 npm `latest` 为 `0.2.1-rc.2`。更新前核对官方发布信息，再显式指定版本运行相同命令。使用官方 npm 源，不设置镜像。现有 shell profile 已将 `~/.local/bin` 加入 PATH；setup 不重复安装 npm 全局包。

在目标工作目录启动：

```sh
dsh web --no-open
```

按终端显示的本机 URL 打开 Web UI（默认 `http://127.0.0.1:3080`），退出使用 Ctrl-C。不要从含有不必要敏感文件的目录启动。

## Codex 与订阅

可以采用两种集成，认证和主 agent 费用要分别理解：

- **Codex 作为主模型（当前选择）**：通过官方 `dsh-llm-pi-ai` 的 `openai-codex` 路由使用 ChatGPT 订阅，默认 `gpt-6.1-sol`、`medium` 推理强度，与本机 Codex 的模型名一致。它运行 dsh 的工具与会话循环。配置模板为 [`config/dsh/codex.patch.yml`](../config/dsh/codex.patch.yml)，关闭 DeepSeek 模型路由，避免误选需要另外付费的 API。
- **Codex 作为子代理**：官方 `@deepseek-ai/dsh-subagent-codex` 将任务交给真正的 Codex app-server，并遵循原生 Codex 认证。它自带固定版本的 Codex 运行时，不使用 PATH 中的独立版作为后备；确需安装时先检查插件版本及文档。父 agent 若使用 DeepSeek API，仍独立产生 DeepSeek 费用。

OpenAI app-server 支持 ChatGPT 托管登录和订阅账户限额查询。使用订阅必须走受支持的 ChatGPT 登录流程；普通 OpenAI API Key 属于另一种认证方式。实际模型权限、可用额度和成功调用须以账户及一次完成的请求为准。安装检查不自动发起模型请求或消耗额度。

### 应用主模型配置

先检查 `~/.dsh/profiles/web/cordis.patch.yml`。新建的空 profile 可备份后复制模板；已有其他自定义项时，应按 id 合并而不是覆盖。不要把含凭据的文件提交到仓库。

```sh
cp ~/.dsh/profiles/web/cordis.patch.yml ~/.dsh/profiles/web/cordis.patch.yml.before-codex
cp config/dsh/codex.patch.yml ~/.dsh/profiles/web/cordis.patch.yml
```

2026-10-19 已应用 Web profile，原文件备份为同目录的
`cordis.patch.yml.before-codex-20261019-235614`。这个配置由 dsh 自己维护，
不由 setup 链接，模型选择可以继续通过 Web UI 保存。

### 登录订阅

当前 Web 页面尚缺少完整的第三方通用登录入口。仓库提供一个小型登录命令，
调用已安装的官方 pi-ai Codex OAuth 实现，并通过 dsh 官方凭据服务保存授权。
不安装第三方认证包，不复制或修改 Codex CLI 登录文件。

```sh
node ~/.dotfiles/config/dsh/codex-login.mjs status
node ~/.dotfiles/config/dsh/codex-login.mjs login --device
```

在浏览器打开命令显示的地址，输入设备码，用订阅账户授权。账户若禁用了设备
授权，可改用 `login`（不加 `--device`）走浏览器回调。需要手工输入回调信息时
请在真实终端操作。授权存入 `$DSH_HOME/.credentials.yaml`，默认 `~/.dsh`；
pi-ai 在调用时负责刷新。`codex-device-id` 保存非敏感安装标识。

```sh
dsh web
```

新会话应默认选中 `gpt-6.1-sol`。已有会话仍使用其历史模型选择，应新建会话。
退出 dsh 的 Codex 登录使用 `node ~/.dotfiles/config/dsh/codex-login.mjs logout`，
不影响独立 Codex CLI。辅助脚本依赖 `0.2.1-rc.2` 安装布局，升级后需重新验证。

## 验证与故障排查

2026-10-19：`dsh --version` 返回 `0.2.1-rc.2`，CLI 和 Web 帮助均通过。
临时启动 `dsh web --no-open --host 127.0.0.1 --port 0` 后，未认证请求
返回 HTTP 401，启动链接经认证重定向后返回 HTTP 200。未发起模型请求。
本机 `codex login status` 显示 `Logged in using ChatGPT`，此状态不能替代
dsh 主模型的独立 OAuth 授权验证。

2026-10-20：设备授权成功保存，`codex-login.mjs status` 确认 dsh 已配置
OAuth。使用 `openai-codex / gpt-6.1-sol`、`medium` 完成真实订阅请求，
返回 `DSH_CODEX_OK`。首次 headless 测试报
`PI_AI_ERROR: Provider is not configured: openai-codex`，原因是官方
headless bundle 默认禁用了 `credentials`，而 Web profile 没有禁用。
测试时在临时 patch 中追加以下条目后成功，无需重新登录：

```yaml
- id: credentials
  disabled: false
  config:
    watch: false
```

若要在 headless 中使用同一登录，需要显式启用该服务；仅传入模型配置
不足以加载本地 OAuth。一次性任务应同时关闭凭据文件 watcher，避免已输出
答案后进程仍因 watcher 保持运行；本次测试输出成功后由 Ctrl-C 关闭。
日常 `dsh web` 直接使用已部署的 Web profile。

```sh
type -a dsh
dsh --version
dsh --help
dsh web --help
```

- 命令不存在：确认 `~/.local/bin` 在 PATH，运行 `rehash`。mise 更新 Node 后仍需有可用的 `node`。
- npm 超时：检查网络及代理。完整包索引可能较大，可用 `curl -fsSL https://registry.npmjs.org/@deepseek-ai/dsh/latest` 检查官方元数据端点。不要绕过 TLS 校验。
- Codex provider 存在但不能请求：确认已完成 OAuth，而非仅添加 provider；检查登录状态和账户额度，不手工粘贴 token。
- 端口冲突：查看 `dsh web --help` 并选择其他本机端口。
- 升级破坏插件：核对 dsh 与插件发布版本，按官方迁移说明处理；不要删除凭据和会话目录来试错。

## 官方资料

- [项目与运行方式](https://github.com/deepseek-ai/deepseek-harness)
- [Web UI](https://deepseek-harness.github.io/deepseek-harness/en/guide/quickstart)
- [模型配置](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/user/guide/providers.md)
- [pi-ai 登录与适配器](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/llm/llm-pi-ai/README.md)
- [Codex 子代理](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/subagent/subagent-codex/README.md)
- [Codex app-server 与认证](https://learn.chatgpt.com/docs/app-server)
- [安全说明](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md)
