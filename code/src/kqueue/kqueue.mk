.PHONY: clean_kqueue_bindings

NON_LIB_MODULES += kqueue_stubs.ml

kqueue_stubs.ml: kqueue_bindings_gen
	./$^ > $@

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
		kqueue_bindings_stubs.c
