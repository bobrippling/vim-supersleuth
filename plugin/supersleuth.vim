function! s:SuperSleuth(verbose, args) abort
	let dry = 0
	if !empty(a:args)
		if a:args ==# '-n'
			let dry = 1
		else
			echoerr 'Usage: SuperSleuth [-n]  # -n: dry run'
			return
		endif
	endif

	if &l:buftype =~# '^\v%(quickfix|help|terminal|prompt|popup)$'
		if a:verbose
			echo 'not supersleuthing bt=' .. &l:buftype
		endif
		return
	endif

	if &l:filetype ==# 'netrw'
		if a:verbose
			echo 'not supersleuthing ft=' .. &l:filetype
		endif
		return
	endif

	for i in range(1, line('$'))
		let l = getline(i)

		if l =~# '^\s*\*'
			" ignore C style middle-comment lines
			continue
		endif

		if l =~# "^\t\\+\\S"
			if !dry
				setlocal noexpandtab
				setlocal tabstop=4 shiftwidth=4
			endif

			if a:verbose
				echo 'supersleuth: using tabs, found on line ' .. i
			endif

			break
		elseif l =~# "^ \\+\\S"
			let spaces = len(substitute(l, '\S.*', '', ''))

			if !dry
				setlocal expandtab
				let &tabstop = spaces
				let &shiftwidth = spaces
			endif

			if a:verbose
				echo 'supersleuth: using spaces, found initial indent of ' .. spaces .. ' on line ' .. i
			endif

			break
		endif
	endfor
endfunction

augroup supersleuth
	autocmd!
	autocmd FileType * call s:SuperSleuth(0, '')
augroup END

command! -bar -nargs=? SuperSleuth call s:SuperSleuth(1, <q-args>)
