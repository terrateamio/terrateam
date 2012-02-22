.PHONY: all clean install build
all: build doc 

NAME=uri
OFLAGS=-annot
export OCAMLRUNPARAM=b

setup.bin: setup.ml
	ocamlopt.opt $(OFLAGS) -o $@ $< 	\
	  || ocamlopt $(OFLAGS) -o $@ $< 	\
	  || ocamlc $(OFLAGS) -o $@ $<
	$(RM) setup.cmx setup.cmi setup.o setup.cmo

setup.data: setup.bin
	./setup.bin -configure

build: setup.data setup.bin
	./setup.bin -build

doc: setup.data setup.bin
	./setup.bin -doc

install: setup.bin
	./setup.bin -install

test: setup.bin build
	./setup.bin -test

reinstall: setup.bin
	ocamlfind remove $(NAME) || true
	./setup.bin -reinstall

clean:
	ocamlbuild -clean
	$(RM) setup.data setup.log setup.bin
