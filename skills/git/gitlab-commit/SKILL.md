---
name: gitlab-commit
description: Commit message conventions for repositories hosted on GitLab (client engagements on gitlab.com or a self-hosted GitLab) — Conventional Commits with an optional ticket key prefix, no AI attribution, and how to squash local commits before pushing. Trigger when committing, rewording or squashing commits in a repo whose remote is a GitLab host. Do NOT trigger for github.com/groupbees repos (commit-groupbees) or personal open-source repos (commit-open-source).
---

# Skill: GitLab Commit

## Context

GitLab-hosted client repositories usually follow **Conventional Commits**: the
subject says what kind of change it is, release notes and SemVer bumps are
derived from it (see `gitlab-release`), and squash-merged merge requests keep
`main` readable.

**The repository's own `AGENTS.md` / `CONTRIBUTING.md` wins.** Read it first:
some repos add a scope list, forbid a body, or use gitmoji. This skill is the
default when the repo says nothing.

## Message format

```
[<TICKET> ]<type>(<scope>)[!]: <description>

[<body>]

[BREAKING CHANGE: <what breaks and how to migrate>]
```

- **Ticket key first, only if one exists** (`HDV-3491 feat(dag): ...`): GitLab's
  Jira integration links it, and `git log --grep HDV-3491` finds the feature for
  a cherry-pick. No ticket → no prefix; never a placeholder like `NO-TICKET`.
- **Subject** ≤ 72 characters (ticket included), imperative (`add`, not
  `added`), no final period, in English.
- **Body** only when it earns it: *what* and *why* a reviewer cannot infer from
  the diff, wrapped at 80 characters, a short paragraph or up to ~7 bullets.
- **`!` / `BREAKING CHANGE:`** for anything a consumer must adapt to — it drives
  a major version bump.

| Type | Use for | Release section |
|------|---------|-----------------|
| `feat` | new behaviour | Added |
| `fix` | bug fix | Fixed |
| `perf`, `refactor` | no behaviour change / faster | Changed |
| `docs` | documentation only | Docs |
| `ci`, `build` | pipeline, packaging, Dockerfile | CI |
| `test`, `style`, `chore` | tests, formatting, maintenance | (usually omitted) |

The scope is the component a reader would look for: `registrar`, `api`,
`litellm`, `dag`, `helm`. Keep it stable across the repo's history.

## Workflow

1. **Look before staging**: `git status`, `git diff`, `git log --oneline -5`
   (match the surrounding style).
2. **Stage by name**: `git add <file> ...` — never `git add -A` / `git add .`
   without reviewing what it picks up; never stage `.env`, keys, tokens.
3. **Commit with a HEREDOC** so the body keeps its line breaks:

   ```bash
   git commit -F - <<'EOF'
   fix(litellm): keep models in the gateway when their backend lookup fails

   A transient 503 from the Cloud Run API dropped the id from the desired
   set, and the prune step deleted a healthy route.
   EOF
   ```

4. **Squash local work before pushing** when a branch holds several WIP commits:

   ```bash
   git log --oneline origin/main..HEAD          # what would ship
   git reset --soft origin/main && git commit   # one commit, same tree
   git diff <old-tip> HEAD                      # must be empty: nothing lost
   ```

## Rewriting what is already pushed

Only on **your own** merge-request branch, only when asked, and never on `main`:

- Squash with `git reset --soft <base>` + commit, prove the tree is unchanged
  (`git diff <old-tip> HEAD` is empty), then
  `git push --force-with-lease=<branch>:<old-tip>` — the push is refused if
  someone else pushed meanwhile.
- A force push usually **resets merge-request approvals** (see `gitlab-mr`):
  tell the reviewers.

## Conventions

- **No AI attribution of any kind**: no `Co-Authored-By`, no "Generated with"
  line, in commits or merge requests.
- Never `--no-verify`: fix what the pre-commit hook reports.
- Never amend or force-push a commit someone else may have based work on.
- One logical change per commit; formatting-only changes (`ruff format`,
  `terraform fmt`) in their own commit so the review diff stays readable.
