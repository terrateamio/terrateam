.PHONY: .merlin

all: .merlin
	pds
	$(MAKE) -f pds.mk all

%: .merlin
	pds
	$(MAKE) -f pds.mk $*

.merlin:
	 pds -f | merlin-of-pds > .merlin
