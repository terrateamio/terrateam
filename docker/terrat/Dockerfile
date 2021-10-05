# build image
FROM 654862118936.dkr.ecr.us-west-2.amazonaws.com/terrateam-base:latest as build

COPY ./ /mono

# setup
WORKDIR /
RUN eval $(opam env) && \
    opam repository add opam-acsl mono/opam && \
    opam pin add -y containers 3.4 && \
    opam install -y hll pds && \
    mkdir -p opam-mono/compilers && \
    mkdir -p opam-mono/packages && \
    echo 'opam-version: "2.0"' > opam-mono/repo && \
    opam repository add opam-mono opam-mono && \
    cd /mono/code && \
    hll generate -n monorepo --opam-dir ../../opam-mono --tag 1.0 --test-deps-as-regular-deps && \
    opam update opam-mono && \
    opam pin add -n uri ../vendor/ocaml-uri && \
    opam pin add -n uri-sexp ../vendor/ocaml-uri && \
    opam install -y uri uri-sexp && \
    opam info monorepo && \
    opam install -j4 -y --strict --deps-only monorepo

# compile
WORKDIR /mono/code
RUN eval $(opam env) && \
    make -j4 release_terrat

# test
WORKDIR /mono
RUN eval $(opam env) && \
    env OCAMLRUNPARAM=b make -j4 -k cicd-test && \
    find . -name '*.tap' -exec cat '{}' \;

# app image
FROM alpine:3.13

# packages
RUN apk add --no-cache aws-cli gmp libffi libressl3.1-libtls libtls-standalone nginx runit

# configs
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf /etc/nginx/nginx.conf

# artifacts
COPY --from=build /usr/lib/libkqueue.so /usr/lib/libkqueue.so
COPY --from=build /mono/code/build/release/terrat/terrat.native /usr/local/bin/terrat

# expose
EXPOSE 8080
EXPOSE 8081

# run
CMD ["runsvdir", "/etc/service"]
