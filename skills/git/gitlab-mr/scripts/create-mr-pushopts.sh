#!/usr/bin/env bash
# Create a GitLab merge request from the push itself (git push options over SSH).
# No token, no REST API: works wherever `git push` works.
#
# - Options are processed ONLY on a ref update: push them on the branch's first
#   push. If the branch is already on the remote at this SHA they are ignored.
# - Option values cannot contain newlines: the description is one line of HTML.
# - Labels that do not exist are CREATED in the project: use existing ones.
#
# Usage: edit the variables, run from the branch to propose.
set -euo pipefail

# ---- edit these -------------------------------------------------------------
TARGET="main"
TICKET=""                                           # Jira/other key (HDV-3491) or "#42"; empty if none
SUBJECT="fix(scope): short imperative description"
LABELS=()                                           # e.g. (bug litellm)
DRAFT=false
# -----------------------------------------------------------------------------

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$BRANCH" != "$TARGET" ] || { echo "Refusing to open an MR from $TARGET" >&2; exit 1; }

if git ls-remote --exit-code origin "refs/heads/${BRANCH}" >/dev/null 2>&1; then
  echo "Branch '${BRANCH}' already exists on the remote: push options would be" >&2
  echo "ignored. Create the MR with glab/the API/the UI instead." >&2
  exit 1
fi

# A ticket key leads the title (GitLab issues are referenced in the description only).
case "$TICKET" in
  "" | \#*) TITLE="$SUBJECT" ;;
  *)        TITLE="$TICKET $SUBJECT" ;;
esac

# One physical line of HTML. Keep every appended chunk newline-free.
# The ticket, when there is one, is the first thing a reviewer reads.
DESC=""
case "$TICKET" in
  "")  ;;
  \#*) DESC="<p>Closes ${TICKET}</p>" ;;
  *)   DESC="<p><strong>${TICKET}</strong></p>" ;;
esac
DESC+="<h3>Summary</h3><p>TODO: the problem and what this MR does about it.</p>"
DESC+="<h3>What changed</h3><ul><li>TODO</li></ul>"
DESC+="<h3>Test plan</h3><ul><li>TODO: what was run, with results</li></ul>"

opts=(
  -o merge_request.create
  -o "merge_request.target=${TARGET}"
  -o "merge_request.title=${TITLE}"
  -o "merge_request.description=${DESC}"
  -o merge_request.remove_source_branch
)
for label in "${LABELS[@]+"${LABELS[@]}"}"; do opts+=(-o "merge_request.label=${label}"); done
[ "$DRAFT" = true ] && opts+=(-o merge_request.draft)

git push -u origin "$BRANCH" "${opts[@]}"
