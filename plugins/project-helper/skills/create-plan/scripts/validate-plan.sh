#!/usr/bin/env bash
set -euo pipefail

plan_root="${1:?사용법: validate-plan.sh <계획 디렉터리> }"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }

warn() { printf '경고: %s\n' "$1" >&2; }

# 구현 항목마다 완료 판정이 있는지 본다.
# 새 표기는 항목 아래 `- 완료 판정:` 줄이고, 옛 표기는 항목 줄 안에 이어 붙는다. 둘 다 통과시킨다.
check_criteria() {
  local plan="$1" missing
  missing="$(awk '
    /^(- |[0-9]+\. )\[[ x]\] \*\*[A-Z0-9]+-[A-Z0-9]+-[0-9][0-9][0-9]\*\* /{
      if (id != "" && !found) print id
      found = ($0 ~ /완료 판정:/)
      match($0, /[A-Z0-9]+-[A-Z0-9]+-[0-9][0-9][0-9]/)
      id = substr($0, RSTART, RLENGTH)
      next
    }
    /^[ \t]+- 완료 판정:/{ found = 1; next }
    /^#/{ if (id != "" && !found) print id; id = ""; found = 0 }
    END { if (id != "" && !found) print id }
  ' "$plan")"
  [[ -z "$missing" ]] || warn "${plan}의 항목에 완료 판정이 없습니다:$(printf ' %s' $missing)"
}

[[ -f "$plan_root/README.md" ]] || fail '최상위 README.md가 없습니다.'
domains="$(find "$plan_root" -mindepth 1 -maxdepth 1 -type d)"
[[ -n "$domains" ]] || fail '도메인 디렉터리가 없습니다.'

for domain in $domains; do
  [[ -f "$domain/README.md" ]] || fail "${domain}/README.md가 없습니다."
  while IFS= read -r plan; do
    [[ "$plan" == */README.md ]] && continue
    if grep -qE '<!-- 사용자 검토 필요 -->' "$plan"; then fail "${plan}에 사용자 검토 표시가 남아 있습니다."; fi
    grep -qE '^\| 단계 \| (초안 작성|계획 완료|완료) \|' "$plan" || fail "${plan}의 단계가 허용된 값이 아닙니다."
    grep -qE '^\| 구현 진행률 \| [0-9]+ / [0-9]+ \|' "$plan" || fail "${plan}의 구현 진행률 형식이 잘못되었습니다."
    grep -qE '^(- |[0-9]+\. )\[[ x]\] \*\*[A-Z0-9]+-[A-Z0-9]+-[0-9]{3}\*\* ' "$plan" || fail "${plan}에 올바른 구현 항목이 없습니다."
    check_criteria "$plan"
  done < <(find "$domain" -maxdepth 1 -type f -name '*.md')
done

(( errors == 0 )) || exit 1
printf '계획서 검증 통과: %s\n' "$plan_root"
