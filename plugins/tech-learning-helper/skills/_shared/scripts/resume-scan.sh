#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '사용법: resume-scan.sh repos <학습폴더>\n' >&2
  printf '       resume-scan.sh packages <저장소>\n' >&2
  exit 1
}

[[ $# == 2 ]] || usage
mode="$1"
target="${2%/}"
[[ -d "$target" ]] || usage

# 저장소 state.json의 상태를 ok · missing_state · invalid_state · legacy 중 하나로 판정한다.
repo_status() {
  local repo="$1" state="$1/state.json"
  if [[ -f "$repo/state.md" || -f "$repo/knowledge.md" || -f "$repo/summary.md" ]]; then
    echo "legacy"; return
  fi
  if [[ -f "$state" ]] && jq -e 'has("package") or has("sessionStatus") or has("activePackage")' "$state" >/dev/null 2>&1; then
    echo "legacy"; return
  fi
  if [[ ! -f "$state" ]]; then
    echo "missing_state"; return
  fi
  if ! jq -e '
    type == "object"
    and (["packages", "discoveredConcepts"] | all(. as $key | $ROOT | has($key)))
    and (.packages | type == "array")
    and (.packages | all(.[]; (.name | type == "string") and (.lastActivity | type == "string")))
  ' --argjson ROOT "$(cat "$state")" <(cat "$state") >/dev/null 2>&1; then
    echo "invalid_state"; return
  fi
  echo "ok"
}

# repo/packages/<name> 디렉터리가 없는 이름만 골라 JSON 배열로 낸다.
stale_package_names() {
  local repo="$1" state="$2" name result="[]"
  local names=()
  while IFS= read -r name; do
    [[ -d "$repo/packages/$name" ]] || names+=("$name")
  done < <(jq -r '.packages[].name' "$state")
  if [[ ${#names[@]} -gt 0 ]]; then
    result="$(printf '%s\n' "${names[@]}" | jq -R . | jq -s .)"
  fi
  echo "$result"
}

legacy_file_list() {
  local repo="$1" names=()
  [[ -f "$repo/state.md" ]] && names+=("state.md")
  [[ -f "$repo/knowledge.md" ]] && names+=("knowledge.md")
  [[ -f "$repo/summary.md" ]] && names+=("summary.md")
  if [[ ${#names[@]} -eq 0 ]]; then
    echo "[]"
  else
    printf '%s\n' "${names[@]}" | jq -R . | jq -s .
  fi
}

scan_repos() {
  local repo name status last_epoch last_date last_package stale legacy_files
  local entries=()
  while IFS= read -r repo; do
    [[ -e "$repo/.git" ]] || continue
    name="$(basename "$repo")"
    status="$(repo_status "$repo")"
    last_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo 0)"
    last_date="$(git -C "$repo" log -1 --format=%cs 2>/dev/null || echo "")"
    last_package="null"
    stale="[]"
    legacy_files="[]"
    if [[ "$status" == "ok" ]]; then
      local lp
      lp="$(jq -r '.packages | sort_by(.lastActivity) | last | .name // empty' "$repo/state.json")"
      if [[ -n "$lp" ]]; then
        last_package="$(jq -Rn --arg v "$lp" '$v')"
      fi
      stale="$(stale_package_names "$repo" "$repo/state.json")"
    fi
    if [[ "$status" == "legacy" ]]; then
      legacy_files="$(legacy_file_list "$repo")"
    fi
    entries+=("$(jq -n \
      --arg name "$name" --arg status "$status" \
      --argjson lastCommitEpoch "$last_epoch" \
      --arg lastCommitDate "$last_date" \
      --argjson lastPackage "$last_package" \
      --argjson staleEntries "$stale" \
      --argjson legacyFiles "$legacy_files" \
      '{name: $name, status: $status, lastCommitEpoch: $lastCommitEpoch, lastCommitDate: $lastCommitDate, lastPackage: $lastPackage, staleEntries: $staleEntries, legacyFiles: $legacyFiles}')")
  done < <(find "$target" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ ${#entries[@]} == 0 ]]; then
    echo '{"repos":[]}'
    return
  fi
  printf '%s\n' "${entries[@]}" | jq -s 'sort_by(-.lastCommitEpoch) | {repos: .}'
}

scan_packages() {
  local repo="$target" state="$target/state.json" readme="$target/README.md"
  local status
  status="$(repo_status "$repo")"
  if [[ "$status" != "ok" ]]; then
    jq -n --arg status "$status" '{status: $status, packages: []}'
    return
  fi
  local last_name
  last_name="$(jq -r '.packages | sort_by(.lastActivity) | last | .name // empty' "$state")"
  local entries=() name last_activity dir stale goal is_last
  while IFS=$'\t' read -r name last_activity; do
    dir="$repo/packages/$name"
    stale="false"
    [[ -d "$dir" ]] || stale="true"
    goal="$(awk -F'|' -v name="$name" '
      { gsub(/^ +| +$/, "", $2) }
      $2 == "`" name "`" { gsub(/^ +| +$/, "", $3); print $3; exit }
    ' "$readme" 2>/dev/null || true)"
    is_last="false"
    [[ "$name" == "$last_name" ]] && is_last="true"
    entries+=("$(jq -n \
      --arg name "$name" --arg lastActivity "$last_activity" --arg goal "${goal:-}" \
      --argjson isLast "$is_last" --argjson stale "$stale" \
      '{name: $name, lastActivity: $lastActivity, goal: $goal, isLast: $isLast, stale: $stale}')")
  done < <(jq -r '.packages[] | [.name, .lastActivity] | @tsv' "$state")

  if [[ ${#entries[@]} == 0 ]]; then
    jq -n --arg status "$status" '{status: $status, packages: []}'
    return
  fi
  printf '%s\n' "${entries[@]}" | jq -s --arg status "$status" 'sort_by(.lastActivity) | reverse | {status: $status, packages: .}'
}

case "$mode" in
  repos) scan_repos ;;
  packages) scan_packages ;;
  *) usage ;;
esac
