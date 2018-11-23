include $(SRC_DIR)/abb.mk

$(SRC_DIR)/abb.ml: .selector-other
	echo "include Abb_scheduler_select" > $(SRC_DIR)/abb.ml

.selector-other:
	rm .select-* || true
	touch .selector-other
