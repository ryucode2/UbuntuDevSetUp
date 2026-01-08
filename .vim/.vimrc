" Enable vim-plug for managing plugins
call plug#begin('~/.vim/plugged')

" File Explorer (NERDTree)
Plug 'preservim/nerdtree'

" Autocompletion engine (YouCompleteMe)
Plug 'ycm-core/YouCompleteMe'

" Git integration (vim-gitgutter shows git diff in the gutter)
Plug 'airblade/vim-gitgutter'

" Linting (Syntastic for syntax checking)
Plug 'scrooloose/syntastic'

" Fuzzy file finder (fzf.vim)
Plug 'junegunn/fzf.vim'

" Gruvbox color scheme
Plug 'morhetz/gruvbox'

" End vim-plug section
call plug#end()

" File Explorer: Toggle NERDTree with Ctrl+n
map <C-n> :NERDTreeToggle<CR>

" Enable line numbers
set number

" Enable line wrapping
set wrap

" Enable auto-indentation
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" Enable syntax highlighting
syntax enable

" Enable file type detection
filetype plugin indent on

" Enable YouCompleteMe autocompletion
set omnifunc=syntaxcomplete#Complete

" Enable git gutter (shows git diff in the gutter)
set updatetime=300

" Set background to dark (for gruvbox theme)
set background=dark

" Set gruvbox as the default color scheme
colorscheme gruvbox

" Enable cursor line highlighting
set cursorline

" Optional: Set bold text for keywords and comments in Gruvbox
let g:gruvbox_contrast_dark = 'hard'  " Change to 'medium' or 'soft' for different contrast

" Disable swap files
set noswapfile

" Clipboard mappings
" Map '<leader>y' to copy the selected text to clipboard
vnoremap <leader>y "+y

" Map '<leader>p' to paste from clipboard into Vim
nnoremap <leader>p "+p

" Map '<leader>Y' to copy the entire line to clipboard
nnoremap <leader>Y "+yy
