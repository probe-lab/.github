# ProbeLab's shared GitHub files

This repo holds the GitHub Actions workflows that ProbeLab repos share, and
the default files for repos that have none of their own. The templates for a
repo's workflows are in the `probelab-github-actions` skill of
[probe-lab/ai-commons](https://github.com/probe-lab/ai-commons).

In short: a pull request runs `just lint`, `just build` and `just test`, a
merge builds one image, and a merge deploys that image when its pull request
has the label `deploy`. A person deploys any commit with one click.

## What is shared, and what is not

A workflow is shared only when it holds production credentials or sets a
naming contract that all repos must follow. The steps of a check are not
shared: every repo spells them out from a template, because a check is
setup steps and `just` recipes. The special needs of one repo, such as a
ClickHouse container for the tests, belong in that repo's own `ci.yml`.

| Path | What it is |
| --- | --- |
| `.github/workflows/image.yml` | Builds a Docker image, and pushes it to ECR as `<service>-sha<commit>` when asked. |
| `.github/workflows/deploy-ecs.yml` | Deploys the image of one commit to one ECS service. |
| `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md` | Defaults for every org repo that has no file of its own. |
| `profile/README.md` | The public page of the org. |
| `.github/workflows/ci.yml`, `tests/` | The CI of this repo. |

Each shared workflow lists all of its inputs at the top of its file.

## The files of a repo

| File | Content |
| --- | --- |
| `ci.yml` | The `check` job. A service adds the `image` job. A service that deploys adds the `deploy` job and the Deploy button (`workflow_dispatch`). |
| `.github/dependabot.yml` | Keeps the action versions of the repo current. |

Start from the templates in the `probelab-github-actions` skill of ai-commons:
`go-library-ci`, `go-service-ci` and `python-service-ci`.

### The `check` job

The job checks out the code, sets up the language and `just`, and runs
`just lint`, `just build` and `just test` as 3 steps. The pinned versions of
tools such as `gofumpt` or `staticcheck`
live in the `justfile`, for example `go run mvdan.cc/gofumpt@v0.12.0 -l .`,
so a person and CI run the same thing.

A repo adds what only it needs to its own job:

- A service container: nebula starts ClickHouse and priv-hermes starts
  LocalStack, and the tests read the mapped port from the environment.
- `lfs: true` on the checkout: atlas keeps database backups in Git LFS.
- A step that only this repo has.

When `just test` starts its own services on a laptop, the repo adds a
`test-plain` recipe that expects the services, and the test step runs
`just test-plain`.

### A service image

```yaml
  image:
    name: Container Image
    needs: check
    if: github.event.pull_request.draft != true && !failure() && !cancelled()
    permissions:
      contents: read
      id-token: write
      pull-requests: read
    uses: probe-lab/.github/.github/workflows/image.yml@main
    with:
      service: boomo
      commit: ${{ inputs.commit }}
```

The other inputs are `dockerfile`, `build-args`, `platforms` and `lfs`, which
downloads the Git LFS files for a Dockerfile that copies them (atlas). The build
context is the repo root.

Several images from one repo use a matrix. data-platform builds one image for
each Dagster component with `dockerfile: Dockerfile.${{ matrix.component }}`.
api builds 5 services from one Dockerfile with `build-args: SERVICE=<name>`
and the tag `<name>service`.

### The Deploy workflow

`deploy-ecs.yml` always deploys; the caller decides when to call it. The
`deploy` job of `ci.yml` has this rule:

| Run | Deploys? |
| --- | --- |
| A pull request | Never. |
| A merge | When its pull request has the label `deploy`. `image.yml` looks it up and sets its output `deploy`. |
| A person, from the Actions tab | When the flag `deploy` is set. The label does not matter. |

Otherwise the `deploy` job is skipped, and the run shows it as skipped. No job
of its own looks up the label: `image.yml` does it in a step, because a job
`if` cannot see a pull request label on a `push` event. The workflow stops if
the commit is not on the default branch, or if the image of the commit is not
in ECR. It never waits for an image: after a merge, the `deploy` job starts
only when the `image` job of the same run has pushed it. To roll back, deploy
an older commit by hand.

The `deploy` job of the service templates also runs after a skipped `check`
job (the `skip-checks` flag): its `if` has `!cancelled()` and
`needs.image.result == 'success'`.

Inputs of
`deploy-ecs.yml`: `service`, `commit`, `cluster`, `ecs-service`,
`task-definition`, `container`, `container-env` (environment variables for
the container, one `KEY=VALUE` per line) and `task-definition-only` (registers
a task definition without a service deploy). The workflow takes no secrets.
Create the label `deploy` (Issues, Labels, New label) in each service repo.
The workflow uses no GitHub environment, because the free plan has none for
private repos.

A repo with several services calls `deploy-ecs.yml` once for each, with a
`strategy.matrix` or with separate jobs. A step that only one repo needs, such
as the atlas upload of static files and the Cloudflare purge, is a job in that
repo's `ci.yml` before or after the `deploy` job.

## Runners

Checks and image builds run on the runner that the org variable `RUNNER_LABEL`
names, and on `ubuntu-latest` when the variable is empty. `RUNNER_LABEL` is
`probelab-ci`, and only private repos can read it. A public repo gets an empty
value and runs on GitHub-hosted runners, because public repos must not use the
self-hosted runners.

Deploys run on the runner of `RUNNER_LABEL` too, because a deploy
waits for the service and would burn hosted minutes. The runner needs `gh` and
`jq`.

### Runner tools

A GitHub-hosted runner has these tools. The self-hosted runner `probelab-ci`
has only what someone installed on it. Setup actions install Go, uv, just and
the Docker Buildx plugin themselves, so they are not in the list. A workflow
does not check its tools: a missing one fails the step that uses it. Install
the tools of this table when you set up a runner.

| Tool | Needed by | Why |
| --- | --- | --- |
| `git` | every workflow | The checkout. |
| `git-lfs` | `image.yml` with `lfs`, repo checks with `lfs: true` | Downloads the Git LFS files. |
| `docker` | `image.yml`, repo checks that build images | Builds the image and logs in to ECR. |
| `aws` (CLI v2) | `image.yml`, `deploy-ecs.yml` | Looks for the image in ECR, and reads the task definition. |
| `gh` | `image.yml`, `deploy-ecs.yml` | Finds the merged pull request of a push, and the commit on the default branch. |
| `jq` | `image.yml`, `deploy-ecs.yml` | Reads the answers of `gh` and `aws`. |

When a workflow starts to use a new tool, add it to this table and install it
on the runner.

To move every check to GitHub-hosted runners, for example when the
self-hosted machine is down, delete the org variable `RUNNER_LABEL`.

## Set up the org, once

1. Create the org variable `RUNNER_LABEL` with the value `probelab-ci` and
   the repository access "Private repositories".
2. In each service repo, create the label `deploy`.
3. Narrow the AWS trust in probelab-infra (`tf/oidc.tf`).
4. Optional: when the plan allows it, add the check jobs of a repo to the
   required checks of its ruleset. No workflow here depends on a check name.

## Development

`just` lists the recipes. `just lint` runs actionlint on the workflows
(`scripts/lint.sh`) and downloads `actionlint` if it is not on the PATH. `just ci`
runs the same checks as CI.

## Change this repo

1. Open a pull request. Its CI lints every workflow.
2. The shared workflows need AWS, so CI only lints them. Before the
   merge, try a change in one repo with `@<your branch>` instead of `@main`.
3. Write the changes in `CHANGELOG.md`, under the date of the merge.
4. Callers use `@main`, so a merge reaches every caller at once. A change that
   breaks a caller, such as a renamed or removed input, updates the callers
   too.
5. Before you add an input, ask if the repo could do it in its own `ci.yml` or
   `justfile`. An input is only for a generic idea, such as a build argument or
   an ECS container variable, never for the tooling of one repo.
