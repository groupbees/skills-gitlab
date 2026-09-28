---
name: gitlab-mr
description: Creates and updates GitLab merge requests — title, structured description, labels, draft state — through git push options over SSH (no token), glab, or the REST API, and explains what happens to approvals, labels and pipelines when the branch changes. Trigger when opening, pushing to, force-pushing, retitling or labelling a merge request in a GitLab-hosted repo. Do NOT trigger for GitHub pull requests (pr-groupbees).
---

# Skill: GitLab Merge Request

## Context

A merge request (MR, written `!<n>`, e.g. `gateway!1`) is where a change is
reviewed, its pipeline runs, and approvals are collected. Three ways to create
one, in order of preference:

| Method | Needs | Can update an existing MR? |
|--------|-------|----------------------------|
| **A. `git push` options** | only the SSH key used for `git push` | **No** — options apply at creation only |
| **B. `glab`** | a token with `api` scope + HTTPS reachable | Yes |
| **C. REST API (`curl`)** | same as B | Yes |

Method A works everywhere `git push` works, including hosts whose HTTPS API is
unreachable from your network, and needs no secret. Prefer it for creation; use
B/C (or the web UI) to edit afterwards.

**Check the repo's `AGENTS.md` first**: many repos forbid an agent from opening,
approving or merging an MR — the branch then stops at `git push`, and you hand
over the URL GitLab prints.

## Title and description

- **Title** = the Conventional Commit subject the squash will produce
  (`gitlab-commit`): `fix(litellm): keep models in the gateway when ...`,
  ticket key first if there is one. ≤ 72 characters, English.
- **Ticket first, when there is one.** If the work is tracked in Jira or any
  other ticketing tool (ServiceNow, Linear, a GitLab issue), put its reference
  on the **first line of the description**, so a reviewer sees what it answers
  before reading anything else:
  - Jira and similar: the key, e.g. `**HDV-3491**` — GitLab's Jira integration
    turns it into a link (also put it at the start of the title, see above);
  - GitLab issue: `Closes #42` (or `Relates to #42`) — `Closes` also closes the
    issue when the MR merges.
  No ticket → no line; never a placeholder.
- **Description**, in English:

  ```markdown
  **HDV-3491**            ← only when a ticket exists

  ## Summary
  One paragraph: the problem and what this MR does about it.

  ## What changed
  - bullet per meaningful change, naming files or components

  ## Why
  The reasoning a reviewer needs (only when not obvious).

  ## Test plan
  - [x] what was run, with results (tests, dry-run, before/after table)
  - [ ] what is still to verify after merge
  ```

- Link the related MRs (`other-repo!37`) and say when merge order matters.
- No AI attribution in the description.

## Method A — push options (recommended)

```bash
git push -u origin "$BRANCH" \
  -o merge_request.create \
  -o merge_request.target=main \
  -o "merge_request.title=$TITLE" \
  -o "merge_request.description=$DESC" \
  -o merge_request.label=bug -o merge_request.label=litellm \
  -o merge_request.remove_source_branch
# add -o merge_request.draft for a draft MR
```

Hard constraints (git and GitLab, not the skill):

1. **Options only run on a ref update.** A branch already pushed at the same SHA
   prints `Everything up-to-date` and ignores them — pass them on the first push.
2. **No newline in an option value.** Encode the description as **one line of
   HTML** (`<h3>`, `<ul><li>`, `<code>`, `<table>`); Markdown headings do not
   render without newlines. Escape literal `<` / `>` as `&lt;` / `&gt;`.
   Task lists do not survive: `<li>[x] ...</li>` shows the text `[x]`, not a
   checkbox. When the checklist matters, paste the Markdown version in the UI
   after creation.
3. **The description cannot be changed this way later.** Edit it in the UI or
   with B/C.

A ready-to-edit script: [`templates/create-mr-pushopts.sh`](templates/create-mr-pushopts.sh).

## Methods B and C

```bash
glab mr create --title "$TITLE" --description "$(cat mr.md)" \
  --target-branch main --label bug,litellm --remove-source-branch [--draft]
glab mr update 1 --description "$(cat mr.md)"        # edit later

curl -s --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$(jq -n --arg t "$TITLE" --arg d "$(cat mr.md)" \
      '{source_branch:"'"$BRANCH"'", target_branch:"main", title:$t, description:$d}')" \
  "https://<gitlab-host>/api/v4/projects/<url-encoded-path>/merge_requests"
```

A token is a secret: use `glab auth login` (stored in glab's config), never a
token pasted in a command line or committed.

## Labels

- **A label that does not exist is created** by push options (and by the API).
  In a client project that silently adds labels to their taxonomy: list the
  existing labels first, or ask which to use.
- No house convention imposed here: use the project's labels (type, component,
  priority) as its README or maintainers define them.

## What happens when the branch changes

| Action | Effect |
|--------|--------|
| New commit pushed | A new pipeline runs; **approvals are usually reset** — the project setting *Settings → Merge requests → Approval settings → "When a commit is added"* decides |
| Force push (squash, rebase) | Same, and the MR's commit list is rewritten; reviewers lose their "changes since last review" view |
| Nothing pushed | Push options are ignored (see A.1) |

If the project is managed as code (Terraform `gitlab` provider), the approval
rule may be there but the reset setting may not — check the UI before assuming.

So: finish the review fixes **before** asking for approval, and tell reviewers
in the MR when you push after they approved.

## Merge

Follow the project's settings: merge method (`merge`, `ff`, `rebase_merge`),
squash option, "pipeline must succeed", "all threads resolved". With squash
on, the MR title becomes the commit on `main` — make it a good Conventional
Commit. A fast-forward-only project needs the branch rebased on `main` first.

## Automated reviewers

A review bot (pr-agent, Duo) can be wrong: reproduce its scenario before
changing code, and answer in the thread with the evidence either way.
