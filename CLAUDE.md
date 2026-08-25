# 프로젝트 지시사항

## 저장소 성격

`project-helper` 플러그인 저장소다. 계획서를 함께 쓰고(`create-plan`), 그 계획서대로 구현하고(`implement`), 결과를 검증하는(`verify`) 세 스킬을 담는다.

## 커밋 규칙

Conventional Commits를 따른다.

```
<type>(<scope>): <설명>
```

- `type`: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- `scope`: 스킬 이름(`create-plan`, `implement`, `verify`) 또는 `shared`. 저장소 전반이면 생략한다.
- 설명은 한국어 명사형으로 끝낸다. 예: `feat(create-plan): 섹션 기준 참조 문서 추가`

한 커밋은 되돌릴 수 있는 최소 단위다. 계획서의 구현 항목 하나가 커밋 하나에 대응한다.

## 계획서 경로

생성되는 계획서는 `docs/plans/YYYY-MM-DD-<주제>.md`에 둔다.

## 작성 언어

문서와 커밋 메시지는 한국어로 쓴다. 코드 식별자와 파일명은 영문 kebab-case를 쓴다.

## 스킬 파일 규약

- 플러그인 내부 경로는 `${CLAUDE_PLUGIN_ROOT}`를 기준으로 표기한다. 절대 경로를 박지 않는다.
- `SKILL.md` 본문은 200줄 안팎으로 유지하고, 세부 판정 기준은 `references/`로 뺀다.
