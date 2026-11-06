# ProbeLab's shared GitHub files

This repo holds the GitHub Actions workflows that every ProbeLab repo calls,
the templates for new workflows, and the default files for repos that have
none of their own. The plan behind it is the Notion page "ProbeLab CI,
release and deploy strategy".

In short: a pull request runs the checks, a merge builds one image, and a
person deploys that image with one click. A merge deploys only when its pull
request has the label `deploy`.

## What is here

| Path | What it is |
| --- | --- |
| `.github/workflows/go.yml` | Lints and tests a Go repo with its `just` recipes, with an optional ClickHouse and an optional goreleaser check. |
| `.github/workflows/python.yml` | Lints and tests a Python repo with `uv` and `just`, with an optional ClickHouse. |
| `.github/workflows/image.yml` | Builds a Docker image, and pushes it to ECR as `<service>-sha<commit>` when asked. |
| `.github/workflows/deploy-ecs.yml` | Deploys the image of one commit to one ECS service. Every Deploy button calls it. |
| `.github/workflows/release.yml` | Publishes a version tag: the GitHub release, and optional binaries and images. |
| `.github/workflows/terraform.yml` | Plans Terraform on a pull request, and applies it when a person starts it. |
| `workflow-templates/` | Starter files that every org repo offers under Actions, New workflow. |
| `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md` | Defaults for every org repo that has no file of its own. |
| `profile/README.md` | The public page of the org. |
| `.github/workflows/ci.yml`, `tests/` | The CI of this repo. |
| `.github/workflows/stale.yml`, `generated-pr.yml` | Housekeeping workflows from ipdx. |

Each workflow lists all of its inputs at the top of its file.

## Use it in a repo

Repos call the workflows with a major version, `@v1`. A service repo has 2
files: `ci.yml` checks every pull request and builds the image of every
merge, and `deploy.yml` is the Deploy button. `ci.yml` also calls
`deploy.yml` after a merge with the label `deploy`. Start from the templates: in
the repo, open Actions, then New workflow, and pick a ProbeLab template.

### A Go service

```yaml
jobs:
  go:
    uses: probe-lab/.github/.github/workflows/go.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}

  image:
    needs: go
    permissions:
      contents: read
      id-token: write
    uses: probe-lab/.github/.github/workflows/image.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      service: boomo
      push: ${{ github.event_name == 'push' }}
```

The whole file, with the `ci-ok` job that branch rules require, is
`workflow-templates/go-service-ci.yml`.

A repo whose `just lint` runs golangci-lint sets `golangci-lint` to the
version to install, for example `golangci-lint: v2.15`. Other tools come
from `go-tools`, which installs them with `go install`.

A repo with more needs sets more inputs. nebula needs gofumpt, a ClickHouse
with its own user, its own name for the port, and a check of the release
build:

```yaml
  go:
    uses: probe-lab/.github/.github/workflows/go.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      go-tools: mvdan.cc/gofumpt@v0.12.0
      clickhouse: true
      clickhouse-user: nebula_test
      clickhouse-password: password_test
      clickhouse-database: nebula_test
      test-command: NEBULA_TEST_CLICKHOUSE_PORT=$CLICKHOUSE_PORT just test-plain
      goreleaser-check: true
```

A repo that uses a private module, such as boomo with the api module, gives a
token to both workflows. `image.yml` passes it to the Docker build as the
secret `github_token`:

```yaml
  go:
    uses: probe-lab/.github/.github/workflows/go.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      goprivate: github.com/probe-lab/api
    secrets:
      GO_PRIVATE_TOKEN: ${{ secrets.REPO_PROBE_LAB_API_READ }}
```

In the Dockerfile, read the token only in the `RUN --mount=type=secret` step
that downloads the modules. Self-hosted runners keep the build cache, so a
token that a step writes to a file, such as a git config, stays on the
machine.

### A Python service

atlas keeps its database backups in Git LFS and has its own sync recipe:

```yaml
  python:
    uses: probe-lab/.github/.github/workflows/python.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      lfs: true
      sync-command: just sync
      lint-command: just lint && just format-check
```

### Several images in one repo

data-platform builds 3 images, one for each Dagster component:

```yaml
  image:
    needs: python
    strategy:
      matrix:
        component: [daemon, usercode, webserver]
    permissions:
      contents: read
      id-token: write
    uses: probe-lab/.github/.github/workflows/image.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      service: dagster-${{ matrix.component }}
      dockerfile: Dockerfile.${{ matrix.component }}
      push: ${{ github.event_name == 'push' }}
```

### Several services from one Dockerfile

api builds 5 services from one Dockerfile, and the build argument `SERVICE`
selects the service. The tags keep api's `<service>service` names, because
the nebula and ants-watch repos push `nebula-` and `ants-` tags to the same
ECR repository. Every merge builds all 5 images, so every service can deploy
every commit:

```yaml
  go:
    uses: probe-lab/.github/.github/workflows/go.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      golangci-lint: v2.15
      go-tools: github.com/bufbuild/buf/cmd/buf@v1.75.0
      test-command: just test && just test-integration

  image:
    needs: go
    strategy:
      matrix:
        service: [api, ants, geoip, nebula, probe]
    permissions:
      contents: read
      id-token: write
    uses: probe-lab/.github/.github/workflows/image.yml@v1
    with:
      runner: ${{ vars.RUNNER_LABEL }}
      service: ${{ matrix.service }}service
      build-args: SERVICE=${{ matrix.service }}
      push: ${{ github.event_name == 'push' }}
```

Its Deploy button asks for the service:

```yaml
on:
  workflow_dispatch:
    inputs:
      service:
        type: choice
        options: [api, ants, geoip, nebula, probe]
      commit:
        description: The commit to deploy. Empty means the newest on the default branch.
        type: string
        required: false

jobs:
  deploy:
    uses: probe-lab/.github/.github/workflows/deploy-ecs.yml@v1
    with:
      service: ${{ inputs.service }}service
      commit: ${{ inputs.commit }}
      cluster: prod-use1-web-ecs-cluster
      ecs-service: prod-use1-web-${{ inputs.service }}-service
      task-definition: prod-use1-web-${{ inputs.service }}-task
      container: prod-use1-web-${{ inputs.service }}
    secrets: inherit
```

### The Deploy button

`deploy.yml` deploys the newest commit on the default branch, or the commit
that the person names. It stops if the commit is not on the default branch.
If the image of the commit is not in ECR yet, because CI still builds it, the
deploy waits up to 10 minutes (`image-wait-minutes`) and then stops. So a
person can press Deploy right after a merge. The template is
`workflow-templates/service-deploy.yml`. A repo with several services uses a
matrix; each service gets its own rollout:

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        project: [celestia, agntcy]
    uses: probe-lab/.github/.github/workflows/deploy-ecs.yml@v1
    with:
      service: ants
      commit: ${{ inputs.commit }}
      cluster: prod-use1-cmi-ecs-cluster
      ecs-service: prod-use1-cmi-ants-${{ matrix.project }}-watch
      task-definition: prod-use1-cmi-ants-${{ matrix.project }}-watch-task
      container: prod-use1-cmi-ants-${{ matrix.project }}-watch
    secrets: inherit
```

Other inputs: `container-env` sets environment variables in the container,
`smoke-url` checks a URL after the deploy, and `task-definition-only`
registers a task definition without a service deploy. `SLACK_WEBHOOK_URL`
gets a message after every deploy, with a link to the commits it brings.

To deploy from a terminal, add this recipe to the repo's justfile:

```just
# deploys a commit, by default the newest on the default branch
deploy commit="":
    gh workflow run deploy.yml -f commit={{commit}}
```

To roll back, deploy an older commit.

### Deploy a merge with a label

To deploy a pull request as soon as it merges, add the label `deploy` to it
before the merge. After the merge, CI tests the commit and builds its image
as usual, then calls `deploy.yml` for that commit. A merge without the label
deploys nothing. In `ci.yml`:

```yaml
  deploy:
    needs: image
    if: github.event_name == 'push'
    permissions:
      contents: read
      id-token: write
      pull-requests: read
    uses: ./.github/workflows/deploy.yml
    with:
      commit: ${{ github.sha }}
      pr-label: deploy
    secrets: inherit
```

For this, `deploy.yml` also has a `workflow_call` trigger with the inputs
`commit` and `pr-label`, and grants `pull-requests: read`. It passes both to
`deploy-ecs.yml`, as the template does. `deploy-ecs.yml` checks the label in
a job of its own, so a merge without the label shows no deployment in
GitHub.

### A release

The template is `workflow-templates/release.yml`. It tests the tagged
commit, then calls `release.yml`. Write the changes under `## [1.2.3]` in
`CHANGELOG.md` before you push the tag `v1.2.3`.

| Repo | Inputs |
| --- | --- |
| go-commons | none: the notes only |
| nebula | `goreleaser: true`, `ecr-service: nebula` |
| eth-das-guardian | `goreleaser: true`, `dockerhub-repository: probelab/eth-das-guardian`, and the `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets |

### Terraform

No repo runs Terraform in CI. probelab-infra runs Terraform from a local
shell. A repo that plans on every pull request, and applies when a person
starts the workflow on `main`, calls `terraform.yml` like this:

```yaml
on:
  pull_request:
    paths: ["tf/**"]
  workflow_dispatch:

jobs:
  plan:
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    uses: probe-lab/.github/.github/workflows/terraform.yml@v1
    with:
      mode: plan
      aws-role: arn:aws:iam::<account-id>:role/<read-only-plan-role>
    secrets: inherit

  apply:
    if: github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      id-token: write
    uses: probe-lab/.github/.github/workflows/terraform.yml@v1
    with:
      mode: apply
      aws-role: arn:aws:iam::<account-id>:role/<apply-role>
    secrets: inherit
```

Every secret whose name starts with `TF_VAR_` becomes a Terraform variable.
The plan job runs the Terraform code of the pull request. Give it a read-only
role, and make sure that the trust policy of the apply role rejects pull
request runs.

## Runners

Checks and image builds run on the runner that the `runner` input names. The
templates pass `${{ vars.RUNNER_LABEL }}`. The org variable `RUNNER_LABEL` is
`probelab-ci`, and only private repos can read it. A public repo gets an empty
value and runs on GitHub-hosted runners, because public repos must not use the
self-hosted runners.

Deploys, releases and Terraform always run on GitHub-hosted runners, because
they hold strong credentials.

To move every check to GitHub-hosted runners, for example when the
self-hosted machine is down, delete the org variable `RUNNER_LABEL`.

## Set up the org, once

1. Merge this repo and tag the first version: `git tag v1.0.0 && git tag v1
   && git push origin v1.0.0 v1`.
2. Create the org variable `RUNNER_LABEL` with the value `probelab-ci` and
   the repository access "Private repositories".
3. In each service repo, create the environment `production` (Settings,
   Environments). Deploys run in it, and GitHub shows the live commit under
   Deployments on the repo page.
4. Narrow the AWS trust in probelab-infra (`tf/oidc.tf`), as the strategy's
   first phase says.

## Move a repo

1. Replace the repo's workflows with `ci.yml` and, for a service,
   `deploy.yml`. Delete the old files. For a service, also create the label
   `deploy` (Issues, Labels, New label).
2. atlas and data-platform: remove the deploy on merge. Steps that only one
   repo needs stay in that repo's own jobs, for example the atlas upload of
   static files and the Cloudflare purge around its deploy.
3. Tests that use ClickHouse: read `CLICKHOUSE_PORT` and the other variables,
   or map them in `test-command`, as nebula does above. The ports change on
   every run.
4. Image tags become `<service>-sha<commit>`. atlas (`atlas-<commit>`) and
   data-platform (`dagster-<component>-<commit>`) change their format. The
   first deploy after the move uses the new tag.
5. After the first green run, add `ci-ok` to the required checks of the org
   ruleset.

## Development

`just` lists the recipes. `just lint` runs actionlint on the workflows and
needs `actionlint` on the PATH. `just ci` runs the checks that can run
locally. The build, test and format recipes have nothing to do here: CI runs
the shared workflows against the projects in `tests/`.

## Change this repo

1. Open a pull request. Its CI lints every workflow and template, and runs
   `go.yml`, `python.yml` and `image.yml` against the projects in `tests/`.
2. `deploy-ecs.yml`, `release.yml` and `terraform.yml` need AWS, so the CI
   only lints them. Before a release, try a change to them in one repo with
   `@<your branch>` instead of `@v1`.
3. Write the changes under a new `## [X.Y.Z]` section in `CHANGELOG.md`.
   After the merge, tag `vX.Y.Z` and move `v1` to it: `git tag -f v1 vX.Y.Z && git push -f origin vX.Y.Z v1`.
4. A change that breaks a caller, such as a renamed or removed input, is a new
   major version, `v2`.
