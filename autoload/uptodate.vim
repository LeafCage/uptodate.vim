"最新版のautoload/uptodate.vimのみを読み込ませる "{{{
if exists('s:thisfile_updatetime')
  finish
endif
if !exists('g:uptodate_is_firstloaded')
  let g:uptodate_is_firstloaded = 1
  let s:firstloaded_is_this = 1
endif

let s:thisfile_updatetime = 1374041758
try
  if exists('g:uptodate_latesttime') && g:uptodate_latesttime >= s:thisfile_updatetime
    finish
  endif
  let g:uptodate_latesttime = s:thisfile_updatetime

  " NeoBundleLazyされてるplugin pathも 'runtimepath' に加える
  if !exists('g:uptodate_lazyrtp') && exists('*neobundle#config#get_neobundles')
    let g:uptodate_lazyrtp = join(map(filter(neobundle#config#get_neobundles(),'v:val.lazy'), 'v:val.rtp'), ',')
    let s:vimrt_idx = match(substitute(&rtp, '\\', '/', 'g'), substitute($VIMRUNTIME, '\\', '/', 'g'))-1
    let &rtp = &rtp[:(s:vimrt_idx)]. g:uptodate_lazyrtp. &rtp[(s:vimrt_idx):]
    unlet s:vimrt_idx
  endif
  let g:uptodate_lazyrtp = get(g:, 'uptodate_lazyrtp', '')

  if !exists('g:uptodate_is_runtiming')
    let g:uptodate_is_runtiming = 1
    runtime! autoload/uptodate.vim
  endif
  if g:uptodate_latesttime > s:thisfile_updatetime
    finish
  endif
finally
  unlet s:thisfile_updatetime
  if exists('s:firstloaded_is_this')
    exe 'set rtp-='. g:uptodate_lazyrtp
    unlet g:uptodate_lazyrtp
    unlet g:uptodate_is_runtiming g:uptodate_latesttime g:uptodate_is_firstloaded s:firstloaded_is_this
  endif
endtry
"}}}

"======================================
if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:TIMESTAMPROW_LAST = 35

function! s:_reset_scriptlocalvars()
  let s:sfiles = {}
  let s:latesttime = 0
  let s:is_runtiming = 0
  let s:lazyrtp = ''
endfunction
call s:_reset_scriptlocalvars()

"NeoBundleLazyされていて 'runtimepath' に加わっていないパスを一時的に加える
function! s:_add_runtimepath_for_neobundlelazy() "{{{
  let lazyrtp = ''
  if exists('*neobundle#config#get_neobundles')
    let lazyrtp = join(map(filter(neobundle#config#get_neobundles(),'v:val.lazy'), 'v:val.rtp'), ',')
    let vimrt_idx = match(substitute(&rtp, '\\', '/', 'g'), substitute($VIMRUNTIME, '\\', '/', 'g'))-1
    let &rtp = &rtp[:vimrt_idx]. lazyrtp. &rtp[(vimrt_idx):]
  endif
  return lazyrtp
endfunction
"}}}

"=============================================================================

"runtime!する そして読み込み中のスクリプトファイルが最新でない時は1を返す
function! uptodate#isnot_this_uptodate(sfilename, ...) "{{{
  if has_key(s:sfiles, a:sfilename)
    return 1
  endif
  let runtimecmd_args = a:0 ? a:1 : substitute(a:sfilename, '.*/\zeautoload/', '', '')
  let s:sfiles[a:sfilename] = s:sfiles == {} ? {'firstloaded': 1} : {'firstloaded': 0}
  let s:sfiles[a:sfilename].updatetime = s:__get_updatetime(a:sfilename)

  try
    if s:latesttime >= s:sfiles[a:sfilename].updatetime
      return 1
    endif
    let s:latesttime = s:sfiles[a:sfilename].updatetime

    if !s:is_runtiming
      let s:is_runtiming = 1
      let s:lazyrtp = s:_add_runtimepath_for_neobundlelazy()
      exe 'runtime! '. runtimecmd_args
    endif
    if s:latesttime > s:sfiles[a:sfilename].updatetime
      return 1
    endif
  finally
    if s:sfiles[a:sfilename].firstloaded
      call s:__log_loaded(a:sfilename, runtimecmd_args, s:sfiles[a:sfilename].updatetime)
      exe 'set rtp-='. s:lazyrtp
      call s:_reset_scriptlocalvars()
    endif
  endtry
endfunction
"}}}
function! s:__get_updatetime(filename) "{{{
  let lines = readfile(a:filename, '', s:TIMESTAMPROW_LAST)
  let timestamp_line = matchstr(lines, 'UPTODATE:\s*\d\+\.')
  if timestamp_line == ''
    return 0
  endif
  return eval(matchstr(timestamp_line, 'UPTODATE:\s*\zs\d\+\ze\.'))
endfunction
"}}}
"g:uptodate_loadedを更新
function! s:__log_loaded(sfilename, runtimecmd_args, updatetime) "{{{
  let runtimecmd_argslist = split(a:runtimecmd_args)
  let thispat = substitute(a:sfilename, '.*/\zeautoload/', '', '')
  let pat = substitute(get(runtimecmd_argslist, index(runtimecmd_argslist, thispat), ''), 'autoload/', '', '')
  if !exists('g:uptodate_loaded') || !has_key(g:uptodate_loaded, pat)
    return
  endif
  let g:uptodate_loaded[pat].filename = a:sfilename
  let g:uptodate_loaded[pat].ver = a:updatetime
endfunction
"}}}

"======================================
"再読み込みさせる
function! uptodate#reload(sfilenames) "{{{
  let sfilenames = a:sfilenames==[] ? g:uptodate_filepatterns : a:sfilenames
  for sfilename in sfilenames
    exe 'runtime autoload/'. sfilename
  endfor
endfunction
"}}}

"======================================
":UptodateReload の候補表示に利用
function! uptodate#_get_cmdcomplete_for_reload(arglead, cmdline, cursorpos) "{{{
  let libfiles = exists('g:uptodate_filepatterns') ? copy(g:uptodate_filepatterns) : []
  return filter(libfiles, 'v:val =~? a:arglead')
endfunction
"}}}

"======================================
"UPTODATE: . のタイムスタンプを発見、更新する
function! uptodate#update_timestamp() "{{{
  let lines = getline(1, s:TIMESTAMPROW_LAST)
  let timestamp_row = match(lines, 'UPTODATE:\s*\d*\.')+1
  if timestamp_row == 0
    return -1
  endif
  let updatetime = localtime()
  call setline(timestamp_row, substitute(lines[timestamp_row-1], 'UPTODATE:\s*\zs\d*\ze\.', updatetime, ''))
endfunction
"}}}
"autoload/uptodate.vimのタイムスタンプ変数を更新する
function! uptodate#update_uptodatefile() "{{{
  let lines = getline(1, s:TIMESTAMPROW_LAST)
  let timestamp_row = match(lines, '\s*let\s\+s:thisfile_updatetime')+1
  if timestamp_row == 0
    return -1
  endif
  let updatetime = localtime()
  call setline(timestamp_row, 'let s:thisfile_updatetime = '. updatetime)
endfunction
"}}}

"======================================
"runtimepathの通ったライブラリスクリプトファイルを更新する
function! uptodate#update_libfiles(filepatterns) "{{{
  let filepatterns = s:__select_crrpats(a:filepatterns)
  if filepatterns == []
    return
  endif

  let pat = get(filepatterns, 0)
  let lazyrtp = s:_add_runtimepath_for_neobundlelazy()
  let paths = split(globpath(&rtp, 'autoload/'. pat), "\n")
  exe 'set rtp-='. lazyrtp
  call filter(paths, 'filereadable(v:val)')
  for path in paths
    call writefile(readfile(expand('%:p'), 'b'), path, 'b')
  endfor
endfunction
"}}}
function! s:__select_crrpats(filepatterns) "{{{
  let filepatterns = copy(a:filepatterns)
  let crrpath = expand('%:p')
  let crrtail = fnamemodify(crrpath, ':t')
  call filter(filepatterns, 'fnamemodify(v:val, ":t")==crrtail')
  if filepatterns == []
    return []
  endif

  let i = 1
  while filepatterns!=[]
    let save_filepatterns = copy(filepatterns)
    let mod = repeat(':h', i)
    let crrupperdir = fnamemodify(crrpath, mod. ':t')
    call filter(filepatterns, 'fnamemodify(v:val, mod. ":t")==crrupperdir')
    let i += 1
  endwhile
  return save_filepatterns
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
