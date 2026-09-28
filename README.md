# 🐝 skills-gitlab

> GitLab and GitLab CI/CD conventions for client engagements hosted on GitLab — the `skills-gitlab` module of the GroupBees skills catalog.

## 🎯 Purpose

This repo is the source of truth for its skills — **one module** alongside
`skills-core` (transverse) and the others. Each skill is a standard **Agent
Skill** (`SKILL.md`, the [agentskills.io](https://agentskills.io) open standard),
read natively by **Claude Code**, **GitHub Copilot** and **Cursor**.

## 🚀 Usage

Install with [skillmgr](https://github.com/groupbees/skillmgr): add this module
to your project's `skillmgr.yaml`, pinned to a release, then `skillmgr update`.

```yaml
repos:
  - repo: https://github.com/groupbees/skills-gitlab
    revision: vX.Y.Z
    paths:
      - path: skills
        recurse: true
```

It deploys into `.claude/skills/` (Claude Code) and `.agents/skills/` (Copilot,
Cursor, Codex…). Skill names must be **unique across modules**. See
[AGENTS.md](AGENTS.md).

## 📋 Skills Catalog

<!-- BEGIN skills-table — auto-generated from skills/*/*/SKILL.md by scripts/skills-catalog.sh --readme; do not edit by hand -->
| Domain | Skill | Description |
|--------|-------|-------------|
| CI/CD | [gitlab-ci-shared-components](skills/cicd/gitlab-ci-shared-components/) | Builds a repository's .gitlab-ci.yml on top of shared GitLab CI/CD catalog components (include component with inputs) instead of hand-written jobs — how to read a component's real inputs, and a worked Python uv + Docker setup (test/dev dependency groups, ruff format check, pre-commit, kaniko-compatible Dockerfile, Docker Hub mirror build arg, nightly image per branch promoted on vX.Y.Z tags, SonarCloud auto mode). Trigger when creating or fixing .gitlab-ci.yml in a GitLab repo that uses a shared CI catalog, or when a shared-component job fails (missing dependency group, pre-commit config, sonar properties, kaniko error). |
| Git | [gitlab-commit](skills/git/gitlab-commit/) | Commit message conventions for repositories hosted on GitLab (client engagements on gitlab.com or a self-hosted GitLab) — Conventional Commits with an optional ticket key prefix, no AI attribution, and how to squash local commits before pushing. Trigger when committing, rewording or squashing commits in a repo whose remote is a GitLab host. Do NOT trigger for github.com/groupbees repos (commit-groupbees) or personal open-source repos (commit-open-source). |
| Git | [gitlab-mr](skills/git/gitlab-mr/) | Creates and updates GitLab merge requests — title, structured description, labels, draft state — through git push options over SSH (no token), glab, or the REST API, and explains what happens to approvals, labels and pipelines when the branch changes. Trigger when opening, pushing to, force-pushing, retitling or labelling a merge request in a GitLab-hosted repo. Do NOT trigger for GitHub pull requests (pr-groupbees). |
| Git | [gitlab-release](skills/git/gitlab-release/) | Cuts a release of a GitLab-hosted repository — computes the next SemVer from the Conventional Commits since the last tag, creates the annotated vX.Y.Z tag on main, writes the release notes and attaches them as a GitLab Release, then checks the tag pipeline (image promotion, package publish). Trigger when tagging, releasing or publishing a version of a repo whose remote is a GitLab host. Do NOT trigger for github.com/groupbees repos (tag-groupbees) or public packages (tag-opensource). |
<!-- END skills-table -->

> Generated from the skills' `description` fields: `scripts/skills-catalog.sh --readme`.

## ✅ CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml): `skill-validator check
--strict`, `skillmgr validate`, the generated README table, and
`shellcheck scripts/*.sh`.

## 🏷️ Versioning

Repo-wide git tags (`vX.Y.Z`) cut with `tag-groupbees`; the GitHub Releases page
is the changelog.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
