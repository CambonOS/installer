set title
set number
set background=dark
set mouse=a
colorscheme peachpuff

" Autocierre
inoremap ( ()<Esc>i
inoremap [ []<Esc>i
inoremap { {}<Esc>i
inoremap {<CR> {<CR><CR>}<Esc>ki	
inoremap < <><Esc>i
inoremap ' ''<Esc>i
inoremap " ""<Esc>i
inoremap `p ```python<CR><CR>```<Esc>ki
inoremap `b ```bash<CR><CR>```<Esc>ki

nnoremap <C-s> :w<CR>  " Guardar con <líder> + s

" Usar <líder> + y para copiar al portapapeles
vnoremap <C-y> "+y
nnoremap <C-y> "+y

" Usar <líder> + d para cortar al portapapeles
vnoremap <C-d> "+d
nnoremap <C-d> "+d

" Usar <líder> + p para pegar desde el portapapeles
nnoremap <C-p> "+p
vnoremap <C-p> "+p
