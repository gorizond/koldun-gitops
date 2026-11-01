#!/usr/bin/env bash
# Fail when a Fleet helm block is not pinned: every <layer>/fleet.yaml that
# carries a top-level "helm:" block must name a chart and an explicit version,
# and neither value may be "latest".
set -euo pipefail

cd "$(dirname "$0")/.."

status=0

strip() {
  local value="$1"
  # Drop a trailing comment, surrounding whitespace and optional quotes.
  value="${value%%#*}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

field() {
  # Print the value of a key inside the given helm block.
  printf '%s\n' "$1" |
    awk -v key="$2" '
      $0 ~ "^[[:space:]]+" key ":[[:space:]]*" {
        sub("^[[:space:]]+" key ":[[:space:]]*", "")
        print
        exit
      }
    '
}

shopt -s nullglob
for fleet in */fleet.yaml; do
  # Body of the top-level helm block: indented lines after "helm:".
  block=$(awk '
    /^helm:[[:space:]]*(#.*)?$/ { inside = 1; next }
    inside && /^[^[:space:]#]/ { inside = 0 }
    inside { print }
  ' "$fleet")

  # Layers may ship raw manifests only; nothing to pin in that case.
  [ -n "$block" ] || continue

  chart=$(strip "$(field "$block" chart)")
  version=$(strip "$(field "$block" version)")

  if [ -z "$chart" ]; then
    echo "$fleet: helm block has no chart" >&2
    status=1
  fi

  if [ -z "$version" ]; then
    echo "$fleet: helm block has no version (pin an explicit chart version)" >&2
    status=1
  fi

  if printf '%s' "$chart $version" | grep -qi 'latest'; then
    echo "$fleet: chart or version resolves to latest (pin an explicit chart version)" >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "Pinned Helm version check failed." >&2
  exit 1
fi

echo "All helm blocks are pinned."
