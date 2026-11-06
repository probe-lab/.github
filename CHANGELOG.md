# Changelog

All notable changes to the shared workflows are listed here. Repos pin a
major version such as `@v1`. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Removed

- `deploy-ecs.yml`: the `SLACK_WEBHOOK_URL` secret and the Slack message after
  a deploy. A caller that passes `SLACK_WEBHOOK_URL:` under `secrets:` now
  fails at startup. Remove that line. Callers with `secrets: inherit` are not
  affected.

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
