#!/usr/bin/env bash
# Scan lines added by a pull request for personal data and local paths.
#
# Inputs:
#   BASE_SHA, HEAD_SHA  Required git revisions. The diff is BASE...HEAD.
#
# Output: GitHub Actions error annotations with masked values. Exit 1 on a
# finding, 0 when clean, 2 for invalid input. No network or write access.
# Exceptions are hardcoded here and cannot be supplied by the pull request.
set -euo pipefail

base="${BASE_SHA:-${1:-}}"
head="${HEAD_SHA:-${2:-}}"
if [[ -z "$base" || -z "$head" ]]; then
  echo "usage: BASE_SHA=<sha> HEAD_SHA=<sha> $0" >&2
  exit 2
fi

email_re='[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'
home_re='(/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|[A-Za-z]:\\{1,2}Users\\{1,2}[A-Za-z0-9._-]+)'
key_re='BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'

# Return 0 when an address is a documented placeholder or service address.
allowed_email() {
  case "$1" in
    *@example.com|*@example.test|*@example.invalid)
      return 0 ;;
    demo@demo.com|noreply@github.com|git@github.com)
      return 0 ;;
  esac
  return 1
}

# Return 0 when the path is the one reviewed configuration exception.
allowed_path() {
  case "$1" in
    clusters/*/cluster-vars.yaml|clusters/*/cluster-vars.yml)
      return 0 ;;
  esac
  return 1
}

mask_email() {
  local local_part="${1%%@*}" domain="${1#*@}"
  printf '%s***@%s' "${local_part:0:1}" "$domain"
}

mask_path() {
  sed -E 's#(/Users/|/home/)[A-Za-z0-9._-]+#\1***#g; s#[A-Za-z]:.*Users.*#<windows-user-path>#g' <<< "$1"
}

fail=0
if ! diff="$(git diff --unified=0 --no-color --no-ext-diff "${base}...${head}" 2>/dev/null)"; then
  echo "::error::PII guard could not compute the pull request diff."
  exit 2
fi
if [[ -z "$diff" ]]; then
  echo "PII guard: no added lines to scan."
  exit 0
fi

while IFS=$'\t' read -r path line text; do
  [[ -z "$path" ]] && continue
  allowed_path "$path" && continue

  while IFS= read -r email; do
    [[ -z "$email" ]] && continue
    allowed_email "$email" && continue
    printf '::error file=%s,line=%s::Personal email address %s\n' \
      "$path" "$line" "$(mask_email "$email")"
    fail=1
  done < <(grep -Eo "$email_re" <<< "$text" || true)

  while IFS= read -r home; do
    [[ -z "$home" ]] && continue
    printf '::error file=%s,line=%s::Home-directory path %s\n' \
      "$path" "$line" "$(mask_path "$home")"
    fail=1
  done < <(grep -Eo "$home_re" <<< "$text" || true)

  if grep -Eq "$key_re" <<< "$text"; then
    printf '::error file=%s,line=%s::Private key material\n' "$path" "$line"
    fail=1
  fi
done < <(awk '
  /^\+\+\+ / { path=substr($0,7); sub(/^b\//,"",path); next }
  /^@@ / { split($0,a,"+"); split(a[2],b,","); split(b[1],c," "); line=c[1]; next }
  /^\+/ && !/^\+\+\+/ { print path "\t" line "\t" substr($0,2); line++ }
' <<< "$diff")

if (( fail )); then
  echo "PII guard failed. Use placeholders such as <operator>@sap.com and /absolute/path/...."
  exit 1
fi
echo "PII guard passed."
