#!/usr/bin/env bash
set -euo pipefail

docs_root="${1:?사용법: validate-docs.sh <문서 루트 디렉터리> }"
errors=0
fail() { printf '오류: %s\n' "$1" >&2; errors=$((errors + 1)); }

[[ -d "$docs_root" ]] || { printf '오류: %s 디렉터리가 없습니다.\n' "$docs_root" >&2; exit 1; }

require_file() {
  [[ -f "$1" ]] || fail "${1} 파일이 없습니다."
}

require_sections() {
  local file="$1"; shift
  [[ -f "$file" ]] || return 0
  local section
  for section in "$@"; do
    grep -qE "^#{2,3} $section" "$file" || fail "${file}에 '$section' 절이 없습니다."
  done
}

check_unresolved() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if grep -q '<!-- 미확인:' "$file"; then
    fail "${file}에 미확인 표시가 남아 있습니다."
  fi
}

require_file "$docs_root/글로벌_아키텍처_가이드.md"
require_sections "$docs_root/글로벌_아키텍처_가이드.md" \
  '시스템 개요' '도메인 구성' '기술 스택' '인프라' '공통 보안 원칙' '공통 컨벤션'

common_dir="$docs_root/공통_인프라_및_컨벤션"
require_file "$common_dir/공통_에러_코드.md"
require_sections "$common_dir/공통_에러_코드.md" \
  '에러 응답 형식' '공통 코드 목록' '도메인별 코드 규칙'
require_file "$common_dir/인증_및_인가_가이드.md"
require_sections "$common_dir/인증_및_인가_가이드.md" \
  '인증 방식' '인가 규칙' '실패 처리'

domain_root="$docs_root/도메인_문서"
if [[ ! -d "$domain_root" ]]; then
  fail "${domain_root} 디렉터리가 없습니다."
else
  domains="$(find "$domain_root" -mindepth 1 -maxdepth 1 -type d)"
  [[ -n "$domains" ]] || fail '도메인 디렉터리가 하나도 없습니다.'
  while IFS= read -r domain; do
    [[ -n "$domain" ]] || continue
    require_file "$domain/01_도메인_개요.md"
    require_sections "$domain/01_도메인_개요.md" \
      '도메인 정의' '유비쿼터스 용어 사전' '핵심 비즈니스 규칙'
    require_file "$domain/02_도메인_모델.md"
    require_sections "$domain/02_도메인_모델.md" \
      '엔티티와 값 객체' '데이터베이스 스키마'
    require_file "$domain/03_API_명세.md"
    require_sections "$domain/03_API_명세.md" \
      '엔드포인트 목록' '이벤트 메시징'
    require_file "$domain/04_도메인_특화_가이드.md"
    require_sections "$domain/04_도메인_특화_가이드.md" \
      '외부 의존성' '핵심 테스트 시나리오' '트러블슈팅'
  done <<< "$domains"
fi

while IFS= read -r file; do
  check_unresolved "$file"
done < <(find "$docs_root" -type f -name '*.md')

(( errors == 0 )) || exit 1
printf '개발 문서 검증 통과: %s\n' "$docs_root"
