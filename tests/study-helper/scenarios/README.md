# study-helper 대화 회귀 시나리오

## 목적

세 스킬의 핵심 분기를 입력, 상태, 기록 변화, 금지 동작으로 대조합니다.

## 시나리오

| 번호 | 시나리오 | 구현 항목 |
| --- | --- | --- |
| 01 | [JavaScript 클로저 만들기](01-single-runtime.md) | INIT-FLOW-001 |
| 02 | [복수 런타임 선택](02-multiple-runtimes.md) | INIT-FLOW-001 |
| 03 | [React 재렌더링 원인 찾기](03-install-script-approved.md) | INIT-FLOW-001, INIT-SAFETY-001 |
| 04 | [설치 거절 뒤 재개](04-install-denied-resume.md) | INIT-SAFETY-001 |
| 05 | [옛 기록 변환](05-legacy-record-migration.md) | COMMON-RECORD-001 |
| 06 | [시도 정보가 있는 질문](06-attempt-starts-stage-three.md) | TUTOR-ANSWER-001 |
| 07 | [재설명과 다음 힌트](07-rephrase-and-next-hint.md) | TUTOR-ANSWER-001 |
| 08 | [활동 유형별 완료](08-completion-evidence.md) | TUTOR-COMPLETE-001 |
| 09 | [혼합 진단과 일정 병합](09-review-merge.md) | MANAGER-REVIEW-001 |
| 10 | [기존 저장소 커밋](10-existing-repository-commit.md) | INIT-SAFETY-001 |

## 실행 방법

각 시나리오는 새 대화에서 실행합니다. 기대 상태와 기록 변화를 확인하고 금지 동작이 한 번도 발생하지 않아야 통과입니다.
