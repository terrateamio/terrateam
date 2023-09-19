.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

migrations_files := $(wildcard $(SRC_DIR)/migrations/*.sql)

sql_files := $(wildcard $(SRC_DIR)/sql/*.sql)

tmpl_files := $(wildcard $(SRC_DIR)/tmpl/*.tmpl)

# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

NON_LIB_MODULES = \
	terrat_files.ml \
	terrat_files_migrations.ml \
	terrat_files_sql.ml \
        terrat_files_tmpl.ml

$(SRC_DIR)/terrat_files.ml:
	mkdir -p "$(SRC_DIR)"
	test -e $@ || touch $@

$(SRC_DIR)/terrat_files_migrations.ml: $(migrations_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf migrations
	mkdir migrations
	cp $^ migrations/
	ocaml-crunch -m plain migrations/ > $@

$(SRC_DIR)/terrat_files_sql.ml: $(sql_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf sql
	mkdir sql
	cp $^ sql/
	ocaml-crunch -m plain sql/ > $@

$(SRC_DIR)/terrat_files_tmpl.ml: $(tmpl_files)
	mkdir -p "$(SRC_DIR)"
	-rm -rf tmpl
	mkdir tmpl
	cp $^ tmpl/
	ocaml-crunch -m plain tmpl/ > $@

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/terrat_files.ml" \
	   "$(SRC_DIR)/terrat_files_migrations.ml" \
	   "$(SRC_DIR)/terrat_files_sql.ml" \
           "$(SRC_DIR)/terrat_files_tmpl.ml"
