☂️
☔️

" ずっと雨が降っているときの通知をどうしよう
"     基本的に右下にずっと常駐でもいいかも
"     0だったら非表示、0以外だったら表示
" 降水確率を取得できるグローバル関数があるといいかも
" ざーざー降りのときに無効にする機能

if exists('g:loaded_rainfall')
  finish
endif
let g:loaded_rainfall = 1

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

command RainfallEnable call rainfall#enable()
command RainfallDisable call rainfall#disable()
command RainfallClose call rainfall#close()

RainfallEnable

let &cpo = s:save_cpo
unlet s:save_cpo

scriptencoding utf-8

let g:rainfall_url = 'https://tenki.jp/amedas/3/17/46106.html'
let g:rainfall_show_amount = v:true
let g:rainfall_prefix = 'raining: '
let g:rainfall_postfix = ' mm'

let s:last_datetime = ''
let s:amedas_updated = v:false
let s:winid = 0
let s:timerid = 0

function s:show_rainfall(timer) abort
  if s:winid == 0
    let s:amedas_updated = v:false
    let l:job = job_start(
          \ ['curl', g:rainfall_url,
          \ {'out_cb': function('s:parse_and_show_new_rainfall')})
  endif
endfunction

function s:parse_and_show_new_rainfall(ch, msg) abort
  if a:msg =~# 'amedas-point-datetime' && a:msg !=# s:last_datetime
    " 前回見た時刻から更新されている
    let s:last_datetime = a:msg
    let s:amedas_updated = v:true
  endif
  if s:amedas_updated && a:msg =~# '10分値'
    " 結果を表示
    let l:rainfall = a:msg[match(a:msg, "[0-9.]*mm"):match(a:msg, 'mm')-1]
    if str2float(l:rainfall) != 0.0
      if !g:rainfall_show_amount | let l:rainfall = '' | endif
      let s:winid = popup_create(g:rainfall_prefix .. l:rainfall .. g:rainfall_postfix, {
            \ 'border': [],
            \ 'padding': [],
            \ 'line': &lines-5,
            \ 'col': &columns-5,
            \ 'pos': 'botright',
            \ })
    endif
    let s:amedas_updated = v:false
  endif
endfunction

function rainfall#enable() abort
  " 5 分ごとに見に行く
  let s:timerid = timer_start(5 * 1000, function('s:show_rainfall'), {'repeat': -1})
endfunction

function rainfall#disable() abort
  call timer_stop(s:timerid)
endfunction

function rainfall#close() abort
  call popup_close(s:winid)
  let s:winid = 0
endfunction
