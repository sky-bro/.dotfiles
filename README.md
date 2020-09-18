# dotfiles

Use a bare git repository to manage dotfiles.

## start

create the repo

```shell
git init --bare $HOME/.dotfiles.git
```

set git alias for the repo

```shell
echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'" >> $HOME/.zshrc # or .bashrc
. $HOME/.zshrc
```

then use this command to not show untracked files on `dotfiles status`

```shell
dotfiles config --local status.showUntrackedFiles no
```

## backup files

use `dotfiles` like your original `git` command

```shell
dotfiles status
dotfiles add .vimrc
dotfiles commit -m "backup .vimrc"
dotfiles remote add origin https://www.github.com/sky-bro/.dotfiles.git
dotfiles push origin master
```

## restore files

on this computer

```shell
# rm .vimrc
dotfiles checkout
```

on another computer

```shell
echo 'alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"' >> $HOME/.zshrc
source ~/.zshrc
echo ".dotfiles.git" >> .gitignore # prevent recursion issues
git clone --bare https://www.github.com/username/repo.git $HOME/.dotfiles.git
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

## refs

* [The best way to store your dotfiles: A bare Git repository](https://www.atlassian.com/git/tutorials/dotfiles)
