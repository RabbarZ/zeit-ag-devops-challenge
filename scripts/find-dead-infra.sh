#!/usr/bin/env bash
# Read-only report of Terraform code that nothing uses (C3). Run from the repository root:
#   bash scripts/find-dead-infra.sh
# Exit code 0: nothing found. Exit code 1: something to review. It never calls Terraform or Azure:
# whether *state* still holds a resource is a separate check (see SOLUTION.md, C3).
set -uo pipefail
cd "$(dirname "$0")/.."
found=0
report() { echo "  $1"; found=1; }

echo "Modules that no module block uses as its source:"
for dir in infra/modules/*/; do
  name=$(basename "$dir")
  # Callers use relative paths such as ../postgres or ../../modules/vm.
  grep -rqsE --include='*.tf' "source\s*=\s*\"[./]*(modules/)?${name}\"" infra || report "$dir"
done

echo "Import blocks (remove once the import has been applied):"
while IFS= read -r line; do report "$line"; done < <(grep -rnE --include='*.tf' '^\s*import\s*\{' infra)

echo "Variables that no expression in their own directory reads:"
for dir in infra/environments/*/ infra/modules/*/; do
  for var in $(grep -hoE '^variable "[A-Za-z0-9_]+"' "$dir"*.tf | cut -d'"' -f2); do
    grep -qsE "var\.${var}\b" "$dir"*.tf || report "${dir}variables.tf: ${var}"
  done
done

[ "$found" -eq 0 ] && echo "Nothing found."
exit "$found"
