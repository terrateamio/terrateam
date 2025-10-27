.PHONY: clean_kqueue_bindings

# Modifying NON_LIB_MODULES, so make it serial
.NOTPARALLEL:

OLD_SRC_DIR := $(SRC_DIR)

SRC_DIR = src

NON_LIB_MODULES += kqueue_stubs.ml

$(NATIVE_TARGET): kqueue_fun_stubs.o

$(BYTE_TARGET): kqueue_fun_stubs.o

OCAMLC_LINK_OPTS=-custom -thread $(BUILD_DIR)/kqueue_fun_stubs.o
OCAMLOPT_LINK_OPTS=-thread $(BUILD_DIR)/kqueue_fun_stubs.o

kqueue_fun_stubs.o: $(OLD_SRC_DIR)/kqueue_fun_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

$(SRC_DIR)/kqueue_stubs.ml: kqueue_bindings_gen
	mkdir -p "$(SRC_DIR)"
	./$^ > $@.$$$$ && mv $@.$$$$ $@

$(SRC_DIR)/%.ml: $(OLD_SRC_DIR)/%.ml
	mkdir -p "$(SRC_DIR)"
	cp $^ $@

$(SRC_DIR)/%.mli: $(OLD_SRC_DIR)/%.mli
	mkdir -p "$(SRC_DIR)"
	cp $^ $@

kqueue_bindings_gen: kqueue_bindings_stubs.o
	$(CC) -o $@ $^

kqueue_bindings_stubs.o: kqueue_bindings_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

kqueue_bindings_stubs.c: ../kqueue_bindings_gen/kqueue_bindings_gen.native
	../kqueue_bindings_gen/kqueue_bindings_gen.native

clean: clean_kqueue_bindings

clean_kqueue_bindings:
	-rm kqueue_bindings_gen \
		kqueue_bindings_stubs.o \
		kqueue_bindings_stubs.c \
		$(SRC_DIR)/kqueue_stubs.ml \
		$(SRC_DIR)/kqueue_fun_stubs.o
