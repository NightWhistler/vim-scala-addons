
"A quick list of common classes I import, so I don't
"need to use Ensime's slow lookup for them.
let s:expansions = { 'Try': 'scala.util.Try', 
  \'Success': 'scala.util.Success', 
  \'Failure': 'scala.util.Failure' 
  \}

command! AddFastImport call s:AddFastImport(expand("<cword>"))

function! s:AddFastImport( word ) 

  if has_key(s:expansions, a:word) 

    let full_import = s:expansions[a:word]
    echom "Adding import for " . full_import
 " insert after last import or in first line
    if search('^\s*import\s', 'b') == 0
      1
    endif

    execute "normal! Iimport " . full_import . "\<cr>\<esc>"
  else
    echom "Unknown class, can't add import."
  endif

endfunction

"Simple template for an empty Scala class with proper package
command EmptyScalaClass :call EmptyScalaClass()
function! EmptyScalaClass()
  let filename = expand("%")
  let filename = substitute(filename, "\.scala$", "", "")
  let dir = getcwd() . "/" . filename
  let dir = substitute(dir, "^.*\/src\/.*\/scala\/", "", "")
  let dir = substitute(dir, "\/[^\/]*$", "", "")
  let dir = substitute(dir, "\/", ".", "g")
  let filename = substitute(filename, "^.*\/", "", "")
  let dir = "package " . dir 
  let result = append(0, dir)
  let result = append(1, "")
  let result = append(2, "class " . filename . " {")
  let result = append(4, "}")
endfunction

"Loads SBT errors into the Quickfix list. This assumes you are
"running SBT with the -Dsbt.log.noformat=true flag.
"
"This also depends on the SBT compiler being present, as provided
"by vim-scala
"
"This allows you to have SBT running a continuous compile loop (~compile)
"and to quickly load the errors into VIM and jump to the first error.
command LoadSBTErrors :call LoadSBTErrors()
function! LoadSBTErrors()
  "Since SBT only compiles tests when the main code compiles, load tests first
  if filereadable("target/streams/test/compileIncremental/\$global/streams/out")
    cfile target/streams/test/compileIncremental/\$global/streams/out
    caddfile target/streams/compile/compileIncremental/\$global/streams/out
    cc
  else 
    cfile target/streams/compile/compileIncremental/\$global/streams/out
  endif

endfunction



