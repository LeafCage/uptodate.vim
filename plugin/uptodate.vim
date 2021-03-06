let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=0   UptodateResetAutocmd    runtime plugin/uptodate.vim
if !exists('g:uptodate_filenamepatterns')
  finish
endif
command! -nargs=* -complete=customlist,uptodate#uptodate#_get_cmdcomplete_for_reload
  \ UptodateReloadManagedScripts    call lib#uptodate#reload([<f-args>])
command! -nargs=0   UptodateShowManagedScripts    call lib#uptodate#show_managed_scripts()

let g:uptodate_cellardir = get(g:, 'uptodate_cellardir', '~/uptodate/_autoload')


"=============================================================================
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
exe 'autocmd uptodate StdinReadPost,BufWinEnter '. s:autocmd_pat. '  call lib#uptodate#forbid_editting_previousver('. string(g:uptodate_filenamepatterns). ')'
"autocmd for bufwrite
let s:cellarfile_pat = g:uptodate_cellardir=='' ? '' : fnamemodify(g:uptodate_cellardir, ':p:s?/$??'). '/*'
exe 'autocmd uptodate BufWritePre,FileWritePre '. s:autocmd_pat. ','. s:cellarfile_pat. '  call lib#uptodate#update_timestamp()'
exe 'autocmd uptodate BufWritePost,FileWritePost '. s:autocmd_pat. ','. s:cellarfile_pat. '  call lib#uptodate#update_otherfiles('. string(g:uptodate_filenamepatterns). ')'

exe 'autocmd uptodate StdinReadPost,BufWinEnter '. s:cellarfile_pat. '  call lib#uptodate#define_libfile_localinterfaces()'
unlet s:autocmd_pat s:cellarfile_pat

aug uptodate_internal
  au!
  autocmd BufWritePre,FileWritePre */autoload/lib/uptodate.vim  call lib#uptodate#update_uptodatefile()
  autocmd StdinReadPost,BufNewFile,BufRead */autoload/lib/uptodate.vim  call lib#uptodate#define_uptodate_localinterfaces()
aug END
"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
