# ProbeLab's shared GitHub files

This repo holds the GitHub Actions workflows that ProbeLab repos share, the
templates for new workflows, and the default files for repos that have none
of their own.

In short: a pull request runs `just ci`, a merge builds one image, and a
person deploys that image with one click. A merge deploys only when its pull
request has the label `deploy`.

## What is shared, and what is not

A workflow is shared only when it holds production credentials or sets a
naming contract that all repos must follow. The steps of a check are not
shared: every repo spells them out from a template, because a check is
`setup`, `just`, and `just ci`. The special needs of one repo, such as a
ClickHouse container for the tests, belong in that repo's own `ci.yml`.

| Path | What it is |
| --- | --- |
| `.github/workflows/image.yml` | Builds a Docker image, and pushes it to ECR as `<service>-sha<commit>` when asked. |
| `.github/workflows/deploy-ecs.yml` | Deploys the image of one commit to one ECS service. |
| `.github/workflows/release.yml` | Publishes a version tag: the GitHub release with the notes from `CHANGELOG.md`, goreleaser binaries when the repo has a `.goreleaser.yaml`, and an optional ECR image. |
| `workflow-templates/` | Starter files that every org repo offers under Actions, New workflow. |
| `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md` | Defaults for every org repo that has no file of its own. |
| `profile/README.md` | The public page of the org. |
| `.github/workflows/ci.yml`, `tests/` | The CI of this repo. |

Each shared workflow lists all of its inputs at the top of its file.

## The files of a repo

| File | Content |
| --- | --- |
| `ci.yml` | The `check` job, and the `image` job for a service. |
| `deploy.yml` | Only in a service that deploys. The Deploy button, and the deploy after a merge. |
| `release.yml` | Only in a repo with releases. |
| `.github/dependabot.yml` | Keeps the action versions of the repo current. |

Start from the templates: in the repo, open Actions, then New workflow, and
pick a ProbeLab template. The templates are `go-library-ci`,
`go-service-ci`, `python-service-ci`, `service-deploy` and `release`.

### The `check` job

The job checks out the code, sets up the language, `just`, and runs
`just ci`. The pinned versions of tools such as `gofumpt` or `golangci-lint`
live in the `justfile`, for example `go run mvdan.cc/gofumpt@v0.12.0 -l .`,
so a person and CI run the same thing.

A repo adds what only it needs to its own job:

- A service container: nebula starts ClickHouse and priv-hermes starts
  LocalStack, and the tests read the mapped port from the environment.
- `lfs: true` on the checkout: atlas keeps database backups in Git LFS.
- A step that only this repo has, such as the release build of nebula.

When `just test` starts its own services on a laptop, the repo adds a
`test-plain` recipe that expects the services, and CI runs
`just lint test-plain`.

### A service image

```yaml
  image:
    needs: check
    permissions:
      contents: read
      id-token: write
    uses: probe-lab/.github/.github/workflows/image.yml@v2
    with:
      service: boomo
      push: ${{ github.event_name == 'push' }}
```

The other inputs are `dockerfile`, `build-args` and `platforms`. The build
context is the repo root.

Several images from one repo use a matrix. data-platform builds one image for
each Dagster component with `dockerfile: Dockerfile.${{ matrix.component }}`.
api builds 5 services from one Dockerfile with `build-args: SERVICE=<name>`
and the tag `<name>service`.

### The Deploy workflow

`deploy.yml` starts in 2 ways:

| Start | Check |
| --- | --- |
| A person, from the Actions tab or `gh workflow run deploy.yml -f commit=<commit>` | None. An empty commit means the newest on the default branch. |
| The `deploy` job of `ci.yml`, after the `image` job of a merge | The merged pull request must have the label `deploy`. |

Without the label, the deploy is skipped and GitHub shows no deployment. A
repo with no `deploy.yml` never deploys. The workflow stops if the commit is
not on the default branch, or if the image of the commit is not in ECR. It
never waits for an image: after a merge, the `deploy` job starts only when the
`image` job of the same run has pushed it. To roll back, deploy an older commit
by hand.

The template is `workflow-templates/service-deploy.yml`. Inputs of
`deploy-ecs.yml`: `service`, `commit`, `cluster`, `ecs-service`,
`task-definition`, `container`, `container-env` (environment variables for
the container, one `KEY=VALUE` per line) and `task-definition-only` (registers
a task definition without a service deploy). The workflow takes no secrets.
Create the label `deploy` (Issues, Labels, New label) and the environment
`production` (Settings, Environments) in each service repo.

A repo with several services calls `deploy-ecs.yml` once for each, with a
`strategy.matrix` or with separate jobs. A step that only one repo needs, such
as the atlas upload of static files and the Cloudflare purge, is a job in that
repo's `deploy.yml` before or after the call.

### A release

Write the changes under `## [1.2.3]` in `CHANGELOG.md`, merge them, wait for
CI, then push the tag `v1.2.3`. The template is `workflow-templates/release.yml`.
The release fails unless the tagged commit has a passing `Checking the code`, so the repo
does not run its checks again. The caller grants `contents: write`,
`checks: read` and, for an image, `id-token: write`.

| Repo | Inputs |
| --- | --- |
| go-commons | none: the notes only |
| nebula | `ecr-service: nebula` |
| priv-hermes | `ecr-service: hermes`, `platforms: linux/amd64` |

## Runners

Checks and image builds run on the runner that the org variable `RUNNER_LABEL`
names, and on `ubuntu-latest` when the variable is empty. `RUNNER_LABEL` is
`probelab-ci`, and only private repos can read it. A public repo gets an empty
value and runs on GitHub-hosted runners, because public repos must not use the
self-hosted runners.

Deploys and releases always run on GitHub-hosted runners, because
they hold strong credentials.

To move every check to GitHub-hosted runners, for example when the
self-hosted machine is down, delete the org variable `RUNNER_LABEL`.

## Set up the org, once

1. Merge this repo and tag the major version: `git tag v2.0.0 && git tag v2
   && git push origin v2.0.0 v2`.
2. Create the org variable `RUNNER_LABEL` with the value `probelab-ci` and
   the repository access "Private repositories".
3. In each service repo, create the environment `production` and the label
   `deploy`.
4. Narrow the AWS trust in probelab-infra (`tf/oidc.tf`).
5. After the first green run of a repo, add `Checking the code` to the
   required checks of the org ruleset. In a service repo, also add the image
   check. Copy its name from a finished run. Remove `ci-ok` from the ruleset.

## Development

`just` lists the recipes. `just lint` runs actionlint on the workflows and the
templates (`scripts/lint.sh`) and needs `actionlint` on the PATH. `just ci`
runs the checks that can run locally. CI also builds a small image with
`image.yml`.

## Change this repo

1. Open a pull request. Its CI lints every workflow and template, and builds
   the image in `tests/image/`.
2. `deploy-ecs.yml` and `release.yml` need AWS or a tag, so the CI only lints
   them. Before a release, try a change in one repo with `@<your branch>`
   instead of `@v2`.
3. Write the changes under a new `## [X.Y.Z]` section in `CHANGELOG.md`.
   After the merge, tag `vX.Y.Z` and move the major tag to it:
   `git tag -f v2 vX.Y.Z && git push -f origin vX.Y.Z v2`.
4. A change that breaks a caller, such as a renamed or removed input, is a new
   major version.
5. Before you add an input, ask if the repo could do it in its own `ci.yml` or
   `justfile`. An input is only for a generic idea, such as a build argument or
   an ECS container variable, never for the tooling of one repo.
