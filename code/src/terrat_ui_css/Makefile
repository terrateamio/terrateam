.PHONY: all release debug clean docs

SITE_FILES = $(wildcard ../terrat_ui_site/*.html) $(wildcard ../terrat_ui_js/*.js)

all: release

release: style_release.css
	diff style_release.css style.css > /dev/null 2>&1 || cp style_release.css style.css

debug: style.css

profile: style.css

docs:

clean:
	-rm style.css tailwind.config.js

tailwind.config.js: $(SRC_DIR)/tailwind.config.js
	cp $< $@

style.css: $(SRC_DIR)/style.css tailwind.config.js $(SITE_FILES)
	../tailwindcss/node_modules/.bin/tailwindcss build -i "$(SRC_DIR)/style.css" -o style.css

style_release.css: $(SRC_DIR)/style.css tailwind.config.js $(SITE_FILES)
	env NODE_ENV=production ../tailwindcss/node_modules/.bin/tailwindcss build -i "$(SRC_DIR)/style.css" -o style_release.css
