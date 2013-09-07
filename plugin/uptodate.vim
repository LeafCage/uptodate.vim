let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=0   UptodateResetting    runtime plugin/uptodate.vim
if !exists('g:uptodate_filenamepatterns')
  finish
endif
command! -nargs=* -complete=customlist,uptodate#_get_cmdcomplete_for_reload
  \ UptodateReload    call uptodate#reload([<f-args>])


"=============================================================================
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
for elm in g:uptodate_filenamepatterns
  let g:uptodate_loaded[elm] = {'filepath': '', 'ver': 0}
endfor

"=============================================================================
aug uptodate
  au!
aug END

"autocmd for safety lock
let s:autocmd_pat = join(map(copy(g:uptodate_filenamepatterns), '"*/autoload/". v:val'), ',')
exe 'autocmd uptodate StdinReadPost,BufWinEnter '. s:autocmd_pat. '  call uptodate#forbid_editting_previousver('. string(g:uptodate_filenamepatterns). ')'
unlet s:autocmd_pat

"autocmd for bufwrite
let s:autocmd_pats = copy(g:uptodate_filenamepatterns)
call map(s:autocmd_pats, 'fnamemodify(v:val, ":t")')
call s:_uniq(s:autocmd_pats)
for s:filename in s:autocmd_pats
  exe 'autocmd uptodate BufWritePre,FileWritePre '. s:filename. '  call uptodate#update_timestamp()'
  exe 'autocmd uptodate BufWritePost,FileWritePost '. s:filename. '  call uptodate#update_otherfiles('. string(g:uptodate_filenamepatterns). ')'
endfor
delfunction s:_uniq
unlet s:autocmd_pats s:filename

exe 'autocmd uptodate BufWritePre,FileWritePre */autoload/uptodate.vim  call uptodate#update_uptodatefile()'
"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
