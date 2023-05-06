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
		" just tabs, no (consistent) spaces
		if !dry
			setlocal noexpandtab tabstop=2 shiftwidth=0
		endif

		if a:verbose
			echo 'supersleuth: using tabs (line ' .. tab_line .. ')'
		endif
	elseif space_consistent && !tab_line
		" just spaces (consistent), no tabs
		if !dry
			setlocal expandtab shiftwidth=0
			let &l:tabstop = space_consistent
		endif

		if a:verbose
			echo 'supersleuth: using spaces, found consistent indent of ' .. space_consistent .. ' (line ' .. space_line .. ')'
		endif
	elseif space_consistent
		" tabs and (consistent) spaces
		if !dry
			" something like vim's source code
			setlocal noexpandtab tabstop=8 shiftwidth=0
			let &l:shiftwidth = space_consistent
		endif

		if a:verbose
			echo 'supersleuth: using a mix, found tabs (line ' .. tab_line .. ') and consistent indent of ' .. space_consistent .. ' spaces (line ' .. space_line .. ')'
		endif
	else
		" no tabs, no consistent spaces

		" any spaces at all?
		if empty(space_indents)
			if !dry
				setlocal noexpandtab tabstop=2 shiftwidth=0
			endif

			if a:verbose
				echo 'supersleuth: no indent, defaulting to ts=' .. &ts
			endif
		else
			" what's the difference between indents? consistent?
			let indents = sort(map(keys(space_indents), 'str2nr(v:val)'))
			let indent = -1

			if len(indents) == 1
				let indent = indents[0]
			elseif len(indents) > 2
				call assert_true(len(indents) > 1)
				let first_diff = indents[1] - indents[0]

				let same_step = 1
				for i in range(2, len(indents) - 1)
					if indents[i] - indents[i-1] != first_diff
						let same_step = 0
						break
					endif
				endfor

				if same_step
					let indent = first_diff
				endif
			else
				" two indents, take their difference if they're divisible by two
				" (like above, but a little more restricted)
				let div0 = indents[0] / 2.0
				let div1 = indents[1] / 2.0

				if s:is_integral(div0) && s:is_integral(div1)
					let indent = indents[1] - indents[0]
				endif
			endif

			if indent > 0
				setlocal expandtab shiftwidth=0
				let &l:tabstop = indent

				if a:verbose
					echo 'supersleuth: using consistent step between indents (' .. &ts .. ')'
				endif
			else
				" no indent - always echo, regardless of a:verbose
				echohl ErrorMsg
				echo 'supersleuth: warning: no indent found - no tabs & inconsistent spaces'
				echohl none
			endif
		endif
	endif
endfunction

function! s:is_integral(n)
	return a:n == float2nr(a:n)
endfunction
