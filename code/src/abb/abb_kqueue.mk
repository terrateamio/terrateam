include $(SRC_DIR)/abb.mk

$(SRC_DIR)/abb.ml: .selector-kqueue
	echo "include Abb_scheduler_kqueue" > $(SRC_DIR)/abb.ml

.selector-kqueue:
	rm .select-* || true
	touch .selector-kqueue
