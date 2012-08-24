#!/bin/sh -e

ocaml etc/gen_services.ml etc/services.short > lib/Uri_services.ml
cat etc/Uri_services_raw.ml >> lib/Uri_services.ml
ocaml etc/gen_services.ml etc/services.full > lib/Uri_services_full.ml
cat etc/Uri_services_raw.ml >> lib/Uri_services_full.ml
