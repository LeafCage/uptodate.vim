let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=0   UptodateResetAutocmd    runtime plugin/uptodate.vim
if !exists('g:uptodate_filenamepatterns')
  finish
endif
command! -nargs=* -complete=customlist,uptodate#_get_cmdcomplete_for_reload
  \ UptodateReloadManagedScripts    call uptodate#reload([<f-args>])


"=============================================================================
let g:uptodate_loaded = {}
for elm in g:uptodate_filenamepatterns
  let g:uptodate_loaded[elm] = {'filepath': '', 'ver': 0}
endfor

"=============================================================================
aug uptodate
  au!
aug uptodate_internal
  au!
aug END

"autocmd for safety lock
let s:autocmd_pat = join(map(copy(g:uptodate_filenamepatterns), '"*/autoload/". v:val'), ',')
exe 'autocmd uptodate StdinReadPost,BufWinEnter '. s:autocmd_pat. '  call uptodate#forbid_editting_previousver('. string(g:uptodate_filenamepatterns). ')'
"autocmd for bufwrite
exe 'autocmd uptodate BufWritePre,FileWritePre '. s:autocmd_pat. '  call uptodate#update_timestamp()'
exe 'autocmd uptodate BufWritePost,FileWritePost '. s:autocmd_pat. '  call uptodate#update_otherfiles('. string(g:uptodate_filenamepatterns). ')'
unlet s:autocmd_pat

autocmd uptodate_internal BufWritePre,FileWritePre */autoload/uptodate.vim  call uptodate#update_uptodatefile()
autocmd uptodate_internal StdinReadPost,BufNewFile,BufRead */autoload/uptodate.vim  call uptodate#define_uptodate_localinterfaces()
"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
