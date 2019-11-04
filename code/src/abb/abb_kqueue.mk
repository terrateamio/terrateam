include $(SRC_DIR)/abb.mk

$(SRC_DIR)/abb.ml: .selector-kqueue
	mkdir -p "$(SRC_DIR)"
	echo "include Abb_scheduler_kqueue" > "$(SRC_DIR)/abb.ml"

.selector-kqueue:
	rm .select-* || true
	touch .selector-kqueue
