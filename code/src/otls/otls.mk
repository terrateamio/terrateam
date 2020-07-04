.PHONY: clean_otls_bindings

# Modifying NON_LIB_MODULES, so make it serial
.NOTPARALLEL:

NON_LIB_MODULES += otls_stubs.ml

$(SRC_DIR)/otls_stubs.ml: otls_bindings_gen
	./$^ > $@.$$$$ && mv $@.$$$$ $@

otls_bindings_gen: otls_bindings_stubs.o
	$(CC) $(shell pkg-config --cflags libtls) -o $@ $^

otls_bindings_stubs.o: otls_bindings_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

otls_bindings_stubs.c: ../otls_bindings_gen/otls_bindings_gen.native
	../otls_bindings_gen/otls_bindings_gen.native

clean: clean_otls_bindings

clean_otls_bindings:
	-rm otls_bindings_gen \
		otls_bindings_stubs.o \
		otls_bindings_stubs.c \
		$(SRC_DIR)/otls_stubs.ml
