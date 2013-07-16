let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=0   UptodateResetting    runtime plugin/uptodate.vim
if !exists('g:uptodate_filepatterns')
  finish
endif
command! -nargs=* -complete=customlist,uptodate#_get_cmdcomplete_for_reload  UptodateReload
  \ call uptodate#reload([<f-args>])


function! s:_get_autocmd_pats_as_list(autocmd_pats) "{{{
  "TODO: split()は\,はエスケープとしてsplit対象にしない
  return type(a:autocmd_pats) == type([]) ? copy(a:autocmd_pats) : split(a:autocmd_pats, ',')
endfunction
"}}}

let g:uptodate_loaded = {}
for elm in s:_get_autocmd_pats_as_list(g:uptodate_filepatterns)
  let g:uptodate_loaded[elm] = {}
endfor

aug uptodate
  au!
aug END


"======================================
function! s:def_autocmd_for_safetylock(autocmd_pats) "{{{
  let autocmd_pats = s:_get_autocmd_pats_as_list(a:autocmd_pats)
  let autocmd_pat = join(s:__append_autoloadstr(autocmd_pats), ',')
  exe 'autocmd uptodate StdinReadPost,BufWinEnter '. autocmd_pat. '  setl ro'
endfunction
"}}}
function! s:__append_autoloadstr(autocmd_pats) "{{{
  return map(a:autocmd_pats, '"*/autoload/". v:val')
endfunction
"}}}
call s:def_autocmd_for_safetylock(g:uptodate_filepatterns)

function! s:def_autocmd_for_bufwrite(autocmd_pats) "{{{
  let autocmd_pats = s:_get_autocmd_pats_as_list(a:autocmd_pats)
  call map(autocmd_pats, 'fnamemodify(v:val, ":t")')
  call s:__uniq(autocmd_pats)
  for filename in autocmd_pats
    exe 'autocmd uptodate BufWritePre,FileWritePre '. filename. '  call uptodate#update_timestamp()'
    exe 'autocmd uptodate BufWritePre,FileWritePre '. filename. '  call uptodate#update_libfiles('. string(a:autocmd_pats). ')'
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
call s:def_autocmd_for_bufwrite(g:uptodate_filepatterns)

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
