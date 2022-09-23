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

function! s:Init(redetect)
	if !a:redetect && exists('b:supersleuth')
		return
	endif
	let b:supersleuth = 1

	call supersleuth#SuperSleuth(0, '')
endfunction

augroup supersleuth
	autocmd!

	autocmd FileType * nested call s:Init(0)
augroup END

command! -bar -nargs=? SuperSleuth call supersleuth#SuperSleuth(0, <q-args>)
