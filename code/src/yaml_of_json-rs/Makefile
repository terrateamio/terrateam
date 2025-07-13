.PHONY: all release debug clean docs

all: release

release:
	cd $(SRC_DIR) && cargo build -j2 --release --target-dir $(BUILD_DIR)/build
	cp build/release/libyaml_of_json.a ./

debug:
	cd $(SRC_DIR) && cargo build -j2 --target-dir $(BUILD_DIR)/build
	cp build/debug/libyaml_of_json.a ./

profile: release

docs:

clean:
