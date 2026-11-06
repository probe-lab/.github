#!/usr/bin/env bash
# Lints the shared workflows and the workflow templates with actionlint.
# Needs actionlint on the PATH.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v actionlint >/dev/null; then
  echo "actionlint not found on the PATH" >&2
  exit 1
fi

actionlint -color .github/workflows/*.yml

# Lints the templates as a repo holds them: in .github/workflows, with the
# Deploy template saved as deploy.yml, and calling the shared workflows of
# this commit, so a wrong input name fails here.
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/.github/workflows"
cp .github/workflows/{image,deploy-ecs,release}.yml "$dir/.github/workflows/"
for f in workflow-templates/*.yml; do
  sed 's#probe-lab/.github/.github/workflows/\(.*\)\.yml@v2#./.github/workflows/\1.yml#' "$f" \
    > "$dir/.github/workflows/template-$(basename "$f")"
done
cp "$dir/.github/workflows/template-service-deploy.yml" "$dir/.github/workflows/deploy.yml"
git -C "$dir" init -q
cd "$dir"
actionlint -color .github/workflows/template-*.yml .github/workflows/deploy.yml
