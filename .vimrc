syntax on filetype on
colorscheme koehler
set laststatus=2
set wildmenu wildmode=list:longest wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
setlocal spell spelllang=en_us encoding=utf8
set shiftwidth=4 tabstop=4 expandtab foldcolumn=1
set nobackup
set showmatch mat=1
set scrolloff=10 nowrap whichwrap=b,s,<,>,[,] ai si wrap
set showcmd showmatch ignorecase
set hlsearch incsearch history=100
set statusline= statusline+=%=set statusline+=\ %F\ %M\ %Y\ %R statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%
set clipboard=unnamedplus
set mouse=a

function TransBuffer(iso)
	execute ':%!trans -b :' . a:iso
endfunction
function TransBufferISO()
	:call TransBuffer(nr2char(getchar()) . nr2char(getchar()))
endfunction
noremap t :call<space>TransBufferISO()<CR>

nnoremap x :%s/;/\r/g<CR>
