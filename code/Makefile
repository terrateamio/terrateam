all: .merlin

.merlin: pds.conf
	 pds -f | merlin-of-pds > .merlin

pds.mk: pds.conf
	pds

-include pds.mk
