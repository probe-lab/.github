# .github

ProbeLab repository. Follow the `probelab` skill: it holds the company rules. Load it before you start any task here.

Org-level repo of `probe-lab`. It holds the shared reusable workflows that ProbeLab repos call at `@v2`, the workflow templates, and the default community health files (security policy, pull request template, org profile).

## Layout

- `.github/workflows/` — shared workflows (`image.yml`, `deploy-ecs.yml`, `release.yml`) and this repo's own `ci.yml`
- `workflow-templates/` — starter workflows offered under Actions, New workflow
- `scripts/` — `lint.sh`, which `just lint` and CI run
- `tests/image/` — the small Dockerfile that CI builds with `image.yml`
- `profile/` — public org page
- `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `CODEOWNERS` — org defaults
- `CHANGELOG.md` — changes to the shared workflows, by version

## Commands

- `just lint` runs `scripts/lint.sh`: actionlint on the workflows and on the templates (downloads `actionlint` into `~/.cache/actionlint` if it is not on the PATH); `just ci` runs the checks. CI runs `just lint` too.
- CI also builds an image with `image.yml`. `deploy-ecs.yml` and `release.yml` need AWS, so only actionlint checks them.

## Conventions

- Callers pin `@v2`. Do not rename or remove an input or output, or change behavior, in a way that breaks a caller: that is a new major version.
- Do not move or retag `v2` as part of a normal change. The README, "Change this repo", has the release steps.
- Write changes under a new `## [X.Y.Z]` section in `CHANGELOG.md`.
- Shared workflows hold production credentials or a naming contract only. A need of one repo goes in that repo's `ci.yml` or `justfile`, not in an input here.
- A workflow that starts to use a new command-line tool adds it to "Runner tools" in the README.
- A change to a template goes with the matching change in the README examples.
- Change `PULL_REQUEST_TEMPLATE.md` together with the template in the `probelab-git` skill.

## Related repositories

- Every ProbeLab repo calls these workflows.
- ai-commons — holds the `probelab-*` skills that describe the standards these workflows implement.

## Owner

@probe-lab/probelab-core
