" Autodownload and autoload plugins on fresh install
if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
   echo "Downloading junegunn/vim-plug to manage plugins..."
   silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload
   silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
   autocmd VimEnter * PlugInstall
endif

" Plugins to install and use
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'preservim/nerdcommenter'
  Plug 'airblade/vim-gitgutter'
  Plug 'itchyny/lightline.vim'
  Plug 'mhinz/vim-startify'
  Plug 'ap/vim-css-color'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'airblade/vim-rooter' " project directory scope, consider .gitignore, etc in fzf
  Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
call plug#end()

" nerdcommenter
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1
let g:NERDAltDelims_java = 1
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
let g:NERDToggleCheckAllLines = 1

" vim-gitgutter
highlight! link SignColumn LineNr
set signcolumn=yes
set updatetime=100
highlight GitGutterAdd guifg=#4B5632 ctermfg=2
highlight GitGutterChange guifg=#bbbb00 ctermfg=3
highlight GitGutterDelete guifg=#ff2222 ctermfg=1
let g:gitgutter_map_keys = 0

" lightline
let g:lightline = { 'colorscheme': 'monokai_tasty' }

" startify
let g:startify_files_number = 18
let g:startify_lists = [ { 'type': 'dir', 'header': ['   Recent files'] }, { 'type': 'sessions', 'header': ['   Saved sessions'] }, ]
let g:startify_custom_header = [ '                        _',
  \ ' .____   ___  _____   _(_)____ ___',
  \ ' |  _ \ / _ \/ _ \ \ / / |  _ ` _ \',
  \ ' | | | |  __/ (_) \ V /| | | | | | |',
  \ ' |_| |_|\___|\___/ \_/ |_|_| |_| |_|',
  \ ]
