# tech-learning-helper 아키텍처

## 버전 표

| 항목 | 값 |
| --- | --- |
| 버전 | 6.1 |
| 마지막 갱신 | 2026-09-16 23:16 |

## 시스템의 목적

개발자는 공식 문서를 기초 개념부터 차례로 읽느라 당장 필요하지 않은 개념까지 거치고, 그 과정에서 지치거나 포기합니다. 이 플러그인은 동작하는 예제에서 학습을 시작하고, 학습자가 '왜?'와 '어떻게?'를 물으며 원리를 찾아가게 합니다.

## 공통 개념 모델

| 개념 | 뜻 |
| --- | --- |
| 학습 목표 | 학습자가 이번 학습으로 이해하려는 동작이나 개념 |
| 기술 지식 | 한 기술의 개념·관계·선수 지식·예제·예제별 질문 묶음 |
| 예제 | 학습 목표를 담은, 바로 실행할 수 있는 코드 |
| 탐색 질문 | 예제의 코드와 동작 안에서 나오는 '왜?'·'어떻게?' 질문 |
| 사전 안내 | 설명 경로에 들어가기 전 주는 범위·용어 설명·관찰 대상 묶음 |
| 학습 상태 | 질문별 진행 상태, 발견·부분 이해 개념과 다음 탐색 후보 |
| 가져온 자료 | 학습자가 코드·링크·파일 경로로 넘긴 학습 대상 |
| 사용자 스킬 | 학습자가 부르는 `learn`·`structure`·`trace`·`experiment`·`review` |

## 영역 목록

| 영역 | 파일 | 담당 범위 |
| --- | --- | --- |
| 학습 진행 | [learning-flow.md](learning-flow.md) | 기술과 무관한 가르치는 방법 |
| 기술 지식 | [technology-knowledge.md](technology-knowledge.md) | 기술 지식의 생성·저장·재사용 |
| 학습 작업 공간 | [learning-workspace.md](learning-workspace.md) | 예제를 만들고 실행하는 위치와 단위 |
| 학습 기록 | [learning-record.md](learning-record.md) | 학습 상태와 질의응답 기록 |

## 변경 이력

| 버전 | 갱신 시각 | 바뀐 파일 | 변경 요약 |
| --- | --- | --- | --- |
| 6.1 | 2026-09-16 23:16 | README.md, learning-flow.md, learning-record.md | 질문 상태를 질문 파일로 옮긴 구조를 반영하고, 이미 해소된 위험 항목을 정리함 |
| 6.0 | 2026-09-16 22:30 | README.md, decisions.md, learning-flow.md, technology-knowledge.md | 사전 안내의 범위를 예제에서 관찰할 수 있는 것으로 정하고, 용어를 정체·역할·구성 요소·사용 시점 순서로 서술하며, 선행 관계 순으로 배열해 저장 순서대로 보여 줌. 안내에 담긴 용어를 되물으면 요청 없이 다시 설명하고, 작성 기준 표시가 없는 안내는 한 번 다시 만듦 |
| 5.0 | 2026-09-16 10:27 | decisions.md, learning-flow.md, technology-knowledge.md, question-gate.md, knowledge-navigator.md, example-builder.md | 생소한 질문에 범위·관계·용어·관찰 대상을 먼저 안내하고, 범위 밖 개념은 다음 후보로 보류하며, 안내를 질문별 `orientation`으로 저장 |
| 4.0 | 2026-09-15 09:10 | README.md, decisions.md, learning-record.md, learning-flow.md | 저장소 루트 파일에서 진행 중인 패키지 포인터와 세션·입력 상태를 빼고, 패키지 이름·마지막 활동 날짜 인덱스로 바꿈. 새 세션은 이어 하기 목록에서 패키지를 고른 뒤에만 그 패키지 파일로 재개 |
| 3.0 | 2026-09-15 08:19 | README.md, decisions.md, technology-knowledge.md, learning-record.md, learning-flow.md | 개념 목록(`knowledge.md`)과 정리 산출물(`summary.md`)을 없애고, 상태 파일을 패키지 단위 파일과 저장소 루트 요약 파일로 재구성 |
| 2.4 | 2026-09-14 18:10 | decisions.md, learning-record.md | 기록을 날짜 디렉터리와 질문별 파일로 분리 |
| 2.3 | 2026-09-14 18:10 | decisions.md, learning-record.md | 중간 세션 재개 상태를 `state.json`으로 분리 |
| 2.2 | 2026-09-14 17:32 | README.md, learning-flow.md, learning-record.md | `review`는 예제 준비 없이 학습 선택과 상태 읽기만 거치고, 질의응답 기록을 받는 계약 추가 |
| 2.1 | 2026-09-14 14:38 | README.md, learning-flow.md, learning-record.md | 이어 하기 후보를 최근 저장소 하나에서 최근 순 저장소 목록과 기존 학습 패키지 목록으로 넓힘 |
| 2.0 | 2026-09-14 12:46 | README.md, decisions.md, learning-flow.md, learning-workspace.md | Codex 지원을 위해 학습 폴더 위치를 도구와 무관한 설정 파일로 받도록 AD-008을 AD-011로 대체 |
| 1.0 | 2026-09-14 12:36 | README.md, decisions.md, learning-flow.md, technology-knowledge.md, learning-workspace.md, learning-record.md | 첫 확정 |
