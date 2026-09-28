#!/usr/bin/env bash
# Cut a release: annotated tag on main (SSH) + GitLab Release (glab, if available).
# Edit VERSION and notes.md, run from the repository root.
set -euo pipefail

VERSION="v0.1.0"          # confirm it with the user first
NOTES_FILE="notes.md"     # release notes, see the skill's step 3

[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || { echo "Not a vX.Y.Z version: $VERSION" >&2; exit 1; }
[ -s "$NOTES_FILE" ] || { echo "Write the release notes in $NOTES_FILE first" >&2; exit 1; }

git fetch origin --tags
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
  echo "$VERSION already exists: cut a new version instead of moving it" >&2
  exit 1
fi

LAST=$(git describe --tags --abbrev=0 origin/main 2>/dev/null || true)
echo "Commits since ${LAST:-the beginning}:"
git log --oneline "${LAST:+$LAST..}origin/main"

git tag -a "$VERSION" origin/main -F "$NOTES_FILE"
git push origin "$VERSION"

if command -v glab >/dev/null && glab auth status >/dev/null 2>&1; then
  glab release create "$VERSION" --name "$VERSION" --notes-file "$NOTES_FILE"
else
  echo "No glab session: create the Release in the UI (Deploy > Releases > New release)"
  echo "for tag $VERSION, with the content of $NOTES_FILE."
fi
