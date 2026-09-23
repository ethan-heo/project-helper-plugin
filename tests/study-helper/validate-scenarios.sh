#!/usr/bin/env bash
set -euo pipefail

scenario_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/scenarios" && pwd)}"
errors=0

fail() {
  printf '오류: %s\n' "$1" >&2
  errors=$((errors + 1))
}

count="$(find "$scenario_root" -maxdepth 1 -type f -name '[0-9][0-9]-*.md' | wc -l | tr -d '[:space:]')"
[[ "$count" -eq 10 ]] || fail "시나리오는 10개여야 합니다: $count개"

expected=1
while IFS= read -r scenario; do
  number="$(basename "$scenario" | cut -d- -f1)"
  expected_number="$(printf '%02d' "$expected")"
  [[ "$number" == "$expected_number" ]] || fail "시나리오 번호가 연속되지 않습니다: $scenario"

  for section in '연결 구현 항목' '입력' '기대 대화와 상태' '기록 변화' '금지 동작'; do
    grep -q "^## $section$" "$scenario" || fail "필수 절이 없습니다: $(basename "$scenario") / $section"
  done

  grep -qE '`[A-Z]+-[A-Z]+-[0-9]{3}`' "$scenario" || fail "구현 항목 ID가 없습니다: $(basename "$scenario")"
  expected=$((expected + 1))
done < <(find "$scenario_root" -maxdepth 1 -type f -name '[0-9][0-9]-*.md' | sort)

number_value=1
while [[ "$number_value" -le 10 ]]; do
  number="$(printf '%02d' "$number_value")"
  grep -q "| $number |" "$scenario_root/README.md" || fail "색인에 번호가 없습니다: $number"
  number_value=$((number_value + 1))
done

((errors == 0)) || exit 1
printf 'study-helper 시나리오 검사 통과: %s\n' "$scenario_root"
