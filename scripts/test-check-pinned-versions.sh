#!/usr/bin/env bash
# Tests for check-pinned-versions.sh. Each case builds a throwaway repo root
# with one layer and runs a copy of the checker against it.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0

# check <name> <expected-exit> <fleet.yaml content, or "-" for no layer file>
check() {
  local name="$1" expected="$2" content="${3-}" root out actual
  root="$tmp/$name"
  mkdir -p "$root/scripts" "$root/layer"
  cp "$here/check-pinned-versions.sh" "$root/scripts/"

  if [ "$content" != "-" ]; then
    printf '%s\n' "$content" > "$root/layer/fleet.yaml"
  fi

  if out=$(bash "$root/scripts/check-pinned-versions.sh" 2>&1); then
    actual=0
  else
    actual=$?
  fi

  if [ "$actual" -eq "$expected" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: expected exit $expected, got $actual" >&2
    printf '%s\n' "$out" | sed 's/^/     /' >&2
    failures=$((failures + 1))
  fi
}

check pinned 0 "$(cat <<'YAML'
defaultNamespace: demo
helm:
  repo: https://charts.example.test
  chart: demo
  version: 1.2.3
YAML
)"

check quoted-version-with-comment 0 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  chart: demo
  version: "1.2.3"  # pinned
YAML
)"

check chart-named-latest 0 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  chart: latest
  version: 1.2.3
YAML
)"

check raw-manifests-only 0 "$(cat <<'YAML'
defaultNamespace: rook-ceph
labels:
  koldun.io/component: ceph-s3
YAML
)"

check nested-chart-version-only 1 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  values:
    chart: nested
    version: 1.2.3
YAML
)"

check nested-latest-before-pinned 0 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  values:
    version: latest
  chart: demo
  version: 1.2.3
YAML
)"

check channel-latest 1 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  chart: demo
  version: latest
YAML
)"

check inline-helm 1 'helm: {repo: https://charts.example.test, chart: demo, version: 1.2.3}'

check empty-helm-block 1 "$(cat <<'YAML'
helm:

labels:
  koldun.io/component: demo
YAML
)"

check missing-chart 1 "$(cat <<'YAML'
helm:
  repo: https://charts.example.test
  version: 1.2.3
YAML
)"

index=0
for range in '>=1.0.0' '1.x' '~1.2' '*'; do
  index=$((index + 1))
  check "range-$index" 1 "$(cat <<YAML
helm:
  repo: https://charts.example.test
  chart: demo
  version: $range
YAML
)"
done

check no-layer-files 1 -

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed." >&2
  exit 1
fi

echo "All pinned-version checks behaved as expected."
