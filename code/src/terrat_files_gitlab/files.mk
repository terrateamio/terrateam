.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

gitlab_sql_files := $(wildcard $(SRC_DIR)/sql/*.sql)

gitlab_tmpl_files := $(wildcard $(SRC_DIR)/tmpl/*.tmpl)


# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

NON_LIB_MODULES = \
	terrat_files_gitlab.ml \
	terrat_files_gitlab_sql.ml \
        terrat_files_gitlab_tmpl.ml

$(SRC_DIR)/terrat_files_gitlab.ml:
	mkdir -p "$(SRC_DIR)"
	test -e $@ || touch $@

$(SRC_DIR)/terrat_files_gitlab_sql.ml: $(gitlab_sql_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf sql
	mkdir -p sql
	cp $^ sql/
	ocaml-crunch -m plain sql/ > $@

$(SRC_DIR)/terrat_files_gitlab_tmpl.ml: $(gitlab_tmpl_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf tmpl
	mkdir -p tmpl
	cp $^ tmpl/
	ocaml-crunch -m plain tmpl/ > $@

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/terrat_files_gitlab.ml" \
	   "$(SRC_DIR)/terrat_files_gitlab_sql.ml" \
           "$(SRC_DIR)/terrat_files_gitlab_tmpl.ml"
