$(NATIVE_TARGET): jsonschema_check_stubs.o

$(BYTE_TARGET): jsonschema_check_stubs.o

jsonschema_check_stubs.o: $(SRC_DIR)/jsonschema_check_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

META_EXTRA_LINES = archive(native) += \"$(BUILD_DIR)/../jsonschema-rs/libjsonschema_c_wrapper.a\" \
	archive(byte) += \"$(BUILD_DIR)/../jsonschema-rs/libjsonschema_c_wrapper.a\"

OCAMLC_LINK_OPTS=-custom -thread -ccopt -L$(BUILD_DIR)/../jsonschema-rs -cclib -ljsonschema_c_wrapper $(BUILD_DIR)/jsonschema_check_stubs.o
OCAMLOPT_LINK_OPTS=-thread -ccopt -L$(BUILD_DIR)/../jsonschema-rs -cclib -ljsonschema_c_wrapper $(BUILD_DIR)/jsonschema_check_stubs.o

EXTERNAL_DEPS += ../jsonschema-rs/libjsonschema_c_wrapper.a
