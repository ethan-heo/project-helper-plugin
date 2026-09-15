#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '사용법: questions-store.sh toc <패키지>\n' >&2
  printf '       questions-store.sh get <패키지> <id>\n' >&2
  printf '       questions-store.sh add <패키지> <id> <관점> <기록경로> <질문원문> <단계...>\n' >&2
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
    [[ $# -ge 5 ]] || usage
    base_id="$1" viewpoint="$2" record="$3" question="$4"
    shift 4
    steps_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"
    existing="$(read_store | jq -c '[.[].id]')"
    id="$base_id"
    n=2
    while jq -e --arg id "$id" '. as $ids | ($ids | index($id)) != null' >/dev/null 2>&1 <<<"$existing"; do
      id="${base_id}-${n}"
      n=$((n + 1))
    done
    entry="$(jq -n \
      --arg id "$id" --arg question "$question" --arg viewpoint "$viewpoint" \
      --arg record "$record" --argjson path "$steps_json" \
      '{id: $id, question: $question, viewpoint: $viewpoint, path: $path, status: "진행", record: $record}')"
    updated="$(read_store | jq --argjson entry "$entry" '. + [$entry]')"
    mkdir -p "$package"
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
