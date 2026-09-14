# tech-learning-helper 아키텍처

## 버전 표

| 항목 | 값 |
| --- | --- |
| 버전 | 2.1 |
| 마지막 갱신 | 2026-09-14 14:38 |

## 시스템의 목적

개발자는 공식 문서를 기초 개념부터 차례로 읽느라 당장 필요하지 않은 개념까지 거치고, 그 과정에서 지치거나 포기합니다. 이 플러그인은 동작하는 예제에서 학습을 시작하고, 학습자가 '왜?'와 '어떻게?'를 물으며 원리를 찾아가게 합니다.

## 공통 개념 모델

| 개념 | 뜻 |
| --- | --- |
| 학습 목표 | 학습자가 이번 학습으로 이해하려는 동작이나 개념 |
| 기술 지식 | 한 기술의 개념·관계·선수 지식·예제·예제별 질문 묶음 |
| 예제 | 학습 목표를 담은, 바로 실행할 수 있는 코드 |
| 탐색 질문 | 예제의 코드와 동작 안에서 나오는 '왜?'·'어떻게?' 질문 |
| 학습 상태 | 발견·부분 이해·미공개 개념과 다음 탐색 후보 |
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
| 2.1 | 2026-09-14 14:38 | README.md, learning-flow.md, learning-record.md | 이어 하기 후보를 최근 저장소 하나에서 최근 순 저장소 목록과 기존 학습 패키지 목록으로 넓힘 |
| 2.0 | 2026-09-14 12:46 | README.md, decisions.md, learning-flow.md, learning-workspace.md | Codex 지원을 위해 학습 폴더 위치를 도구와 무관한 설정 파일로 받도록 AD-008을 AD-011로 대체 |
| 1.0 | 2026-09-14 12:36 | README.md, decisions.md, learning-flow.md, technology-knowledge.md, learning-workspace.md, learning-record.md | 첫 확정 |
