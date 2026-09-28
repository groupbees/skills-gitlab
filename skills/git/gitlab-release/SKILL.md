---
name: gitlab-release
description: Cuts a release of a GitLab-hosted repository — computes the next SemVer from the Conventional Commits since the last tag, creates the annotated vX.Y.Z tag on main, writes the release notes and attaches them as a GitLab Release, then checks the tag pipeline (image promotion, package publish). Trigger when tagging, releasing or publishing a version of a repo whose remote is a GitLab host. Do NOT trigger for github.com/groupbees repos (tag-groupbees) or public packages (tag-opensource).
---

# Skill: GitLab Release

## Context

A release is **one SemVer tag for the whole repository** (`vX.Y.Z`), cut on
`main`, plus a **GitLab Release** carrying the notes. The Release page is the
changelog: no hand-maintained `CHANGELOG.md` to keep in sync.

The tag is usually what the pipeline acts on: promoting the image built on
`main` to a release registry, publishing a package. So a tag is a deployment
trigger as much as a label — cut it deliberately.

## Workflow

### 1. Start from an up-to-date `main`

```bash
git fetch origin --tags && git switch main && git pull --ff-only
LAST=$(git describe --tags --abbrev=0 2>/dev/null || true)
git log --oneline "${LAST:+$LAST..}HEAD"
```

The pipeline on `main` must be green, and the versions declared in code
(`pyproject.toml`, `__version__`, `Chart.yaml`) must match the tag you are about
to cut — fix them in an MR first if not.

### 2. Compute the version

| Commits since the last tag contain | Bump |
|------------------------------------|------|
| `!` after the type, or `BREAKING CHANGE:` | major |
| any `feat` | minor |
| only `fix`, `perf`, `refactor`, `docs`, `ci`, `chore`… | patch |

First release: `v0.1.0`. Below `v1.0.0`, a breaking change bumps the minor.
**Confirm the version with the user before tagging.**

### 3. Write the notes

Group the commits by type, rewritten for a reader rather than pasted:

```markdown
One sentence on what this release is.

**Artifact:** `<registry>/<path>/<image>:vX.Y.Z`

### Added
- ...
### Fixed
- ...
### Validated
- what was tested, and where (unit tests, dry-run in dev, ...)
```

Keep ticket keys so GitLab cross-links them. Say what an operator must do (a
pin to bump, a config key to add). English.

### 4. Tag

```bash
git tag -a vX.Y.Z origin/main -m "vX.Y.Z - <one line on what it is>"   # annotated, from main
git push origin vX.Y.Z                                                  # SSH, no token needed
```

Keep the tag message to one line: the notes live in the Release (step 5), and a
tag message cannot be edited later without deleting and re-pushing the tag. Put
the full notes in the message only when no Release will be created.

### 5. Attach the GitLab Release

A tag alone does not create the Release object. With a token (`glab auth login`):

```bash
glab release create vX.Y.Z --name vX.Y.Z --notes-file notes.md
```

Without API access, give the user the notes and the path: **Deploy → Releases →
New release**, pick the tag. This is a normal setup, not a gap to work around:
many client projects give no personal token and want no release job in CI, so
the agent's job is to hand over notes ready to paste, one block per version.
A CI job with `release:` (CI_JOB_TOKEN) is an option to *offer*, never to add
unasked. A ready-to-edit script:
[`templates/create-release.sh`](templates/create-release.sh).

### 6. Check what the tag triggered

The tag pipeline must be green, and its artifact must exist where consumers pin
it (e.g. the promote job printing the `digest:` it pushed). Only then bump the
pins that reference the new version, in their own repositories.

## Conventions

- `vX.Y.Z` with the `v`; pre-releases `vX.Y.Z-rc.1`.
- **Annotated** tags only; **from `main`** only.
- **Never move or delete a pushed tag**: consumers, caches and registries have
  seen it. A mistake gets a new patch version.
- Tags may be protected: a push refused on a protected tag is expected for a
  non-maintainer — ask one, do not work around it.
- No AI attribution in tag messages or release notes.
