.PHONY: all release debug clean docs

all: release

release:
	cd $(SRC_DIR) && cargo build -j2 --release --target-dir $(BUILD_DIR)/build
	cp -a build/release/libminijinja_c_wrapper.a ./

debug:
	cd $(SRC_DIR) && cargo build -j2 --target-dir $(BUILD_DIR)/build
	cp -a build/debug/libminijinja_c_wrapper.a ./

profile: release

docs:

clean:
