#!/bin/sh

BYTES=`ocamlfind query bytes`
STRINGEXT=`ocamlfind query stringext`
if [ -e ${BYTES}/bytes.cma ]
then
    DEPS="-I ${BYTES} bytes.cma -I ${STRINGEXT} stringext.cma"
else
    DEPS="-I ${STRINGEXT} stringext.cma"
fi
ocaml ${DEPS} gen_services.ml services.short > uri_services.ml
cat uri_services_raw.ml >> uri_services.ml
ocaml ${DEPS} gen_services.ml services.full > uri_services_full.ml
cat uri_services_raw.ml >> uri_services_full.ml
