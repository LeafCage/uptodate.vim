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

"runtime!する
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
      let s:lazyrtp = s:__add_runtimepath_for_neobundlelazy()
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
function! s:__add_runtimepath_for_neobundlelazy() "{{{
  let lazyrtp = ''
  if exists('*neobundle#config#get_neobundles')
    let lazyrtp = join(map(filter(neobundle#config#get_neobundles(),'v:val.lazy'), 'v:val.rtp'), ',')
    let vimrt_idx = match(substitute(&rtp, '\\', '/', 'g'), substitute($VIMRUNTIME, '\\', '/', 'g'))-1
    let &rtp = &rtp[:vimrt_idx]. lazyrtp. &rtp[(vimrt_idx):]
  endif
  return lazyrtp
endfunction
"}}}
"g:uptodate_loadedを更新
function! s:__log_loaded(sfilename, runtimecmd_args, updatetime) "{{{
  let runtimecmd_argslist = split(a:runtimecmd_args)
  let thispat = substitute(a:sfilename, '.*/\zeautoload/', '', '')
  let pat = substitute(get(runtimecmd_argslist, index(runtimecmd_argslist, thispat), ''), 'autoload/', '', '')
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
  let libfiles = copy(g:uptodate_filepatterns)
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

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
