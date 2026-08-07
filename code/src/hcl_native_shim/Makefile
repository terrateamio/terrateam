.PHONY: all release debug profile clean docs

GO_BIN := $(shell command -v go 2>/dev/null || echo /usr/local/go/bin/go)

SRC_FILES := $(shell find $(SRC_DIR) -type f -name '*.go') $(SRC_DIR)/go.mod $(SRC_DIR)/go.sum

# The binary lives in $(BUILD_DIR). At runtime, Hcl_native looks for it
# as a sibling at [../hcl_native_shim/sg_hcl_shim] relative to the
# current OCaml executable. Production binaries are not expected to call
# Hcl_native at all (the shim is a test-only "oracle" for the Menhir
# parser), so production doesn't need to ship the binary; however we
# still build it everywhere because [make stategraph] pulls it in via
# hcl_native's compile_deps.
#
# Test binaries live under build/test-<profile>/<module>/, not
# build/<profile>/<module>/, so ../hcl_native_shim resolves to
# build/test-<profile>/hcl_native_shim. Mirror the binary into that
# parallel directory via a symlink so the same relative lookup works
# for both source and test executables.

# Compute the matching test-profile sibling directory. BUILD_DIR is
# something like /.../code/build/debug/hcl_native_shim; the test sibling
# lives at /.../code/build/test-debug/hcl_native_shim.
_BUILD_DIR_PARENT := $(patsubst %/,%,$(dir $(BUILD_DIR)))
_BUILD_ROOT := $(dir $(_BUILD_DIR_PARENT))
_PROFILE := $(notdir $(_BUILD_DIR_PARENT))
TEST_BUILD_DIR := $(_BUILD_ROOT)test-$(_PROFILE)/hcl_native_shim

all: release

$(BUILD_DIR)/sg_hcl_shim: $(SRC_FILES)
	cd $(SRC_DIR) && GOCACHE=$(BUILD_DIR)/gocache GOMODCACHE=$(BUILD_DIR)/gomodcache \
		$(GO_BIN) build -o $(BUILD_DIR)/sg_hcl_shim .

$(TEST_BUILD_DIR)/sg_hcl_shim: $(BUILD_DIR)/sg_hcl_shim
	mkdir -p $(TEST_BUILD_DIR)
	ln -sf $< $@

release: $(BUILD_DIR)/sg_hcl_shim $(TEST_BUILD_DIR)/sg_hcl_shim

debug: release

profile: release

docs:

clean:
	rm -f $(BUILD_DIR)/sg_hcl_shim $(TEST_BUILD_DIR)/sg_hcl_shim
