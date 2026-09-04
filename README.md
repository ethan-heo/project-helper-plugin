# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스입니다. 지금은 `project-helper` 하나를 담고 있습니다. 기술적 문제의 해법을 사용자가 직접 설계하도록 돕고, 그 계획서대로 구현하며, 커밋 이력을 학습 문서로 남기는 플러그인입니다.

## 설치

마켓플레이스는 저장소 단위로 한 번만 등록하고, 그 뒤에 필요한 플러그인을 골라 설치합니다. 설치 명령의 인자는 `<플러그인>@helpers` 형식입니다.

**Claude Code**

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@helpers
```

**Codex**

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@helpers
```

설치 결과는 `claude plugin list`와 `codex plugin list`로 각각 확인합니다.

### 갱신

마켓플레이스를 갱신한 뒤 설치해 둔 플러그인을 다시 설치합니다.

**Claude Code**

```
claude plugin marketplace update helpers
claude plugin install project-helper@helpers
```

**Codex**

```
codex plugin marketplace upgrade
codex plugin add project-helper@helpers
```

설치와 갱신 모두 실행 중인 세션에는 적용되지 않습니다. 새로 시작하는 대화부터 스킬을 쓸 수 있습니다.

## project-helper의 스킬

무엇을 만들지 정하는 일부터 커밋을 문서로 남기는 일까지 다섯 스킬이 나눠 맡습니다. 순서대로 다 쓸 수도 있고, 지금 필요한 하나만 쓸 수도 있습니다.

| 스킬 | 언제 쓰는가 | 하는 일 | 남는 산출물 |
| --- | --- | --- | --- |
| `create-prd` | 무엇을 만들지 정하지 못했을 때 | 목적과 요구사항을 질의응답으로 확정 | PRD 한 편 |
| `create-sub-prd` | 요구사항이 뭉뚱그려져 있을 때 | 요구사항을 묶음으로 갈라 옮김 | 하위 PRD 여러 편 |
| `create-plan` | 만들 것은 정해졌고 방법을 정할 때 | 코드베이스 조사 후 해법 선택 | 세 층 구조의 계획서 |
| `impl-plan` | 계획서가 `계획 완료` 상태일 때 | 구현 항목을 하나씩 실행하고 커밋 | 항목별 커밋 |
| `explain-commit` | 커밋 내용을 설명하기 어려울 때 | 커밋을 읽어 학습 문서로 서술 | 커밋마다 문서 한 편 |

명령은 아래처럼 씁니다. 스킬 이름 뒤에 하고 싶은 일을 그대로 적으면 됩니다.

```
/create-prd 브라우저에서 동작하는 간단한 Todo 리스트를 만들고 싶습니다
/create-sub-prd docs/prds/2026-09-04-todo-list.md 를 나눠주세요
/create-plan 하위 PRD 두 편대로 Todo 리스트를 만들 계획서를 써주세요
/impl-plan todo-list 를 진행해주세요
/explain-commit HEAD~4..HEAD
```

### 알아 둘 것

- `create-plan`은 구현 항목 하나가 커밋 하나에 대응하도록 계획을 나눕니다.
- `impl-plan`은 설계의 전제가 바뀌는 사실을 발견하면 멈추고 `create-plan`으로 돌아갑니다.
- `explain-commit`은 코드를 고치지 않습니다. 그 커밋 시점의 기록만 남깁니다.
- 다섯 스킬 가운데 `create-prd`, `create-plan`, `explain-commit`은 앞선 산출물 없이 단독으로 쓸 수 있습니다.

## 사용법 튜토리얼

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽습니다. Todo 리스트를 소재로 다섯 스킬을 부르는 순서와 각 스킬이 남기는 산출물을 예시 문서 전문과 함께 보여 줍니다.
