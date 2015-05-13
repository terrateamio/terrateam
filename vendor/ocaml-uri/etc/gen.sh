#!/bin/sh -e

BYTES=`ocamlfind query bytes`
STRINGEXT=`ocamlfind query stringext`
if [ -e ${BYTES}/bytes.cma ]
then
    DEPS="-I ${BYTES} bytes.cma -I ${STRINGEXT} stringext.cma"
else
    DEPS="-I ${STRINGEXT} stringext.cma"
fi
ocaml ${DEPS} etc/gen_services.ml etc/services.short > lib/uri_services.ml
cat etc/uri_services_raw.ml >> lib/uri_services.ml
ocaml ${DEPS} etc/gen_services.ml etc/services.full > lib/uri_services_full.ml
cat etc/uri_services_raw.ml >> lib/uri_services_full.ml
