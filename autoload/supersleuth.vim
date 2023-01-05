function! supersleuth#SuperSleuth(verbose, args) abort
	let dry = 0
	if !empty(a:args)
		if a:args ==# '-n'
			let dry = 1
		else
			echoerr 'Usage: SuperSleuth [-n]  # -n: dry run'
			return
		endif
	endif

	if &l:buftype =~# '^\v%(quickfix|help|terminal|prompt|popup)$' || @% =~ '^term://'
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

	let regex_tab = "^\t\\+\\S"

	let space_indents = {} " Map<indent-level, count>
	let space_line = 0
	let space_consistent = 0
	let smallest_indent = 999
	let tab_line = 0

	" 100 lines, for time
	for i in range(1, min([100, line('$')]))
		let l = getline(i)

		if l =~# '^\s*\*'
			" ignore C style middle-comment lines
			continue
		endif

		if tab_line is 0 && l =~# regex_tab
			let tab_line = i
		elseif !space_consistent && l =~# '^ \+\S'
			let indent = len(substitute(l, '\S.*', '', ''))
			let space_line = i

			" if no tabs, we might just have an awkwardly spaced file
			if !has_key(space_indents, indent)
				let space_indents[indent] = 0
			endif
			let space_indents[indent] += 1

			if indent < smallest_indent
				let smallest_indent = indent
			endif

			for [indent, nlines] in items(space_indents)
				if nlines <= 1
					continue
				endif

				" we've found multiple - accept if this is the smallest entry
				if indent == smallest_indent
					let space_consistent = indent
					break
				endif

				let remainder = (indent + 0.0) / smallest_indent
				if s:is_integral(remainder)
					" indent is a multiple of smallest_indent, use smallest_indent
					let space_consistent = smallest_indent
				endif
			endfor
		endif

		if tab_line > 0 && space_consistent
			break
		endif
	endfor

	if tab_line && !space_consistent
		if !dry
			setlocal noexpandtab tabstop=2 shiftwidth=0
		endif

		if a:verbose
			echo 'supersleuth: using tabs (line ' .. tab_line .. ')'
		endif
	elseif space_consistent && !tab_line
		if !dry
			setlocal expandtab shiftwidth=0
			let &l:tabstop = space_consistent
		endif

		if a:verbose
			echo 'supersleuth: using spaces, found initial indent of ' .. space_consistent .. ' (line ' .. space_line .. ')'
		endif
	elseif space_consistent
		if !dry
			" something like vim's source code
			setlocal noexpandtab tabstop=8
			let &l:shiftwidth = space_consistent
		endif

		if a:verbose
			echo 'supersleuth: using a mix, found tabs (line ' .. tab_line .. ') and initial indent of ' .. space_consistent .. ' spaces (line ' .. space_line .. ')'
		endif
	else
		if a:verbose
			let extra = empty(space_indents) ? '' : ' (found inconsistent spacing)'
			echo 'supersleuth: no indent found, defaulting to ts=' .. &tabstop .. extra
		endif
	endif
endfunction

function! s:is_integral(n)
	return a:n == float2nr(a:n)
endfunction
