# AGENTS.md — working in skills-gitlab

Guidance for any AI assistant (Claude Code, GitHub Copilot, Cursor, Codex, …)
working **inside this repository**, and the reference for how the catalog is
consumed. This file is the **single source of truth**: `CLAUDE.md` next to it
only does `@AGENTS.md`, so Claude Code loads it even when it would otherwise
skip `AGENTS.md` (a `CLAUDE.local.md` present, an older version, or a session
that can't read `AGENTS.md`).

## What this repo is

The source of truth for GroupBees' **GitLab and GitLab CI/CD** skills — the
`skills-gitlab` module, for client engagements whose repositories live on
GitLab (gitlab.com or self-hosted): commits, merge requests, releases and
pipelines built on shared CI/CD components. It sits alongside the other modules
of `~/my-projects/groupbees/skills` (`skills-core` holds the transverse and the
GitHub-side conventions, e.g. `commit-groupbees`, `pr-groupbees`). A skill is a standard
**Agent Skill** (`SKILL.md`, the [agentskills.io](https://agentskills.io) open
standard): `skills/<domain>/<name>/SKILL.md` — YAML frontmatter with `name` +
`description`, then the instructions body — plus an optional `templates/` folder.

The same `SKILL.md` format is read natively by Claude Code, GitHub Copilot and
Cursor, so there is **one format and one install path**, no per-tool conversion.

## Install: skillmgr, per project first

Skills are consumed with [skillmgr](https://github.com/groupbees/skillmgr), not
copied by hand. A consumer declares sources in a `skillmgr.yaml` (git repos
pinned to a `revision`, or `repo: local`) and `skillmgr update` makes the target
dirs match it — install, refresh, prune — tracking what it owns in a
`.skillmgr.json` per target.

| Scope | Config | Targets |
|-------|--------|---------|
| **Project** (default) | `skillmgr.yaml` committed at the project root — [example](https://github.com/groupbees/skills-core/blob/main/examples/skillmgr.project.yaml) | `.claude/skills/` + `.agents/skills/` (gitignored) |
| **Machine** | one user-level file, run with `--config` — [example](https://github.com/groupbees/skills-core/blob/main/examples/skillmgr.global.yaml) | `~/.claude/skills/` + `~/.agents/skills/` |

Two target dirs because **no single one covers every agent**: Claude Code reads
`.claude/skills`, the others scan `.agents/skills`.

The machine-level file lives at `~/.config/skillmgr/skillmgr.yaml` by
convention (skillmgr has no global default path; pass `--config`, never export
`SKILLMGR_CONFIG_FILE`, which would shadow every project's config).

**One config per target set.** skillmgr prunes whatever the config no longer
selects from that target's state, so two configs writing to the same
`~/.claude/skills` would remove each other's skills. At machine level, list
every module in the one user-level file.

This repo's own [`skillmgr.yaml`](skillmgr.yaml) (`repo: local`) deploys the
catalog into this repo, so agents working here use it — and CI runs
`skillmgr validate` on it. The pre-skillmgr installer, `sync-skills.sh`, lives in
the frozen `skills-core-legacy` repo.

## Modules

skills-gitlab is one module among others (`skills-core`, `skills-slides`, …), each its own repo
with a `skills-module.json` (`{ name, description }`; the version lives in git
tags). A consumer mixes modules by listing several `repos:` in its
`skillmgr.yaml`. Skill names must be **unique across modules**: they deploy
flat, map to a single `/<name>`, and skillmgr rejects two sources yielding the
same name.

## How a skill is used

In every tool: **auto-used** when the prompt matches the skill's `description`
(progressive disclosure), **or** invoked explicitly with `/<name>`.

## The one rule to remember

**Edit the source, never the installed copy.** Everything under a
`.claude/skills/` or `.agents/skills/` is deployed by skillmgr. To change a
skill: edit `skills/<domain>/<name>/SKILL.md`, then re-run `skillmgr update`.

## Design choices

- **Standard `SKILL.md`, nothing tool-specific** — portable across Claude Code,
  Copilot and Cursor as-is.
- **Validation in CI** (`.github/workflows/ci.yml`), four checks:
  1. [`skill-validator`](https://github.com/agent-ecosystem/skill-validator)
     `check --strict` — spec conformance plus what the official validator does
     not cover: token budgets, broken links, orphan files, description quality.
  2. `skillmgr validate` — the catalog deploys the way consumers deploy it.
  3. `scripts/skills-catalog.sh --check-readme` / `--check-names` — the README
     table is generated (CI fails if it drifted); leaf names are unique.
  4. `shellcheck scripts/*.sh`.
- **No per-skill `README.md`.** The validator flags extra files at a skill root,
  and duplicated docs rot: the human docs ARE `SKILL.md`.
- **`templates/`** holds bundled runtime assets (the spec's own name is
  `assets/`; CI passes `--allow-dirs=templates`).

## Before adding a NEW skill — check for overlap

Most skills are added by an AI agent, so the duplicate check is **your** job:

1. **List what already exists** — `scripts/skills-catalog.sh --list` prints every skill's
   `name` + `description` straight from the `SKILL.md` files. Do **not** rely on
   the README table for this.
2. **Compare semantically.** If an existing skill already covers the capability,
   **extend** it, or **extract a shared skill** both can reference — do not add
   an overlapping one.
3. A duplicate **name** is rejected automatically (`--check-names` + CI). Semantic
   **overlap** is the judgment call this list exists for.

## Adding or changing a skill

1. Create/edit `skills/<domain>/<name>/SKILL.md` — frontmatter is **only** `name`
   (= folder name) + `description` (it drives both auto-use and the `/` picker).
   Add `templates/` if the skill ships assets.
2. `skillmgr update --dry-run`, then `skillmgr update` (deploys into this repo).
3. `scripts/skills-catalog.sh --readme` to regenerate the README table, and commit it.
4. Commit with the `commit-groupbees` conventions, open the PR with
   `pr-groupbees`, release with `tag-groupbees`.

## Versioning

Not per-skill. `SKILL.md` carries only `name` + `description`. Versioning is
**catalog-wide via git tags** (semver `vX.Y.Z`, cut with `tag-groupbees`), and
the **GitHub Releases page is the changelog** — no hand-maintained
`CHANGELOG.md`. Pin a release tag instead of `main` when you need stability.

See `CONTRIBUTING.md` and `README.md` for more.
