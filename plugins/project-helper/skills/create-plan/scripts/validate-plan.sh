#!/usr/bin/env bash
set -euo pipefail

plan_root="${1:?사용법: validate-plan.sh <계획 디렉터리> }"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }

[[ -f "$plan_root/README.md" ]] || fail '최상위 README.md가 없습니다.'
domains="$(find "$plan_root" -mindepth 1 -maxdepth 1 -type d)"
[[ -n "$domains" ]] || fail '도메인 디렉터리가 없습니다.'

for domain in $domains; do
  [[ -f "$domain/README.md" ]] || fail "$domain/README.md가 없습니다."
  while IFS= read -r plan; do
    [[ "$plan" == */README.md ]] && continue
    if rg -q '<!-- 사용자 검토 필요 -->' "$plan"; then fail "$plan에 사용자 검토 표시가 남아 있습니다."; fi
    rg -q '^\| 단계 \| (초안 작성|계획 완료|완료) \|' "$plan" || fail "$plan의 단계가 허용된 값이 아닙니다."
    rg -q '^\| 구현 진행률 \| [0-9]+ / [0-9]+ \|' "$plan" || fail "$plan의 구현 진행률 형식이 잘못되었습니다."
    rg -q '^(- |[0-9]+\. )\[[ x]\] \*\*[A-Z0-9]+-[A-Z0-9]+-[0-9]{3}\*\* ' "$plan" || fail "$plan에 올바른 구현 항목이 없습니다."
  done < <(find "$domain" -maxdepth 1 -type f -name '*.md')
done

(( errors == 0 )) || exit 1
printf '계획서 검증 통과: %s\n' "$plan_root"
