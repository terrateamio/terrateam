.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

migrations_files := $(wildcard $(SRC_DIR)/migrations/*.sql)

github_sql_files := $(wildcard $(SRC_DIR)/github/sql/*.sql)

github_tmpl_files := $(wildcard $(SRC_DIR)/github/tmpl/*.tmpl)

# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

NON_LIB_MODULES = \
	terrat_files.ml \
	terrat_files_migrations.ml \
	terrat_files_github_sql.ml \
        terrat_files_github_tmpl.ml

$(SRC_DIR)/terrat_files.ml:
	mkdir -p "$(SRC_DIR)"
	test -e $@ || touch $@

$(SRC_DIR)/terrat_files_migrations.ml: $(migrations_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf migrations
	mkdir migrations
	cp $^ migrations/
	ocaml-crunch -m plain migrations/ > $@

$(SRC_DIR)/terrat_files_github_sql.ml: $(github_sql_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf github/sql
	mkdir -p github/sql
	cp $^ github/sql/
	ocaml-crunch -m plain github/sql/ > $@

$(SRC_DIR)/terrat_files_github_tmpl.ml: $(github_tmpl_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf github/tmpl
	mkdir -p github/tmpl
	cp $^ github/tmpl/
	ocaml-crunch -m plain github/tmpl/ > $@

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/terrat_files.ml" \
	   "$(SRC_DIR)/terrat_files_migrations.ml" \
	   "$(SRC_DIR)/terrat_files_github_sql.ml" \
           "$(SRC_DIR)/terrat_files_github_tmpl.ml"
