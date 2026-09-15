#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || ! -d "$1" ]]; then
  printf '사용법: validate-learning-repo.sh <기술 저장소>\n' >&2
  exit 1
fi
repo="${1%/}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf '경고: %s\n' "$1" >&2; }

# 코드 블록 안의 제목은 양식 예시일 수 있으므로 검사에서 제외한다.
has_heading() {
  awk -v wanted="$2" '
    /^[[:space:]]*```/ { fence = !fence; next }
    !fence && $0 == wanted { found = 1 }
    END { exit !found }
  ' "$1"
}
require_file() {
  local file="$1"
  shift
  if [[ ! -f "$file" ]]; then
    fail "${file#"$repo"/}: 파일 없음"
    return
  fi
  local heading
  for heading in "$@"; do
    has_heading "$file" "$heading" || fail "${file#"$repo"/}: 필수 절 누락 ($heading)"
  done
}
# 저장소 state.json은 재개 지점을 판단하지 않는 인덱스이므로, 패키지 이름과 마지막 활동 날짜만 검사한다.
check_repo_state() {
  local file="$repo/state.json"
  if [[ ! -f "$file" ]]; then
    warn "${file#"$repo"/}: 파일 없음 (기존 저장소 복구 필요)"
    return
  fi
  if ! jq -e '
    type == "object"
    and (. as $state | (["packages", "discoveredConcepts"] | all(.[]; . as $key | $state | has($key))))
    and (.packages | type == "array")
    and (.packages | all(.[]; (.name | type == "string") and (.lastActivity | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))))
    and (.discoveredConcepts | type == "array")
  ' "$file" >/dev/null 2>&1; then
    fail "${file#"$repo"/}: JSON 형식 또는 필수 상태 필드 오류"
    return
  fi
  local name
  while IFS= read -r name; do
    [[ -z "$name" || -d "$repo/packages/$name" ]] || fail "${file#"$repo"/}: packages가 가리키는 패키지 없음 ($name)"
  done < <(jq -r '.packages[].name' "$file")
}
# 구형 패키지는 다음에 그 패키지를 고를 때 questions-store.sh migrate가 옮기므로, 오류가 아닌 경고로 남긴다.
is_legacy_package() {
  local package="$1"
  [[ -f "$package/questions.md" ]] && return 0
  [[ -f "$package/state.json" ]] && jq -e 'type == "object" and (has("questions") or has("activeQuestion"))' "$package/state.json" >/dev/null 2>&1
}
# 패키지 state.json은 재개 포인터(activeQuestionId)와 누적 학습 상태를 담는다.
check_package_state() {
  local package="$1" file="$1/state.json"
  if [[ ! -f "$file" ]]; then
    warn "${file#"$repo"/}: 파일 없음 (기존 저장소 복구 필요)"
    return
  fi
  if ! jq -e -L "$scripts_dir" 'include "learning-store"; valid_state' "$file" >/dev/null 2>&1; then
    fail "${file#"$repo"/}: JSON 형식 또는 필수 상태 필드 오류"
    return
  fi
  if [[ -f "$package/questions.json" ]] && ! jq -en -L "$scripts_dir" \
    --slurpfile state "$file" --slurpfile questions "$package/questions.json" \
    'include "learning-store"; {state:$state[0],questions:$questions[0]} | valid_positions' >/dev/null 2>&1; then
    fail "${file#"$repo"/}: 현재 단계 또는 후보의 재개 위치 오류"
  fi
  local active
  active="$(jq -r '.activeQuestionId // empty' "$file")"
  if [[ -n "$active" && -f "$package/questions.json" ]] \
    && ! jq -e --arg id "$active" 'any(.[]; .id == $id)' "$package/questions.json" >/dev/null 2>&1; then
    fail "${file#"$repo"/}: activeQuestionId가 questions.json에 없음 ($active)"
  fi
}
# 질문 명령과 learning-store가 같은 검증을 사용하며, id는 <저장소>-<패키지>-<순번>이다.
check_questions_json() {
  local package="$1" file="$1/questions.json" prefix
  if [[ ! -f "$file" ]]; then
    fail "${file#"$repo"/}: 파일 없음"
    return
  fi
  prefix="$repo_name-$(basename "$package")-"
  if ! jq -e -L "$scripts_dir" --arg p "$prefix" 'include "learning-store"; valid_questions($p)' "$file" >/dev/null 2>&1; then
    fail "${file#"$repo"/}: JSON 형식 또는 필수 필드 오류 (id는 ${prefix}<순번>, status는 진행|완료)"
    return
  fi
  local record
  while IFS= read -r record; do
    [[ -z "$record" || -f "$package/$record" ]] || fail "${file#"$repo"/}: 기록 파일 없음 ($record)"
  done < <(jq -r '.[].record' "$file")
}
check_record_speakers() {
  local file="$1" invalid
  invalid="$(awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    /^\*\*학습자\*\*/ && $0 != "**학습자**" { print NR; next }
    /^\*\*설명\([^)]*\)\*\*/ && $0 !~ /^\*\*설명\([^)]*\)\*\*$/ { print NR }
  ' "$file")"
  [[ -z "$invalid" ]] || fail "${file#"$repo"/}: 발화 이름을 별도 줄로 작성하지 않음 ($invalid)"
}
[[ -e "$repo/.git" ]] || fail "$repo: git 저장소가 아님"
repo_name="$(basename "$(cd "$repo" && pwd -P)")"
check_repo_state

require_file "$repo/README.md" '## 학습 패키지'

packages=()
if [[ -d "$repo/packages" ]]; then
  while IFS= read -r dir; do packages+=("$dir"); done < <(find "$repo/packages" -mindepth 1 -maxdepth 1 -type d | sort)
fi
(( ${#packages[@]} > 0 )) || warn "$repo: 학습 패키지가 없습니다."

for package in ${packages[@]+"${packages[@]}"}; do
  require_file "$package/README.md" '## 학습 목표' '## 실행 방법'
  [[ -d "$package/src" ]] || fail "${package#"$repo"/}/src: 디렉터리 없음"
  [[ -f "$package/source.md" ]] && require_file "$package/source.md" '## 원본 참조' '## 발췌'
  if is_legacy_package "$package"; then
    warn "${package#"$repo"/}: 구형 질문 형식 (questions-store.sh migrate 필요)"
  else
    check_questions_json "$package"
    check_package_state "$package"
  fi
  if [[ -d "$package/records" ]]; then
    # 새 형식은 날짜 디렉터리 안에 질문별 파일을 두고, 기존 날짜 파일은 호환한다.
    while IFS= read -r record; do
      name="$(basename "$record")"
      if [[ ! "$name" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
        fail "${record#"$repo"/}: 기록 파일 이름 오류 (YYYY-MM-DD.md 또는 YYYY-MM-DD/NN-question-slug.md)"
        continue
      fi
      date="${BASH_REMATCH[1]}"
      [[ "$(head -n 1 "$record")" == "# $date" ]] || fail "${record#"$repo"/}: 첫 줄 날짜 불일치 (# $date)"
      check_record_speakers "$record"
    done < <(find "$package/records" -mindepth 1 -maxdepth 1 -type f | sort)

    while IFS= read -r date_dir; do
      date="$(basename "$date_dir")"
      [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
        fail "${date_dir#"$repo"/}: 날짜 디렉터리 이름 오류 (YYYY-MM-DD)"
        continue
      }
      while IFS= read -r record; do
        name="$(basename "$record")"
        if [[ ! "$name" =~ ^([0-9]{2})-([a-z0-9]+(-[a-z0-9]+)*)\.md$ ]]; then
          fail "${record#"$repo"/}: 질문 기록 파일 이름 오류 (NN-question-slug.md)"
          continue
        fi
        [[ "$(head -n 1 "$record")" == "# $date" ]] || fail "${record#"$repo"/}: 첫 줄 날짜 불일치 (# $date)"
        check_record_speakers "$record"
      done < <(find "$date_dir" -mindepth 1 -maxdepth 1 -type f | sort)
    done < <(find "$package/records" -mindepth 1 -maxdepth 1 -type d | sort)
  fi
done

(( errors == 0 )) || exit 1
printf '학습 저장소 검증 통과: %s\n' "$repo"
