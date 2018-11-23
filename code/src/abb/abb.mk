.PHONY: clean_files

# Make it serial because we are adding a NON_LIB_MODULE
.NOTPARALLEL:

NON_LIB_MODULES += abb.ml

clean: clean_files

clean_files:
	rm $(SRC_DIR)/abb.ml .selector-*
