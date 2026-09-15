#!/usr/bin/env bash
# 호출자는 store_init 후 사용한다. 메타데이터는 Git 관리 디렉터리에 둔다.
store_meta() {
  local top
  top="$(git -C "$STORE_REPO" rev-parse --show-toplevel 2>/dev/null)" || store_fail invalid_repo 'Git 저장소가 아닙니다'
  [[ "$(cd "$top" && pwd -P)" == "$STORE_REPO" ]] || store_fail invalid_repo '기술 저장소 루트가 아닙니다'
  STORE_META="$(git -C "$STORE_REPO" rev-parse --absolute-git-dir)/learning-store"
}

store_unlock() {
  if [[ "${STORE_LOCKED:-0}" == 1 && -f "$STORE_META/lock/owner" && "$(cat "$STORE_META/lock/owner")" == "$$" ]]; then
    if [[ -d "$STORE_META/pending" && ! -f "$STORE_META/pending/manifest.json" ]]; then
      rm -rf "$STORE_META/pending"
    fi
    rm -f "$STORE_META/lock/owner"
    rmdir "$STORE_META/lock" 2>/dev/null || true
  fi
}

store_lock() {
  local owner
  store_meta
  mkdir -p "$STORE_META/receipts"
  if ! mkdir "$STORE_META/lock" 2>/dev/null; then
    owner="$(cat "$STORE_META/lock/owner" 2>/dev/null || true)"
    [[ "$owner" =~ ^[1-9][0-9]*$ ]] || store_fail busy '소유자를 확인할 수 없는 저장 잠금입니다'
    kill -0 "$owner" 2>/dev/null && store_fail busy '다른 저장 요청이 실행 중입니다'
    mkdir "$STORE_META/reaping" 2>/dev/null || store_fail busy '잠금 복구 중입니다'
    owner="$(cat "$STORE_META/lock/owner" 2>/dev/null || true)"
    if [[ "$owner" =~ ^[1-9][0-9]*$ ]] && ! kill -0 "$owner" 2>/dev/null; then
      rm -f "$STORE_META/lock/owner"
      rmdir "$STORE_META/lock" 2>/dev/null || true
    fi
    rmdir "$STORE_META/reaping"
    mkdir "$STORE_META/lock" 2>/dev/null || store_fail busy '다른 저장 요청이 잠금을 얻었습니다'
  fi
  printf '%s\n' "$$" > "$STORE_META/lock/owner"
  STORE_LOCKED=1
  trap store_unlock EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

# 경로는 저장소 기준 상대 경로로만 기록한다. 복구 때도 다시 검사한다.
store_target() {
  local relative="$1" parent
  [[ -n "$relative" && "$relative" != /* && "$relative" != *$'\n'* && "$relative" != *$'\t'* ]] || return 1
  case "/$relative/" in */../*|*/./*|*//*) return 1 ;; esac
  case "$relative" in
    state.json|packages/*/state.json|packages/*/questions.json|packages/*/questions.md|packages/*/records/*.md) ;;
    *) return 1 ;;
  esac
  [[ -d "$STORE_REPO/$(dirname "$relative")" && ! -L "$STORE_REPO/$relative" ]] || return 1
  parent="$(cd "$STORE_REPO/$(dirname "$relative")" && pwd -P)"
  [[ "$parent/" == "$STORE_REPO/"* ]] || return 1
  [[ ! -e "$STORE_REPO/$relative" || -f "$STORE_REPO/$relative" ]] || return 1
  printf '%s/%s\n' "$parent" "$(basename "$relative")"
}

store_replace() {
  local source="$1" target="$2" temp
  temp="$(mktemp "$(dirname "$target")/.learning-store.XXXXXX")" || return 1
  if cp -p "$source" "$temp" && mv -f "$temp" "$target"; then return 0; fi
  rm -f "$temp"
  return 1
}

store_read_guard() {
  store_meta
  [[ ! -d "$STORE_META/pending" && ! -d "$STORE_META/lock" ]] || store_fail recovery_required '저장 중이거나 복구할 작업이 있습니다. 저장 요청을 재시도하세요'
}

store_read_lock() {
  store_read_guard
  store_lock
  [[ ! -d "$STORE_META/pending" ]] || store_fail recovery_required '저장 전에 이전 작업을 복구해야 합니다'
}

store_recover() {
  local pending="$STORE_META/pending" count i relative target existed key
  [[ -d "$pending" ]] || return 0
  if [[ ! -f "$pending/manifest.json" ]]; then
    # manifest를 확정하기 전에는 원본을 바꾸지 않는다.
    rm -rf "$pending"
    return 0
  fi
  jq -e 'type == "array" and all(.[]; (.path|type=="string") and (.existed|type=="boolean") and (.delete|type=="boolean"))' "$pending/manifest.json" >/dev/null 2>&1 \
    || store_fail recovery_failed '복구 목록이 손상되었습니다. 원본 사본을 보존합니다'
  if [[ -f "$pending/committed" ]]; then
    if [[ -f "$pending/key" ]]; then
      key="$(cat "$pending/key")"
      [[ "$key" =~ ^[a-f0-9]+$ ]] || store_fail recovery_failed '요청 키가 손상되었습니다'
      store_replace "$pending/receipt.json" "$STORE_META/receipts/$key.json" || store_fail recovery_failed '완료 요청을 기록하지 못했습니다'
    fi
  else
    count="$(jq length "$pending/manifest.json")"
    for ((i=0;i<count;i++)); do
      relative="$(jq -r ".[$i].path" "$pending/manifest.json")"
      target="$(store_target "$relative")" || store_fail recovery_failed '복구 경로가 잘못되었습니다'
      existed="$(jq -r ".[$i].existed" "$pending/manifest.json")"
      if [[ "$existed" == true ]]; then
        store_replace "$pending/old/$i" "$target" || store_fail recovery_failed '원본 복구에 실패했습니다. 사본을 보존합니다'
      else
        rm -f "$target" || store_fail recovery_failed '새 파일을 복구하지 못했습니다'
      fi
    done
  fi
  rm -rf "$pending"
}

# canonical envelope: package + mode + payload. 키 충돌과 같은 ID의 다른 입력을 구분한다.
store_request() {
  local mode="$1" payload="$2" existing
  STORE_REQUEST="$(jq -cnS --arg package "${STORE_PACKAGE#"$STORE_REPO"/}" --arg mode "$mode" --argjson payload "$payload" '{package:$package,mode:$mode,payload:$payload}')"
  STORE_KEY="$(jq -cS '{package,mode,operationId:.payload.operationId}' <<<"$STORE_REQUEST" | git -C "$STORE_REPO" hash-object --stdin)"
  STORE_REPLAY=0
  if [[ -f "$STORE_META/receipts/$STORE_KEY.json" ]]; then
    existing="$(jq -cS '.request' "$STORE_META/receipts/$STORE_KEY.json")" || store_fail invalid_receipt '저장 요청 기록이 손상되었습니다'
    [[ "$existing" == "$STORE_REQUEST" ]] || store_fail duplicate_id '같은 요청 ID에 다른 입력을 사용할 수 없습니다'
    STORE_REPLAY=1
    STORE_RESULT="$(jq -c '.result' "$STORE_META/receipts/$STORE_KEY.json")"
  fi
}

store_begin() {
  [[ ! -d "$STORE_META/pending" ]] || store_fail recovery_required '먼저 이전 저장을 복구해야 합니다'
  mkdir -p "$STORE_META/pending/old" "$STORE_META/pending/new"
  STORE_MANIFEST='[]'
  STORE_INDEX=0
}

# source가 -이면 삭제한다. 아직 원본을 쓰지 않는다.
store_stage() {
  local relative="$1" source="$2" target existed=false delete=false
  target="$(store_target "$relative")" || store_fail invalid_target '저장 대상 경로가 잘못되었습니다'
  jq -e --arg path "$relative" 'any(.[];.path==$path)' <<<"$STORE_MANIFEST" >/dev/null && store_fail duplicate_target '같은 파일을 두 번 저장할 수 없습니다'
  if [[ -f "$target" ]]; then
    existed=true
    cp -p "$target" "$STORE_META/pending/old/$STORE_INDEX" || store_fail staging_failed '원본 사본을 만들지 못했습니다'
  fi
  if [[ "$source" == - ]]; then delete=true
  else cp "$source" "$STORE_META/pending/new/$STORE_INDEX" || store_fail staging_failed '저장 내용을 준비하지 못했습니다'; fi
  STORE_MANIFEST="$(jq -c --arg path "$relative" --argjson existed "$existed" --argjson delete "$delete" '. + [{path:$path,existed:$existed,delete:$delete}]' <<<"$STORE_MANIFEST")"
  STORE_INDEX=$((STORE_INDEX+1))
}

store_commit() {
  local pending="$STORE_META/pending" i target relative delete
  printf '%s\n' "$STORE_MANIFEST" > "$pending/manifest.tmp"
  mv "$pending/manifest.tmp" "$pending/manifest.json"
  if [[ -n "${STORE_KEY:-}" ]]; then
    printf '%s\n' "$STORE_KEY" > "$pending/key"
    jq -cn --argjson request "$STORE_REQUEST" --argjson result "$STORE_RESULT" '{request:$request,result:$result}' > "$pending/receipt.json"
  fi
  for ((i=0;i<STORE_INDEX;i++)); do
    relative="$(jq -r ".[$i].path" <<<"$STORE_MANIFEST")"
    target="$(store_target "$relative")" || { store_recover; store_fail invalid_target '저장 대상이 바뀌었습니다'; }
    delete="$(jq -r ".[$i].delete" <<<"$STORE_MANIFEST")"
    if [[ "$delete" == true ]]; then
      rm -f "$target" || { store_recover; store_fail write_failed '삭제 실패 후 복구했습니다'; }
    else
      store_replace "$pending/new/$i" "$target" || { store_recover; store_fail write_failed '저장 실패 후 복구했습니다'; }
    fi
    if [[ "${LEARNING_STORE_TESTING:-}" == 1 ]]; then
      if [[ "${LEARNING_STORE_FAIL_AFTER:-}" == "$((i+1))" ]]; then store_recover; store_fail write_failed '테스트 저장 실패 후 복구했습니다'; fi
      if [[ "${LEARNING_STORE_KILL_AFTER:-}" == "$((i+1))" ]]; then kill -KILL "$$"; fi
    fi
  done
  touch "$pending/committed"
  if [[ "${LEARNING_STORE_TESTING:-}" == 1 && "${LEARNING_STORE_KILL_COMMITTED:-}" == 1 ]]; then kill -KILL "$$"; fi
  store_recover
}
