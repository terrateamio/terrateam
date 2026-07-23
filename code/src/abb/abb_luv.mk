include $(SRC_DIR)/abb.mk

$(SRC_DIR)/abb.ml: .selector-luv
	mkdir -p "$(SRC_DIR)"
	echo "include Abb_scheduler_luv" > "$(SRC_DIR)/abb.ml"

.selector-luv:
	rm .select-* || true
	touch .selector-luv
