.PHONY: all release debug clean docs

TAILWIND_CLI_VERSION = 2.2.15

INSTALL_FILES = .installed-tailwind-cli-$(TAILWIND_CLI_VERSION)

all: release

release: $(INSTALL_FILES)

debug: $(INSTALL_FILES)

profile: $(INSTALL_FILES)

docs:

.installed-tailwind-cli-$(TAILWIND_CLI_VERSION):
	mkdir -p node_modules
	npm install tailwindcss-cli@$(TAILWIND_VERSION)
	touch $@

clean:
	-rm $(INSTALL_FILES) || true
