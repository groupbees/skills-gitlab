# 🤝 Contributing Guide

## Adding a new skill

### 0. First, check it doesn't already exist

Skills are usually added by an AI agent, so **check for overlap before creating
one** (a duplicate *name* is auto-rejected by CI, but semantic *overlap* is not):

```bash
scripts/skills-catalog.sh --list   # every skill's name + description, straight from SKILL.md
```

If an existing skill already covers the capability, **extend it** — or **extract
a shared skill** both can reference — rather than adding an overlapping one.
Don't use the README table for this check; use `--list`.

### 1. Skill structure

Each skill is a standard [Agent Skill](https://agentskills.io) — a directory
whose only required file is `SKILL.md`:

```
skills/<domain>/<skill-name>/
├── SKILL.md            # Required: the Agent Skill (name + description + body)
└── templates/          # Optional: bundled resources the skill uses
    ├── example.py
    └── ...
```

No per-skill `README.md` (the validator flags extra files at a skill root, and a
second doc rots), no `VERSION`, no per-skill `CHANGELOG.md` — see **Versioning**.

### 2. `SKILL.md` format

The frontmatter carries **only** `name` and `description` — the two fields the
standard requires:

```markdown
---
name: skill-name
description: What the skill does AND when to use it — include the keywords that
  make the agent trigger it (this drives both auto-matching and the / picker).
---

# Skill Name

## Context
...

## Conventions
...

## Code Template
...

## Examples
...
```

Rules enforced by CI ([`skill-validator`](https://github.com/agent-ecosystem/skill-validator)
`check --strict`):

- `name`: 1–64 chars, lowercase `a-z 0-9` and hyphens, no leading/trailing/double
  hyphen, and **must equal the folder name**.
- `description`: 1–1024 chars, non-empty, no keyword stuffing.
- Keep `SKILL.md` under ~500 lines / 5 000 tokens; move long reference material
  into `templates/` (or a referenced file) and tell the agent *when* to load it.
- Links must resolve, and no orphan files at the skill root.

### 3. Pre-merge checklist

- [ ] Checked for overlap with `scripts/skills-catalog.sh --list` (extend, don't duplicate)
- [ ] `SKILL.md` frontmatter has only `name` (= folder name) + `description`
- [ ] The skill name is unique across all domains **and all modules**
- [ ] `skillmgr validate` and `scripts/skills-catalog.sh --check-names` pass (CI runs them too)
- [ ] Regenerated the README table: `scripts/skills-catalog.sh --readme`
- [ ] `skill-validator check --strict --allow-dirs=templates skills/` passes
- [ ] Templates (if any) are functional and tested

### 4. Review process

1. Branch: `feat/skills/<domain>/<skill-name>`
2. Add/modify the skill
3. Open the PR with the [`pr-groupbees`](https://github.com/groupbees/skills-core/blob/main/skills/git/pr-groupbees/SKILL.md)
   conventions (Summary / What changed / Test plan, labels for release notes)
4. Squash-merge after approval

## Versioning

Skills are **not versioned per file** — no `VERSION`, no per-skill changelog, no
`version` frontmatter field (matching the Agent Skills standard and the public
Anthropic / Google skill repos). Versioning is **catalog-wide, via git tags**:

- The **repo commit** is the working version; consumers should not track it.
- Releases are catalog-wide semver tags (`vX.Y.Z`) cut with
  [`tag-groupbees`](https://github.com/groupbees/skills-core/blob/main/skills/git/tag-groupbees/SKILL.md).
- The **GitHub Releases page is the changelog** — no hand-maintained
  `CHANGELOG.md` to keep in sync.
- To **pin**, a consumer sets `revision: vX.Y.Z` in its `skillmgr.yaml` — a
  branch there floats (skillmgr has no lockfile yet).

## Naming conventions

- **Folders / skill names**: `kebab-case`, unique across domains *and* modules
  (they install flat and map to a single `/<name>`)
- **Domains**: `git` (commits, merge requests, releases), `cicd` (GitLab CI)
- **Branches**: `feat/skills/<domain>/<name>`, `fix/skills/<domain>/<name>`
- **Commits**: descriptive titles, no Conventional Commits prefix, no
  `Co-Authored-By` trailer — see
  [`commit-groupbees`](https://github.com/groupbees/skills-core/blob/main/skills/git/commit-groupbees/SKILL.md)
