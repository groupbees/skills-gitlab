---
name: gitlab-ci-shared-components
description: Builds a repository's .gitlab-ci.yml on top of shared GitLab CI/CD catalog components (include component with inputs) instead of hand-written jobs — how to read a component's real inputs, and a worked Python uv + Docker setup (test/dev dependency groups, ruff format check, pre-commit, kaniko-compatible Dockerfile, Docker Hub mirror build arg, nightly image per branch promoted on vX.Y.Z tags, SonarCloud auto mode). Trigger when creating or fixing .gitlab-ci.yml in a GitLab repo that uses a shared CI catalog, or when a shared-component job fails (missing dependency group, pre-commit config, sonar properties, kaniko error).
---

# Skill: GitLab CI with shared components

## Context

Platform teams publish reusable pipelines as **GitLab CI/CD components**; a
project's `.gitlab-ci.yml` is then a few `include: - component:` blocks with
inputs, not hundreds of lines of jobs. The work is less writing jobs than
**meeting what each component expects** of the repository — and those
expectations are only fully visible in the component's templates.

## Workflow

### 1. Find a sibling that already uses the components

Copy the include blocks from a repository of the same stack in the same group,
then adapt the inputs. It carries local knowledge (registry names, runner tags,
mirror variables) no documentation has.

### 2. Read the component's templates, not only its README

```bash
git clone --depth 1 git@<gitlab-host>:<group>/cicd-catalog/<component>.git
grep -n -A4 '^    [A-Z_]*:$' templates/pipeline.yml     # inputs, defaults, options
```

READMEs drift from templates. A real case: the README said SonarCloud was off
by default, the template turned it on — and the job failed on a file nobody
knew was required. Check each job's `script:` for the files and dependency
groups it assumes, and its `rules:` for when it runs.

### 3. Include with a pinned major version

```yaml
include:
  - component: $CI_SERVER_FQDN/<group>/cicd-catalog/python/pipeline@3
    inputs: { ... }
```

`@3` follows the component's major version; never `@main`.

### 4. Satisfy what the jobs assume, then run them locally

Replay each job's commands locally before pushing: the first pipeline should not
be where you learn the repository is missing a file.

## Worked example — Python (uv) + Docker

[`templates/gitlab-ci.python-uv-docker.yml`](templates/gitlab-ci.python-uv-docker.yml)
is a complete file. What each part required, from a real setup:

| Component job | Runs | Repository must provide |
|---------------|------|-------------------------|
| install | `uv sync --frozen --no-dev` | an up-to-date `uv.lock` |
| unit tests | `uv sync --group test`, `coverage run -m pytest --cov <APP_SRC_DIR>` | a **`test` dependency group** containing pytest, pytest-cov, coverage **and every runtime extra the tests import** — a group cannot pull a project extra |
| lint | `uv sync --group dev`, `ruff check` + **`ruff format --check`** on `APP_SRC_DIR` | a `dev` group with ruff; the code already formatted |
| pre-commit | `pre-commit run --all-files` | a **`.pre-commit-config.yaml`** (the job fails without one) and pre-commit in `dev` |
| SonarCloud | scanner | either `SONAR_AUTO: "optional"` (the component manages the project, key derived from the path, job non-blocking) or a `sonar-project.properties` |
| docker build | **kaniko**, destination `docker-nightly-<scope>/<project>/<image>:<short-sha>` | a Dockerfile kaniko can build |
| promote | on a `vX.Y.Z` tag, copies the nightly image to `docker-releases-<scope>` | nothing, but the tag must be on a commit whose image was built |

The dependency groups, so every job finds what it needs:

```toml
[dependency-groups]
test = ["pytest", "pytest-cov", "coverage", "responses",
        "fastapi", "google-auth"]            # the extras the tests import
dev = ["ruff", "pre-commit", { include-group = "test" }]
```

A `.pre-commit-config.yaml` with **local** hooks, so nothing is fetched at hook
time: [`templates/pre-commit-config.yaml`](templates/pre-commit-config.yaml).

Replay the jobs before the first push:

```bash
uv sync --no-dev --group test && uv run coverage run -m pytest --cov <pkg> tests
uv sync --all-extras && uv run ruff check <pkg> && uv run ruff format --check <pkg>
uv run pre-commit run --all-files
docker build .
```

## Dockerfile under kaniko

- **No `RUN --mount=type=cache`**: kaniko does not support it the way BuildKit
  does; drop the cache mounts (set `UV_NO_CACHE=1`).
- **Base images through the mirror build arg** the component passes
  (`BUILD_ARG_NAMES: "DOCKER_HUB_MIROR"` → `ARG DOCKER_HUB_MIROR=docker.io`,
  `FROM ${DOCKER_HUB_MIROR}/python:3.13-slim-bookworm`), so nothing pulls from
  Docker Hub directly.
- Registries with no mirror (`ghcr.io`) will not be reachable the same way:
  install tools like uv from PyPI (`pip install uv==<pinned>`) instead of
  `COPY --from=ghcr.io/astral-sh/uv`.
- Pin uv to the component's `UV_VERSION` so the lock reads the same in CI and in
  the image.

## Releasing what the pipeline built

Branch and `main` pipelines push `…:<short-sha>` (8 characters) to the nightly
registry: that tag can be tried in a dev environment before any release. A
`vX.Y.Z` tag promotes that same image to the release registry (see
`gitlab-release`); consumers pin the release tag, never a nightly one — nightly
tags are mutable.

## Conventions

- Pin component majors (`@3`), tool versions (uv, kaniko) and base images.
- Comment every non-default input with **why**, next to it.
- Never disable a check to get green (`allow_failure`, removing a job): make the
  repository meet it, or agree the exception with the component owners.
- No secret in `.gitlab-ci.yml`: CI/CD variables, masked and protected.
