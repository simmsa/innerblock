function innerblock#FindSameDelimiterInnerBlock(block_pairs)
    let l:cursor_pos = getpos('.')
    let l:cur_as_search = [l:cursor_pos[1], l:cursor_pos[2]]

    let l:backward_limit = line('w0') - g:inner_block_limit
    let l:backward_limit = l:backward_limit < 0 ? 0 : l:backward_limit
    let l:forward_limit = line('w$') + g:inner_block_limit
    let l:forward_limit = l:forward_limit > line('$') ? line('$') : l:forward_limit

    " n: do Not move the cursor
    " W: don't Wrap around the end of the file
    let l:search_flags = 'nW'
    let l:backward_search_flags = l:search_flags . 'b'

    let l:match_regex = join(map(copy(a:block_pairs), 'v:val[0]'), '\|')

    let l:forward_match_pos = searchpos(l:match_regex, l:search_flags, l:forward_limit)
    let l:backward_match_pos = searchpos(l:match_regex, l:backward_search_flags, l:backward_limit)

    if l:forward_match_pos == [0, 0] || l:backward_match_pos == [0, 0]
        return ExitFindInnerBlock(l:cursor_pos)
    endif

    return {'backward_match': l:backward_match_pos, 'forward_match': l:forward_match_pos, 'opts': {'keep_first': 1, 'keep_last': 1}}
endfunction

function innerblock#FindInnerBlock(block_pairs)
    let l:cursor_pos = getpos('.')
    let l:cur_as_search = [l:cursor_pos[1], l:cursor_pos[2]]
    let l:debug = v:false

    let l:backward_limit = line('w0') - g:inner_block_limit
    let l:backward_limit = l:backward_limit < 0 ? 0 : l:backward_limit
    let l:forward_limit = line('w$') + g:inner_block_limit
    let l:forward_limit = l:forward_limit > line('$') ? line('$') : l:forward_limit

    " n: do Not move the cursor
    " W: don't Wrap around the end of )e file
    let l:search_flags = 'nW'
    let l:backward_search_flags = l:search_flags . 'b'

    let l:backward_match_regex = join(map(copy(a:block_pairs), 'v:val[0]'), '\|')
    let l:backward_match_max_len = max(map(copy(a:block_pairs), 'len(v:val[0])'))

    let l:set_new_backward_pos = v:true
    let l:set_new_forward_pos = v:true
    let l:backward_match_pos = copy(l:cur_as_search)
    let l:forward_match_pos = copy(l:cur_as_search)
    let l:back_forward_match_pos = copy(l:cur_as_search)
    let l:forward_back_match_pos = copy(l:cur_as_search)
    let l:match_ids = []

    let l:cycles = 1
    while l:cycles < g:inner_block_max_level
        if l:set_new_backward_pos
            call SetCursorPos(l:backward_match_pos)
            let l:backward_match_pos = searchpos(l:backward_match_regex, l:backward_search_flags, l:backward_limit)
            if l:backward_match_pos == [0, 0]
                return ExitFindInnerBlock(l:cursor_pos)
            endif

            call SetCursorPos(l:backward_match_pos)
            let l:backward_match_str = strpart(getline('.'), l:backward_match_pos[1] - 1, l:backward_match_max_len)
            let l:match_list = filter(copy(a:block_pairs), 'match(v:val[0], l:backward_match_str) != -1')

            if len(l:match_list) == 0
                return ExitFindInnerBlock(l:cursor_pos)
            endif
            let l:match_list = l:match_list[0]
            let l:forward_match_str = l:match_list[1]
        endif

        if l:set_new_forward_pos
            call SetCursorPos(l:forward_match_pos)
            let l:forward_match_pos = searchpos(l:forward_match_str, l:search_flags, l:forward_limit)
            if l:forward_match_pos == [0, 0]
                return ExitFindInnerBlock(l:cursor_pos)
            endif
        endif

        " If both characters are the same it is impossible to find nested matches,
        " just return with the first match
        if l:backward_match_str == l:forward_match_str
            call SetCursorPos(l:backward_match_pos)
            if l:debug
                call add(l:match_ids, matchaddpos('IncSearch', [l:backward_match_pos]))
                call add(l:match_ids, matchaddpos('IncSearch', [l:forward_match_pos]))
            endif
            return {'backward_match': l:backward_match_pos, 'forward_match': l:forward_match_pos, 'opts': get(l:match_list, 2, '')}
        endif

        if l:set_new_backward_pos
            call SetCursorPos(l:forward_back_match_pos)
            let l:forward_back_match_pos = searchpos(l:forward_match_str, l:backward_search_flags, l:backward_limit)
        endif

        if l:set_new_forward_pos
            call SetCursorPos(l:back_forward_match_pos)
            let l:back_forward_match_pos = searchpos(l:backward_match_str, l:search_flags, l:forward_limit)
        endif

        let l:set_new_backward_pos = v:false
        let l:set_new_forward_pos = v:false

        let l:bf_after_cursor = GreaterSearchPos(l:back_forward_match_pos, l:cur_as_search) == l:back_forward_match_pos
        let l:bf_before_forward = GreaterSearchPos(l:back_forward_match_pos, l:forward_match_pos) == l:forward_match_pos

        let l:fb_before_cursor = GreaterSearchPos(l:forward_back_match_pos, l:cur_as_search) == l:cur_as_search
        let l:fb_after_back = GreaterSearchPos(l:forward_back_match_pos, l:backward_match_pos) == l:forward_back_match_pos

        if l:debug
            if len(l:match_ids) > 0
                for l:x in range(0, len(l:match_ids) - 1)
                    call matchdelete(l:match_ids[0])
                    call remove(l:match_ids, 0)
                endfor
            endif

            call add(l:match_ids, matchaddpos('IncSearch', [l:backward_match_pos]))
            redraw!
            sleep 1
            call add(l:match_ids, matchaddpos('IncSearch', [l:forward_match_pos]))
            redraw!
            sleep 1
        endif

        if l:bf_after_cursor && l:bf_before_forward
            " Find next forward from forward pos
            " find next bf from bf pos
            let l:set_new_forward_pos = v:true
        elseif l:fb_before_cursor && l:fb_after_back
            " Find a new back and search for a new fb from fb - 1
            let l:set_new_backward_pos = v:true
        else
            call SetCursorPos(l:backward_match_pos)
            return {'backward_match': l:backward_match_pos, 'forward_match': l:forward_match_pos, 'opts': get(l:match_list, 2, '')}
        endif
        let l:cycles += 1
    endwhile
    return ExitFindInnerBlock(l:cursor_pos)
endfunction

function! ExitFindInnerBlock(original_cursor_position)
    echo 'InnerBlock: No block found!'
    call setpos('.', a:original_cursor_position)
    return 0
endfunction

function! SetCursorPos(searchpos)
    let l:cursor = getpos('.')
    let l:cursor[1] = a:searchpos[0]
    let l:cursor[2] = a:searchpos[1]
    call setpos('.', l:cursor)
endfunction

function! GreaterSearchPos(pos_a, pos_b)
    if a:pos_a[0] != a:pos_b[0]
        return a:pos_a[0] > a:pos_b[0] ? a:pos_a : a:pos_b
    else
        return a:pos_a[1] > a:pos_b[1] ? a:pos_a : a:pos_b
    endif
endfunction

function! innerblock#DeleteInnerBlock(block_pairs, block_delimeter_type, key)
    if a:block_delimeter_type == "same"
        let l:blocks = innerblock#FindSameDelimiterInnerBlock(a:block_pairs)
    else
        let l:blocks = innerblock#FindInnerBlock(a:block_pairs)
    endif

    if type(l:blocks) == type(0)
        return
    endif

    let l:backward_match_line = l:blocks.backward_match[0]
    let l:backward_match_col = l:blocks.backward_match[1]
    let l:forward_match_line = l:blocks.forward_match[0]
    let l:forward_match_col = l:blocks.forward_match[1]

    if l:backward_match_line != l:forward_match_line
        let l:opts = split(l:blocks.opts, ',')
        let l:keep_first = index(l:opts, 'keep_first') != -1
        let l:keep_last = index(l:opts, 'keep_last') != -1

        if !(l:keep_first && l:keep_last)
            call setpos('.', SearchPosToCursorPos(l:blocks.backward_match))
            let l:line = getline('.')
            let l:corrected_line = strpart(l:line, 0, l:backward_match_col)
            call setline('.', l:corrected_line)

            call setpos('.', SearchPosToCursorPos(l:blocks.forward_match))
            let l:line = getline('.')
            let l:whitespace = strpart(l:line, 0, match(l:line, '\S'))
            let l:corrected_line = strpart(l:line, l:forward_match_col - 1)
            call setline('.', l:whitespace . l:corrected_line)
        endif

        let l:indent_level = []

        for l:line in range(l:backward_match_line + 1, l:forward_match_line - 1)
            call add(l:indent_level, indent(l:backward_match_line + 1))
            exe l:backward_match_line + 1 . 'd'
        endfor

        call setpos('.', SearchPosToCursorPos(l:blocks.backward_match))
        if(a:key ==# 'c')
            startinsert!
            call feedkeys("\<CR>")
        endif
    else
        let l:line = getline('.')
        let l:block_start = l:backward_match_col
        let l:block_end = l:forward_match_col - 1
        let l:newline = strpart(l:line, 0, l:block_start) . strpart(l:line, l:block_end, len(l:line))
        call setline('.', l:newline)

        let l:current_pos = getpos('.')
        let l:current_pos[2] = l:block_start + 1
        call setpos('.', l:current_pos)

        if(a:key ==# 'c')
            startinsert
        endif
    endif
endfunction

function! IsPositionAt(pos, pattern)
    return match(getline(a:pos[0]), a:pattern) + 1 == a:pos[1]
endfunction

function! SearchPosToCursorPos(pos)
    let l:cur_pos = getpos('.')
    let l:cur_pos[1] = a:pos[0]
    let l:cur_pos[2] = a:pos[1]
    return l:cur_pos
endfunction

function! innerblock#SortInsideBlock(blocks)
    let l:blocks = innerblock#FindInnerBlock(a:blocks)
    if type(l:blocks) == type(0)
        return
    endif

    let l:backward_match_line = l:blocks.backward_match[0]
    let l:backward_match_col = l:blocks.backward_match[1]
    let l:forward_match_line = l:blocks.forward_match[0]
    let l:forward_match_col = l:blocks.forward_match[1]

    execute(printf('%s,%s:sort', l:backward_match_line + 1, l:forward_match_line - 1))
endfunction
