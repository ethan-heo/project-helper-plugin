#!/usr/bin/env bash
set -euo pipefail

prd="${1:?사용법: validate-prd.sh <PRD 파일> }"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }

[[ -f "$prd" ]] || { printf '오류: %s 파일이 없습니다.\n' "$prd" >&2; exit 1; }

sections=(
  '한 줄 요약'
  '배경과 문제'
  '목적과 목표'
  '사용자와 사용 상황'
  '요구사항'
  '범위 밖'
  '제약과 전제'
  '미해결 질문'
)

for section in "${sections[@]}"; do
  grep -qxF "## $section" "$prd" || fail "'$section' 절이 없습니다."
done

grep -q '<!-- 사용자 검토 필요 -->' "$prd" && fail '사용자 검토 표시가 남아 있습니다.'

grep -qE '^\| R[0-9]+ \| (필수|선택) \|' "$prd" || fail '요구사항 항목이 필수 또는 선택으로 표시되어 있지 않습니다.'

unresolved="$(sed -n '/^## 미해결 질문$/,$p' "$prd" | grep -E '^\| .+ \| .+ \| .+ \|$' | grep -vcE '^\| *-+ *\|' || true)"
if (( unresolved > 1 )); then
  fail "미해결 질문이 $((unresolved - 1))건 남아 있습니다."
fi

(( errors == 0 )) || exit 1
printf 'PRD 검증 통과: %s\n' "$prd"
