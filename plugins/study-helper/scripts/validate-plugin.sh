#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="${1:-$(cd "$script_dir/.." && pwd)}"
errors=0

fail() {
  printf '오류: %s\n' "$1" >&2
  errors=$((errors + 1))
}

require_file() {
  local path="$1"
  [[ -f "$plugin_root/$path" ]] || fail "필수 파일이 없습니다: $path"
}

validate_json() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    jq empty "$path" >/dev/null 2>&1 || return 1
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$path" >/dev/null 2>&1 || return 1
  elif command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$path" >/dev/null 2>&1 || return 1
  else
    fail 'JSON을 검사할 jq, python3, node 중 하나가 필요합니다.'
    return 0
  fi
}

for path in \
  .codex-plugin/plugin.json \
  .claude-plugin/plugin.json \
  references/learning-model.md \
  references/record-contract.md \
  references/writing-style.md \
  skills/init/SKILL.md \
  skills/init/references/environment.md \
  skills/init/references/input-safety.md \
  skills/tutor/SKILL.md \
  skills/tutor/references/answering.md \
  skills/tutor/references/completion.md \
  skills/manager/SKILL.md \
  skills/manager/references/review.md; do
  require_file "$path"
done

for manifest in "$plugin_root/.codex-plugin/plugin.json" "$plugin_root/.claude-plugin/plugin.json"; do
  [[ -f "$manifest" ]] || continue
  validate_json "$manifest" || fail "JSON 형식이 잘못되었습니다: ${manifest#"$plugin_root/"}"
done

for skill in init tutor manager; do
  skill_file="$plugin_root/skills/$skill/SKILL.md"
  [[ -f "$skill_file" ]] || continue
  for reference in learning-model record-contract writing-style; do
    grep -q "../../references/$reference.md" "$skill_file" || fail "$skill가 $reference.md를 참조하지 않습니다."
  done
done

while IFS= read -r markdown; do
  while IFS= read -r link; do
    target="${link#](}"
    target="${target%)}"
    target="${target%%#*}"
    [[ -z "$target" || "$target" == http://* || "$target" == https://* ]] && continue
    resolved="$(cd "$(dirname "$markdown")" && pwd)/$target"
    [[ -e "$resolved" ]] || fail "깨진 링크: ${markdown#"$plugin_root/"} -> $target"
  done < <(grep -Eo '\]\([^)]+' "$markdown" | sed 's/$/)/' || true)
done < <(find "$plugin_root" -type f -name '*.md' | sort)

((errors == 0)) || exit 1
printf 'study-helper 플러그인 검사 통과: %s\n' "$plugin_root"
