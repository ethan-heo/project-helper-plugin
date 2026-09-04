# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스다.

| 플러그인 | 목적 |
| --- | --- |
| `project-helper` | 기술적 문제의 해법을 사용자가 직접 설계하도록 돕고, 그 계획서대로 구현하며, 커밋 이력을 학습 문서로 남긴다 |

## 설치

마켓플레이스는 저장소 단위로 한 번만 등록하고, 그 뒤에 필요한 플러그인을 골라 설치한다. 설치 명령의 인자는 `<플러그인>@helpers` 형식이다.

### Claude Code

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@helpers
```

설치 결과는 `claude plugin list`로 확인한다.

### Codex

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@helpers
```

설치 결과는 `codex plugin list`로 확인한다.

### 갱신

마켓플레이스를 갱신한 뒤 설치해 둔 플러그인을 다시 설치한다.

```
claude plugin marketplace update helpers
claude plugin install project-helper@helpers
```

```
codex plugin marketplace upgrade
codex plugin add project-helper@helpers
```

설치와 갱신 모두 실행 중인 세션에는 적용되지 않는다. 새로 시작하는 대화부터 스킬을 쓸 수 있다.

## 사용법

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽는다. Todo 리스트를 소재로 스킬 다섯 개를 부르는 순서와 각 스킬이 남기는 산출물을 순서대로 보여 준다.

### project-helper

무엇을 만들지 정하는 일부터 커밋을 문서로 남기는 일까지 다섯 스킬이 나눠 맡는다. 다섯 개를 순서대로 쓸 수도 있고, 지금 필요한 하나만 쓸 수도 있다.

| 스킬 | 언제 쓰는가 | 남는 산출물 |
| --- | --- | --- |
| `create-prd` | 무엇을 만들지 아직 정하지 못했을 때 | PRD 한 편 |
| `create-sub-prd` | PRD가 커서 요구사항이 뭉뚱그려져 있을 때 | 하위 PRD 여러 편 |
| `create-plan` | 만들 것은 정해졌고 방법을 정할 때 | 세 층 구조의 계획서 |
| `impl-plan` | 계획서가 `계획 완료` 상태일 때 | 항목별 커밋과 갱신된 계획서 |
| `explain-commit` | 커밋 내용을 다시 설명하기 어려울 때 | 커밋마다 학습 문서 한 편 |

#### create-prd

목적과 요구사항을 질의응답으로 확정해 PRD 한 편으로 남긴다. 여덟 카테고리를 순서대로 물으며, 구현 방식은 다루지 않는다.

```
/create-prd 브라우저에서 동작하는 간단한 Todo 리스트를 만들고 싶습니다
```

#### create-sub-prd

확정된 PRD의 요구사항을 묶음 단위로 갈라 하위 PRD 여러 편으로 옮긴다. 묶음 후보는 상위 PRD의 사용 상황에서 끌어오고, 상위 문서는 목차 역할로 정리한다.

```
/create-sub-prd docs/prds/2026-09-04-todo-list.md 를 나눠주세요
```

#### create-plan

코드베이스를 조사해 제약을 제시하고, 사용자가 해법을 고르게 한 뒤 계획서로 남긴다. 요약·상태·설계·구현 순서·테스트 다섯 섹션을 위에서부터 확정한다. 구현 항목 하나가 커밋 하나에 대응한다.

```
/create-plan 하위 PRD 두 편대로 Todo 리스트를 만들 계획서를 써주세요
```

#### impl-plan

`계획 완료` 상태의 계획서를 입력으로 받아 구현 순서를 하나씩 실행한다. 항목마다 검증을 통과시키고 커밋하며, 계획서의 진행률과 기록 줄을 갱신한다. 설계의 전제가 바뀌는 사실을 발견하면 멈추고 `create-plan`으로 돌아간다.

```
/impl-plan todo-list 를 진행해주세요
```

#### explain-commit

지정한 커밋을 읽어 학습 문서로 남긴다. 커밋 하나가 문서 한 편이며, 변경 전 상태와 의도, 실행 흐름, 의존 관계를 고정된 절 순서로 담는다. 코드는 고치지 않는다.

```
/explain-commit HEAD~4..HEAD
```
