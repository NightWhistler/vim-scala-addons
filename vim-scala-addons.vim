" A quick list of common classes I import, so I don't
"need to use Ensime's slow lookup for them.
let s:expansions = {
  \'Try': 'scala.util.Try',
  \'Success': 'scala.util.Success',
  \'Failure': 'scala.util.Failure' ,
  \'Timeout': 'akka.util.Timeout',
  \'Actor': 'akka.actor.Actor',
  \'ActorLogging': 'akka.actor.ActorLogging',
  \'ActorSystem': 'akka.actor.ActorSystem',
  \'ActorRef': 'akka.actor.ActorRef',
  \'Props': 'akka.actor.Props',
  \'pipeTo': 'akka.pattern.pipe',
  \'?': 'akka.pattern.ask',
  \'TestKit': 'akka.testkit.TestKit',
  \'ImplicitSender': 'akka.testkit.ImplicitSender',
  \'TestProbe': 'akka.testkit.TestProbe',
  \'ConfigFactory': 'com.typesafe.config.ConfigFactory',
  \'Config': 'com.typesafe.config.Config',
  \'Logger': 'com.typesafe.scalalogging.Logger',
  \'LoggerFactory': 'org.slf4j.LoggerFactory',
  \'Future': 'scala.concurrent.Future',
  \'WordSpec': 'org.scalatest.WordSpec',
  \'WordSpecLike': 'org.scalatest.WordSpecLike',
  \'Matchers': 'org.scalatest.Matchers',
  \'ExecutionContext': 'scala.concurrent.ExecutionContext',
  \'seconds': "scala.concurrent.duration._",
  \'minutes': 'scala.concurrent.duration._',
  \'millis': 'scala.concurrent.duration._',
  \'JavaConverters': 'scala.collection.JavaConverters',
  \'UUID': 'java.util.UUID',
  \'@tailrec': 'scala.annotation.tailrec'
  \}

"Adds a Scala import based on the idea that most of the time I
"only really use the same couple dozen classes, so this is way faster
"than having Ensime look it up.
"
"The added benefit is that it can do matching that a more intelligent
"import tool can't do like ? -> akka.pattern.ask
"
"Based in part on http://vim.wikia.com/wiki/Add_Java_import_statements_automatically
command! AddFastImport call s:AddFastImport()

function! s:AddFastImport()

  execute "normal! mi"
  let foundPackages = []

  if has_key(s:expansions, expand("<cword>"))
    let foundPackages = [s:expansions[expand("<cword>")]]
  elseif has_key(s:expansions, expand("<cWORD>"))
    let foundPackages = [s:expansions[expand("<cWORD>")]]
  else
    let foundPackages = s:FindPackage(expand("<cword>"))
  endif

  if len(foundPackages) == 1 
    let full_import = foundPackages[0]
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
  elseif len(foundPackages) > 1
    echom "More than 1 match found for class '" . expand("<cword>") . "' can't add import."
  else
    echom "No matches found for class '" . expand("<cword>") . "' can't add import."
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

command OpenSpec :call s:OpenSpec()
function! s:OpenSpec()
  let filename = expand("%")

  if filename =~# 'Spec\.scala$'
    let filename = substitute(filename, "\Spec.scala$", "\.scala", "")
    let filename = substitute(filename, "src/test/scala/", "src/main/scala/", "")
  else
    let filename = substitute(filename, "\.scala$", "Spec\.scala", "")
    let filename = substitute(filename, "src/main/scala/", "src/test/scala/", "")
  endif
  execute "edit " . filename
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
  " compiler sbt
  "
  " SBT 1.0 Changed the errorformat, so the one in vim-scala no longer works.
  " We really need a nice dynamic way to switch.
  set errorformat=%E\ %#[error]\ %f:%l:%c:\ %m,%C\ %#[error]\ %p^,%-C%.%#,%Z,
      \%W\ %#[warn]\ %f:%l:%c:\ %m,%C\ %#[warn]\ %p^,%-C%.%#,%Z,
      \%-G%.%#

  "Clear the Quickfix list
  cexpr []
  let foundItem = 0

  "Find all files named 'out'
  let outFiles = systemlist("find . -name out")

  for item in outFiles
    "Filter on items with compileIncremental
    if item =~# 'compile' || item =~# 'scalastyle'
      let foundItem = 1
      "Escape the $ in $global
      let fileName = substitute( item, "\\$", "\\\\$", "")
      execute "caddfile " . fileName
    endif
  endfor

  if foundItem
    cc
  else
    "This will hardly ever happen since I can't actually detect yet if the
    "files contained errors.
    echo "Found no errors... yay!"
  endif

endfunction

command LoadCtags :call s:LoadCtags()
function! s:LoadCtags()
  let tagFiles = systemlist("find $PWD -name .tags")
  set tags=""
  for item in tagFiles
    execute "set tags+=" . item
  endfor
endfunction

command ShowPackages :call s:ShowPackages(expand("<cword>"))
function! s:ShowPackages(word)
  let matching = s:FindPackage(a:word)
  for item in matching
    echo "Match: " . item
  endfor

  if len(matching) == 0
    echo "No matches found for " . a:word
  endif

endfunction

command FindPackage :call s:FindPackage(expand("<cword>"))
function! s:FindPackage(word)

  let word = a:word
  let tags = taglist('^' . word)
  let tags = filter(tags, 's:IsSupportedTag(v:val["kind"])')

  let mapped = map(tags, 's:ConstructClassName(v:val["filename"], word)')

  return uniq(sort(mapped))
endfunction

function s:IsSupportedTag(kind)
  return a:kind == "c"  
    || a:kind == "i"
    || a:kind == "t"
    || a:kind == "O"
    || a:kind == "C"
endfunction

function s:ConstructClassName(filename, className)
  let packageName = g:FileNameToPackage(a:filename)
  let fullName = packageName . "." . a:className
  return fullName
endfunction

function g:FileNameToPackage(filename)
  let filename = a:filename
  "TODO: Find out how to do an OR pattern
  let filename = substitute(filename, "\.scala$", "", "")
  let filename = substitute(filename, "\.java$", "", "")

  let dir = filename
  let dir = substitute(dir, "^.*src\/.*\/java\/", "", "")
  let dir = substitute(dir, "^.*src\/.*\/scala\/", "", "")

  "TODO: Slightly hacky hard-coded folder name
  let dir = substitute(dir, "^.*target\/sbt-ctags-dep-srcs\/", "", "")

  let dir = substitute(dir, "\/", ".", "g")

  "Strip off the class name / file name
  let dir = substitute(dir, "\.[A-Za-z]*$", "", "")

  return dir

endfunction


