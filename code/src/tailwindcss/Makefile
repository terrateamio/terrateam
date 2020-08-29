.PHONY: all release debug clean docs

VERSION = 1.4.6

all: release

release: .installed-$(VERSION)

debug: .installed-$(VERSION)

profile: .installed-$(VERSION)

docs:

.installed-$(VERSION):
	mkdir -p node_modules
	npm install tailwindcss@$(VERSION)
	touch $@

clean:
	-rm .installed-$(VERSION)
