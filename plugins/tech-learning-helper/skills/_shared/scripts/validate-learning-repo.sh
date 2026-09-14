#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || ! -d "$1" ]]; then
  printf '사용법: validate-learning-repo.sh <기술 저장소>\n' >&2
  exit 1
fi
repo="${1%/}"
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
check_state() {
  local file="$repo/state.json"
  if [[ ! -f "$file" ]]; then
    warn "${file#"$repo"/}: 파일 없음 (기존 저장소 복구 필요)"
    return
  fi
  if ! jq -e '
    type == "object"
    and (. as $state | (["sessionStatus", "inputMode", "package", "record", "activeQuestion", "viewpoint", "path", "stage", "awaiting", "nextCandidates", "lastTurn"] | all(.[]; . as $key | $state | has($key))))
    and (.sessionStatus | IN("idle", "awaiting_selection", "in_progress", "recovery_required"))
    and (.inputMode | IN("selection", "learning"))
    and (.package | type == "string")
    and (.record | type == "string")
    and (.activeQuestion | type == "string")
    and (.nextCandidates | type == "array")
    and (.lastTurn | type == "object")
    and (.lastTurn.speaker | IN("학습자", "assistant"))
    and (.lastTurn.type | type == "string")
  ' "$file" >/dev/null 2>&1; then
    fail "${file#"$repo"/}: JSON 형식 또는 필수 상태 필드 오류"
  fi
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
# 탐색 질문은 질문마다 ### 제목과 설명 경로의 번호 목록을 가진다.
check_questions() {
  local file="$1" missing
  missing="$(awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    /^### / {
      if (title != "" && !steps) print title
      title = substr($0, 5); steps = 0; count++; next
    }
    /^## / { if (title != "" && !steps) print title; title = ""; next }
    /^[0-9]+\. / { if (title != "") steps = 1 }
    END {
      if (title != "" && !steps) print title
      if (!count) print "(질문 없음)"
    }
  ' "$file")"
  [[ -z "$missing" ]] || fail "${file#"$repo"/}: 설명 경로 누락 ($(printf '%s' "$missing" | paste -sd ',' -))"
}

[[ -e "$repo/.git" ]] || fail "$repo: git 저장소가 아님"
check_state

require_file "$repo/README.md" '## 학습 패키지'
require_file "$repo/knowledge.md" '## 개념' '## 선수 관계'
require_file "$repo/state.md" '## 마지막 학습 패키지' '## 발견한 개념' '## 부분 이해 개념' '## 미공개 개념' '## 다음 탐색 후보'

packages=()
if [[ -d "$repo/packages" ]]; then
  while IFS= read -r dir; do packages+=("$dir"); done < <(find "$repo/packages" -mindepth 1 -maxdepth 1 -type d | sort)
fi
(( ${#packages[@]} > 0 )) || warn "$repo: 학습 패키지가 없습니다."

for package in ${packages[@]+"${packages[@]}"}; do
  require_file "$package/README.md" '## 학습 목표' '## 실행 방법'
  require_file "$package/questions.md" '## 탐색 질문'
  [[ -f "$package/questions.md" ]] && check_questions "$package/questions.md"
  [[ -d "$package/src" ]] || fail "${package#"$repo"/}/src: 디렉터리 없음"
  [[ -f "$package/source.md" ]] && require_file "$package/source.md" '## 원본 참조' '## 발췌'
  [[ -f "$package/summary.md" ]] && require_file "$package/summary.md" '## 학습 목표' '## 다룬 질문' '## 발견한 개념' '## 부분 이해 개념' '## 다음 탐색 후보'
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
