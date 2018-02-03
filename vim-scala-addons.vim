" A quick list of common classes I import, so I don't
"need to use Ensime's slow lookup for them.
let s:expansions = { 
  \'Try': 'scala.util.Try', 
  \'Success': 'scala.util.Success', 
  \'Failure': 'scala.util.Failure' ,
  \'Timeout': 'akka.util.Timeout',
  \'Actor': 'akka.actor.Actor',
  \'ActorSystem': 'akka.actor.ActorSystem',
  \'ActorRef': 'akka.actor.ActorRef',
  \'Props': 'akka.actor.Props',
  \'pipeTo': 'akka.pattern.pipe',
  \'?': 'akka.pattern.ask',
  \'ConfigFactory': 'com.typesage.config.ConfigFactory',
  \'Logger': 'com.typesafe.scalalogging.Logger',
  \'LoggerFactory': 'org.slf4j.LoggerFactory',
  \'Future': 'scala.concurrent.Future',
  \'ExecutionContext': 'scala.concurrent.ExecutionContext',
  \'seconds': "scala.concurrent.duration._",
  \'minutes': 'scala.concurrent.duration._',
  \'millis': 'scala.concurrent.duration._',
  \'JavaConverters': 'scala.collection.JavaConverters',
  \'UUID': 'java.util.UUID',
  \'@tailrec': 'scala.annotation.tailrec'
  \}

command! AddFastImport call s:AddFastImport()

function! s:AddFastImport() 

  execute "normal! mi"
  if has_key(s:expansions, expand("<cword>")) 
    let full_import = s:expansions[expand("<cword>")]
  elseif has_key(s:expansions, expand("<cWORD>"))
    let full_import = s:expansions[expand("<cWORD>")]
  else
    let full_import = ""
  endif

  if strlen( full_import ) > 0  
    echom "Adding import for " . full_import
 " insert after last import, after package or on first line
    if search('^\s*import\s', 'b') > 0 
      execute "normal! jIimport " . full_import . "\<cr>\<esc>"
    elseif search('^\s*package\s', 'b') > 0 
      execute "normal! joimport " . full_import . "\<cr>\<esc>"
    else 
      1
      execute "normal! Oimport " . full_import . "\<cr>\<esc>"
    endif
  else
    echom "Unknown class '" . expand("<cword>") . "' can't add import."
  endif

  execute "normal! `i"

endfunction

"Simple template for an empty Scala class with proper package
command EmptyScalaClass :call s:EmptyScalaClass()
function! s:EmptyScalaClass()
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
command LoadSBTErrors :call s:LoadSBTErrors()
function! s:LoadSBTErrors()
  compiler sbt
  "Since SBT only compiles tests when the main code compiles, load tests first
  if filereadable("target/streams/test/compileIncremental/\$global/streams/out")
    cfile target/streams/test/compileIncremental/\$global/streams/out
    caddfile target/streams/compile/compileIncremental/\$global/streams/out
    cc
  else 
    cfile target/streams/compile/compileIncremental/\$global/streams/out
  endif
endfunction



