#!/usr/bin/env bash
set -euo pipefail

prd="${1:?사용법: validate-sub-prd.sh <상위 PRD 파일> }"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }

[[ -f "$prd" ]] || { printf '오류: %s 파일이 없습니다.\n' "$prd" >&2; exit 1; }

prd_dir="$(dirname "$prd")"
base="$(basename "$prd" .md)"
if [[ "$base" == "README" ]]; then
  sub_dir="$prd_dir"
else
  sub_dir="$prd_dir/$base"
fi
shared_validator="$(dirname "$0")/../../_shared/prd/validate-prd.sh"

req_rows="$(sed -n '/^## 요구사항$/,/^## /p' "$prd" | grep -E '^\| R[0-9-]+ \|' || true)"
[[ -n "$req_rows" ]] || fail '요구사항 표에서 항목을 찾지 못했습니다.'

assignments=""
while IFS= read -r row; do
  [[ -n "$row" ]] || continue
  id="$(printf '%s' "$row" | sed -E 's/^\| *([^ |]+) *\|.*/\1/')"
  link="$(printf '%s' "$row" | sed -E 's/.*\| *([^|]*) *\|[[:space:]]*$/\1/')"
  path="$(printf '%s' "$link" | sed -nE 's/.*\]\(([^)]+)\).*/\1/p')"

  if [[ -z "$path" ]]; then
    fail "$id 요구사항에 하위 PRD가 배정되지 않았습니다."
    continue
  fi

  target="$prd_dir/$path"
  if [[ ! -f "$target" ]]; then
    fail "$id 요구사항이 가리키는 $path 파일이 없습니다."
    continue
  fi

  assignments="$assignments$id $target"$'\n'
done <<< "$req_rows"

if [[ "$base" == "README" ]]; then
  [[ -n "$(find "$sub_dir" -maxdepth 1 -name '*.md' ! -name 'README.md' -print -quit)" ]] \
    || fail "$sub_dir 에 하위 PRD가 없습니다. 아직 분해 전 상태입니다."
else
  fail "상위 PRD가 $prd_dir/$base/README.md 로 옮겨져 있지 않습니다."
  [[ -d "$sub_dir" ]] || fail "하위 디렉터리 $sub_dir 가 없습니다. 아직 분해 전 상태입니다."
fi

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  id="${line%% *}"
  target="${line#* }"

  owners="$(printf '%s' "$assignments" | awk -v t="$target" '$2 == t {print $1}' | tr '\n' ' ')"

  grep -qE '^\*\*상위 PRD\*\* — ' "$target" \
    || fail "$target 에 상위 PRD 출처 줄이 없습니다."

  grep -qE "^\*\*상위 PRD\*\* — .*(^|[ ,])$id([ ,]|$)" "$target" \
    || fail "$target 의 상위 출처 줄에 담당 요구사항 $id 가 없습니다."

  bad_ids="$(sed -n '/^## 요구사항$/,/^## /p' "$target" | grep -E '^\| [^ |]+ \| (필수|선택) \|' | sed -E 's/^\| *([^ |]+) *\|.*/\1/' | grep -vE "^($(printf '%s' "$owners" | sed 's/ *$//' | tr ' ' '|'))-" || true)"
  [[ -z "$bad_ids" ]] || fail "$target 의 요구사항 ID가 상위 ID를 이어받지 않았습니다: $(printf '%s' "$bad_ids" | tr '\n' ' ')"
done <<< "$assignments"

dups="$(printf '%s' "$assignments" | awk 'NF {print $1}' | sort | uniq -d)"
[[ -z "$dups" ]] || fail "같은 요구사항 ID가 여러 행에 있습니다: $(printf '%s' "$dups" | tr '\n' ' ')"

if [[ -x "$shared_validator" ]]; then
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    "$shared_validator" "$target" >/dev/null || fail "$target 가 단일 문서 검증을 통과하지 못했습니다."
  done < <(printf '%s' "$assignments" | awk 'NF {print $2}' | sort -u)
else
  fail "단일 문서 검증 스크립트를 찾지 못했습니다: $shared_validator"
fi

(( errors == 0 )) || exit 1
printf '분해 검증 통과: %s\n' "$prd"
