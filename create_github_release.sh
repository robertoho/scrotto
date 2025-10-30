#!/usr/bin/env bash
set -euo pipefail

# create_github_release.sh
# Creates a GitHub release for the version in Cargo.toml and uploads the dist artifacts.

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

VERSION=$(grep '^version' Cargo.toml | cut -d'"' -f2)
TAG="v${VERSION}"
RELEASE_NAME="$TAG"
DIST_DIR="dist"
ARCHIVE="$DIST_DIR/scrotto-${VERSION}.tar.gz"
CHECKSUM="$ARCHIVE.sha256"

print() { printf "%s\n" "$*"; }
err() { printf "Error: %s\n" "$*" >&2; }

ensure_archive() {
  if [[ ! -f "$ARCHIVE" || ! -f "$CHECKSUM" ]]; then
    print "Distribution artifacts not found, running ./dist.sh to build them..."
    ./dist.sh
  fi
}

create_git_tag() {
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    print "Git tag $TAG already exists"
  else
    git tag -a "$TAG" -m "Release $VERSION"
    git push origin "$TAG"
    print "Pushed tag $TAG"
  fi
}

use_gh_cli() {
  if command -v gh >/dev/null 2>&1; then
    print "Using gh CLI to create release"
    # Create release (idempotent: will fail if exists)
    if gh release view "$TAG" >/dev/null 2>&1; then
      print "Release $TAG already exists, uploading assets..."
    else
      gh release create "$TAG" "$ARCHIVE" --title "$RELEASE_NAME" --notes "Release $VERSION"
      print "Created release $TAG"
    fi

    # Upload checksum (gh release upload will add/replace)
    gh release upload "$TAG" "$CHECKSUM" --clobber || true
    print "Uploaded assets to release $TAG"
    return 0
  fi
  return 1
}

use_api() {
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    err "GITHUB_TOKEN not set and gh CLI not available. Cannot create release."
    return 1
  fi

  # Determine repo owner/name from origin URL
  ORIGIN_URL=$(git remote get-url origin)
  # support https and git@ formats
  if [[ "$ORIGIN_URL" =~ ^git@github.com:(.+)/(.+)\.git$ ]]; then
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]}
  elif [[ "$ORIGIN_URL" =~ ^https://github.com/(.+)/(.+)\.git$ ]]; then
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]}
  else
    err "Could not parse origin URL: $ORIGIN_URL"
    return 1
  fi

  API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases"

  # Create release JSON
  read -r -d '' PAYLOAD <<EOF || true
{
  "tag_name": "${TAG}",
  "name": "${RELEASE_NAME}",
  "body": "Release ${VERSION}",
  "draft": false,
  "prerelease": false
}
EOF

  RESP=$(curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -H "Content-Type: application/json" -d "$PAYLOAD" "$API_URL")
  UPLOAD_URL=$(echo "$RESP" | python3 -c "import sys, json
data=json.load(sys.stdin)
print(data.get('upload_url',''))")

  if [[ -z "$UPLOAD_URL" ]]; then
    err "Failed to create release. Response: $RESP"
    return 1
  fi

  # upload_url has pattern: https://uploads.github.com/...{?name,label}
  UPLOAD_URL=${UPLOAD_URL%%\{*}

  # Upload archive
  for FILE in "$ARCHIVE" "$CHECKSUM"; do
    NAME=$(basename "$FILE")
    print "Uploading $NAME"
    curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -H "Content-Type: application/octet-stream" --data-binary @"$FILE" "${UPLOAD_URL}?name=${NAME}"
  done
  print "Uploaded assets via API"
  return 0
}

main() {
  ensure_archive
  create_git_tag

  if use_gh_cli; then
    return 0
  fi

  if use_api; then
    return 0
  fi

  err "Failed to create release. Install the GitHub CLI (gh) or set GITHUB_TOKEN to use the API."
  exit 1
}

main "$@"
