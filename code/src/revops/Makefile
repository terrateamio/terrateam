CAMLP4=

OCAMLDEP_OPTS=
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40' -package core
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=revops.ml revops_fn.ml revops_sys.ml revops_univ.ml revops_univ_fn.ml
NON_LIB_MODULES=revops_intf.ml revops_univ_intf.ml

BYTE_TARGETS=revops.cma
NATIVE_TARGETS=revops.cmxa

.PHONY: all test install

all: native-code byte-code

test:

install: install_lib

# Dependencies
include ../Ocamlrules.mk.in
