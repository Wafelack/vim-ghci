" ghci.vim - a Haskell REPL inside Vim
" Maintainer: Wafelack <wafelack@riseup.net>
" Version: 0.1.0
" License: GPL-3.0-or-later

if exists("g:ghci_loaded")
    finish
endif
let g:ghci_loaded = 1

if !exists("g:mapleader")
    let g:mapleader = ' '
endif

if !exists("g:ghci_open_split")
    " Possible values:
    "   0 => Edit in a vertical split
    "   1 => Edit in the current window
    "   2 => Edit in a horizontal split
    "   3 => Edit in a new tab
    let g:ghci_open_split = 0
endif
if !exists("g:ghci_prefix")
    let g:ghci_prefix = "-- "
endif

let s:end = "normal! G$a\<CR>\<ESC>"
let s:matcher = 'my @slurp = <>; my @slurp = reverse @slurp; shift @slurp; my @lines = (); foreach (@slurp) { if ($_ =~ /;;==FF(.*)$/) { push @lines, ("'. g:ghci_prefix . '" . $1 . "\n"); last; } push @lines, ("' . g:ghci_prefix . '" . $_); } foreach (reverse @lines) { print; }'

function! s:IsAtHome()
    return getcwd() ==# $HOME
endfunction

function! s:WriteFile(filename, content, append)
    let @h = a:content
    exec "normal! :split " . a:filename . "\<CR>" . (a:append ? "G$a\<CR>\<ESC>" : "ggdG") . "\"hp:g/^$/d\<CR>:x\<CR>"
endfunction

function! SetupGHCi()
    if !s:IsAtHome()
        call s:WriteFile(".ghci", ":set prompt \";;==FF\"", 0)
    else
        echom "Please do not run this plugin in your home directory, as changing some rules in your global `.ghci` file might break."
        return
    endif
    let s:command = "vsplit"
    if g:ghci_open_split == 1
        let s:command = "enew"
    elseif g:ghci_open_split == 2
        let s:command = "split"
    elseif g:ghci_open_split == 3
        let s:command = "tabnew"
    endif
    exec s:command
    enew
    setfiletype ghci
endfunction

function! s:Chomp(s)
    return substitute(substitute(a:s, '^\n\+', '', ''), '\n\+$', '', '')
endfunction

function! s:DeleteFile(filename)
    if delete(a:filename)
        echom "[-] Failed to delete `" . a:filename . "`."
    else
        echom "[+] Deleted `" . a:filename . "`."
    endif
endfunction

function! DestroyGHCi()
    if !s:IsAtHome()
        call s:DeleteFile(".ghci")
        call s:DeleteFile(".vim.ghci")
    endif
    if &filetype ==# "ghci"
        quit!
    endif
endfunction

function! RunCode(code)
    let s:fname = ".vim.ghci"
    echom a:code
    call s:WriteFile(s:fname, a:code, 1)
    let s:code = ".!ghci < " . s:fname . " >& /dev/stdout | perl -e '" . s:matcher . "'"
    exec s:code
endfunction

function! RunLine()
    exec "normal! yy$a\<CR>\<ESC>"
    call RunCode(s:Chomp(@"))
    exec s:end
endfunction

command GHCiOpen :call SetupGHCi()
command GHCiEval :call RunLine()

augroup ghci
    autocmd!
    autocmd FileType ghci nnoremap <buffer> <leader>ge :call RunLine()<CR>
    autocmd FileType ghci nnoremap <buffer> <leader>gc :call s:DeleteFile(".vim.ghci")<CR>
    autocmd FileType ghci nnoremap <buffer> <leader>gk :call DestroyGHCi()<CR>
augroup end
