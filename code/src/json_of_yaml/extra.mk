$(NATIVE_TARGET): json_of_yaml_stubs.o

$(BYTE_TARGET): json_of_yaml_stubs.o

json_of_yaml_stubs.o: $(SRC_DIR)/json_of_yaml_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

META_EXTRA_LINES = archive(native) += \"$(BUILD_DIR)/../json_of_yaml-rs/libjson_of_yaml.a\" \
	archive(byte) += \"$(BUILD_DIR)/../json_of_yaml-rs/libjson_of_yaml.a\"

OCAMLC_LINK_OPTS=-custom -thread -ccopt -L$(BUILD_DIR)/../json_of_yaml-rs -cclib -ljson_of_yaml $(BUILD_DIR)/json_of_yaml_stubs.o
OCAMLOPT_LINK_OPTS=-thread -ccopt -L$(BUILD_DIR)/../json_of_yaml-rs -cclib -ljson_of_yaml $(BUILD_DIR)/json_of_yaml_stubs.o

EXTERNAL_DEPS += ../json_of_yaml-rs/libjson_of_yaml.a
