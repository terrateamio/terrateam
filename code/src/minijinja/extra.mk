$(NATIVE_TARGET): minijinja_stubs.o

$(BYTE_TARGET): minijinja_stubs.o

minijinja_stubs.o: $(SRC_DIR)/minijinja_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

META_EXTRA_LINES = archive(native) += \"$(BUILD_DIR)/../minijinja-rs/libminijinja_c_wrapper.a\" \
	archive(byte) += \"$(BUILD_DIR)/../minijinja-rs/libminijinja_c_wrapper.a\"

OCAMLC_LINK_OPTS=-custom -thread -ccopt -L$(BUILD_DIR)/../minijinja-rs -cclib -lminijinja_c_wrapper $(BUILD_DIR)/minijinja_stubs.o
OCAMLOPT_LINK_OPTS=-thread -ccopt -L$(BUILD_DIR)/../minijinja-rs -cclib -lminijinja_c_wrapper $(BUILD_DIR)/minijinja_stubs.o

EXTERNAL_DEPS += ../minijinja-rs/libminijinja_c_wrapper.a
