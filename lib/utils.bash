#!/usr/bin/env bash

set -euo pipefail

declare -r GH_REPO='https://github.com/neovim/neovim-releases'
declare -r GH_API_REPO='https://api.github.com/repos/neovim/neovim-releases'
declare -r TOOL_NAME='neovim-legacy'
declare -r TOOL_BIN='nvim'
declare -r TOOL_TEST="${TOOL_BIN} --version"

fail() {
  printf 'asdf-%s: %s\n' "$TOOL_NAME" "$*" >&2
  exit 1
}

declare -a curl_opts=('-f' '-s' '-S' '-L' '--proto' '=https' '--tlsv1.2' '--retry' 3 '--retry-delay' 2)

if [[ -n "${GITHUB_API_TOKEN:-}" ]]; then
  curl_opts+=('--header' "Authorization: token $GITHUB_API_TOKEN")
fi

resolve_release_tag() {
  local -r version="$1"

  case "$version" in
    stable | nightly | nightly-test | v*)
      printf '%s' "$version"
      ;;
    *)
      printf 'v%s' "$version"
      ;;
  esac
}

# fetch_asset_sha256 <release_tag> <browser_download_url>
# Prints the lowercase hex SHA-256 digest reported by the GitHub Releases API
# for the asset whose browser_download_url matches the requested one.
# Uses jq when available, falling back to python3, then to a grep/sed parser.
fetch_asset_sha256() {
  local -r release_tag="$1"
  local -r asset_url="$2"

  local payload
  payload="$(
    curl "${curl_opts[@]}" -H 'Accept: application/vnd.github+json' \
      "${GH_API_REPO}/releases/tags/${release_tag}"
  )" || fail "Could not query GitHub API for release ${release_tag}"

  local digest=''
  if type 'jq' &>/dev/null; then
    digest="$(
      printf '%s' "$payload" |
        jq -r --arg url "$asset_url" \
          '.assets[] | select(.browser_download_url == $url) | .digest // empty'
    )"
  elif type 'python3' &>/dev/null; then
    digest="$(
      ASSET_URL="$asset_url" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
url = os.environ["ASSET_URL"]
for asset in data.get("assets", []):
    if asset.get("browser_download_url") == url:
        print(asset.get("digest") or "")
        break
' <<<"$payload"
    )"
  else
    # Last-resort dependency-free parser: normalize JSON whitespace, split on
    # asset object boundaries, then locate the object whose
    # browser_download_url matches and pull its digest field.
    digest="$(
      printf '%s' "$payload" |
        awk -v url="$asset_url" '
          { doc = doc " " $0 }
          END {
            gsub(/[[:space:]]+/, " ", doc)
            gsub(/" *: */, "\":", doc)
            gsub(/, */, ",", doc)
            gsub(/{ */, "{", doc)
            gsub(/ *}/, "}", doc)
            n = split(doc, parts, /},{/)
            for (i = 1; i <= n; i++) {
              if (index(parts[i], "\"browser_download_url\":\"" url "\"") > 0) {
                if (match(parts[i], /"digest":"[^"]+"/)) {
                  print substr(parts[i], RSTART + 10, RLENGTH - 11)
                  exit
                }
              }
            }
          }
        '
    )"
  fi

  # Older releases (published before GitHub added per-asset digests in
  # February 2025) have no digest field. Warn and return empty so the
  # caller can decide to skip verification.
  if [[ -z "$digest" ]]; then
    printf 'asdf-%s: warning: GitHub API reports no SHA256 digest for %s (release %s); skipping checksum verification\n' \
      "$TOOL_NAME" "${asset_url##*/}" "$release_tag" >&2
    return 0
  fi

  [[ "$digest" == sha256:* ]] ||
    fail "Unexpected digest algorithm for ${asset_url}: ${digest}"

  printf '%s' "${digest#sha256:}"
}

# verify_sha256 <file> <expected_hex>
verify_sha256() {
  local -r file="$1"
  local -r expected="$2"

  [[ -n "$expected" ]] || fail "Empty expected SHA256 for $file"

  local actual
  if type 'sha256sum' &>/dev/null; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  elif type 'shasum' &>/dev/null; then
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    fail 'Neither sha256sum nor shasum is available for SHA256 verification'
  fi

  if [[ "${actual,,}" != "${expected,,}" ]]; then
    fail "SHA256 mismatch for $file: expected $expected, got $actual"
  fi

  printf '* SHA256 verified (%s)\n' "$actual"
}
