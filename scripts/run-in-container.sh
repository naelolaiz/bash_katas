#!/usr/bin/env bash
# Open an interactive shell inside the bash-katas container.
# Equivalent to `make shell` but with explicit flag control.

set -euo pipefail

cd "$(dirname "$0")/.."

OCI=${OCI:-podman}
IMAGE=${IMAGE:-localhost/bash-katas:dev}

# Build if missing.
if ! "$OCI" image exists "$IMAGE" 2>/dev/null && ! "$OCI" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "image $IMAGE not present; building..." >&2
  "$OCI" build -t "$IMAGE" .
fi

exec "$OCI" run --rm -it \
  -v "$PWD:/work:rw" \
  -w /work \
  -e LANG="${LANG:-C.UTF-8}" \
  "$IMAGE" "$@"
