#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '사용법: questions-store.sh toc <패키지>\n' >&2
  printf '       questions-store.sh get <패키지> <id>\n' >&2
  printf '       questions-store.sh add <패키지> <관점> <기록경로> <질문원문> <단계...>\n' >&2
  printf '       questions-store.sh complete <패키지> <id>\n' >&2
  exit 1
}

[[ $# -ge 2 ]] || usage
mode="$1"
package="${2%/}"
shift 2
file="$package/questions.json"

read_store() {
  if [[ -f "$file" ]]; then cat "$file"; else echo '[]'; fi
}

# id 접두어 <저장소>-<패키지>는 <저장소>/packages/<패키지> 경로에서만 만든다.
id_prefix() {
  local abs
  abs="$(cd "$package" && pwd -P)"
  if [[ "$(basename "$(dirname "$abs")")" != "packages" ]]; then
    printf '오류: 패키지 경로가 <저장소>/packages/<패키지> 형태가 아님: %s\n' "$package" >&2
    exit 1
  fi
  printf '%s-%s' "$(basename "$(dirname "$(dirname "$abs")")")" "$(basename "$abs")"
}

case "$mode" in
  toc)
    [[ $# == 0 ]] || usage
    read_store | jq -c '[.[] | {id, question, viewpoint, status}]'
    ;;
  get)
    [[ $# == 1 ]] || usage
    id="$1"
    result="$(read_store | jq --arg id "$id" '[.[] | select(.id == $id)] | first')"
    if [[ "$result" == "null" ]]; then
      printf '오류: id를 찾을 수 없음: %s\n' "$id" >&2
      exit 1
    fi
    printf '%s\n' "$result"
    ;;
  add)
    [[ $# -ge 4 ]] || usage
    viewpoint="$1" record="$2" question="$3"
    shift 3
    [[ -d "$package" ]] || { printf '오류: 패키지 디렉터리 없음: %s\n' "$package" >&2; exit 1; }
    prefix="$(id_prefix)"
    next="$(read_store | jq --arg p "$prefix-" '[.[].id | select(startswith($p)) | ltrimstr($p) | tonumber? ] | (max // 0) + 1')"
    id="$prefix-$next"
    steps_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"
    entry="$(jq -n \
      --arg id "$id" --arg question "$question" --arg viewpoint "$viewpoint" \
      --arg record "$record" --argjson path "$steps_json" \
      '{id: $id, question: $question, viewpoint: $viewpoint, path: $path, status: "진행", record: $record}')"
    updated="$(read_store | jq --argjson entry "$entry" '. + [$entry]')"
    printf '%s\n' "$updated" >"$file"
    printf '%s\n' "$id"
    ;;
  complete)
    [[ $# == 1 ]] || usage
    id="$1"
    if ! read_store | jq -e --arg id "$id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
      printf '오류: id를 찾을 수 없음: %s\n' "$id" >&2
      exit 1
    fi
    updated="$(read_store | jq --arg id "$id" 'map(if .id == $id then .status = "완료" else . end)')"
    printf '%s\n' "$updated" >"$file"
    ;;
  *)
    usage
    ;;
esac
