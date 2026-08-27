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

## Codex 플러그인 개발·재설치

Codex 플러그인은 설치할 때 로컬 소스를 캐시에 복사한다. 캐시를 끄거나 파일 변경을 자동 반영하는 공식 개발 모드는 없으므로, 소스 파일을 수정한 뒤에는 플러그인을 재설치하고 새 대화에서 확인한다.

개인 마켓플레이스가 별도 로컬 사본을 참조하는 경우 저장소의 플러그인 디렉터리를 해당 경로에 심링크로 연결할 수 있다. 심링크는 재설치할 때 최신 소스를 사용하게 할 뿐, 실행 중인 캐시를 갱신하지는 않는다.

```bash
codex plugin remove project-helper@personal
rm -rf ~/.codex/plugins/cache/personal/project-helper
codex plugin add project-helper@personal
```

플러그인을 삭제할 때는 해당 플러그인의 캐시 디렉터리도 함께 삭제한다. 전체 캐시 디렉터리는 삭제하지 않는다. 재설치 전에 캐시버스터를 갱신해야 변경된 플러그인을 확실히 인식한다. 개발 중에는 플러그인 업데이트 도구를 사용하고, 마켓플레이스 설정 파일은 직접 수정하지 않는다.
