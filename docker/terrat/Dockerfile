# build image
ARG BASE_IMAGE=terrateam-base
FROM $BASE_IMAGE as build

COPY ./ /mono

# setup
WORKDIR /
RUN eval $(opam env) && \
    opam option depext=false && \
    opam update && \
    opam repository add opam-acsl mono/opam && \
    opam pin add -y containers 3.12 && \
    opam install -y hll pds && \
    mkdir -p opam-mono/compilers && \
    mkdir -p opam-mono/packages && \
    echo 'opam-version: "2.0"' > opam-mono/repo && \
    opam repository add opam-mono opam-mono && \
    cd /mono/code && \
    hll generate \
      -n monorepo \
      --opam-dir ../../opam-mono \
      --tag 1.0 \
      --test-deps-as-regular-deps \
      --url-override file://$PWD && \
    opam update opam-mono && \
    opam info monorepo && \
    opam install -j4 -y --deps-only monorepo

ARG TERRAT_UI_ANALYTICS=false
# compile
WORKDIR /mono/code
RUN ulimit -s 524288 && ulimit -a && eval $(opam env) && \
    (time env TERRAT_UI_ANALYTICS=$TERRAT_UI_ANALYTICS make -j4 release_terrat_ee release_terrat_ui \
     || time env TERRAT_UI_ANALYTICS=$TERRAT_UI_ANALYTICS make -j1 release_terrat_ee release_terrat_ui)

# test stage
FROM build as test

WORKDIR /mono/code
RUN eval $(opam env) && \
    time env OCAMLRUNPARAM=b make -j4 -k test && \
    find . -name '*.tap' -exec cat '{}' \;

# app image
FROM alpine:3.18

# packages
RUN apk add --no-cache \
    bash \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libressl \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit \
    yj

# configs
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx /usr/local/share/terrat/ui/assets
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf.template /etc/nginx/nginx.conf.template

# artifacts
COPY --from=build /usr/lib/libkqueue.so /usr/lib/libkqueue.so
COPY --from=build /mono/code/build/release/terrat_ee/terrat_ee.native /usr/local/bin/terrat
COPY --from=build /mono/code/build/release/terrat_ui_files/assets /usr/local/share/terrat/ui/assets/

# expose
EXPOSE 8080

# run
CMD ["runsvdir", "/etc/service"]
