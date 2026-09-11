#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || ! -d "$1" ]]; then
  printf '사용법: validate-architecture.sh <아키텍처 디렉터리>\n' >&2
  exit 1
fi
architecture_dir="$1"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf '경고: %s\n' "$1" >&2; }

# 코드 예시에 들어 있는 제목과 표는 검사에서 제외한다.
section() {
  awk -v wanted="$2" '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    /^## / { active = ($0 == "## " wanted); next }
    active { print }
  ' "$1"
}
rows() {
  section "$1" "$2" | awk -F '|' '
    /^[[:space:]]*\|/ {
      if (!header++) next
      out = ""; separator = 1
      for (i = 2; i < NF; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        if ($i !~ /^:?-+:?$/) separator = 0
        out = out (i == 2 ? "" : "|") $i
      }
      if (!separator) print out
    }
  '
}
check_headings() {
  local file="$1" heading
  shift
  for heading in "$@"; do
    if ! awk -v wanted="## $heading" '
      /^[[:space:]]*```/ { fence = !fence; next }
      !fence && $0 == wanted { found = 1 }
      END { exit !found }
    ' "$file"; then
      fail "$file: 필수 절 누락 ($heading)"
    fi
  done
}

index="$architecture_dir/README.md"
decisions="$architecture_dir/decisions.md"
[[ -f "$index" ]] || fail "$index: 색인 파일 누락"
[[ -f "$decisions" ]] || fail "$decisions: 결정 기록 파일 누락"
(( errors == 0 )) || exit 1
check_headings "$index" '버전 표' '시스템의 목적' '공통 개념 모델' '영역 목록' '변경 이력'
check_headings "$decisions" '결정 기록 표'

version="$(rows "$index" '버전 표' | awk -F '|' '$1 == "버전" { print $2 }')"
updated="$(rows "$index" '버전 표' | awk -F '|' '$1 == "마지막 갱신" { print $2 }')"
[[ "$version" =~ ^[0-9]+\.[0-9]+$ ]] || fail "$index: 버전 형식 오류 (N.N)"
[[ "$updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]] || fail "$index: 마지막 갱신 형식 오류 (YYYY-MM-DD HH:MM)"

listed_files=''
area_count=0
while IFS='|' read -r area file scope extra; do
  [[ -n "$area$file$scope$extra" ]] || continue
  # 양식의 상대 링크와 인라인 코드 파일명을 모두 받는다.
  file="$(printf '%s\n' "$file" | sed -E 's/^\[[^]]*\]\(([^)]+)\)$/\1/; s/^`([^`]+)`$/\1/')"
  if [[ ! "$file" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ || "$file" == decisions.md ]]; then
    fail "$index: 영역 파일 이름 오류 ($file)"
    continue
  fi
  if printf '%s\n' "$listed_files" | grep -Fxq -- "$file"; then
    fail "$index: 영역 파일 중복 ($file)"
  fi
  listed_files="${listed_files}${file}"$'\n'
  area_count=$((area_count + 1))
  if [[ ! -f "$architecture_dir/$file" ]]; then
    fail "$index: 영역 파일 누락 ($file)"
    continue
  fi
  check_headings "$architecture_dir/$file" '목적과 문제' '요구사항과 품질 속성' '개념 모델' '책임과 경계' '실행 흐름' '계약' '위험과 미해결 질문'
done < <(rows "$index" '영역 목록')

while IFS= read -r file; do
  name="${file##*/}"
  [[ "$name" == README.md || "$name" == decisions.md ]] && continue
  printf '%s\n' "$listed_files" | grep -Fxq -- "$name" || fail "$index: 목록에 없는 영역 파일 ($name)"
done < <(find "$architecture_dir" -maxdepth 1 -type f -name '*.md' -print)
(( area_count > 0 )) || warn "$index: 영역 파일이 없습니다."

decision_rows="$(rows "$decisions" '결정 기록 표')"
if [[ -z "$decision_rows" ]]; then
  warn "$decisions: 결정 기록이 비어 있습니다."
else
  while IFS= read -r row; do
    [[ "$(printf '%s\n' "$row" | awk -F '|' '{print NF}')" == 8 ]] || fail "$decisions: 결정 기록은 8열이어야 합니다."
    IFS='|' read -r id decision reason alternative state introduced areas replacement <<< "$row"
    [[ "$id" =~ ^AD-[0-9]{3}$ ]] || fail "$decisions: 결정 ID 형식 오류 ($id)"
    count="$(printf '%s\n' "$decision_rows" | awk -F '|' -v id="$id" '$1 == id { n++ } END { print n+0 }')"
    [[ "$count" == 1 ]] || fail "$decisions: 결정 ID 중복 ($id)"
    [[ "$state" == 채택 || "$state" == 대체됨 ]] || fail "$decisions: 결정 상태 오류 ($id: $state)"
    if [[ "$state" == 대체됨 ]]; then
      if [[ -z "$replacement" || "$replacement" == "$id" ]] || ! printf '%s\n' "$decision_rows" | awk -F '|' -v id="$replacement" '$1 == id { found = 1 } END { exit !found }'; then
        fail "$decisions: 대체한 결정 ID 오류 ($id: $replacement)"
      fi
    elif [[ "$state" == 채택 && -n "$replacement" ]]; then
      fail "$decisions: 채택한 결정의 대체한 결정 열은 빈칸이어야 합니다 ($id)"
    fi
  done <<< "$decision_rows"
fi

latest="$(rows "$index" '변경 이력' | awk -F '|' 'NR == 1 { print $1 }')"
[[ -n "$latest" && "$latest" == "$version" ]] || fail "$index: 변경 이력 최신 버전 불일치 ($latest / $version)"
(( errors == 0 )) || exit 1
printf '아키텍처 문서 검증 통과: %s\n' "$architecture_dir"
