#!/usr/bin/env bash
set -euo pipefail

source_root="${1:?사용법: compare-install.sh <소스 플러그인> <설치 플러그인>}"
installed_root="${2:?사용법: compare-install.sh <소스 플러그인> <설치 플러그인>}"

[[ -d "$source_root" ]] || {
  printf '오류: 소스 플러그인이 없습니다: %s\n' "$source_root" >&2
  exit 1
}

[[ -d "$installed_root" ]] || {
  printf '오류: 설치 플러그인이 없습니다: %s\n' "$installed_root" >&2
  exit 1
}

if ! diff -qr "$source_root" "$installed_root"; then
  printf '오류: 소스와 설치본이 다릅니다.\n' >&2
  exit 1
fi

printf 'study-helper 설치본 비교 통과\n'
