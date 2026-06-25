#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for script in "${repo_root}"/bin/*; do
  bash -n "${script}"
done

echo "syntax ok"
