augroup supersleuth
	autocmd!
	autocmd FileType * call supersleuth#SuperSleuth(0, '')
augroup END

command! -bar -nargs=? SuperSleuth call supersleuth#SuperSleuth(1, <q-args>)
