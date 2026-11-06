#!/usr/bin/env bash
# Local regression tests for scan.sh. Uses a throwaway git repository only.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q
git -C "$tmp" config user.name "PII guard test"
git -C "$tmp" config user.email "test@example.test"
printf 'base\n' > "$tmp/README.md"
git -C "$tmp" add README.md
git -C "$tmp" commit -qm base

base="$(git -C "$tmp" rev-parse HEAD)"

# Failing case: real email, home path, and a private key marker.
mkdir -p "$tmp/docs" "$tmp/clusters/dev" "$tmp/.github"
printf '.*\n' > "$tmp/.github/pii-allowlist.txt"
printf 'Contact marek.gruszecki@sap.com\n' > "$tmp/docs/email.md"
printf 'export KG=/Users/igor/garden.yaml\n' > "$tmp/docs/path.md"
printf -- '-----BEGIN PRIVATE KEY-----\n' > "$tmp/docs/key.md"
printf 'SHOWROOM_ORG_OWNER_EMAIL: marek.gruszecki@sap.com\n' > "$tmp/clusters/dev/cluster-vars.yaml"
git -C "$tmp" add .
git -C "$tmp" commit -qm failing
head="$(git -C "$tmp" rev-parse HEAD)"

if (cd "$tmp" && BASE_SHA="$base" HEAD_SHA="$head" bash "$here/scan.sh" >/dev/null 2>&1); then
  echo "FAIL: expected findings" >&2
  exit 1
fi

# Passing case: placeholders, demo address, and the config exception.
git -C "$tmp" reset -q --hard "$base"
mkdir -p "$tmp/docs" "$tmp/clusters/dev"
printf 'Contact <operator>@sap.com and demo@demo.com\n' > "$tmp/docs/email.md"
printf 'export KG=/absolute/path/garden.yaml\n' > "$tmp/docs/path.md"
printf 'SHOWROOM_ORG_OWNER_EMAIL: marek.gruszecki@sap.com\n' > "$tmp/clusters/dev/cluster-vars.yaml"
git -C "$tmp" add .
git -C "$tmp" commit -qm passing
head="$(git -C "$tmp" rev-parse HEAD)"

if ! (cd "$tmp" && BASE_SHA="$base" HEAD_SHA="$head" bash "$here/scan.sh" >/dev/null 2>&1); then
  echo "FAIL: expected a pass" >&2
  exit 1
fi

echo "PII guard tests passed."
