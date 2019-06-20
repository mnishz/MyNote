scriptencoding utf-8

" ずっと雨が降っているときの通知をどうしよう
"     基本的に右下にずっと常駐でもいいかも
"     0だったら非表示、0以外だったら表示
" 降水確率を取得できるグローバル関数があるといいかも
" ざーざー降りのときに無効にする機能

let g:last_datetime = ''
let g:amedas_updated = v:false
let g:winid = 0

let g:cur_line = 1
let g:test_rain = v:false

function s:show_rainfall(timer) abort
  let g:cur_line = 1
  if g:winid == 0
    let g:amedas_updated = v:false
    " for proxy, "curl URL -x http://ID:password@proxy:port"
    let l:job = job_start(
          \ ['curl', 'https://tenki.jp/amedas/3/17/46106.html'],
          \ {'out_cb': function('s:parse_and_show_new_rainfall')})
    call popup_create('job_started', {'time': 1000, 'line': g:cur_line, 'col': 1}) | let g:cur_line = (g:cur_line % 10) + 1
  endif
endfunction

function s:parse_and_show_new_rainfall(ch, msg) abort
  if a:msg =~# 'amedas-point-datetime'
    if a:msg !=# g:last_datetime
      " 前回見た時刻から更新されている
      let g:last_datetime = a:msg
      let g:amedas_updated = v:true
      hi Pmenu guibg=Magenta
      call popup_create('updated', {'time': 1000, 'line': g:cur_line, 'col': 1}) | let g:cur_line = (g:cur_line % 10) + 1
    else
      hi Pmenu guibg=Blue
      call popup_create('not updated', {'time': 1000, 'line': g:cur_line, 'col': 1}) | let g:cur_line = (g:cur_line % 10) + 1
    endif
  endif
  if g:amedas_updated && (a:msg =~# '10分値' || g:test_rain)
    " 結果を表示
    let l:rainfall = a:msg[match(a:msg, "[0-9.]*mm"):match(a:msg, 'mm')-1]
    if g:test_rain
      let l:rainfall = '1.0'
      let g:test_rain = v:false
    endif
    call popup_create(l:rainfall, {'time': 1000, 'line': g:cur_line, 'col': 1}) | let g:cur_line = (g:cur_line % 10) + 1
    if str2float(l:rainfall) != 0.0
      let g:winid = popup_create(l:rainfall, {'border': []})
      hi Pmenu guibg=Red
      call popup_create('rain', {'time': 1000, 'line': g:cur_line, 'col': 1}) | let g:cur_line = (g:cur_line % 10) + 1
    endif
    let g:amedas_updated = v:false
  endif
endfunction

" 5 分ごとに見に行く
let timer = timer_start(5 * 1000, function('s:show_rainfall'), {'repeat': -1})

function s:rainfall_close() abort
  call popup_close(g:winid)
  let g:winid = 0
endfunction

command RainfallClose call s:rainfall_close()
