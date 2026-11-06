# .github

ProbeLab repository. Follow the `probelab` skill: it holds the company rules. Load it before you start any task here.

Org-level repo of `probe-lab`. It holds the shared reusable workflows that every ProbeLab repo calls at `@v1`, the workflow templates, and the default community health files (security policy, pull request template, org profile).

## Layout

- `.github/workflows/` — shared workflows (`go.yml`, `python.yml`, `image.yml`, `deploy-ecs.yml`, `release.yml`, `terraform.yml`) and this repo's own `ci.yml`
- `workflow-templates/` — starter workflows offered under Actions, New workflow
- `tests/go/`, `tests/python/` — small fixture projects that CI runs the shared workflows against
- `profile/` — public org page
- `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `CODEOWNERS` — org defaults
- `CHANGELOG.md` — changes to the shared workflows, by version

## Commands

- `just lint` runs actionlint on the workflows (needs `actionlint` on the PATH); `just ci` runs the checks.
- CI also lints the templates and runs the shared workflows against `tests/`. `deploy-ecs.yml`, `release.yml` and `terraform.yml` need AWS, so only actionlint checks them.

## Conventions

- Callers pin `@v1`. Do not rename or remove an input or output, or change behavior, in a way that breaks a caller: that is a new major version.
- Do not move or retag `v1` as part of a normal change. The README, "Change this repo", has the release steps.
- Write changes under a new `## [X.Y.Z]` section in `CHANGELOG.md`.
- A change to a template goes with the matching change in the README examples.
- Change `PULL_REQUEST_TEMPLATE.md` together with the template in the `probelab-git` skill.

## Related repositories

- Every ProbeLab repo calls these workflows.
- ai-commons — holds the `probelab-*` skills that describe the standards these workflows implement.

## Owner

@probe-lab/probelab-core
