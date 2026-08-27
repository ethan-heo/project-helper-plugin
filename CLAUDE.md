# 프로젝트 지시사항

## 저장소 성격

`project-helper` 플러그인 저장소다. 계획서를 함께 쓰고(`create-plan`), 그 계획서대로 구현하는(`impl-plan`) 두 스킬을 담는다.

## 커밋 규칙

Conventional Commits를 따른다.

```
<type>(<scope>): <설명>
```

- `type`: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- `scope`: 스킬 이름(`create-plan`, `impl-plan`). 저장소 전반이면 생략한다.
- 설명은 한국어 명사형으로 끝낸다. 예: `feat(create-plan): 섹션 기준 참조 문서 추가`

한 커밋은 되돌릴 수 있는 최소 단위다. 계획서의 구현 항목 하나가 커밋 하나에 대응한다.

## 브랜치 병합 규칙

`main`에 병합할 때는 별도 요청이 없으면 fast-forward를 우선한다. `main`에 별도 커밋이 있어 fast-forward가 불가능하면 일반 병합을 사용하고, 작업 브랜치의 병합 경계를 남겨야 할 때만 `--no-ff`를 사용한다.

## 참조 문서 관리

- 문서 구조·배치·참조·갱신을 관리할 때는 [`docs/documentation-management-guide.md`](docs/documentation-management-guide.md)를 참조한다.
- 문서와 프롬프트를 생성하거나 개선할 때는 [`docs/prompt-writing-guide.md`](docs/prompt-writing-guide.md)를 참조한다.

## 로컬 재설치

스킬 파일을 고친 내용은 설치된 플러그인에 자동으로 반영되지 않는다. 저장소 루트에서 아래 순서대로 실행해 현재 작업 디렉터리의 파일을 그대로 다시 설치한다.

```
claude plugin uninstall project-helper@project-helpers
claude plugin marketplace update project-helpers
claude plugin install project-helper@project-helpers
```

`.claude-plugin/marketplace.json`이 이 저장소를 상대 경로로 가리키므로, 위 명령은 원격 저장소를 거치지 않고 로컬 파일만 사용한다. 커밋하지 않은 변경분도 함께 설치된다.

설치 결과는 `claude plugin list`로 확인한다. 버전 표시는 `plugins/project-helper/.claude-plugin/plugin.json`의 값을 따르므로, 변경을 구분하려면 이 파일의 버전을 올린 뒤 재설치한다.

재설치한 내용은 실행 중인 세션에 적용되지 않는다. Claude Code CLI에서는 세션을 종료하고 다시 실행하며, VS Code 확장에서는 명령 팔레트의 `Developer: Reload Window`로 창을 새로 고친 뒤 세션을 다시 시작해야 새 스킬 정의가 적용된다.
