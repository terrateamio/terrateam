#!/usr/bin/env bash
set -eufx -o pipefail

echo "${TERRATEAM_SELF_HOSTED_BUILD_GH_TOKEN}" | docker login ghcr.io -u $ --password-stdin
docker build --squash -t terrateam-base -f docker/terrat/Dockerfile.base .
docker build --squash -t ghcr.io/terrateamio/terrateam:v1 -f docker/terrat/Dockerfile .
docker push ghcr.io/terrateamio/terrateam:v1
