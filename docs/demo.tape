# Real sealed-council CLI demo. Hide = waits/setup, not fake output.
# Run from the repo root: vhs docs/demo.tape
Output docs/demo.gif

Require sealed-council

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.3
Set Framerate 16
Set Padding 20
Set WindowBar Colorful

Hide
Type "R=$PWD; export PATH=$R/bin:$PATH"
Enter
Type "export SC_HOME=$(mktemp -d)"
Enter
Type "cd $(mktemp -d)"
Enter
Type "cp $R/examples/one-run/brief.md brief.md"
Enter
Type "cp $R/examples/one-run/verdict.md verdict.md"
Enter
Type "clear"
Enter
Show

Type "sealed-council seats"
Enter
Sleep 800ms

Type "r=$(sealed-council new brief.md); echo $r"
Enter
Sleep 1s

Type "# (waiting ~25s, cut)"
Enter
Type "sealed-council ask $r"
Enter
Hide
Sleep 90s
Show
Sleep 1.5s

Type "sealed-council seal $r"
Enter
Sleep 1s

Type "ls $r"
Enter
Sleep 1s

Type "head -n 8 $r/A.md"
Enter
Sleep 2s

Type "# (waiting ~25s, cut)"
Enter
Type "sealed-council rank $r"
Enter
Hide
Sleep 90s
Show
Sleep 1.5s

Type "# host writes verdict.md"
Enter
Hide
Type "cp verdict.md $r/verdict.md"
Enter
Sleep 300ms
Show

Type "cat $r/verdict.md"
Enter
Sleep 2s

Type "sealed-council reveal $r"
Enter
Sleep 4s
