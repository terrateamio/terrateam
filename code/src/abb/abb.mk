.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

NON_LIB_MODULES += abb.ml

# Since we are generating this .ml file, there is no source to in the predfined
# SRC_DIR, so we set it to someplace else since the source dir cannot be
# modified by the build system.
SRC_DIR = src

clean: clean_files

clean_files:
	rm "$(SRC_DIR)/abb.ml" .selector-*
