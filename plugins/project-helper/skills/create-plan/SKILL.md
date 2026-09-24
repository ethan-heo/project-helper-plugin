---
name: create-plan
description: 코드 변경이 필요한 요구사항이나 기술적 문제를 받았을 때, 곧바로 구현하지 말고 먼저 구현 계획서를 작성한다. 사용자가 해법을 직접 설계하도록 질문으로 이끌고, 기능 계획서의 요약·상태·설계·구현 순서·테스트 다섯 섹션을 순서대로 채운다. "계획서 쓰자", "구현 방법을 같이 설계해보자", "어떻게 구현할지 정리하자", "이거 어떻게 접근해야 할까" 같은 요청과, 구현 방법을 정하거나 여러 단계가 필요한 작업 요청에서 사용한다. 일정 수립이나 업무 계획, 한 단계로 끝나는 수정, 원인만 밝히면 되는 버그 조사에는 사용하지 않는다. 여러 계획이 따를 구조·패턴·계약을 정하는 일은 create-architecture를 사용한다.
---

# create-plan

## 역할과 목적

`create-plan`은 코드 변경을 바로 구현하지 않고, 사용자와 함께 구현 결정을 좁혀 실행 가능한 계획서로 기록합니다. 사용자는 계획의 결정권자이고, AI는 조사·질문·검토·기록을 맡습니다.

## 실행 원칙

**사용자의 결정은 기록하고, AI의 추정은 표시하며, 문서에 없는 범위는 추가하지 않습니다.**

**호출 후 입력은 [스킬 실행 맥락](../_shared/session.md#입력-해석)에 따라 해석합니다.**

추가 작업은 [계획에 추가 작업 반영](../_shared/session.md#계획에-추가-작업-반영)에 따라 처리합니다.

## 참조 문서 규칙

이 문서가 `create-plan`의 실행 지시사항을 정하는 기준 문서입니다. 작업을 시작할 때 이 문서를 먼저 읽고, 참조 문서는 [참조 파일](#참조-파일) 표가 지정한 시점에만 읽습니다. 참조 문서는 본문에 없는 실행 범위를 추가하지 않습니다.

시작하기 전에 [`roles.md`](references/collaboration/roles.md)와 [`questioning.md`](references/collaboration/questioning.md)를 읽습니다. AI는 관련 파일과 제약을 조사해 제시하고, 해법과 선택은 사용자에게 맡깁니다.

## 계획 작성 절차

### 0. 준비

**요구사항과 저장소를 확인한 다음, 상태를 `초안 작성`으로 둔 빈 양식을 복사합니다.**

| 순서 | 할 일 |
| --- | --- |
| 1 | 요구사항을 확인합니다. 무엇을 원하는지 불분명하면 여기서 한 번 좁힙니다 |
| 2 | [`existing-docs.md`](references/planning/existing-docs.md)를 읽고 프로젝트의 기존 문서를 찾아 읽습니다. 아키텍처 문서의 선행 조건을 아래 분기로 확인합니다 |
| 3 | 관련 파일, 기존 처리 방식, 제약을 찾아 둡니다. 여기서 해법을 만들지는 않습니다 |
| 4 | [`docs-root.md`](../_shared/docs-root.md)를 읽고 문서 루트를 판정한 뒤, 계획서 경로 `<루트>/plans/`가 `.gitignore`에 등록되어 있는지 확인합니다. 없으면 추가합니다 |
| 5 | `assets/plan-template.md`를 복사해 초안 `YYYY-MM-DD-<주제>.md` 하나를 만듭니다 |

**초안을 만들기 전에 아키텍처 문서의 결정으로 요청을 해결할 수 있는지 확인합니다.**

구조 결정의 범위는 [공통 판단 기준](../_shared/architecture.md#구조-결정의-범위)을 따릅니다.

| 선행 상태 | 할 일 |
| --- | --- |
| 아키텍처 문서 없음 | `create-architecture` 실행 후 계획 재개 |
| 요청이 문서의 결정 안에서 해결됨 | 관련 문서 확인과 기준 버전 기록 |
| 문서에 없는 구조 결정이 필요함 | 아키텍처 문서 갱신 후 계획 재개 |
| 계획 설계가 문서의 결정과 어긋남 | 설계 수정·문서 갱신 중 사용자 선택 |

아키텍처 작업을 먼저 해야 하면 [선행 실행과 계획 재개](references/planning/existing-docs.md#선행-실행과-계획-재개)를 따릅니다.

문서 조사와 코드 대조는 [기존 문서 조사의 예외 처리](references/planning/existing-docs.md#예외-처리)를 따릅니다.

문서별 역할과 상태 관리 위치는 [문서 계층](references/documents/hierarchy.md)을 따릅니다.

대화 중에는 초안 한 편에 기록하고, 구현 순서가 정해지면 4-1번에서 디렉터리 구조로 옮깁니다.

### 1~6. 섹션 작성

**위에서부터 순서대로 채우고, 섹션마다 통과 조건을 만족했는지 사용자에게 확인받은 뒤 다음으로 넘어갑니다.**

| 순서 | 섹션 | 지킬 것 |
| --- | --- | --- |
| 1 | 요약(가제) | 목표와 배경만 씁니다. 변경점은 비워 둡니다 |
| 2 | 상태 | 기능 계획서에만 규격대로 자동 생성. 단계 `초안 작성`, 진행률 `0 / 0` |
| 3 | 설계 | 필요한 설계 유형을 제안하고, 사용자가 승인한 유형의 형식으로 해법과 근거를 작성합니다 |
| 4 | 구현 순서 | 한 항목 = 한 커밋 = 되돌릴 수 있는 최소 단위 |
| 4-1 | (경계 긋기) | 도메인과 기능을 가르고 위층부터 구조로 옮깁니다 |
| 5 | 테스트 | 모든 구현 항목이 최소 하나의 검증에 대응 |
| 6 | 요약 확정 | 변경점을 채우고 설계·구현 순서와 대조 |

계획서의 문체와 표기는 [공유 표기 기준](../_shared/writing-style.md)을 따릅니다.

질문·힌트·대안은 [질문과 대안](references/collaboration/questioning.md)을 따릅니다. 카테고리의 답변이 구현자가 추가 질문 없이 작성할 만큼 구체적이면 기록하고 다음으로 넘어갑니다.

확인받지 못한 결정은 확정된 사실처럼 쓰지 않습니다.

**설계 섹션을 작성하기 전에 [`design.md`](references/design.md)를 읽고 해당하는 설계 유형만 제안합니다.**

| 설계 승인 상태 | 할 일 |
| --- | --- |
| 사용자가 유형을 승인함 | 선택한 유형의 형식으로 작성합니다 |
| 사용자가 유형을 승인하지 않음 | 범위를 다시 좁힙니다 |

해당하지 않는 설계 유형은 계획서에 넣지 않습니다.

아키텍처 결정의 인용은 [계획서에 반영하는 방식](references/planning/existing-docs.md#계획서에-반영하는-방식)을 따릅니다.

설계 도중 새로운 구조 결정이나 기존 결정과의 충돌을 발견하면 준비 단계의 분기로 돌아갑니다. 처리한 뒤 해당 설계부터 이어 갑니다.

**설계와 구현 순서가 정해진 뒤 요약의 변경점을 작성합니다.**

실제 변경 범위가 확정된 뒤 작성해야 요약과 구현 순서가 어긋나지 않습니다.

### 4-1. 문서 경계 결정

**[경계 판정](references/planning/boundaries.md)에 따라 경계를 제안하고 사용자 동의를 받습니다.**

**[문서 계층](references/documents/hierarchy.md)에 따라 위층부터 내용을 옮기고 초안을 삭제합니다.**

문서 루트를 최상위 문서에 남기는 이유는 `impl-plan`이 탐색을 다시 하지 않고 같은 위치를 쓰게 하기 위해서입니다. 후보가 여럿이라 사용자에게 물어 정했다면, 그 경로를 프로젝트 지시사항에도 적어 두기를 함께 제안합니다.

### 7. 확정

**구조 이전과 인계 점검을 마치면 단계를 `계획 완료`로 바꿉니다.**

| 순서 | 할 일 |
| --- | --- |
| 1 | 규격과 대조해 표기를 확인합니다 |
| 2 | 미해결 검토 표시가 남아 있으면 표시된 결정을 사용자와 정리합니다. 하나라도 남으면 확정할 수 없습니다 |
| 3 | `writing-style.md`의 어휘 절과 용어 규칙을 세 층 문서 전체에 대조합니다 |
| 4 | 인계 점검을 합니다. 항목마다 "이것만 읽고 무엇을 어디에 할지 정해지는가"를 묻습니다 |
| 5 | 구현 진행률의 전체 수를 구현 항목 수로 맞춥니다 |

확정 직전에는 [아키텍처 기준 버전 확정](references/planning/existing-docs.md#아키텍처-기준-버전-확정)을 따릅니다.

확정하기 전에 `scripts/validate-plan.sh <계획 디렉터리>`로 문서 구조와 상태와 항목 형식을 검사합니다.

구조 이전과 인계 점검이 끝나면 계획서는 로컬에 둔 채 `/impl-plan`으로 진행한다고 안내합니다.

## 경계

- 여러 계획이 따를 구조·패턴·계약은 `/create-architecture`에서 정합니다. 문서가 없거나 새 구조 결정이 필요하면 같은 대화에서 선행 실행한 뒤 계획을 재개합니다.
- 이미 계획서가 있고 상태가 `계획 완료`이면 이 스킬이 아니라 `/impl-plan`입니다.
- 상태가 `완료`면 구현 결과를 확인합니다.
- 사용자가 구현을 직접 요청했지만 계획서가 없으면, 먼저 이 스킬로 계획을 만듭니다.
- `impl-plan`이 계획의 결함을 발견하면 이 스킬로 돌아와 해당 부분을 다시 설계합니다. 이때 요약부터 다시 쓰지 않고 어긋난 곳만 고칩니다.

## 참조 파일

| 읽는 시점 | 참조 파일 | 담는 내용 |
| --- | --- | --- |
| 준비 | [`docs-root.md`](../_shared/docs-root.md), [`scope.md`](references/planning/scope.md), [`existing-docs.md`](references/planning/existing-docs.md), [`format.md`](references/documents/format.md) | 문서 루트 판정, 범위와 기존 문서, 계획서 형식 확인 |
| 질문·대안 | [`questioning.md`](references/collaboration/questioning.md), [`roles.md`](references/collaboration/roles.md), [`questioning-examples.md`](../_shared/questioning-examples.md) | 사용자와 판단을 좁힘 |
| 설계 | [`design.md`](references/sections/design.md), [`design.md`](references/design.md) | 설계 유형과 근거 작성 |
| 경계·이전 | [`boundaries.md`](references/planning/boundaries.md), [`hierarchy.md`](references/documents/hierarchy.md), [`migration.md`](references/documents/migration.md) | 문서 구조 결정·이전 |
| 섹션 작성 | [`summary.md`](references/sections/summary.md), [`design.md`](references/sections/design.md), [`implementation.md`](references/sections/implementation.md), [`testing.md`](references/sections/testing.md), [`structure.md`](references/writing/structure.md), [`markdown.md`](references/writing/markdown.md), [`examples.md`](references/writing/examples.md), [`writing-style.md`](../_shared/writing-style.md) | 섹션과 Markdown 작성, 문체와 표기 |
| 승인·확정 | [`approval.md`](references/collaboration/approval.md), [`format.md`](references/documents/format.md) | 승인과 형식 검증 |
| 계획서 생성 | `assets/plan-template.md`, `assets/index-template.md` | 템플릿 적용 |
