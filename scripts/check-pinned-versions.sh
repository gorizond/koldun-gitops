#!/usr/bin/env bash
# Fail when a Fleet helm block is not pinned.
#
# Scope: only top-level <layer>/fleet.yaml files are scanned (nested fleet
# files are ignored). A layer with a top-level helm block must use block style,
# name a chart, and pin an exact chart version. Version ranges, channels such
# as "latest", and inline helm maps are rejected.
set -euo pipefail

cd "$(dirname "$0")/.."

version_re='^v?[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'
status=0
layers=0

# Trim surrounding whitespace. A quoted value ends at its closing quote, so a
# '#' inside quotes survives. An unquoted value treats '#' as the start of a
# trailing YAML comment (chart names and semver values never contain one).
strip() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  case "$value" in
    \"*)
      value="${value#\"}"
      value="${value%%\"*}"
      ;;
    \'*)
      value="${value#\'}"
      value="${value%%\'*}"
      ;;
    *)
      value="${value%%#*}"
      value="${value%"${value##*[![:space:]]}"}"
      ;;
  esac
  printf '%s' "$value"
}

# Print the value of a key that is a direct child of the helm block: the key
# must start at exactly the block's child indentation. Deeper keys (for
# example values.version) do not match.
field() {
  local block="$1" key="$2" indent="$3" pad
  pad=$(printf '%*s' "$indent" '')
  printf '%s\n' "$block" | awk -v pad="$pad" -v key="$key" '
    index($0, pad key ":") == 1 {
      rest = substr($0, length(pad key ":") + 1)
      sub(/^[[:space:]]*/, "", rest)
      print rest
      exit
    }
  '
}

shopt -s nullglob
for fleet in */fleet.yaml; do
  layers=$((layers + 1))

  # Split the top-level helm block: __INLINE__ for a flow map, __HELM__ plus
  # the indented body for block style, empty output when there is no helm block.
  parsed=$(awk '
    /^helm:/ {
      rest = $0
      sub(/^helm:[[:space:]]*/, "", rest)
      sub(/[[:space:]]*#.*$/, "", rest)
      if (rest != "") { print "__INLINE__"; exit }
      print "__HELM__"
      inside = 1
      next
    }
    inside && /^[^[:space:]#]/ { exit }
    inside { print }
  ' "$fleet")

  if [ "$parsed" = "__INLINE__" ]; then
    echo "$fleet: inline helm blocks are not supported; use block style" >&2
    status=1
    continue
  fi

  # No helm block at all: the layer ships raw manifests only.
  [ -n "$parsed" ] || continue

  block=${parsed#__HELM__}
  block=${block#$'\n'}

  # Direct children of helm: share the indentation of its first real line.
  indent=$(printf '%s\n' "$block" | awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    { match($0, /^[[:space:]]*/); print RLENGTH; exit }
  ')

  if [ -z "$indent" ]; then
    echo "$fleet: helm block has no chart/version" >&2
    status=1
    continue
  fi

  chart=$(strip "$(field "$block" chart "$indent")")
  version=$(strip "$(field "$block" version "$indent")")

  if [ -z "$chart" ]; then
    echo "$fleet: helm block has no chart" >&2
    status=1
  fi

  if [ -z "$version" ]; then
    echo "$fleet: helm block has no version (pin an exact chart version)" >&2
    status=1
  elif [[ ! "$version" =~ $version_re ]]; then
    echo "$fleet: helm version '$version' is not an exact semver (pin x.y.z; ranges and channels are rejected)" >&2
    status=1
  fi
done

if [ "$layers" -eq 0 ]; then
  echo "no <layer>/fleet.yaml files found (only top-level layer fleet.yaml files are scanned)" >&2
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo "Pinned Helm version check failed." >&2
  exit 1
fi

echo "All helm blocks are pinned."
