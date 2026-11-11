# Changelog

All notable changes to the shared workflows are listed here. Repos call the
workflows at `@main`, so a change reaches every caller when it merges.
Old callers keep `@v1`. Changes are listed under the date of the merge, in the
format of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 2026-11-11

### Fixed

- `image.yml`: a run that only builds, such as a pull request without the
  label `push-image`, no longer looks up the image in ECR. It has no AWS
  login, so on a runner without its own AWS credentials the lookup failed
  the job with `NoCredentials`. Such a run now always builds.

## 2026-11-10

The special cases of single repos move out of the shared workflows, and
callers move from `@v1` to `@main`. A caller of version 1 keeps working at
`@v1`.

### Removed

- `go.yml`, `python.yml`: a repo now spells out a `check` job that runs
  `just lint`, `just build` and `just test`, from the templates
  `go-service-ci`, `go-library-ci` and `python-service-ci`. Tool versions move into the repo's `justfile`.
- `terraform.yml`: no repo called it.
- `image.yml`: the inputs `runner`, `context`, `fetch-depth`, `aws-*`,
  `ecr-*`, `timeout-minutes` and the secret `GO_PRIVATE_TOKEN`. The runner is
  the `RUNNER_LABEL` variable, the build context is the repo root, and the
  checkout always has the full history.
- `deploy-ecs.yml`: the inputs `pr-label`, `smoke-url`, `environment`,
  `wait-minutes`, `image-wait-minutes`, `aws-*` and `ecr-*`, and the
  `SLACK_WEBHOOK_URL` secret with the Slack message after a deploy.
- The template `service-deploy`: the Deploy button is part of `ci.yml`.
- `workflow-templates/`: the templates are in the `probelab-github-actions`
  skill of probe-lab/ai-commons, so there is one copy.
- `release.yml`: releases come back, built from scratch, once CI works
  across all repos. A caller of `@v1` keeps its release workflow.

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
- The workflow templates call `@main`. In the service templates, the `deploy`
  job calls `deploy-ecs.yml` directly, and the Deploy button is a
  `workflow_dispatch` trigger of `ci.yml` with the inputs `commit`,
  `skip-checks` and `deploy`.
- The CI of this repo and the templates have no `ci-ok` job, and nothing
  depends on the name of a check job.

### Added

- `image.yml`: the `lfs` input, which downloads the Git LFS files of the
  checkout for a Dockerfile that copies them. The runner needs `git-lfs`.
- The README lists the tools that the self-hosted runner needs.
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
