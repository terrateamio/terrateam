.PHONY: all release debug clean docs

export npm_config_prefix:=$(PWD)/node_modules
export BUILD_DIR:=$(PWD)
export OUT_DIR:=$(BUILD_DIR)/dist

all: release

release:
	rsync -avr --delete --exclude='dist/' --exclude='node_modules/' $(SRC_DIR)/ ./src
	cd src && ln -sf ../../../../../api_schemas/terrat/api.json ./api.json
	cd src && npm i && npm run test && npm run build
	ln -sf src/dist ./

debug: release

profile: release

docs:

clean:
