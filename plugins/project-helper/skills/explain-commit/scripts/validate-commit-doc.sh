#!/usr/bin/env bash
set -euo pipefail

target="${1:?사용법: validate-commit-doc.sh <학습 문서 파일 또는 디렉터리>}"

sections=(
  "## 한 줄 요약"
  "## 변경 전 상태와 문제"
  "## 변경 의도"
  "## 실행 흐름"
  "## 의존 관계"
  "## 용어와 배경"
)

failed_docs=""
warned_docs=""

check_doc() {
  local doc="$1"
  local name errors=0
  name="$(basename "$doc")"

  local prev=0
  for section in "${sections[@]}"; do
    local line
    line="$(grep -n -F -x "$section" "$doc" | head -1 | cut -d: -f1 || true)"
    if [[ -z "$line" ]]; then
      printf '오류: %s — 필수 절이 없습니다: %s\n' "$name" "$section" >&2
      errors=$((errors + 1))
      continue
    fi
    if (( line < prev )); then
      printf '오류: %s — 절 순서가 규칙과 다릅니다: %s\n' "$name" "$section" >&2
      errors=$((errors + 1))
    fi
    prev="$line"
  done

  local deps
  deps="$(sed -n '/^## 의존 관계$/,/^## 용어와 배경$/p' "$doc" || true)"
  if ! printf '%s' "$deps" | grep -q '^```mermaid'; then
    printf '오류: %s — 의존 관계 절에 mermaid 블록이 없습니다.\n' "$name" >&2
    errors=$((errors + 1))
  fi

  local terms
  terms="$(sed -n '/^## 용어와 배경$/,$p' "$doc" || true)"
  if ! printf '%s' "$terms" | grep -q '^| '; then
    printf '오류: %s — 용어와 배경 절에 표가 없습니다.\n' "$name" >&2
    errors=$((errors + 1))
  fi

  if ! printf '%s' "$name" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-f]{7}-.+\.md$'; then
    printf '오류: %s — 파일명이 YYYY-MM-DD-<짧은해시>-<제목>.md 형식이 아닙니다.\n' "$name" >&2
    errors=$((errors + 1))
  fi

  if grep -q '확인 필요:' "$doc"; then
    printf '경고: %s — 확인 필요 표시가 남아 있습니다.\n' "$name" >&2
    warned_docs="$warned_docs $name"
  fi

  if (( errors > 0 )); then
    failed_docs="$failed_docs $name"
    return 1
  fi
  return 0
}

docs=()
if [[ -d "$target" ]]; then
  while IFS= read -r doc; do
    docs+=("$doc")
  done < <(find "$target" -maxdepth 1 -type f -name '*.md' | sort)
  if (( ${#docs[@]} == 0 )); then
    printf '검사할 문서가 없습니다: %s\n' "$target"
    exit 0
  fi
elif [[ -f "$target" ]]; then
  docs=("$target")
else
  printf '오류: %s 경로가 없습니다.\n' "$target" >&2
  exit 1
fi

for doc in "${docs[@]}"; do
  check_doc "$doc" || true
done

if [[ -n "$failed_docs" ]]; then
  printf '학습 문서 검증 실패:%s\n' "$failed_docs" >&2
  exit 1
fi

if [[ -n "$warned_docs" ]]; then
  printf '학습 문서 검증 통과 (확인 필요 표시 있음):%s\n' "$warned_docs"
else
  printf '학습 문서 검증 통과: %s\n' "$target"
fi
