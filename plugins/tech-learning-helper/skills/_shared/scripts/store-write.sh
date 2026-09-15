#!/usr/bin/env bash
store_write() {
  local mode="$1" payload transformed work i count id relative target before_path new_path
  payload="$(jq -cse 'if length == 1 and (.[0] | type == "object") then .[0] else error("JSON 객체 하나가 필요합니다") end' 2>/dev/null)" \
    || store_fail invalid_payload '표준 입력에 JSON 객체 하나를 전달하세요'
  jq -e -L "$STORE_SCRIPTS" 'include "learning-store"; valid_payload' <<<"$payload" >/dev/null 2>&1 \
    || store_fail invalid_payload '저장 입력 필드가 잘못되었습니다'
  store_lock
  store_recover
  store_request "$mode" "$payload"
  if [[ "$STORE_REPLAY" == 1 ]]; then printf '%s\n' "$STORE_RESULT"; return; fi
  store_load
  transformed="$(jq -c -L "$STORE_SCRIPTS" --argjson p "$payload" \
    'include "learning-store"; validate_request($p) | apply_turn($p) | normalize_bundle
      | if valid_positions then . else error("재개 위치 오류") end' <<<"$STORE_BUNDLE" 2>/dev/null)" \
    || store_fail invalid_request '질문 상태 또는 기록 대상이 잘못되었습니다'
  if [[ "$mode" == finish-question ]]; then
    transformed="$(jq -c -L "$STORE_SCRIPTS" --argjson p "$payload" \
      --arg name "$(basename "$STORE_PACKAGE")" --arg date "$(date +%F)" \
      'include "learning-store"; finish_turn($p; $name; $date)' <<<"$transformed")"
  fi
  store_begin
  work="$STORE_META/pending/work"
  mkdir -p "$work"
  jq '.state' <<<"$transformed" > "$work/state.json"
  jq -e -L "$STORE_SCRIPTS" 'include "learning-store"; valid_state' "$work/state.json" >/dev/null \
    || store_fail invalid_state '갱신할 상태가 잘못되었습니다'
  count="$(jq '.records | length' <<<"$payload")"
  for ((i=0;i<count;i++)); do
    id="$(jq -r ".records[$i].questionId" <<<"$payload")"
    relative="$(jq -r --arg id "$id" '.questions[] | select(.id==$id) | .record' <<<"$STORE_BUNDLE")"
    target="$(store_record_path "$relative")" || store_fail invalid_record '기록 경로가 잘못되었습니다'
    new_path="$work/record-$i.md"
    cp "$target" "$new_path"
    printf '\n' >> "$new_path"
    jq -rj -L "$STORE_SCRIPTS" "include \"learning-store\"; .records[$i].turns | render_turns" <<<"$payload" >> "$new_path"
    store_stage "${target#"$STORE_REPO"/}" "$new_path"
  done
  store_stage "${STORE_PACKAGE#"$STORE_REPO"/}/state.json" "$work/state.json"
  if [[ "$mode" == finish-question ]]; then
    jq '.questions' <<<"$transformed" > "$work/questions.json"
    jq '.repo' <<<"$transformed" > "$work/repo.json"
    jq -e -L "$STORE_SCRIPTS" --arg prefix "$STORE_PREFIX" 'include "learning-store"; valid_questions($prefix)' "$work/questions.json" >/dev/null \
      || store_fail invalid_questions '완료 처리할 질문 형식이 잘못되었습니다'
    jq -e -L "$STORE_SCRIPTS" 'include "learning-store"; valid_repo' "$work/repo.json" >/dev/null \
      || store_fail invalid_repo '갱신할 저장소 상태가 잘못되었습니다'
    store_stage "${STORE_PACKAGE#"$STORE_REPO"/}/questions.json" "$work/questions.json"
    store_stage state.json "$work/repo.json"
  fi
  STORE_RESULT="$(jq -cn --arg operationId "$(jq -r .operationId <<<"$payload")" --argjson files "$STORE_MANIFEST" '{operationId:$operationId,changedFiles:[$files[].path]}')"
  store_commit
  printf '%s\n' "$STORE_RESULT"
}
