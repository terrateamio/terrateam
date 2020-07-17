.PHONY: clean_otls_bindings

# Modifying NON_LIB_MODULES, so make it serial
.NOTPARALLEL:

OLD_SRC_DIR := $(SRC_DIR)

SRC_DIR = src

NON_LIB_MODULES += otls_stubs.ml

$(SRC_DIR)/otls_stubs.ml: otls_bindings_gen
	mkdir -p "$(SRC_DIR)"
	./$^ > $@.$$$$ && mv $@.$$$$ $@

$(SRC_DIR)/%.ml: $(OLD_SRC_DIR)/%.ml
	mkdir -p "$(SRC_DIR)"
	cp $^ $@

$(SRC_DIR)/%.mli: $(OLD_SRC_DIR)/%.mli
	mkdir -p "$(SRC_DIR)"
	cp $^ $@

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
