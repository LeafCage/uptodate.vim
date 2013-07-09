let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
"test: 動作確認したら消す
let g:loadlatest_libfile_patterns = ['*/autoload/lclib3.vim', '*/autoload/test/lclib3.vim']

if !exists('g:loadlatest_libfile_patterns')
  finish
endif

aug loadlatest
  au!
aug END

function! s:def_autocmd_for_safetylock(autocmd_pat) "{{{
  let autocmd_pat = type(a:autocmd_pat) == type([]) ? join(a:autocmd_pat, ',') : a:autocmd_pat
  exe 'autocmd loadlatest StdinReadPost,BufWinEnter '. autocmd_pat. '  setl ro noma'
endfunction
"}}}
call s:def_autocmd_for_safetylock(g:loadlatest_libfile_patterns)

function! s:def_autocmd_for_updatetimeheader(autocmd_pats) "{{{
  "TODO: split()は\,はエスケープとしてsplit対象にしない
  let autocmd_pats = type(a:autocmd_pats) == type([]) ? a:autocmd_pats : split(a:autocmd_pats, ',')
  call map(autocmd_pats, 'fnamemodify(v:val, ":t")')
  call s:__uniq(autocmd_pats)
  for filename in autocmd_pats
    exe 'autocmd loadlatest BufWritePre,FileWritePre '. filename. '  call loadlatest#update_timestamp()'
  endfor
endfunction
"}}}
function! s:__uniq(list) "{{{
  let seen = {}
  for elm in a:list
    let key = string(elm)
    if has_key(seen, key)
      call remove(a:list, index(a:list, elm))
    else
      let seen[key] = 1
    endif
  endfor
endfunction
"}}}
call s:def_autocmd_for_updatetimeheader(g:loadlatest_libfile_patterns)

"command! -nargs=? -complete=custom  LoadLatest    <`4:#:<q-args><f-args><line1-2><count><bang><reg>`>
"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
