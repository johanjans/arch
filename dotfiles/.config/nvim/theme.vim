set termguicolors                               " enable 24-bit color support in terminal
let g:vim_monokai_tasty_italic = 1              " enable italic fonts
let g:vim_monokai_tasty_machine_tint = 1        " monokai machine colorscheme variant
let g:vim_monokai_tasty_highlight_active_window = 1 " make highlighted window stand out
colorscheme vim-monokai-tasty                   " set colorscheme 
let g:airline_theme='monokai_tasty'

highlight clear LineNr                          " set transparent line number column
highlight clear SignColumn                      " set transparent gitgutter column
highlight clear Conceal                         " set transparent conceals
highlight clear CursorLine                      " set transparent cursorline
highlight clear CursorLineNR                    " set transparent cursorline line number
highlight Normal ctermbg=NONE guibg=NONE        " set transparent background with termguicolors enabled

autocmd InsertEnter * highlight CursorLine guibg=black
autocmd InsertLeave * highlight clear CursorLine
