# build image
ARG BASE_IMAGE=terrateam-base
FROM $BASE_IMAGE as build

COPY ./ /mono

# setup
WORKDIR /
RUN eval $(opam env) && \
    opam update && \
    opam repository add opam-acsl mono/opam && \
    opam pin add -y containers 3.12 && \
    opam install -y hll pds && \
    mkdir -p opam-mono/compilers && \
    mkdir -p opam-mono/packages && \
    echo 'opam-version: "2.0"' > opam-mono/repo && \
    opam repository add opam-mono opam-mono && \
    cd /mono/code && \
    hll generate -n monorepo --opam-dir ../../opam-mono --tag 1.0 --test-deps-as-regular-deps && \
    opam update opam-mono && \
    opam info monorepo && \
    opam install -j4 -y --strict --deps-only monorepo

# compile
WORKDIR /mono/code
RUN ulimit -s 524288 && ulimit -a && eval $(opam env) && \
    (time make -j4 release_terrat_cli || time make -j1 release_terrat_cli)

# test
WORKDIR /mono/code
RUN eval $(opam env) && \
    time env OCAMLRUNPARAM=b make -j4 -k test && \
    find . -name '*.tap' -exec cat '{}' \;

# app image
FROM alpine:3.13

# packages
RUN apk add --no-cache \
    bash \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libressl3.1-libtls \
    libtls-standalone \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit

# configs
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf /etc/nginx/nginx.conf

# artifacts
COPY --from=build /usr/lib/libkqueue.so /usr/lib/libkqueue.so
COPY --from=build /mono/code/build/release/terrat_cli/terrat_cli.native /usr/local/bin/terrat

# expose
EXPOSE 8080

# run
CMD ["runsvdir", "/etc/service"]
