#!/usr/bin/env bash
set -euo pipefail

scenario_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/scenarios" && pwd)}"
errors=0

fail() {
  printf '오류: %s\n' "$1" >&2
  errors=$((errors + 1))
}

require_text() {
  local path="$1"
  local text="$2"
  grep -Fq -- "$text" "$path" || fail "필수 기대값이 없습니다: $(basename "$path") -> $text"
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

scenario_01="$scenario_root/01-single-runtime.md"
require_text "$scenario_01" '## 생성 결과'
require_text "$scenario_01" '## 초기 검증'
require_text "$scenario_01" 'src/create-counter.js'
require_text "$scenario_01" 'tests/provided/create-counter.test.js'
require_text "$scenario_01" 'tests/learner/create-counter.test.js'
require_text "$scenario_01" 'STUDY_NOT_IMPLEMENTED'

scenario_03="$scenario_root/03-install-script-approved.md"
require_text "$scenario_03" '## 생성 결과'
require_text "$scenario_03" '## 초기 검증'
require_text "$scenario_03" 'npm run measure'
require_text "$scenario_03" '수정 전 측정값'
require_text "$scenario_03" '원인이나 수정 코드를 시작 자료와 계획에 적지 않습니다.'

scenario_08="$scenario_root/08-completion-evidence.md"
require_text "$scenario_08" '## 완료 근거'
require_text "$scenario_08" '제공 테스트가 기준 커밋과 같은지 확인합니다.'
require_text "$scenario_08" '추가 테스트'
require_text "$scenario_08" '개념 설명'

((errors == 0)) || exit 1
printf 'study-helper 시나리오 검사 통과: %s\n' "$scenario_root"
