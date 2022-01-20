set modelines=1

" leader is comma
let mapleader=","

" Don't try to be vi compatible
set nocompatible

" Colors {{{
colorscheme industry

" enable syntax processing
syntax on
" }}}

" UI {{{
" highlight current line
set cursorline

" line numbers and distances
set relativenumber 
set number 

" show command in bottom bar
set showcmd

" Show file stats
set ruler

" load filetype-specific indent files
" ~/.vim/indent/python.vim gets loaded every time I open a *.py file
filetype indent on

" errors flash screen rather than emit beep
set visualbell

" visual autocomplete for command menu
set wildmenu
set wildmode=longest,list,full

" redraw only when we need to (like no need to redraw in the middle of macros)
set lazyredraw
" [ { ( highligh matching ) } ]
set showmatch
" }}}

" Space & Tabs {{{
" number of visual spaces per tab
set tabstop=4
" number of spaces in tab when editing
set softtabstop=4
set autoindent
" tabs are spaces
set expandtab

" remove trailing whitespaces on saving buffer for these filetypes
autocmd FileType org,c,cpp,java,php autocmd BufWritePre <buffer> %s/\s\+$//e

set list listchars=tab:▸\ ,trail:·,precedes:←,extends:→,eol:¬
" }}}

" Searching {{{
" search as characters are entered
set incsearch

" highlight matches
set hlsearch

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
" }}}

" Folding {{{
set foldenable

" toggle fold with SPC
nnoremap <space> za
" }}}

" Editing {{{
" use Unicode
set encoding=utf-8

" reload files changed outside of Vim not currently modified in Vim (needs below)
set autoread

" make Backspace work like Delete
set backspace=indent,eol,start

" don't create `filename~` backups
set nobackup

" don't create temp files
set noswapfile
" }}}

" Copy & Pasting {{{
" http://stackoverflow.com/questions/2490227/how-does-vims-autoread-work#20418591
au FocusGained,BufEnter * :silent! !
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
" }}}

" vim:foldmethod=marker:foldlevel=0
