let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=0   UptodateResetting    runtime plugin/uptodate.vim
if !exists('g:uptodate_filenamepatterns')
  finish
endif
command! -nargs=* -complete=customlist,uptodate#_get_cmdcomplete_for_reload  UptodateReload
  \ call uptodate#reload([<f-args>])


"=============================================================================
"TODO: split()は\,はエスケープとしてsplit対象にしない
let s:filenamepatterns = type(g:uptodate_filenamepatterns)==type([]) ? g:uptodate_filenamepatterns
  \ : split(g:uptodate_filenamepatterns, ',')
"==================
function! s:_uniq(list) "{{{
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

"======================================
let g:uptodate_loaded = {}
for elm in s:filenamepatterns
  let g:uptodate_loaded[elm] = {'filename': '', 'ver': 0}
endfor

"=============================================================================
aug uptodate
  au!
aug END

"autocmd for safety lock
let s:autocmd_pat = join(map(copy(s:filenamepatterns), '"*/autoload/". v:val'), ',')
exe 'autocmd uptodate StdinReadPost,BufWinEnter '. s:autocmd_pat. '  setl ro'
unlet s:autocmd_pat

"autocmd for bufwrite
let s:autocmd_pats = copy(s:filenamepatterns)
call map(s:autocmd_pats, 'fnamemodify(v:val, ":t")')
call s:_uniq(s:autocmd_pats)
for filename in s:autocmd_pats
  exe 'autocmd uptodate BufWritePre,FileWritePre '. filename. '  call uptodate#update_timestamp()'
  exe 'autocmd uptodate BufWritePost,FileWritePost '. filename. '  call uptodate#update_libfiles('. string(s:filenamepatterns). ')'
endfor
delfunction s:_uniq
unlet s:autocmd_pats filename s:filenamepatterns

exe 'autocmd uptodate BufWritePre,FileWritePre */autoload/uptodate.vim  call uptodate#update_uptodatefile()'
"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
