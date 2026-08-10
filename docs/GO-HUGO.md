# Go 与 Hugo

## 个人约定

Go 运行时由 mise 管理，并在
[`config/mise/config.toml`](../config/mise/config.toml) 中声明全局默认版本。
这里使用 `latest` 与仓库已有的 Node/uv 策略保持一致；具体项目应在项目自己的
`mise.toml` 或 `.go-version` 中固定 Go 版本，避免升级影响构建。

每次 mise 安装新的 Go 版本时，`postinstall` 会同时安装：

- `gopls`：语言服务器、格式化、导入整理和代码导航；
- `dlv`：Delve 调试器；
- `staticcheck`：静态分析。

这些工具安装到 mise 管理的 Go 版本目录，不额外维护 `~/.default-go-packages`。
Go 模块缓存继续使用默认的 `~/go/pkg/mod`；开发项目不要求放在 `GOPATH` 下。
私有模块地址或凭据属于机器/项目环境，不写入公共 dotfiles。

Hugo 由 Homebrew 安装。Homebrew 当前提供 Hugo extended/deploy edition，支持
Hugo Modules；项目需要较新 Sass 特性时应按项目单独声明 Dart Sass 或前端工具，
而不是全局隐式安装。

VS Code 使用官方 `golang.go` 扩展，保存 Go 文件时由 gopls 格式化并显式整理
imports，同时启用 semantic tokens 与完整 Staticcheck analyzers。由于 mise 已
随 Go 安装 `gopls`、`dlv` 和 `staticcheck`，VS Code 只检查最低工具版本，不自动
更新它们，也不再额外启动一份客户端 Staticcheck。工作区仍应使用 Go Modules，
并提交 `go.mod` 与 `go.sum`。

## 安装与应用

先审查 dry-run：

```sh
./setup.sh --check
```

确认后安装 Homebrew 软件、mise 运行时和 VS Code 扩展，并应用链接：

```sh
./setup.sh --install-packages --apply
exec zsh
```

## 验证

```sh
go version
go env GOPATH GOMODCACHE
gopls version
dlv version
staticcheck -version
hugo version
code --list-extensions | grep '^golang.go$'
mise current go
```

`hugo version` 应包含 `extended`。创建一次性测试站点时使用临时目录，不要把测试
内容写入 dotfiles 仓库。

## 常用操作

```sh
go mod init example.com/project
go test ./...
go vet ./...
staticcheck ./...
hugo new site my-site
hugo server -D
```

## 故障排查

- `go: command not found`：执行 `mise current go` 和 `mise install go`，再用
  `exec zsh` 重新载入 mise activation。
- VS Code 找不到 `gopls` 或 `dlv`：在终端确认对应版本命令可用，然后执行
  “Developer: Reload Window”；也可在命令面板运行 “Go: Locate Configured Go
  Tools”。
- Go 项目版本不一致：在项目根目录添加 `mise.toml` 或 `.go-version` 并固定
  版本，不要修改全局版本来迎合单个旧项目。
- Hugo 模块下载失败：先用 `go env GOPROXY GOPRIVATE` 检查项目所需设置；不要
  把私有仓库凭据写进仓库配置。
- Sass 管道报缺少功能：确认 `hugo version` 包含 `extended`，再检查主题是否要求
  Dart Sass、PostCSS 或 Node 项目依赖。

官方资料：

- [Go installation](https://go.dev/doc/install)
- [Go modules reference](https://go.dev/ref/mod)
- [mise Go backend](https://mise.jdx.dev/lang/go.html)
- [VS Code Go extension](https://marketplace.visualstudio.com/items?itemName=golang.go)
- [Hugo on macOS](https://gohugo.io/installation/macos/)
- [Hugo Modules](https://gohugo.io/hugo-modules/)
