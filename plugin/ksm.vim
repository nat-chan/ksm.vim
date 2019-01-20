scriptencoding utf-8
let s:save_cpo = &cpoptions
set cpoptions&vim
if exists('s:is_loaded')
    finish
endif
let s:is_loaded = 1

command KsmStart call ksm#start()
command KsmGoto call ksm#goto()

let &cpoptions = s:save_cpo
unlet s:save_cpo
