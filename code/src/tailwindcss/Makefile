.PHONY: all release debug clean

VERSION = 1.4.6

all: release

release: .installed-$(VERSION)

debug: .installed-$(VERSION)

profile: .installed-$(VERSION)

.installed-$(VERSION):
	mkdir -p node_modules
	npm install tailwindcss@$(VERSION)
	touch $@

clean:
	-rm .installed-$(VERSION)
