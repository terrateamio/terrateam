.PHONY: all release debug clean docs

export BUILD_DIR:=$(PWD)
export OUT_DIR:=$(BUILD_DIR)/dist

SRC_FILES := $(shell find $(SRC_DIR) -type f)

all: release

# Use build.tag to track when the build was so we only run the build operations
# again if something changed.  This is because whatever iris is being built with
# performs work even if none of the files have changed.
$(BUILD_DIR)/build.tag: $(SRC_FILES) $(BUILD_DIR)/../../../../api_schemas/terrat/api.json
	rsync -avr --delete --exclude='dist/' --exclude='node_modules/' $(SRC_DIR)/ ./src
	cd src && ln -sf ../../../../../api_schemas/terrat/api.json ./api.json
	cd src && npm i && npm run generate-api-types && npm run test && npm run build
	ln -sf src/dist ./
	touch $(BUILD_DIR)/build.tag

release: $(BUILD_DIR)/build.tag

debug: release

profile: release

docs:

clean:
