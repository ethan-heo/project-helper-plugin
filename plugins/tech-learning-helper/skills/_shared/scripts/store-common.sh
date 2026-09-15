#!/usr/bin/env bash
# learning-store와 기존 질문 저장 명령이 공유하는 파일·JSON 처리.
STORE_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

store_fail() {
  jq -cn --arg code "$1" --arg message "$2" '{error:{code:$code,message:$message}}' >&2
  exit 1
}

store_init() {
  [[ -d "$1" ]] || store_fail invalid_package '패키지 디렉터리가 없습니다'
  STORE_PACKAGE="$(cd "$1" && pwd -P)"
  [[ "$(basename "$(dirname "$STORE_PACKAGE")")" == packages ]] || store_fail invalid_package 'packages 아래 패키지가 필요합니다'
  STORE_REPO="$(dirname "$(dirname "$STORE_PACKAGE")")"
  STORE_PREFIX="$(basename "$STORE_REPO")-$(basename "$STORE_PACKAGE")-"
}

store_record_path() {
  local relative="$1" physical
  [[ "$relative" == records/*.md && "$relative" != *$'\n'* && "$relative" != *$'\t'* ]] || return 1
  case "/$relative/" in */../*|*/./*|*//*) return 1 ;; esac
  [[ -d "$STORE_PACKAGE/$(dirname "$relative")" && ! -L "$STORE_PACKAGE/$relative" ]] || return 1
  physical="$(cd "$STORE_PACKAGE/$(dirname "$relative")" && pwd -P)"
  [[ "$physical/" == "$STORE_PACKAGE/records/"* ]] || return 1
  printf '%s/%s\n' "$physical" "$(basename "$relative")"
}

store_load() {
  local name relative
  for name in "$STORE_REPO/state.json" "$STORE_PACKAGE/state.json" "$STORE_PACKAGE/questions.json"; do
    [[ -f "$name" && ! -L "$name" ]] || store_fail missing_file "상태 파일을 읽을 수 없습니다: $name"
  done
  STORE_BUNDLE="$(jq -cn -L "$STORE_SCRIPTS" \
    --slurpfile repo "$STORE_REPO/state.json" \
    --slurpfile state "$STORE_PACKAGE/state.json" \
    --slurpfile questions "$STORE_PACKAGE/questions.json" \
    --arg prefix "$STORE_PREFIX" \
    'include "learning-store"; bundle($repo; $state; $questions; $prefix)' 2>/dev/null)" \
    || store_fail invalid_state '상태·질문 JSON 또는 현재 질문 참조가 잘못되었습니다'
  while IFS= read -r relative; do
    [[ -z "$relative" ]] && continue
    name="$(store_record_path "$relative")" || store_fail invalid_record '질문 기록 경로가 잘못되었습니다'
    [[ -f "$name" ]] || store_fail missing_record "질문 기록이 없습니다: $relative"
  done < <(jq -r '.questions[].record' <<<"$STORE_BUNDLE")
}

store_goal() {
  [[ -f "$STORE_PACKAGE/README.md" ]] || store_fail missing_readme '패키지 README.md가 없습니다'
  awk '
    /^```/ { fence = !fence }
    !fence && /^## / { if (found) exit; if ($0 == "## 학습 목표") { found = 1; next } }
    found { print }
    END { if (!found) exit 1 }
  ' "$STORE_PACKAGE/README.md" | jq -Rs 'gsub("^\\s+|\\s+$"; "")'
}
