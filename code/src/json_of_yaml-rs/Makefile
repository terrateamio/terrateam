.PHONY: all release debug clean docs

all: release

release:
	cd $(SRC_DIR) && cargo build -j2 --release --target-dir $(BUILD_DIR)/build
	cp build/release/libjson_of_yaml.a ./

debug:
	cd $(SRC_DIR) && cargo build -j2 --target-dir $(BUILD_DIR)/build
	cp build/debug/libjson_of_yaml.a ./

profile: release

docs:

clean:
