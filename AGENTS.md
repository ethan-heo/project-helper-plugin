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
- `project-helper` 플러그인을 로컬에서 테스트용으로 설치하고 다시 설치할 때는 [`plugins/project-helper/docs/도메인_문서/배포와_설치(distribution)/03_API_명세.md`](plugins/project-helper/docs/도메인_문서/배포와_설치%28distribution%29/03_API_명세.md)의 로컬 테스트 설치 절을 참조한다. 이 문서는 `project-helper` 전용이며, 다른 플러그인의 설치 절차는 해당 플러그인의 `docs/`에서 따로 정한다.
