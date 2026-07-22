#!/usr/bin/env bash
#
# This script must be executed from the repository's root.
#
# This script clones this repo (to avoid sending a dirty code/build directory into the container image)
# and then builds the "terrat-oss" target (or the first argument, if specified)

declare -r TARGET="${1:-terrat-oss}"
echo "Building target: $TARGET"

if ! git diff --quiet || ! git diff --quiet --staged
then
  echo "⚠️ There are changes in this repository. This is probably unintended, because they are not going to make it to the git clone:"
  for file in $(git diff --name-only) $(git diff --staged --name-only)
  do
    echo "  $file"
  done
  echo "🛑 So I'm aborting. You probably want to commit your changes first and re-execute this script."
  exit 1
fi
echo "Using branch: $(git branch --show-current)"

set -eux

declare -r HERE="$PWD"
cd "$(mktemp --tmpdir -d "terrateam-clone-XXX")"
git clone "$HERE" .
./docker/terrat/build-target.sh "$TARGET"
