# Docker 与 Colima

## 个人约定

macOS 使用 Colima 提供 Linux 虚拟机和 Docker daemon，不安装 Docker
Desktop。Docker CLI、Compose 和 Buildx 由 Homebrew 管理。

仓库管理
[`config/colima/default.yaml`](../config/colima/default.yaml)，并将它链接到
`~/.colima/_templates/default.yaml`。该模板只影响新建的 Colima profile；
已经存在的 profile 使用 `~/.colima/<profile>/colima.yaml`，不会被模板静默
覆盖。

默认 profile 面向日常开发：

- 4 CPU、8 GiB 内存和 100 GiB 容器数据盘；
- 使用宿主机架构、Docker runtime、Apple Virtualization (`vz`) 和 VirtioFS；
- 启用 BuildKit，不启用 Kubernetes；
- 不给虚拟机分配局域网可达地址，也不转发 SSH agent；
- Colima 启动后自动激活对应的 Docker context。

Colima 不设置为开机自动启动，需要容器环境时手动启动，避免空闲时占用内存。

## 安装与应用

先检查所有目标；如果有 `replace`，确认列出的文件可以备份后再应用：

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

setup 会把 Homebrew 安装的 Compose 和 Buildx 链接到
`~/.docker/cli-plugins/`。这样无需接管 `~/.docker/config.json`；其中可能
包含 registry 登录状态和其他本机设置。

第一次启动会按仓库模板创建默认 profile，并下载 Colima VM 镜像：

```sh
colima start
```

镜像下载需要访问官方 GitHub release。不要配置 Homebrew、Docker 或 Colima
镜像源；如网络失败，先检查 DNS、代理和 GitHub 连通性。

## 日常使用

```sh
colima status
docker context show
docker ps
docker compose up -d
colima stop
```

临时调整资源可以编辑当前 profile：

```sh
colima start --edit
```

CPU 和内存可调整；数据盘只能增大。`arch`、`runtime`、`vmType` 和
`mountType` 是创建后的不可变设置，更改它们需要删除并重建 profile。删除
profile 或容器数据属于破坏性操作，不由 setup 自动执行。

## 验证

安装和应用后：

```sh
./setup.sh --check
colima version
docker version
docker compose version
docker buildx version
colima start
colima status
test "$(docker context show)" = colima
docker run --rm hello-world
```

`docker version` 在 Colima 尚未启动时会正常显示 client 信息，但 server
部分会连接失败。`hello-world` 会从 Docker Hub 下载公开镜像。

## 故障排查

### `docker compose` 或 `docker buildx` 不存在

确认插件链接与 Homebrew 安装目录：

```sh
ls -l ~/.docker/cli-plugins
brew --prefix
brew list docker-compose docker-buildx
```

然后重新运行 `./setup.sh --apply`。setup 只管理这两个插件链接，不覆盖整个
Docker CLI 配置。

### Docker daemon 无法连接

```sh
colima status
docker context ls
colima start
```

不要设置固定的 `DOCKER_HOST`，Colima 会管理 Docker context。若 shell 中
继承了 `DOCKER_HOST`，先确认来源并在当前 shell 中取消后重试。

### 需要修改现有 profile

仓库模板不会追溯修改已创建的 profile。使用 `colima start --edit` 做本机
调整。若确实要重建，先备份需要保留的镜像、volume 和数据库，再手动执行
Colima 的删除命令。

## 官方资料

- [Colima documentation](https://colima.run/docs/)
- [Colima configuration](https://colima.run/docs/configuration/)
- [Colima installation](https://github.com/abiosoft/colima/blob/main/docs/INSTALL.md)
- [Docker CLI](https://docs.docker.com/reference/cli/docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Buildx](https://docs.docker.com/build/buildx/)
- [Homebrew formulae](https://formulae.brew.sh/)
