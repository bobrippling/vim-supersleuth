augroup supersleuth
	autocmd!
	autocmd FileType * call supersleuth#SuperSleuth(0, '')
augroup END

command! -bar -nargs=? SuperSleuth call supersleuth#SuperSleuth(1, <q-args>)

function! SuperSleuthIndicator() abort
	if &expandtab
		let s = '_' . &tabstop
	else
		let s = '>' . &tabstop
	endif

	if &shiftwidth && &shiftwidth != &tabstop
		let s .= ',sw' . &shiftwidth
	endif

	return s
endfunction
