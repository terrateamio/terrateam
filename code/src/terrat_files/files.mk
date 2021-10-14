.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

asset_files := \
	../terrat_css/style.css \
	../terrat_js/terrat_js.js \
	$(wildcard ../../../../vendor/material-icons/mdi-v20210302.*) \
	$(wildcard ../terrat_site/*.html) \
	$(wildcard ../terrat_site/*.png) \
	$(wildcard ../terrat_site/*.json) \
	$(wildcard ../terrat_site/*.svg)

migrations_files := $(wildcard $(SRC_DIR)/migrations/*.sql)

github_files := $(wildcard $(SRC_DIR)/github/*.sql)

terraform_files := $(wildcard $(SRC_DIR)/terraform/*.sql)

# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

NON_LIB_MODULES = \
	terrat_files.ml \
	terrat_files_assets.ml \
	terrat_files_migrations.ml \
	terrat_files_github.ml \
	terrat_files_terraform.ml

$(SRC_DIR)/terrat_files.ml:
	mkdir -p "$(SRC_DIR)"
	test -e $@ || touch $@

$(SRC_DIR)/terrat_files_assets.ml: $(asset_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf assets
	mkdir assets
	cp $^ assets/
	ocaml-crunch -m plain assets/ > $@

$(SRC_DIR)/terrat_files_migrations.ml: $(migrations_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf migrations
	mkdir migrations
	cp $^ migrations/
	ocaml-crunch -m plain migrations/ > $@

$(SRC_DIR)/terrat_files_github.ml: $(github_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf github
	mkdir github
	cp $^ github/
	ocaml-crunch -m plain github/ > $@

$(SRC_DIR)/terrat_files_terraform.ml: $(terraform_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf terraform
	mkdir terraform
	cp $^ terraform/
	ocaml-crunch -m plain terraform/ > $@

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/terrat_files.ml" \
	   "$(SRC_DIR)/terrat_files_assets.ml" \
	   "$(SRC_DIR)/terrat_files_migrations.ml" \
	   "$(SRC_DIR)/terrat_files_github.ml" \
	   "$(SRC_DIR)/terrat_files_terraform.ml"
