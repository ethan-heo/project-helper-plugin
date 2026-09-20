# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스입니다. 두 플러그인을 담고 있습니다.

| 플러그인 | 하는 일 |
| --- | --- |
| `project-helper` | 제품의 목적과 요구사항, 공용 구조를 문서로 정하고, 구현 계획을 세워 실행하며, 커밋 이력을 학습 문서로 정리 |
| `study-helper` | 수준에 맞는 예제를 내고, 구현 중 질문에 단계를 밟아 답하며, 마친 예제의 복습을 관리 |

## 설치

마켓플레이스는 저장소 단위로 한 번만 등록하고, 그 뒤에 필요한 플러그인을 골라 설치합니다. 설치 명령의 인자는 `<플러그인>@helpers` 형식입니다.

**Claude Code**

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@helpers
/plugin install study-helper@helpers
```

**Codex**

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@helpers
codex plugin add study-helper@helpers
```

설치 결과는 `claude plugin list`와 `codex plugin list`로 각각 확인합니다.

### 갱신

마켓플레이스를 갱신한 뒤 설치해 둔 플러그인을 다시 설치합니다.

**Claude Code**

```
claude plugin marketplace update helpers
claude plugin install project-helper@helpers
claude plugin install study-helper@helpers
```

**Codex**

```
codex plugin marketplace upgrade
codex plugin add project-helper@helpers
codex plugin add study-helper@helpers
```

설치와 갱신 모두 실행 중인 세션에는 적용되지 않습니다. 새로 시작하는 대화부터 스킬을 쓸 수 있습니다.

## project-helper의 스킬

무엇을 만들지 정하는 일부터 커밋을 문서로 남기는 일까지 여섯 스킬이 나눠 맡습니다. 순서대로 다 쓸 수도 있고, 지금 필요한 하나만 쓸 수도 있습니다.

| 스킬 | 언제 쓰는가 | 하는 일 | 남는 산출물 |
| --- | --- | --- | --- |
| `create-prd` | 무엇을 만들지 정하지 못했을 때 | 목적과 요구사항을 질의응답으로 확정 | PRD 한 편 |
| `create-sub-prd` | 요구사항이 뭉뚱그려져 있을 때 | 요구사항을 묶음으로 갈라 옮김 | 하위 PRD 여러 편 |
| `create-architecture` | 여러 계획이 따를 구조를 정할 때 | 구조·패턴·계약을 질의응답으로 확정 | 공용 아키텍처 문서 |
| `create-plan` | 만들 것은 정해졌고 방법을 정할 때 | 코드베이스 조사 후 해법 선택 | 세 층 구조의 계획서 |
| `impl-plan` | 계획서가 `계획 완료` 상태일 때 | 구현 항목을 하나씩 실행하고 커밋 | 항목별 커밋 |
| `explain-commit` | 커밋 내용을 설명하기 어려울 때 | 커밋을 읽어 학습 문서로 서술 | 커밋마다 문서 한 편 |

명령은 아래처럼 씁니다. 스킬 이름 뒤에 하고 싶은 일을 그대로 적으면 됩니다.

```
/create-prd 브라우저에서 동작하는 간단한 Todo 리스트를 만들고 싶습니다
/create-sub-prd docs/prds/2026-09-04-todo-list.md 를 나눠주세요
/create-architecture Todo 리스트의 상태와 화면, 저장 기능 사이의 책임을 함께 정리해주세요
/create-plan 하위 PRD 두 편대로 Todo 리스트를 만들 계획서를 써주세요
/impl-plan todo-list 를 진행해주세요
/explain-commit HEAD~4..HEAD
```

### 알아 둘 것

- `create-plan`은 구현 항목 하나가 커밋 하나에 대응하도록 계획을 나눕니다.
- `impl-plan`은 설계의 전제가 바뀌는 사실을 발견하면 멈추고 `create-plan`으로 돌아갑니다.
- `explain-commit`은 코드를 고치지 않습니다. 그 커밋 시점의 기록만 남깁니다.
- `create-prd`, `create-architecture`, `explain-commit`은 앞선 스킬의 산출물 없이 단독으로 쓸 수 있습니다.
- `create-plan`은 단독으로 호출할 수 있습니다. 아키텍처 문서가 없거나 새 구조 결정이 필요하면 `create-architecture`를 먼저 실행한 뒤 계획 작성으로 돌아갑니다.
- 계획서에는 기준 아키텍처 버전을 남깁니다. `impl-plan`은 현재 문서와 주 버전이 다르면 구현을 중단하고 계획 재검토를 안내합니다.

## study-helper의 스킬

설명을 듣는 대신 직접 구현하며 배우는 스킬입니다. 예제를 받는 `init`, 구현 중 묻는 `tutor`, 마친 뒤 복습하는 `manager` 셋으로 이루어집니다.

| 스킬 | 언제 쓰는가 | 하는 일 |
| --- | --- | --- |
| `init` | 새 기술로 예제를 시작할 때 | 수준에 맞는 예제 하나와 학습 환경을 준비 |
| `tutor` | 예제를 구현하다 모르는 것이 생겼을 때 | 답변 단계를 정해 그 범위까지만 답변 |
| `manager` | 마친 예제를 복습하고 다음 학습을 정할 때 | 복습 질문과 이해 수준 진단, 다음 학습 제안 |

```
/study-helper:init WebRTC Signaling
/study-helper:init 트랜잭션 src/payment/
/study-helper:tutor
/study-helper:manager
```

`init`은 기술 이름만 주어도 되고, 보고 있던 코드나 문서를 함께 건네도 됩니다. 건넨 자료는 수준을 판정하는 근거로만 쓰이고 예제 폴더로 옮겨지지 않습니다.

예제를 시작할 때 `tutor`를 따로 부르지 않습니다. `init`이 안에서 수준을 묻고 학습 목표를 정합니다.

`tutor`는 예제 폴더 안에서 부릅니다. 처음 물으면 무엇을 시도했고 어디서 막혔는지 되묻고, 더 알려 달라고 할 때만 한 단계씩 넓혀 답합니다. 해결 방법은 마지막 단계에서야 나옵니다.

`manager`는 예제 폴더가 아니라 그 폴더들이 놓인 학습 공간에서 부릅니다. 예제를 마친 직후에 부르면 코드를 보지 말고 설명해 달라고 하고, 그 답을 기록에 남깁니다. 나중에 다시 부르면 복습할 때가 된 예제를 보여 줍니다.

### 알아 둘 것

- 예제를 완성하는 코드는 알려 주지 않습니다. 의존성은 수준에 맞는 깊이까지만 설명합니다.
- 학습자 수준은 입문·초급·중급·숙련 넷이며, 사용자가 직접 고릅니다. 수준에 따라 예제를 어디까지 만들어 주는지가 달라집니다.
- 예제 폴더는 `init`을 부른 디렉터리 아래에 `<기술>-<만들 대상>` 이름으로 생기고, 안에 `README.md`·`TASK.md`·`PLAN.md` 셋이 들어갑니다.
- 학습 기록은 예제 폴더 밖의 `.study/records/`에 예제마다 하나씩 쌓입니다. 나중에 `manager`가 이 기록으로 복습 질문을 냅니다.
- 답변 단계는 예제마다 하나씩 기록에 남습니다. 대화를 닫았다 다시 열어도 받던 자리에서 이어집니다.
- 앞 질문과 다른 주제를 물으면 단계가 처음으로 돌아갑니다. 새 질문에 곧바로 해결 방법이 나오지 않게 하기 위해서입니다.
- `PLAN.md`는 사용자가 쓰는 문서입니다. `tutor`는 읽기만 하고 고치지 않습니다.
- 복습 시점은 예제를 마친 날로부터 1일·3일·7일·14일입니다. 그때가 됐다고 먼저 알려 주지는 않으므로 사용자가 `manager`를 불러야 합니다.
- 복습 답변은 학습 목표에 닿았는지로 가립니다. `tutor`에게 도움을 많이 받았던 부분은 이번에 설명이 되더라도 진단 근거에 남습니다.
- 예제 폴더는 Git 저장소로 준비되고, 코드를 쓰기 전 상태가 첫 커밋으로 남습니다. `git diff`로 자기가 쓴 코드만 확인하고, 막히면 첫 커밋으로 되돌아가 다시 시도할 수 있습니다.

## 사용법 튜토리얼

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽습니다. Todo 리스트를 소재로 여섯 스킬을 부르는 순서와 각 스킬이 남기는 산출물을 예시 문서 전문과 함께 보여 줍니다.
