.PHONY: all release debug clean docs

TAILWIND_VERSION = 3.3.3

INSTALL_FILES = .installed-tailwind-$(TAILWIND_VERSION)

all: release

release: $(INSTALL_FILES)

debug: $(INSTALL_FILES)

profile: $(INSTALL_FILES)

docs:

.installed-tailwind-$(TAILWIND_VERSION):
	rm .installed-tailwind-* || true
	mkdir -p node_modules
	npm install tailwindcss@$(TAILWIND_VERSION)
	touch $@

clean:
	-rm $(INSTALL_FILES) || true
