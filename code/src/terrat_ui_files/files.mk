.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

asset_files := \
	../terrat_ui_css/style.css \
	../terrat_ui_js/terrat_ui_js.js \
	$(wildcard ../../../../vendor/material-icons/mdi-v20210302.*) \
	$(wildcard ../../../../vendor/highlightjs/highlight.11.10.0.min.*) \
	$(wildcard ../../../../vendor/highlightjs-terraform/terraform.2024-11-01-eb1b966.*) \
	$(wildcard ../terrat_ui_site/*.html) \
	$(wildcard ../terrat_ui_site/*.png) \
	$(wildcard ../terrat_ui_site/*.json) \
	$(wildcard ../terrat_ui_site/*.svg)

# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

NON_LIB_MODULES = \
	terrat_ui_files.ml \
	terrat_ui_files_assets.ml

$(SRC_DIR)/terrat_ui_files.ml:
	mkdir -p "$(SRC_DIR)"
	test -e $@ || touch $@

$(SRC_DIR)/terrat_ui_files_assets.ml: $(asset_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf assets
	mkdir assets
	cp $^ assets/
	ocaml-crunch -m plain assets/ > $@

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/terrat_ui_files.ml" \
	   "$(SRC_DIR)/terrat_ui_files_assets.ml"
