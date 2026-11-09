# Changelog

All notable changes to the shared workflows are listed here. Repos pin a
major version such as `@v1`. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

Version 2 moves the special cases of single repos out of the shared
workflows. A caller of version 1 keeps working at `@v1`.

### Removed

- `go.yml`, `python.yml`: a repo now spells out a `check` job that runs
  `just ci`, from the templates `go-service-ci`, `go-library-ci` and
  `python-service-ci`. Tool versions move into the repo's `justfile`.
- `terraform.yml`: no repo called it.
- `image.yml`: the inputs `runner`, `context`, `fetch-depth`, `aws-*`,
  `ecr-*`, `timeout-minutes` and the secret `GO_PRIVATE_TOKEN`. The runner is
  the `RUNNER_LABEL` variable, the build context is the repo root, and the
  checkout always has the full history.
- `deploy-ecs.yml`: the inputs `pr-label`, `smoke-url`, `environment`,
  `wait-minutes`, `image-wait-minutes`, `aws-*` and `ecr-*`, and the
  `SLACK_WEBHOOK_URL` secret with the Slack message after a deploy.
- `release.yml`: the inputs `changelog`, `goreleaser`, `dockerfile`,
  `dockerhub-repository`, `aws-*` and `ecr-*`, and the Docker Hub secrets.

### Changed

- `deploy-ecs.yml`: runs on the `RUNNER_LABEL` runner when the repo has one,
  not always on `ubuntu-latest`. The runner needs `aws`, `gh` and `jq`.
- `deploy-ecs.yml`: one job, with no `environment`, which the free plan does
  not offer for private repos.
- `deploy-ecs.yml`: always deploys; it no longer checks the label. The workflow
  no longer waits for an image: the `deploy` job of `ci.yml` runs after the
  `image` job of the same run, on the merge commit.
- `image.yml`: on a push, a step looks up the merged pull request and sets the
  output `deploy` when it has the label `deploy`. The caller's `deploy` job
  uses it in its `if`, so an unlabeled merge shows the deploy as skipped
  without a job of its own for the lookup. The caller grants
  `pull-requests: read` to the image job, not to the deploy job.
- `release.yml`: fails unless the tagged commit has a passing check and no
  failed one, whatever the job is named. The caller grants `checks: read`. The workflow uses goreleaser when the repo
  has a `.goreleaser.yaml`, and always takes the notes from `CHANGELOG.md`.
- The workflow templates call `@v2`. The service templates have a `deploy`
  job, and `service-deploy` is the button and the target of that job.
- The CI of this repo and the templates have no `ci-ok` job, and nothing
  depends on the name of a check job.

### Added

- `image.yml` and `deploy-ecs.yml`: a first step on a self-hosted runner that
  fails with the names of missing tools. The README lists the runner tools.
- `image.yml`: pushes the image of a pull request that has the label
  `push-image`. The `push` input defaults to false and forces the push; without it
  the workflow pushes a merge, a manual run, or a pull request with that label. The
  service templates list `labeled` in their pull request types.
- `image.yml`: the `commit` input, to build a commit other than the one of
  the event. The Deploy button of a repo uses it.
- The template `python-service-ci`.

## [1.1.0]

### Added

- `deploy-ecs.yml`: the `pr-label` input. With it, the workflow deploys a
  commit only if its merged pull request has that label. The Go service
  templates use it: a merge with the label `deploy` deploys after CI.
- `deploy-ecs.yml`: the `image-wait-minutes` input, 10 by default. A deploy
  waits that long for the image of its commit while CI still builds it.
- This repo's CI lints the templates against the shared workflows of the same
  commit.

### Changed

- `deploy-ecs.yml`: a deploy can run 45 minutes instead of 30, because it can
  wait for the image.

## [1.0.0]

### Added

- The shared workflows `go.yml`, `python.yml`, `image.yml`,
  `deploy-ecs.yml`, `release.yml` and `terraform.yml`.
- Workflow templates for a Go service, a Deploy button, a Go library and a
  release.
- A default pull request template and security policy for the org's repos.
- CI for this repo: actionlint, and test runs of the shared workflows.
