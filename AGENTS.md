# .github

ProbeLab repository. Follow the `probelab` skill: it holds the company rules. Load it before you start any task here.

Org-level repo of `probe-lab`. It holds the shared reusable workflows that ProbeLab repos call at `@main`, the workflow templates, and the default community health files (security policy, pull request template, org profile).

## Layout

- `.github/workflows/` — shared workflows (`image.yml`, `deploy-ecs.yml`, `release.yml`) and this repo's own `ci.yml`
- `workflow-templates/` — starter workflows offered under Actions, New workflow
- `scripts/` — `lint.sh`, which `just lint` and CI run
- `tests/image/` — a small Dockerfile; CI no longer builds it
- `profile/` — public org page
- `PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `CODEOWNERS` — org defaults
- `CHANGELOG.md` — changes to the shared workflows, by version

## Commands

- `just lint` runs `scripts/lint.sh`: actionlint on the workflows and on the templates (downloads `actionlint` into `~/.cache/actionlint` if it is not on the PATH); `just ci` runs the same checks as CI.
- The shared workflows need AWS, so only actionlint checks them.

## Conventions

- Callers use `@main`, so a merge reaches every caller at once. A change that breaks a caller, such as a renamed or removed input or output, updates the callers too.
- Write changes in `CHANGELOG.md`, under the date of the merge.
- Shared workflows hold production credentials or a naming contract only. A need of one repo goes in that repo's `ci.yml` or `justfile`, not in an input here.
- A workflow that starts to use a new command-line tool adds it to "Runner tools" in the README.
- A change to a template goes with the matching change in the README examples.
- Change `PULL_REQUEST_TEMPLATE.md` together with the template in the `probelab-git` skill.

## Related repositories

- Every ProbeLab repo calls these workflows.
- ai-commons — holds the `probelab-*` skills that describe the standards these workflows implement.

## Owner

@probe-lab/probelab-core
