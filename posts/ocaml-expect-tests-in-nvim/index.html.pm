#lang pollen

◊h1{Working with OCaml expect tests in NeoVim}
◊posting-date{2025-03-25}

◊section{
  This is just a quick note and not a full-on post.
  I've been playing around with inline expect tests in OCaml using the ◊a[#:href "https://github.com/janestreet/ppx_expect"]{ppx_expect} library.
  The way these expect tests work is that they will capture ◊code{stdout} from select parts of your test function, then they will either store that as their value if you are running it for the first time, or they will compare the output against their stored value.
  If the new output is different from the stored output, then ◊code{dune} will give you a nice diff and tell you that it stored a corrected version of that file.
}

◊code-listing["diff"]{
--- a/_build/default/lib/query.ml
+++ b/_build/.sandbox/6248834ca8898cf067c96e6df4119c43/default/lib/query.ml.corrected
@@ -15,7 +15,7 @@ let print = sexp_of_t >> Sexp.to_string

 let%expect_test "parse load csv" =
   printf "%s" (print (parse "(LoadCSV blah.csv)"));
-  [%expect {| |}]
+  [%expect {| (LoadCSV blah.csv) |}]
}

◊section{
  If you decide you want to accept that diff, then you can run ◊code{dune promote}:
}

◊code-listing["bash"]{
camalbrarian (main) $ dune promote
Promoting _build/default/lib/query.ml.corrected to lib/query.ml.
}

◊section{
  I want to read through all of the ◊a[#:href "https://dune.readthedocs.io/en/stable/"]{dune docs} and maybe write a post dedicated to ◊code{dune}'s features, but I love the integration between ◊code{dune} and the testing library.
  This workflows feels great even if you are switching tabs/terminals to manually run ◊code{dune promote}.

  But, I use NeoVim, so of course, I have to make my own keymappings so I can do all of this within my editor:
}

◊code-listing["lua"]{
-- Run all tests and try to promote the current file
vim.keymap.set('n', '<leader>rp', ':silent !dune runtest<cr>:silent !dune promote %<cr>')
-- Run all tests and show the results
vim.keymap.set('n', '<leader>rr', ':!dune runtest<cr>')
}

◊section{
  These keymaps have been working great so far!
  My only complaint is that ◊code{dune} does not support running inline tests for a single file (as far as I can tell).
  So, you have to run all the tests in a project.
  But, at least ◊code{dune promote} can take in a file parameter, so I can only promote the changes for the file I'm looking at.
}

◊section{
  Most of the time, I like to run ◊code{<leader>rr} first to view the changes in NeoVim to make sure they look good.
  Then I run ◊code{<leader>rp} to run and promote.
  Now that I think about it, I may just change ◊code{<leader>rp} to only promote and let it promote changes for all files.
  I'm usually only working on writing one test at a time anyways.
}

◊section{
  I hope you enjoyed the NeoVim + OCaml tip.
  Thanks for reading!
}
