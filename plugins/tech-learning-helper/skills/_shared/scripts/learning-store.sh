#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/store-common.sh"

source "$STORE_SCRIPTS/store-transaction.sh"

[[ $# == 2 ]] || store_fail usage 'learning-store.sh <context|review-data> <패키지>'
mode="$1"
store_init "$2"
case "$mode" in
  context | review-data)
    store_read_lock
    store_load
    goal="$(store_goal)" || store_fail invalid_goal '학습 목표 절을 읽을 수 없습니다'
    filter='context($goal; $package)'
    [[ "$mode" == review-data ]] && filter='review_data($goal; $package)'
    jq -c -L "$STORE_SCRIPTS" --argjson goal "$goal" --arg package "$STORE_PACKAGE" \
      "include \"learning-store\"; $filter" <<<"$STORE_BUNDLE"
    ;;
  *) store_fail usage '지원하지 않는 명령입니다' ;;
esac
