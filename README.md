# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스입니다. 두 플러그인을 담고 있습니다.

| 플러그인 | 하는 일 |
| --- | --- |
| `project-helper` | 제품의 목적과 요구사항, 공용 구조를 문서로 정하고, 구현 계획을 세워 실행하며, 커밋 이력을 학습 문서로 정리 |
| `study-helper` | 활동과 목표에 맞는 과제·시작 자료·계획 초안을 내고, 구현 중 질문과 완료 확인, 복습을 관리 |

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
| `init` | 새 기술로 예제를 시작할 때 | 활동·수준·시작 자료를 차례로 확정하고 과제와 환경을 준비 |
| `tutor` | 예제를 진행하다 모르는 것이 생기거나 결과를 확인받고 싶을 때 | 질문별 단계에 맞게 답하고 근거를 확인한 뒤 완료를 기록 |
| `manager` | 완료된 예제를 복습하고 다음 학습을 정할 때 | 목표별 복습 질문과 세 단계 진단, 다음 학습 제안 |

```
/study-helper:init WebRTC Signaling
/study-helper:init 트랜잭션 src/payment/
/study-helper:tutor
/study-helper:manager
```

`init`은 기술 이름만 주어도 되고, 보고 있던 코드나 문서를 함께 건네도 됩니다. 건넨 자료는 활동 후보와 수준을 정하는 근거로만 쓰이고 예제 폴더로 옮겨지지 않습니다.

`init`은 배우려는 계기와 마쳤을 때 할 수 있게 되고 싶은 일을 먼저 묻습니다. 학습 활동을 확정한 뒤 질문을 최대 세 개까지 드립니다. 답을 근거로 수준을 추천하면 사용자가 그대로 받거나 고쳐 최종 확정합니다. 수준은 설명과 힌트의 깊이만 정합니다.

활동과 목표에 맞는 시작 자료도 `init`이 추천하고 사용자가 최종 확정합니다. 생성된 `TASK.md`에는 요구 동작과 산출물 경로가, `PLAN.md`에는 권장 설계와 작업 체크리스트 초안이 들어갑니다. 사용자는 계획 초안을 검토·수정한 뒤 구현을 시작합니다.

만들기 활동에는 공개 API만 있는 미구현 뼈대와 핵심 동작 테스트가 제공됩니다. 나머지 필수 테스트와 구현은 사용자가 작성합니다. 원인 찾기·동작 관찰·방식 비교 활동에는 증상이나 결과를 다시 확인할 실행·측정 수단이 제공됩니다.

`tutor`는 예제 폴더 안에서 부릅니다. 시도와 막힌 지점이 모두 있으면 3단계에서, 정보가 빠졌으면 2단계에서 시작합니다. 다른 표현이나 같은 범위의 예시를 요청하면 단계를 유지합니다. 다음 힌트나 더 직접적인 방법을 요청할 때만 한 단계 올립니다. 만들기 활동은 제공 테스트 보존, 사용자 테스트, 전체 성공과 개념 설명을 확인한 뒤에만 완료로 기록합니다.

`manager`는 예제 폴더가 아니라 그 폴더들이 놓인 학습 공간에서 부릅니다. `tutor`가 완료로 기록한 예제만 복습합니다. 코드나 `TASK.md`, `PLAN.md`를 다시 읽지 않고 목표별 진단 기준과 질문 이력으로 독립 설명·부분 이해·재학습 필요 중 하나를 기록합니다.

### 알아 둘 것

- 예제를 완성하는 코드는 알려 주지 않습니다. 의존성은 수준에 맞는 깊이까지만 설명합니다.
- 학습자 수준은 입문·초급·중급·숙련 넷입니다. `init`이 활동별 답변을 근거로 추천하고 사용자가 최종 확정합니다.
- 예제 폴더는 `init`을 부른 디렉터리 아래에 `<기술>-<학습 활동 요약>` 이름으로 생깁니다. `README.md`·`TASK.md`·`PLAN.md`와 UUID v4를 담은 `.study-id`가 있습니다.
- 학습 기록은 학습 공간의 `.study/records/<UUID>.md`에 YAML 머리말과 Markdown 본문으로 쌓입니다.
- 도움 단계는 예제별 한 개가 아니라 질문 주제별 최댓값을 기록합니다. 대화를 닫았다 다시 열어도 같은 주제의 단계를 이어갑니다.
- 앞 질문과 다른 주제를 물으면 단계가 처음으로 돌아갑니다. 새 질문에 곧바로 해결 방법이 나오지 않게 하기 위해서입니다.
- `PLAN.md`는 `init`이 과제별 초안을 만들고 사용자가 검토·수정합니다. `tutor`는 읽기만 하고 고치지 않습니다.
- 복습 시점은 예제 완료일로부터 1일·3일·7일·14일입니다. 재학습이 필요하면 다음 날 보충 복습을 추가하고, 기본 복습과 같은 날이면 한 번으로 합칩니다.
- 복습 답변은 목표별 진단 기준과 질문 이력으로 판정합니다. 결과는 독립 설명·부분 이해·재학습 필요 중 하나입니다.
- 예제 폴더를 Git 저장소로 만들거나 기준 커밋을 남기는 일은 사용자가 승인할 때만 진행합니다.

## 사용법 튜토리얼

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽습니다. Todo 리스트를 소재로 여섯 스킬을 부르는 순서와 각 스킬이 남기는 산출물을 예시 문서 전문과 함께 보여 줍니다.
