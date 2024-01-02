" Inside Brackets
let g:inner_block_bracket_pairs = [
    \ ['(', ')'],
    \ ['{', '}'],
    \ ['[', ']'],
\]
    " \ ['<', '/>\|>'],

let g:inner_block_html_tag_pairs = [
    \ ["<", ">"],
    \ ['<', '/>\|>'],
    \ ['>', '<'],
\]

let g:inner_block_string_pairs = [
    \ ["'", "'"],
    \ ['"', '"'],
    \ ['`', '`'],
\]

" NOTE: WIP. The method this plugin uses for searching does not handle the dollar
" sign character properly, causing odd/undesired behavior
let g:inner_block_latex_pairs = [
    \ ['\$', '\$'],
\]

" Search this many lines above and below the current window
let g:inner_block_limit = 50
let g:inner_block_max_level = 16

" Inside Brackets
nnoremap <silent> cib :call innerblock#DeleteInnerBlock(g:inner_block_bracket_pairs, "different", "c")<CR>
nnoremap <silent> kib :call innerblock#DeleteInnerBlock(g:inner_block_bracket_pairs, "different", "k")<CR>
nnoremap <silent> sib :call innerblock#SortInsideBlock(g:inner_block_bracket_pairs)<CR>

" Inside Tags
nnoremap <silent> cit :call innerblock#DeleteInnerBlock(g:inner_block_html_tag_pairs, "different", "c")<CR>
nnoremap <silent> kit :call innerblock#DeleteInnerBlock(g:inner_block_html_tag_pairs, "different", "k")<CR>
nnoremap <silent> sit :call innerblock#SortInsideBlock(g:inner_block_html_tag_pairs)<CR>

" Inside String
nnoremap <silent> cis :call innerblock#DeleteInnerBlock(g:inner_block_string_pairs, "different", "c")<CR>
nnoremap <silent> kis :call innerblock#DeleteInnerBlock(g:inner_block_string_pairs, "different", "k")<CR>

" Inside Latex
nnoremap <silent> cil :call innerblock#DeleteInnerBlock(g:inner_block_latex_pairs,  "same", "c")<CR>
nnoremap <silent> kil :call innerblock#DeleteInnerBlock(g:inner_block_latex_pairs, "same", "k")<CR>

