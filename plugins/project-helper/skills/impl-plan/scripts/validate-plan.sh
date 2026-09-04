#!/usr/bin/env bash
set -euo pipefail

plan_file="${1:?사용법: validate-plan.sh <기능 계획서> }"
domain_dir="$(dirname "$plan_file")"
plan_root="$(dirname "$domain_dir")"
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

[[ "$(basename "$plan_file")" != README.md ]] || fail 'README.md는 기능 계획서가 아닙니다.'
[[ -f "$plan_root/README.md" ]] || fail '최상위 README.md가 없습니다.'
[[ -f "$domain_dir/README.md" ]] || fail '도메인 README.md가 없습니다.'
[[ "$(dirname "$domain_dir")" == "$plan_root" ]] || fail '기능 계획서가 도메인 바로 아래에 있지 않습니다.'
child_dirs="$(find "$domain_dir" -mindepth 1 -maxdepth 1 -type d -print)"
[[ -z "$child_dirs" ]] || fail '기능 계획서 아래에 잘못된 하위 디렉터리가 있습니다.'
grep -qE '^\| 단계 \| 계획 완료 \|' "$plan_file" || fail '계획 완료 상태가 아닙니다.'
! grep -qE '<!-- 사용자 검토 필요 -->' "$plan_file" || fail '사용자 검토 표시가 남아 있습니다.'
grep -qE '^\| 구현 진행률 \| [0-9]+ / [0-9]+ \|' "$plan_file" || fail '구현 진행률 형식이 잘못되었습니다.'
grep -qE '^(- |[0-9]+\. )\[[ x]\] \*\*[A-Z0-9]+-[A-Z0-9]+-[0-9]{3}\*\* ' "$plan_file" || fail '구현 항목 형식이 잘못되었습니다.'
check_criteria "$plan_file"

(( errors == 0 )) || exit 1
printf '구현 전 계획서 검증 통과: %s\n' "$plan_file"
