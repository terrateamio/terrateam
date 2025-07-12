.PHONY: all release debug clean docs

all: release

release:
	cd $(SRC_DIR) && cargo build -j2 --release --target-dir $(BUILD_DIR)/build
	cp build/release/libjsonschema_c_wrapper.a ./

debug:
	cd $(SRC_DIR) && cargo build -j2 --target-dir $(BUILD_DIR)/build
	cp build/debug/libjsonschema_c_wrapper.a ./

profile: release

docs:

clean:
