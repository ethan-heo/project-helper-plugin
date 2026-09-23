#!/usr/bin/env bash
set -euo pipefail

record="${1:?사용법: validate-record.sh <기록 파일> [study-id 파일]}"
study_id="${2:-}"
errors=0

fail() {
  printf '오류: %s\n' "$1" >&2
  errors=$((errors + 1))
}

[[ -f "$record" ]] || {
  printf '오류: 기록 파일이 없습니다: %s\n' "$record" >&2
  exit 1
}

first_line="$(sed -n '1p' "$record")"
frontmatter_end="$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$record")"
[[ "$first_line" == '---' && -n "$frontmatter_end" ]] || fail 'YAML 머리말 경계가 없습니다.'

required_keys='schema_version example_id display_name folder status recommended_level final_level level_reason language runtime created_at ready_at started_at completed_at baseline_commit preparation_step preparation_error next_supplemental_review_at'
for key in $required_keys; do
  count="$(grep -c "^${key}:" "$record" || true)"
  [[ "$count" -eq 1 ]] || fail "필수 키가 없거나 중복됩니다: $key"
done

schema_version="$(sed -n 's/^schema_version:[[:space:]]*//p' "$record")"
[[ "$schema_version" == '2' ]] || fail 'schema_version은 2여야 합니다.'

example_id="$(sed -n 's/^example_id:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}[[:space:]]*$/\1/p' "$record")"
if ! printf '%s\n' "$example_id" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'; then
  fail 'example_id가 UUID v4 형식이 아닙니다.'
fi

status="$(sed -n 's/^status:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}[[:space:]]*$/\1/p' "$record")"
case "$status" in
  preparing|ready|in_progress|completed) ;;
  *) fail 'status 값이 허용된 네 단계가 아닙니다.' ;;
esac

for section in '학습 목표와 진단 기준' '질문 이력' '배운 내용' '복습 이력'; do
  count="$(grep -c "^## $section$" "$record" || true)"
  [[ "$count" -eq 1 ]] || fail "필수 절이 없거나 중복됩니다: $section"
done

if [[ -n "$study_id" ]]; then
  if [[ ! -f "$study_id" ]]; then
    fail ".study-id 파일이 없습니다: $study_id"
  else
    linked_id="$(tr -d '[:space:]' < "$study_id")"
    [[ "$linked_id" == "$example_id" ]] || fail '.study-id와 기록의 example_id가 다릅니다.'
  fi
fi

((errors == 0)) || exit 1
printf '학습 기록 검사 통과: %s\n' "$record"
