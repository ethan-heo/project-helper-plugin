# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스입니다. 두 플러그인을 담고 있습니다.

| 플러그인 | 하는 일 |
| --- | --- |
| `project-helper` | 제품의 목적과 요구사항, 공용 구조를 문서로 정하고, 구현 계획을 세워 실행하며, 커밋 이력을 학습 문서로 정리 |
| `study-helper` | 배우고 싶은 기술로 직접 구현할 과제를 내고, 과제 폴더와 의존성을 준비 |

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

설명을 듣는 대신 직접 구현하며 배우는 스킬입니다. 지금은 `study` 하나이며, 힌트와 피드백은 다음에 추가합니다.

| 스킬 | 언제 쓰는가 | 하는 일 | 남는 산출물 |
| --- | --- | --- | --- |
| `study` | 관심 가는 기술을 공부하려 할 때 | 배울 범위를 좁혀 과제 하나를 내고 환경을 준비 | 과제 폴더와 `README.md`, `TASK.md`, `PLAN.md`, 첫 커밋 |

```
/study-helper:study WebRTC Signaling
/study-helper:study React 상태 관리
```

부르면 그 기술로 무엇을 만들 수 있게 되고 싶은지 묻고, 답한 범위에서 과제를 냅니다. 같은 디렉터리에서 같은 기술로 다시 부르면 앞선 과제와 겹치지 않는 과제가 나옵니다.

### 알아 둘 것

- 과제를 푸는 코드는 알려 주지 않습니다. 의존성은 하는 일과 쓰는 시점까지만 설명합니다.
- 과제 폴더는 `study`를 부른 디렉터리 아래에 `<기술>-<만들 대상>` 이름으로 생깁니다.
- 과제 폴더의 `README.md`는 과제 소개와 각 파일의 역할을 담습니다. 폴더를 다시 열었을 때 여기부터 읽으면 됩니다.
- `PLAN.md`는 사용자가 채우는 문서입니다. 설계와 구현 단계, 막힌 점, 설계 변경을 적습니다.
- 과제 폴더는 Git 저장소로 준비되고, 코드를 쓰기 전 상태가 첫 커밋으로 남습니다. `git diff`로 자기가 쓴 코드만 확인하고, 막히면 첫 커밋으로 되돌아가 다시 시도할 수 있습니다.
- 학습 기조는 [`plugins/study-helper/skills/_shared/learning-principles.md`](plugins/study-helper/skills/_shared/learning-principles.md)에 있습니다. 원칙을 고치면 `study`의 적용 규칙도 함께 고칩니다.

## 사용법 튜토리얼

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽습니다. Todo 리스트를 소재로 여섯 스킬을 부르는 순서와 각 스킬이 남기는 산출물을 예시 문서 전문과 함께 보여 줍니다.
