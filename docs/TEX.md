# TeX 与 PDF 工具

## 个人约定

- 使用完整 MacTeX，而不是 BasicTeX 或单独的 Tectonic。当前主要用途是维护
  `~/repos/resume` 中基于 XeLaTeX、xeCJK、moderncv 和 fontawesome5 的中文
  简历；完整 TeX Live 避免在新机器上逐个补装宏包。
- 命令行构建统一使用 `latexmk -xelatex`，让 `latexmk` 负责需要的重复编译和
  中间文件收敛。
- 使用 Poppler 的 `pdfinfo` 检查页数和纸张尺寸，使用 `pdftoppm` 将最终 PDF
  渲染为图片后做视觉检查。
- MacTeX 体积较大；这是为了完整、稳定的本地 LaTeX 环境而做的明确取舍。

## 安装

MacTeX 与 Poppler 都由 [`Brewfile`](../Brewfile) 管理。按仓库标准流程安装：

```sh
cd ~/.dotfiles
./setup.sh --check
./setup.sh --install-packages --apply
```

MacTeX 使用系统安装包，安装期间可能要求管理员认证。新安装完成后启动新的
shell，或在当前 shell 中刷新系统 PATH：

```sh
eval "$(/usr/libexec/path_helper)"
```

TeX 命令应从 `/Library/TeX/texbin` 暴露。dotfiles 不固定具体 TeX Live 年份，
由 MacTeX 的默认发行版链接选择当前版本。

## 简历构建

```sh
cd ~/repos/resume
make agent
make inference
```

完整检查：

```sh
make all
pdfinfo resume-agent.pdf
pdfinfo resume-inference.pdf
mkdir -p tmp/pdfs
pdftoppm -png resume-agent.pdf tmp/pdfs/resume-agent
```

渲染图片仅用于本地视觉检查，不应提交到简历仓库。

## 验证

```sh
xelatex --version
latexmk --version
kpsewhich moderncv.cls
kpsewhich xeCJK.sty
kpsewhich fontawesome5.sty
pdfinfo -v
pdftoppm -v
```

`kpsewhich` 的三个查询都应输出实际文件路径。随后在简历仓库运行 `make all`，
确认两个目标均能成功生成且保持预期页数。

## 故障排查

- 找不到 `xelatex` 或 `latexmk`：启动新 shell，或运行
  `eval "$(/usr/libexec/path_helper)"`，再检查 `/Library/TeX/texbin`。
- 找不到宏包：先确认当前默认发行版来自 MacTeX；完整 MacTeX 正常情况下不应
  需要单独用 `tlmgr` 补装上述宏包。
- Homebrew 显示已有另一套 TeX 发行版：先检查 `which xelatex`、
  `ls -l /Library/TeX/texbin` 和已安装 cask，不要同时删除或切换发行版。
- PDF 能生成但排版异常：先用 `pdfinfo` 检查页数和 A4 尺寸，再用 `pdftoppm`
  渲染全部页面，检查溢出、字体缺失、重叠和断行。

## 上游资料

- [MacTeX](https://www.tug.org/mactex/)
- [MacTeX 安装内容](https://www.tug.org/mactex/whatsinthepackage.html)
- [TeX Live](https://www.tug.org/texlive/)
- [latexmk](https://ctan.org/pkg/latexmk/)
- [Poppler](https://poppler.freedesktop.org/)
