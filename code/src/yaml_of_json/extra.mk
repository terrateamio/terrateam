$(NATIVE_TARGET): yaml_of_json_stubs.o

$(BYTE_TARGET): yaml_of_json_stubs.o

yaml_of_json_stubs.o: $(SRC_DIR)/yaml_of_json_stubs.c
	ocamlfind ocamlc $(OCAMLC_OPTS) -c $^

META_EXTRA_LINES = archive(native) += \"$(BUILD_DIR)/../yaml_of_json-rs/libyaml_of_json.a\" \
	archive(byte) += \"$(BUILD_DIR)/../yaml_of_json-rs/libyaml_of_json.a\"

OCAMLC_LINK_OPTS=-custom -thread -ccopt -L$(BUILD_DIR)/../yaml_of_json-rs -cclib -lyaml_of_json $(BUILD_DIR)/yaml_of_json_stubs.o
OCAMLOPT_LINK_OPTS=-thread -ccopt -L$(BUILD_DIR)/../yaml_of_json-rs -cclib -lyaml_of_json $(BUILD_DIR)/yaml_of_json_stubs.o

EXTERNAL_DEPS += ../yaml_of_json-rs/libyaml_of_json.a
