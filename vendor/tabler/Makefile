.PHONY: all filled outline

all: filled outline

filled:
	mkdir -p ../../code/src/tabler_icons
	cd svg/filled && ../../gen > ../../../../code/src/tabler_icons/tabler_icons_filled.ml
	cd ../../code/ && ocamlformat -i src/tabler_icons/tabler_icons_filled.ml

outline:
	mkdir -p ../../code/src/tabler_icons
	cd svg/outline && ../../gen > ../../../../code/src/tabler_icons/tabler_icons_outline.ml
	cd ../../code/ && ocamlformat -i src/tabler_icons/tabler_icons_outline.ml
