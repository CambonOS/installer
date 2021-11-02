set title
set number
set background=dark
set mouse=a
colorscheme peachpuff


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

" Moverse al buffer siguiente con <líder> + l
nnoremap <C-j> :bnext<CR>

" Moverse al buffer anterior con <líder> + j
nnoremap <C-k> :bprevious<CR>

" Cerrar el buffer actual con <líder> + q
nnoremap <C-q> :bdelete<CR>
