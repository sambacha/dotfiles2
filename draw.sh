#!/bin/bash
function recurse () {
	SUBS=$(find $1 -mindepth 1 -maxdepth 1 -type d)
	for a in $SUBS
	do
		echo "\"$1\" -> \"$a\";" >> $DOTFILE
		recurse $a
	done
}
DOTFILE=$(mktemp)
export IFS=$'\n'
echo "digraph unix {" > $DOTFILE
echo "node [color=lightblue2, style=filled];" >> $DOTFILE
recurse $1
echo "}" >> $DOTFILE
dot -Tpng $DOTFILE > dirs.png
