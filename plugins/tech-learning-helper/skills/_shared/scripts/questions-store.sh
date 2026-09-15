#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '사용법: questions-store.sh toc <패키지>\n' >&2
  printf '       questions-store.sh get <패키지> <id>\n' >&2
  printf '       questions-store.sh add <패키지> <관점> <기록경로> <질문원문> <단계...>\n' >&2
  printf '       questions-store.sh start <패키지> <id>\n' >&2
  printf '       questions-store.sh complete <패키지> <id>\n' >&2
  printf '       questions-store.sh migrate <패키지>\n' >&2
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

# 구형 questions.md의 ### 헤더마다 {question, viewpoint, path}를 뽑아 JSON 배열로 낸다.
parse_legacy_questions() {
  awk '
    /^### / { print "Q\t" substr($0, 5); next }
    /^- 관점: / { line = $0; sub(/^- 관점: /, "", line); print "V\t" line; next }
    /^[0-9]+\. / { line = $0; sub(/^[0-9]+\. /, "", line); print "S\t" line; next }
  ' "$1" | jq -R -s '
    split("\n")
    | map(select(length > 0) | {tag: .[0:1], val: .[2:]})
    | reduce .[] as $l (
        {items: [], cur: null};
        if $l.tag == "Q" then
          {items: (.items + (if .cur then [.cur] else [] end)), cur: {question: $l.val, viewpoint: "", path: []}}
        elif $l.tag == "V" and .cur then .cur.viewpoint = $l.val
        elif $l.tag == "S" and .cur then .cur.path += [$l.val]
        else . end
      )
    | .items + (if .cur then [.cur] else [] end)
  '
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
  start | complete)
    [[ $# == 1 ]] || usage
    id="$1"
    status="진행"
    [[ "$mode" == "complete" ]] && status="완료"
    if ! read_store | jq -e --arg id "$id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
      printf '오류: id를 찾을 수 없음: %s\n' "$id" >&2
      exit 1
    fi
    updated="$(read_store | jq --arg id "$id" --arg s "$status" 'map(if .id == $id then .status = $s else . end)')"
    printf '%s\n' "$updated" >"$file"
    ;;
  migrate)
    [[ $# == 0 ]] || usage
    state="$package/state.json"
    legacy="$package/questions.md"
    legacy_state="false"
    if [[ -f "$state" ]] && jq -e 'has("questions") or has("activeQuestion")' "$state" >/dev/null; then
      legacy_state="true"
    fi
    [[ -f "$legacy" || "$legacy_state" == "true" ]] || exit 0
    prefix="$(id_prefix)"

    parsed="[]"
    [[ -f "$legacy" ]] && parsed="$(parse_legacy_questions "$legacy")"
    old="[]"
    [[ -f "$state" ]] && old="$(jq -c '.questions // []' "$state")"

    # 구형 두 파일을 잇는 id가 없으므로, 백틱과 공백만 무시한 원문이 헤더와 같을 때만 경로를 옮긴다.
    migrated="$(jq --arg p "$prefix-" --argjson parsed "$parsed" '
      def norm: gsub("[`\\s]"; "");
      to_entries | map(.value as $q | ([$parsed[] | select((.question | norm) == ($q.question | norm))] | first) as $m | {
        id: ($p + ((.key + 1) | tostring)),
        question: $q.question,
        viewpoint: ($m.viewpoint // ""),
        path: ($m.path // []),
        status: $q.status,
        record: $q.record
      })
    ' <<<"$old")"
    missing="$(jq -r '.[] | select(.path == []) | "  - \(.id): \(.question)"' <<<"$migrated")"
    if [[ -n "$missing" ]]; then
      printf '경고: questions.md에서 같은 헤더를 찾지 못해 경로 없이 옮긴 질문:\n%s\n' "$missing" >&2
    fi
    printf '%s\n' "$migrated" >"$file"

    if [[ -f "$state" ]]; then
      active="$(jq -r '.activeQuestion // empty' "$state")"
      active_id="$(jq --arg q "$active" '[.[] | select(.question == $q) | .id] | first' <<<"$migrated")"
      jq --argjson active "$active_id" '
        del(.questions, .activeQuestion, .viewpoint, .path, .record)
        | if $active then .activeQuestionId = $active else . end
      ' "$state" >"$state.tmp"
      mv "$state.tmp" "$state"
    fi
    rm -f "$legacy"
    ;;
  *)
    usage
    ;;
esac
