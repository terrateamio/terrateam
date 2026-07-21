#! /usr/bin/env bash

if [[ ! -d "code" || ! -d "docker/terrat" ]]
then
  echo "This script must be executed from terrateam's root directory."
  echo "Do: cd $(git rev-parse --show-toplevel)"
  exit 1
fi

set -euo pipefail

declare -r DOCKERFILE="docker/terrat/Dockerfile"
declare -r TARGET="${1:-terrat-oss}"

# Validate that the target exists as a stage in the Dockerfile
if ! grep -qiE "^FROM\s+\S+\s+AS\s+${TARGET}\s*$" "$DOCKERFILE"; then
    echo "Error: target '$TARGET' not found in $DOCKERFILE" >&2
    echo "Available targets:" >&2
    grep -iE '^\s*FROM\s+\S+\s+AS\s+' "$DOCKERFILE" | sed 's/.*AS\s*/  /' >&2
    exit 1
fi

TAG=$(git rev-parse --short HEAD)

declare -a BUILD_ARGS=()
if [[ -n "${BASE_IMAGE:-}" ]]; then
    BUILD_ARGS+=(--build-arg "BASE_IMAGE=$BASE_IMAGE")
fi

docker buildx build \
       "${BUILD_ARGS[@]}" \
       -f "$DOCKERFILE" \
       --target "$TARGET" \
       -t "$TARGET:$TAG" \
       -t "$TARGET:latest" \
       .

echo "Image successfully built. Execute it as follows:"
echo "docker run --rm -it $TARGET:$TAG"
