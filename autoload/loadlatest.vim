if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:TIMESTAMPROW_BGN = 1
let s:TIMESTAMPROW_LAST = 5

function! s:_reset_scriptvars()
  let s:sfiles = {}
  let s:latesttime = 0
  let s:is_runtiming = 0
  let s:lazyrtp = ''
endfunction
call s:_reset_scriptvars()

function! loadlatest#isnot_this_latest_sourcefile(sfilename, runtimecmd_args) "{{{
  if has_key(s:sfiles, a:sfilename)
    return 1
  endif
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
      exe 'runtime! '. a:runtimecmd_args
    endif
    if s:latesttime > s:sfiles[a:sfilename].updatetime
      return 1
    endif
  finally
    if s:sfiles[a:sfilename].firstloaded
      exe 'set rtp-='. s:lazyrtp
      call s:_reset_scriptvars()
    endif
  endtry
endfunction
"}}}
function! s:__get_updatetime(filename) "{{{
  let lines = getline(s:TIMESTAMPROW_BGN, s:TIMESTAMPROW_LAST)
  let timestamp_line = matchstr(lines, 'LOADLATEST:\s*\d\+\.')
  if timestamp_line == ''
    return 0
  endif
  return eval(matchstr(timestamp_line, 'LOADLATEST:\s*\zs\d\+\ze\.'))
endfunction
"}}}
function! s:__add_runtimepath_for_neobundlelazy() "{{{
  let lazyrtp = ''
  if exists('*neobundle#config#get_neobundles')
    let lazyrtp = join(map(filter(neobundle#config#get_neobundles(),'v:val.lazy'), 'v:val.rtp'), ',')
    let vimrt_idx = match(substitute(&rtp, '\\', '/', 'g'), substitute($VIMRUNTIME, '\\', '/', 'g'))-1
    let &rtp = &rtp[:vimrt_idx]. lazyrtp. &rtp[vimrt_idx:]
  endif
  return lazyrtp
endfunction
"}}}

"======================================
"LOADLATEST: . のタイムスタンプを発見、更新する
function! loadlatest#update_timestamp() "{{{
  let lines = getline(s:TIMESTAMPROW_BGN, s:TIMESTAMPROW_LAST)
  let timestamp_row = match(lines, 'LOADLATEST:\s*\d*\.')+1
  if timestamp_row == 0
    return -1
  endif
  let updatetime = localtime()
  call setline(timestamp_row, substitute(lines[timestamp_row-1], 'LOADLATEST:\s*\zs\d*\ze\.', updatetime, ''))
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
