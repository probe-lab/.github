#!/usr/bin/env bash
# Lints the workflows with actionlint.
# Downloads actionlint into a cache directory when it is not on the PATH.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

actionlint_version=1.7.12

if ! command -v actionlint >/dev/null; then
  bin="${XDG_CACHE_HOME:-$HOME/.cache}/actionlint/$actionlint_version"
  if [[ ! -x "$bin/actionlint" ]]; then
    echo "Downloading actionlint $actionlint_version to $bin"
    mkdir -p "$bin"
    bash <(curl -sSfL "https://raw.githubusercontent.com/rhysd/actionlint/v$actionlint_version/scripts/download-actionlint.bash") "$actionlint_version" "$bin"
  fi
  export PATH="$bin:$PATH"
fi

actionlint -color .github/workflows/*.yml

