.PHONY: all release debug clean docs


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
