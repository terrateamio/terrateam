# Define an argument for the base image
ARG BASE_IMAGE

# Optional base setup stage if BASE_IMAGE is not provided
FROM alpine:3.22 AS build-base

# Install base packages
RUN apk add --no-cache \
    bash \
    brotli-static \
    bsd-compat-headers \
    ca-certificates \
    cargo \
    clang \
    cmake \
    coreutils \
    curl \
    curl-dev \
    curl-static \
    git \
    gmp-dev \
    gmp-static \
    libffi-dev \
    libidn2-static \
    libpsl-static \
    libretls \
    libretls-dev \
    libssh2-static \
    libssh2-dev \
    libunistring-static \
    libunistring \
    libuv \
    libuv-dev \
    libuv-static \
    m4 \
    make \
    mercurial \
    musl-dev \
    nghttp2-static \
    nghttp2-dev \
    nghttp3-dev \
    nghttp3-static \
    npm \
    opam \
    openssh \
    openssl-libs-static \
    perl \
    pkgconf \
    py3-yaml \
    python3 \
    rsync \
    rust \
    sqlite-dev \
    zlib-dev \
    zlib-static \
    zstd-dev \
    zstd-static

# Initialize opam
RUN opam init -ay --disable-sandboxing --bare

# Copy source files
COPY ./ /mono
WORKDIR /mono

# Set up opam switch and dependencies. The list of pinned packages lives in
# code/opam.pins (one `<name>.<version>` per line) — the shape `opam install`
# accepts as-is via `xargs`.
RUN eval $(opam env) && \
    opam switch create -y 5.3.0 && \
    eval $(opam env) && \
    opam repository add opam-acsl opam && \
    opam install -j$(nproc --all) -y --no-depexts dune menhir ocamlformat.0.29.0 && \
    xargs -a code/opam.pins opam install -j$(nproc --all) -y --no-depexts && \
    ulimit -s 524288 && ulimit -a && \
    time make -C code test-terrat terrat && \
    mv _build /build-cache

# Use provided BASE_IMAGE if specified, otherwise use the build-base stage
FROM ${BASE_IMAGE:-build-base} AS build-setup

# Refresh source files. We do NOT `rm -rfv /mono` here — iris's npm build
# emits to /mono/code/src/iris/dist/ as a side effect of the dune rule,
# and dune only tracks the build.tag stamp inside _build/. If we wipe
# /mono before COPY, dist/ is gone but build.tag survives in /build-cache,
# so `make iris` in the per-target stages thinks the rule is
# satisfied and doesn't re-run npm — and the final COPY of iris/dist/
# fails. Preserving the prior /mono lets dist/ survive; COPY refreshes
# changed source files on top.
COPY ./ /mono

# Build target for code-indexer
FROM build-setup AS code-indexer-build
WORKDIR /mono
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./_build && \
    eval $(opam env) && \
    time make -C code terrat_code_indexer

# Build target for ttm
FROM build-setup AS ttm-build
WORKDIR /mono
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./_build && \
    eval $(opam env) && \
    time make -C code ttm && \
    _build/default/code/src/ttm/ttm.exe --help

# Build target for terrat-ee
FROM build-setup AS terrat-ee-build
WORKDIR /mono
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./_build && \
    eval $(opam env) && \
    time make -C code test-terrat terrat_ee iris

# Build target for terrat-oss
FROM build-setup AS terrat-oss-build
WORKDIR /mono
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./_build && \
    eval $(opam env) && \
    time make -C code test-terrat terrat_oss iris

# Final code-indexer image
FROM alpine:3.22 AS code-indexer
RUN addgroup -S terrat && adduser -S -G terrat terrat
COPY --from=code-indexer-build /mono/_build/default/code/src/terrat_code_indexer/terrat_code_indexer.exe /usr/local/bin/terrat_code_indexer
USER terrat
WORKDIR /mnt
ENTRYPOINT ["/usr/local/bin/terrat_code_indexer"]

# Final ttm image
FROM alpine:3.22 AS ttm
COPY --from=ttm-build /mono/_build/default/code/src/ttm/ttm.exe /usr/local/bin/ttm
WORKDIR /mnt
ENTRYPOINT ["/usr/local/bin/ttm"]

# Final terrat-ee image
FROM alpine:3.22 AS terrat-ee
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libretls \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit \
    strace \
    sudo \
    yj
RUN addgroup -S terrat && adduser -S -G terrat terrat
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx /usr/local/share/terrat/ui/assets
# Copy the certificate installation script and set proper permissions
COPY docker/terrat/install-ca-cert.py /usr/local/bin/install-ca-cert
RUN chmod 755 /usr/local/bin/install-ca-cert && \
    chown root:root /usr/local/bin/install-ca-cert
# Allow terrat user to only execute the specific script as root with CUSTOM_CA_CERT env var
RUN echo 'terrat ALL=(root) NOPASSWD:SETENV: /usr/local/bin/install-ca-cert' > /etc/sudoers.d/terrat && \
    chmod 440 /etc/sudoers.d/terrat
RUN chown -R terrat:terrat /etc/service /usr/local/share/terrat /etc/nginx /var/lib/nginx /var/log/nginx /run
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf.template /etc/nginx/nginx.conf.template
COPY --from=terrat-ee-build /mono/_build/default/code/src/terrat_ee/terrat_ee.exe /usr/local/bin/terrat
COPY --from=terrat-ee-build /mono/code/src/iris/dist/ /usr/local/share/terrat/ui/assets/
USER terrat
EXPOSE 8080
CMD ["runsvdir", "/etc/service"]

# Final terrat-oss image
FROM alpine:3.22 AS terrat-oss
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libretls \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit \
    strace \
    sudo \
    yj
RUN addgroup -S terrat && adduser -S -G terrat terrat
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx /usr/local/share/terrat/ui/assets
# Copy the certificate installation script and set proper permissions
COPY docker/terrat/install-ca-cert.py /usr/local/bin/install-ca-cert
RUN chmod 755 /usr/local/bin/install-ca-cert && \
    chown root:root /usr/local/bin/install-ca-cert
# Allow terrat user to only execute the specific script as root with CUSTOM_CA_CERT env var
RUN echo 'terrat ALL=(root) NOPASSWD:SETENV: /usr/local/bin/install-ca-cert' > /etc/sudoers.d/terrat && \
    chmod 440 /etc/sudoers.d/terrat
RUN chown -R terrat:terrat /etc/service /usr/local/share/terrat /etc/nginx /var/lib/nginx /var/log/nginx /run
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf.template /etc/nginx/nginx.conf.template
COPY --from=terrat-oss-build /mono/_build/default/code/src/terrat_oss/terrat_oss.exe /usr/local/bin/terrat
COPY --from=terrat-oss-build /mono/code/src/iris/dist/ /usr/local/share/terrat/ui/assets/
USER terrat
EXPOSE 8080
CMD ["runsvdir", "/etc/service"]
