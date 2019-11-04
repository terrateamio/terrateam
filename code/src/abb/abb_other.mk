include $(SRC_DIR)/abb.mk

$(SRC_DIR)/abb.ml: .selector-other
	mkdir -p "$(SRC_DIR)"
	echo "include Abb_scheduler_select" > "$(SRC_DIR)/abb.ml"

.selector-other:
	rm .select-* || true
	touch .selector-other

