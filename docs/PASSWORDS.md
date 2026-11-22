# pass 与 Vicinae 密码管理

## 个人约定

继续使用已有的 `pass + GPG` 密码库，Vicinae **Passwords** 提供日常管理界面。
不转换密码库、不重新 `pass init`、不更改私钥保护或 GPG 收件人配置。
`~/.password-store`、解密内容和任何密钥材料都不属于 dotfiles。

实现入口：

- [界面与表单](../config/vicinae/passwords/src/ui/)；
- [密码库、Git、进程执行与最近使用记录](../config/vicinae/passwords/src/services/)；
- [纯数据模型、字段解析与 OTP](../config/vicinae/passwords/src/domain/)；
- [原生命令依赖装配](../config/vicinae/passwords/src/passwords.tsx)；
- [终端入口 passmenu](../config/pass/passmenu.sh)；
- [随扩展打包的 macOS 剪贴板 helper](../config/vicinae/passwords/assets/clipboard.js)；
- [本地二维码识别 adapter](../config/vicinae/passwords/src/platform/qr.ts) 与 [Vision helper](../config/vicinae/passwords/assets/qr-reader.js)；
- [自动输入服务](../config/vicinae/passwords/src/services/auto-type.ts)、[macOS adapter](../config/vicinae/passwords/src/platform/auto-type.ts) 与 [Quartz helper](../config/vicinae/passwords/assets/auto-type.js)。

## 功能与 pass 对应

| pass 能力 | Vicinae 中的入口与行为 |
| --- | --- |
| `ls` / `find` | 名称模糊搜索、文件夹筛选；浏览时不解密 |
| `show` | 回车复制密码或 TOTP；Browse Fields 进入第二层字段列表，值默认隐藏，可显式显示 |
| 自动输入（rofi-pass 风格） | Type Password / OTP、Type Username、Type Username → Tab → Password；输入原窗口，不自动提交 |
| 指定字段 / 完整条目 | Copy Username、Copy Website URL、Copy Full Entry；字段列表可复制任意自定义字段或备注 |
| `pass-otp` 的常见 TOTP 使用 | New Authenticator (TOTP)、Set Up / Edit TOTP；支持密钥、链接及二维码导入，SHA1/SHA256/SHA512、6/8 位及 period，复制时现算 |
| `insert` / `insert -m` | New Password：名称、密码确认、用户名、网址、备注或自定义字段 |
| `edit` | View / Edit Entry：修改密码与独立 TOTP 区域，未知字段保留在 Notes / Extra Fields |
| `generate` | Generate New Password：默认 24 位，可设置 1–1024 位和是否包含符号 |
| `generate -i` | Replace with Generated Password：确认后仅更换首行，保留后续字段 |
| `mv` / `cp` | Rename / Move Entry、Duplicate Entry：支持路径，按目标文件夹收件人重新加密，不覆盖已有目标 |
| `rm` | Delete Entry：确认后删除单个条目；当前命令未关闭前可撤销最近一次删除 |
| `grep` | Search Entry Contents：用户提交后才逐条解密，以不区分大小写的普通文本匹配，只返回名称，无明文索引 |
| Git 历史 | Entry Git History / Store Git History，显示最近 20 条提交元数据，不显示旧密码 |
| Git 写入 | 密码库是 Git 仓库时自动提交本次涉及的条目，保留无关暂存内容，遵守 Git 签名配置和 `pass.signcommits` |
| 其他高级命令 | Open Store in Terminal 在 WezTerm 打开密码库目录，供本人运行完整的 `pass` CLI |

GUI 管理 UTF-8 文本条目。名称须为相对路径，不含控制字符、`..` 或
`.git` / `.extensions` 等管理路径；不跟随条目或目录符号链接。
不支持递归删除文件夹。收件人变更、`pass init`、QR 展示、Git 远端配置、
同步和第三方 pass 扩展留在终端中执行；界面不会自动执行网络同步或变更密钥。

`username` / `user` / `login` 和 `url` / `website` / `uri` 字段名不区分大小写。
格式沿用 pass 的普通文本：第一行为密码，后续为可选的 `字段: 值` 或任意备注。
生成密码只保存，不自动显示或复制。更改库中记录不会更改对应网站的登录密码。

动作菜单的 **Password Settings** 可以设置密码库路径、复制时长、默认生成长度、
符号、回车默认复制/浏览字段/输入密码或 OTP/输入用户名和密码、最近使用时长和字段 schema。路径支持 `~/`。
最近使用默认 120 秒，只在 Vicinae LocalStorage 保存条目名称、字段 ID/类型和时间，
不保存值、OTP 种子或验证码；设为 0 禁用后不再读写该记录。密码复制后紧接着打开
同一条目时，字段列表优先显示 OTP。记录过期或条目删除后不会创建虚假的列表项。

自动字段解析保留第一个冒号之后的完整值，支持网址、重复字段和自由文本备注。
复制与自动输入共用字段选择及 OTP 转换逻辑；自定义 schema 的 Login/User/Username
和 URL/Website/URI 同样可由对应的快捷动作使用。
非标准文件布局可配置可选 JSON，例如：

```json
[{"key":"Login","type":"field"},{"key":"Password","type":"password"},{"key":"OTP","type":"otp"}]
```

Schema 只决定字段浏览/复制的布局，不改写密码文件；编辑表单按标准 pass 布局编辑
首行和后续文本。HOTP 计数器更新不在 GUI 支持范围内。

## 创建和导入 TOTP

- **新建密码并附带验证码**：`⌘N` → 勾选 **Two-Factor Authentication**。
- **单独保存验证码账户**：`⌘⇧T` → **New Authenticator (TOTP)**，无需填写密码。
- **给现有密码添加或编辑验证码**：条目动作菜单 → **Set Up / Edit TOTP**；普通编辑也显示同一区域。

在 **Setup Key / otpauth Link** 粘贴网站提供的 Base32 密钥或完整 `otpauth://totp/…` 链接。
链接会自动填入 **Service**、**Account** 和高级参数；密钥始终遮蔽。默认 SHA1、6 位、30 秒，
**Advanced** 可按网站要求调整，不需要手写 URI。备注只用于 Notes / Extra Fields。

二维码提供两种入口：

1. **Import QR Image** 选择本地 PNG、JPEG 或 TIFF 图片。
2. 用自己习惯的截图工具把二维码图片复制到剪贴板，再选择
   **Import TOTP QR from Clipboard**，也可按 `⌘⇧V`。macOS 自带 `⌃⌘⇧4` 只是可选截图方式。

二维码只在用户操作时读取，通过 Apple Vision 在本机识别，无相机、录屏或网络服务依赖，
不新增软件包。限制为 20 MB / 4000 万像素；包含多个支持的二维码时必须先选择账号再保存。
非 TOTP、HOTP 和 Google Authenticator 批量迁移二维码不在支持范围内。
输入图片和剪贴板源仍由用户管理，导入不会删除原文件或清空截图。

独立账户以 `otpauth` URI 保存为首行；附带的 TOTP 保存为密码后的一行，继续使用 pass/GPG。
普通的单个 TOTP 行会自动拆到专用表单；不修改 TOTP 配置时保留原 URI、附加参数、行位置及空行。备注中嵌入的说明链接不自动提取。
遇到多个或不支持的链接则保持原始字段，避免猜测覆盖；仍可用 `pass` 编辑。
取消附带 TOTP 的勾选并保存时须确认移除密钥。这里的添加、编辑或移除只影响密码库记录，
不会启用或关闭网站的两步验证。

## 直接输入用户名和密码

沿用旧 Linux `rofi-pass` 的 `user :tab pass` 使用习惯，同时保留复制入口。
先在目标网站或应用点选输入框，再打开 Passwords 并选择条目：

| 动作 | 使用方式 |
| --- | --- |
| Type Password / OTP（`⌘↩`） | 光标放在密码框；独立 TOTP 条目则输入当前验证码 |
| Type Username | 光标放在用户名框，只输入用户名 |
| Type Username → Tab → Password（`⌘⇧↩`） | 光标放在用户名框，输入用户名、一次 Tab、密码 |
| 字段列表的 Type Field / Type Current OTP | 输入所选字段；TOTP 输入当前码，不输入种子 |

以上均不会按 Enter 或点击登录。多步骤登录页面应分别输入用户名和密码；
组合动作要求 Tab 后紧接密码框，不适用于中间夹有其他控件的页面。
字段内的换行、Tab 等控制字符不作为按键解释，会拒绝整个序列；每个字段上限 1024 个 UTF-16 单元。
它向当前光标位置输入，不会自动清空已有内容，也不识别网页 DOM 或验证网站域名。

需要回车直接输入时，在 **Password Settings → Enter Action** 选择
**Type password / OTP** 或 **Type username → Tab → password**。默认保留原来的 Copy 行为，
避免升级后回车意外改变含义；其他动作始终可以从动作菜单选择。

自动输入需要本人在 **系统设置 → 隐私与安全性 → 辅助功能** 允许 Vicinae；
**Auto-Type Permissions** 只打开对应设置页，不自动授予权限。若列表没有 Vicinae，点击 `+` 添加
`/Applications/Vicinae.app`。开启后完全退出再重新启动 Vicinae，然后先点选登录框再打开 Passwords。
权限预检在查询原窗口和解密之前执行；未授权时显示 **Enable Vicinae Accessibility**，
不会再把缺权限笼统报成 “Cannot identify the original input window”。
无需授予全磁盘访问、录屏或输入监控权限。复制与二维码图片导入仍可独立使用。

实现使用 Apple Quartz Unicode 键盘事件，支持 Unicode 和符号，不经过剪贴板，
不切换键盘布局，不引入额外软件包。密码仍由 pass/GPG 解密，密钥口令仍在 pinentry 输入。
在解密前捕获目标窗口并检查权限；准备好内容后关闭 launcher、恢复目标窗口，
输入期间核对 PID、应用启动时间、窗口 ID 和前台应用，并只向捕获的 PID 发送事件。
焦点变化会停止剩余输入。若发生中途失败，可能已输入部分字符，检查/清理输入框后再重试；
同一浏览器窗口内的标签页或字段变化无法可靠检测，因此输入期间不要切换标签或点击其他字段。

## 安全与写入行为

- 默认库为 `~/.password-store`，支持进程环境的 `PASSWORD_STORE_DIR`。
- 只有复制、自动输入、打开编辑、移动或显式内容搜索等动作才会解密。解密内容只在应用或
  子进程内存中使用，不写入日志、通知、命令行参数或临时明文文件。
- 表单禁用草稿和字段持久化；密码默认遮蔽，密码确认只用于新建。
- 新建和编辑通过 stdin 交给 `pass insert --multiline`。先在权限受限的临时目录
  完成加密，临时目录只保存公开收件人配置和密文；成功后原子替换目标文件。
- 生成沿用 `pass generate`；更换密码沿用 `--in-place`。编辑、移动与删除检查
  加密文件版本；同时复核加密期间的 `.gpg-id` 与签名版本，变化时拒绝写入。
- `.vicinae-pass.lock` 以排他创建协调本扩展多个实例的写入。原生 pass / Git
  不遵守此锁，外部版本检查只能尽力检测变化；不要同时用其他工具修改同一条目
  或收件人配置，它不构成跨所有工具的事务。
- 移动在源文件删除失败时，尝试仅回滚本次创建的目标密文；若目标已被他人改动
  或回滚失败，会明确提示 **Operation Partly Completed**，不会删除未知版本。
- 删除的撤销数据只有密文，保存在当前命令内存中，不写入新的备份文件。
- Git 提交失败时加密记录已经保存，界面明确提示 **Saved; Git Commit Failed**。
  不要把它理解成密码没有保存；到密码库终端检查 `git status` 和签名设置。
- GPG 解锁沿用 `pinentry-mac` 和 agent 缓存，口令只在本机可信弹窗输入。
  当前配置为闲置 120 秒、最长 600 秒，见 [GPG.md](GPG.md)。
- 所有字段复制均写入 `ConcealedType`、`TransientType`，默认 45 秒后清除；
  期间复制新内容则保留新内容。定时器仅接收 pasteboard generation，不接收密码。
  `PASSWORD_STORE_CLIP_TIME` 可设置 1–99999 秒，GUI 不会自动读取 `.zshrc`。
  TOTP 的剪贴板时长还会限制为当前码的剩余有效期。
- 直接 `pass -c` 使用 pass 自己的剪贴板实现，不经过本入口的标记与清除逻辑。

机密标记需要历史工具配合。用合成条目确认 CopyQ 和 Vicinae 不收录，
不要用真实密码排查，也不要为了排查输出剪贴板历史。

## 安装与应用

`Brewfile` 默认安装 `pass`、`gnupg` 和 `pinentry-mac`。Vicinae 通过 `--with vicinae` 启用。按仓库流程先检查，
批准安装软件包和备份冲突文件后再应用：

```sh
./setup.sh --check --with vicinae
./setup.sh --apply --with vicinae
```

setup 链接 `~/.local/bin/passmenu`，在选择安装 Vicinae 时为原生扩展执行
`npm ci` 和构建。依赖只属于此扩展；Node/npm 由已有 mise 工具链提供，
TypeScript、vici 和 CLI 打包用的 esbuild 由项目依赖提供，不安装全局版本。
`passmenu` shell 脚本只负责分派，`--list` / `--copy` 由扩展打包的同一套 Node
服务实现；需 Node 22 以上。原生扩展通过 `environment.assetsPath` 定位 helper，
无需依赖仓库路径或 CLI 符号链接。
`npm run format` 和 `npm run format:check` 复用 TypeScript 自带的格式化器，
与 VS Code 的内置 TypeScript formatter 保持同一工具来源，不新增格式化依赖。

已有依赖时单独检查、构建并安装：

```sh
cd config/vicinae/passwords
npm run typecheck
npm run format:check
npm test
npm run build
```

依赖尚未安装时，批准后先执行 `npm ci`。lockfile 固定 SDK 兼容的 Zod 修复版，
避免 GHSA-mrhx-c7xc-m3w5 的资源耗尽问题；更新依赖后运行 `npm audit` 和完整回归。`vici build` 安装到
`~/.local/share/vicinae/extensions/pass-passwords/`。GPG 身份和密码库迁移见
[GPG.md](GPG.md)、[GPG-MIGRATION.md](GPG-MIGRATION.md)。已有库无需初始化。

## 键盘使用

打开 Vicinae 搜索 **Passwords**，或终端运行 `passmenu`。回车默认复制选中的密码，可在 Enter Action 改为直接输入，
`⌘B` 打开动作菜单，Escape 返回或退出。

| 快捷键 | 操作 |
| --- | --- |
| `⌘↩` | 输入密码 / 当前 OTP |
| `⌘⇧↩` | 输入用户名 → Tab → 密码 |
| `⌘N` | 新建密码 |
| `⌘⇧N` | 生成新密码 |
| `⌘⇧T` | 新建独立 TOTP 账户 |
| `⌘⇧V` | 编辑表单中从剪贴板图片导入 TOTP 二维码 |
| `⌘E` | 查看 / 编辑所选条目 |
| `⌘O` | 浏览条目内的字段（默认复制模式） |
| `⌘⇧F` | 搜索条目内容，会触发解密 |
| `⌘R` | 刷新，并清除内容搜索结果 |
| `Control+X` | 删除所选条目，仍须确认 |
| `⌘Z` | 撤销当前命令中最近一次删除 |

根搜索选中 **Passwords** 后，可在动作菜单设置命令级全局快捷键；setup 不自动绑定。

## 验证

```sh
pass --version
bash -n config/pass/passmenu.sh
shellcheck config/pass/passmenu.sh
python3 config/pass/test_passmenu.py
npm --prefix config/vicinae/passwords run typecheck
npm --prefix config/vicinae/passwords test
npm --prefix config/vicinae/passwords run build
vicinae cmd ls | rg '@sky-bro/pass-passwords:passwords'
```

集成测试只在临时目录创建测试专用 GPG 身份和密码库，验证真实 pass 加解密、
生成与保留备注、跨收件人移动、删除撤销、共享锁、收件人变化、移动失败回滚和 Git 提交。
UI 回归使用 React test renderer 和真实 Vicinae API 组件，将子页面作为独立
React 根节点挂载，验证新建表单输入/提交及其他导航页面；所有密码服务均为合成替身。
纯逻辑测试覆盖完整 RFC 6238 时间点向量、TOTP 配置/URI 转换和原有字段保留、字段解析、最近使用 TTL，以及子进程取消/超时。
测试身份通过 GnuPG 创建和删除，不读取私钥内容，不触碰本人的密码库。
严格沙盒可能无法创建 GPG agent socket，需要在本机允许该测试运行。

剪贴板测试会用合成文本覆盖当前剪贴板，须在本机图形会话运行：

```sh
python3 config/pass/test_clipboard.py
```

要同时验证原生扩展的剪贴板桥接，可运行
`PASS_TEST_CLIPBOARD=1 npm --prefix config/vicinae/passwords test`；同样只使用合成文本。

二维码原生测试用公开 RFC 密钥生成临时图片并通过真实 Vision 解码，不读取真实账户。
在 macOS 图形会话运行（剪贴板测试会覆盖当前剪贴板；单独运行以避免与其他剪贴板测试竞争）：

```sh
cd config/vicinae/passwords
PASS_TEST_QR=1 node --experimental-strip-types --test tests/qr.test.ts
PASS_TEST_QR=1 PASS_TEST_QR_CLIPBOARD=1 node --experimental-strip-types --test tests/qr.test.ts
```

用合成条目验证 GUI 新建、编辑、遮蔽/显示、生成、移动、删除和撤销。
不要用真实密码进行自动化测试。

自动输入回归覆盖目标捕获先于解密、缺失权限/字段不输入、用户名和密码顺序、
控制字符拒绝、字段 schema、OTP 不泄露种子、焦点变化中止、PID 复用及页面关闭后的错误通知。
Quartz 原生编码自测不向窗口发送按键，可运行：

```sh
PASS_TEST_INPUT=1 node --experimental-strip-types --test config/vicinae/passwords/tests/auto-type.test.ts
```

端到端测试须在本人已授权辅助功能的图形会话中，用无网络、无表单提交的合成登录框验证，
不要把编码自测或模拟焦点测试当作真实应用接收按键的保证。

## 故障排查

- 找不到 **Passwords**：重新构建，确认上述原生 ID 已注册；必要时重新打开 Vicinae。
- 打开 New Password 等子页面出现 `Password runtime is missing`：属于旧版本
  未跨独立导航根节点传递 Context 的问题；构建并重新加载修复版本。
- 没有条目：确认现有库路径；空库仍可新建，不要为此重新 `pass init`。
- 自动输入提示权限或旧版的 `Cannot identify the original input window`：通过 Auto-Type Permissions 打开辅助功能设置，允许 **Vicinae**（不是仅允许 Codex 或终端），缺少时用 `+` 添加 `/Applications/Vicinae.app`；完全退出并重新启动 Vicinae，再点选登录框打开 Passwords。不需要开启输入监控或录屏。
- 辅助功能已经开启但仍无权限：先退出 Vicinae，在系统设置关闭再开启其辅助功能开关，然后重新启动。升级或更换安装包后旧授权可能未生效；不要手动修改 TCC 数据库。
- 自动输入提示窗口变化：重新点选目标输入框，再打开 Passwords 重试；中途失败时先检查已有字符，避免重复追加。
- 二维码无法导入：确认图片清晰且含网站提供的 TOTP 设置码；剪贴板入口需要图片，普通密钥或链接直接粘贴到 Setup Key / otpauth Link。批量迁移码不支持。
- 解密失败：检查加密子密钥和 `pinentry-mac`，在本人终端用 `pass -c <条目>` 验证。
- 提示已变更或已存在：刷新列表后重新编辑；目标名称必须是未被占用的路径。
- 提示已保存但 Git 失败：检查密码库 `git status`、用户身份、提交 hook 与 GPG 签名。
- 内容搜索耗时：它会逐条解密；返回或刷新会取消当前解密子进程及后续条目；解锁仍由本人处理。
  已经落盘的成功写入会继续完成 Git 记账，避免把取消误当作回滚。
- 提示密码库锁定：检查 `.vicinae-pass.lock` 中的主机和 PID。仅在确认对应写入
  进程已经退出后，才在本人终端删除遗留锁；应用不会自动回收不确定归属的锁。
- 无法打开终端：确认 WezTerm CLI 可用，或本人手动进入 `~/.password-store`。
- SSH/headless 或严格沙盒下无法访问 pasteboard/socket：在本机图形会话使用 GUI。

## 上游设计参考与架构

继续维护本扩展的完整管理能力。参考
[Vicinae Pass 的固定版本](https://github.com/vicinaehq/extensions/tree/181904331f5289b53ee3443f98cfa5441d399f35/extensions/pass)
和 [Raycast Pass](https://www.raycast.com/capipo/pass) 的模块划分、两层字段浏览、
字段 schema、最近使用和 OTP 体验。未复制上游源文件；参考版本与设计取舍见
[扩展开发说明](../config/vicinae/passwords/README.md)。

界面经由 `RuntimeContext` 注入密码库、剪贴板、自动输入、二维码识别与最近使用服务；核心模块不导入
Vicinae API。Vicinae 的每个导航页面是独立 React 根节点，所有页面跳转必须使用
`usePasswordNavigation`，在每个新页面上显式重新提供 runtime；不能假设入口
Provider 会跨导航继承。后续增加字段类型、平台或启动器时可复用核心服务，不必复制密码库
写入流程。进程执行具有脱敏的错误类别与 AbortSignal，表单共享异步任务生命周期。

## 官方资料

- [pass 命令手册](https://git.zx2c4.com/password-store/about/)
- [pass 官网](https://www.passwordstore.org/)
- [Vicinae extensions](https://docs.vicinae.com/extensions/create)
- [Apple NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard)
- [NSPasteboard 机密与临时标记约定](https://nspasteboard.org/)
- [RFC 6238 TOTP](https://www.rfc-editor.org/rfc/rfc6238)
- [Apple Vision barcode detection](https://developer.apple.com/documentation/vision/vndetectbarcodesrequest)
- [Google Authenticator Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)

- [Apple Quartz Unicode keyboard events](https://developer.apple.com/documentation/coregraphics/cgevent/keyboardsetunicodestring(stringlength:unicodestring:))
- [Apple PID-directed events](https://developer.apple.com/documentation/coregraphics/cgevent/posttopid(_:))
- [Apple Accessibility trust](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)
