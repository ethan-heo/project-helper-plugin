#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
plugin_root="$repo_root/plugins/study-helper"
fixtures="$repo_root/tests/study-helper/fixtures"

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    printf '실패해야 하는 명령이 통과했습니다: %s\n' "$*" >&2
    exit 1
  fi
}

"$plugin_root/scripts/validate-plugin.sh" "$plugin_root" >/dev/null
"$plugin_root/scripts/validate-record.sh" "$fixtures/records/valid.md" "$fixtures/ids/matching.study-id" >/dev/null
expect_failure "$plugin_root/scripts/validate-record.sh" "$fixtures/records/missing-key.md"
expect_failure "$plugin_root/scripts/validate-record.sh" "$fixtures/records/missing-section.md"
expect_failure "$plugin_root/scripts/validate-record.sh" "$fixtures/records/valid.md" "$fixtures/ids/mismatching.study-id"

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
cp -R "$plugin_root" "$test_root/source"
cp -R "$plugin_root" "$test_root/installed"
"$plugin_root/scripts/compare-install.sh" "$test_root/source" "$test_root/installed" >/dev/null
printf '\n변경\n' >> "$test_root/installed/references/learning-model.md"
expect_failure "$plugin_root/scripts/compare-install.sh" "$test_root/source" "$test_root/installed"
rm "$test_root/source/references/learning-model.md"
expect_failure "$plugin_root/scripts/validate-plugin.sh" "$test_root/source"

printf 'study-helper 정적 검사 자체 시험 통과\n'
