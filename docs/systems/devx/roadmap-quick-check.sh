#!/usr/bin/env bash
set -euo pipefail

BOARD="docs/implementation-roadmap.md"

echo "Checking In Progress cards for required fields and link validity..."

# Extract In Progress card blocks
awk '/^```roadmap-card/{flag=1;buf=""} flag{buf=buf$0"\n"} /```/{if(flag){print buf; flag=0}}' "$BOARD" \
| awk 'BEGIN{RS="\n\n"} /status:\s*In Progress/' \
| while IFS= read -r card; do
  echo "---"
  echo "$card" | sed -n 's/^id: \(.*\)$/Card id: \1/p'

  # Check docs/code links exist
  echo "$card" | sed -n 's/^\s*- \(docs\/.*\.md\)$/\1/p; s/^\s*- \(Pickleball.*\)$/\1/p; s/^\s*- \(SharedGameCore\/.*\)$/\1/p' \
  | while IFS= read -r path; do
    if [[ -z "$path" ]]; then continue; fi
    if [[ -f "$path" ]] || [[ -d "$path" ]]; then
      echo "OK: $path"
    else
      echo "MISSING: $path" >&2
      exit 1
    fi
  done

  # Check validation refs anchors resolve (heuristic: file exists and has Validation checklist heading)
  echo "$card" | sed -n 's/^\s*- \(docs\/[^#]*\)#.*$/\1/p' \
  | while IFS= read -r docfile; do
    [[ -z "$docfile" ]] && continue
    if ! grep -qi '^##\s\+Validation checklist' "$docfile"; then
      echo "ANCHOR CHECK FAILED: $docfile lacks a Validation checklist heading" >&2
      exit 1
    else
      echo "OK anchor: $docfile#validation-checklist"
    fi
  done

  # Ensure commands present
  if ! echo "$card" | grep -q '^\s\+- cd '; then
    echo "MISSING: links.commands for $BOARD card" >&2
    exit 1
  else
    echo "OK: links.commands present"
  fi
done

echo "Link and anchor checks passed."

# Optionally run fast tests (default ON). Set RUN_FAST_TESTS=0 to skip.
if [[ "${RUN_FAST_TESTS:-1}" -ne 0 ]]; then
  echo "Running fast tests (make test-all-fast)..."
  make test-all-fast
  echo "Fast tests passed."
else
  echo "Skipping fast tests (RUN_FAST_TESTS=0)."
fi

echo "All checks passed."

