" Don't try to be vi compatible
set nocompatible

syntax on

colorscheme industry

set wildmode=longest,list,full
set wildmenu

" reload files changed outside of Vim not currently modified in Vim (needs below)
set autoread

" http://stackoverflow.com/questions/2490227/how-does-vims-autoread-work#20418591
au FocusGained,BufEnter * :silent! !

" use Unicode
set encoding=utf-8

" errors flash screen rather than emit beep
set visualbell

" make Backspace work like Delete
set backspace=indent,eol,start

" don't create `filename~` backups
set nobackup

" don't create temp files
set noswapfile

" line numbers and distances
set relativenumber 
set number 

" Show file stats
set ruler

" how character column
" set colorcolumn=80

set tabstop=4
set autoindent
set expandtab
set softtabstop=4
set cursorline

" copy and paste
if has('clipboard')        " vim --version | grep clipboard # to check if has clipboard support
    if has('unnamedplus')  " When possible use + register for copy-paste
        set clipboard=unnamed,unnamedplus
    else                   " On mac and Windows, use * register for copy-paste
        set clipboard=unnamed
    endif
else
    vmap <C-c> y: call system("xclip -i -selection clipboard", getreg("\""))<CR>
    " conflict with visual block mode
    nmap <C-v> :call setreg("\"",system("xclip -o -selection clipboard"))<CR>p
endif

" remove trailing whitespaces
autocmd FileType org,c,cpp,java,php autocmd BufWritePre <buffer> %s/\s\+$//e

set list listchars=tab:▸\ ,trail:·,precedes:←,extends:→,eol:¬

