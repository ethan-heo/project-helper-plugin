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

- 문서 구조·배치·참조·갱신을 관리할 때는 [`docs/문서_작성_기준.md`](docs/문서_작성_기준.md)를 참조한다.
- 문서와 프롬프트를 생성하거나 개선할 때는 [`docs/프롬프트_작성_가이드.md`](docs/프롬프트_작성_가이드.md)를 참조한다.
- 스킬이 만드는 산출물의 문체·표기·용어를 정할 때는 [`plugins/project-helper/skills/_shared/writing-style.md`](plugins/project-helper/skills/_shared/writing-style.md)를 참조한다. 새 스킬도 이 문서를 참조하도록 만든다.
