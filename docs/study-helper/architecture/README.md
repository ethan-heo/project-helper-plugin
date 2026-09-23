# study-helper 아키텍처

## 버전 표

| 항목 | 값 |
| --- | --- |
| 버전 | 5.2 |
| 마지막 갱신 | 2026-09-23 15:05 |

## 시스템의 목적

기술을 혼자 공부하는 개발자가 설명을 듣는 대신 예제를 직접 구현하며 배우게 하는 플러그인입니다. Claude Code와 Codex에서 함께 씁니다. 예제를 만드는 일과 학습 방향을 정하고 질문에 답하는 일과 배운 내용을 관리하는 일을 각각 `init`·`tutor`·`manager`가 맡습니다.

요구사항은 [PRD](../prds/2026-09-20-학습-플러그인-개편/README.md)의 R1~R17을 따릅니다.

## 공통 개념 모델

| 개념 | 뜻 |
| --- | --- |
| 예제 | 학습 활동과 완성 조건을 적은 과제 하나. 만들기뿐 아니라 원인 찾기, 동작 관찰도 과제가 된다 |
| 예제 폴더 | 예제 하나의 코드·의존성·예제 정보를 담는 폴더 |
| 학습 활동 | 예제에서 사용자가 하는 일. 시작 상태·산출물·확인 방법의 세 속성으로 풀어 적는다 |
| 예제 정보 | 예제 폴더에 기록한 기술·학습 활동과 세 속성·수준·학습 목표·완성 조건 |
| 학습자 수준 | `tutor` 기준의 추천을 사용자가 확정한 네 구분 |
| 답변 단계 | 질문에 어디까지 알려 줄지 정한 다섯 단계 |
| 예제 ID | 폴더 이름과 무관하게 예제와 기록을 잇는 식별자 |
| 예제 상태 | `preparing`·`ready`·`in_progress`·`completed`의 네 단계 |
| 학습 기록 | 상태·수준·질문 이력·배운 내용·복습 이력을 담은 문서 |
| 복습 시점 | 예제를 마친 날로부터 1일·3일·7일·14일이 지난 네 시점 |
| 사용자 스킬 | 사용자가 부르는 `init`·`tutor`·`manager` |

## 영역 목록

| 영역 | 파일 | 담당 범위 |
| --- | --- | --- |
| 학습 진행 | [learning-flow.md](learning-flow.md) | 스킬별 동작과 정보의 전달 |
| 학습 작업 공간 | [learning-workspace.md](learning-workspace.md) | 예제 폴더와 기록의 위치·단위·설치 |

## 변경 이력

| 버전 | 갱신 시각 | 바뀐 파일 | 변경 요약 |
| --- | --- | --- | --- |
| 5.2 | 2026-09-23 15:05 | README.md, decisions.md, learning-flow.md | 질문 정보에 따른 도움 단계와 해결 판정 계약 추가 |
| 5.1 | 2026-09-23 14:58 | README.md, decisions.md, learning-flow.md | 활동 선택 뒤 수준을 추천·확정하는 초기 질문 계약 추가 |
| 5.0 | 2026-09-23 14:46 | README.md, decisions.md, learning-flow.md, learning-workspace.md | 예제 상태 전이와 안정적인 기록 식별·누적 계약 추가 |
| 4.1 | 2026-09-22 22:58 | README.md, decisions.md, learning-flow.md, learning-workspace.md | 활동 속성의 `출발점`을 `시작 상태`로 이름 변경 |
| 4.0 | 2026-09-22 22:41 | README.md, decisions.md, learning-flow.md, learning-workspace.md | 예제를 학습 활동 단위로 넓히고, `init`이 묻고 `tutor` 기준으로 판단하도록 역할을 나누며, 산출물 비워 두기와 요청 시 결과 확인을 추가 |
| 3.1 | 2026-09-20 17:20 | learning-workspace.md | 기록 파일 생성 주체를 `init`으로 지정 |
| 3.0 | 2026-09-20 16:40 | README.md, decisions.md, learning-flow.md, learning-workspace.md, learning-principles.md 삭제 | 스킬을 `init`·`tutor`·`manager` 셋으로 개편하고 학습 기록과 답변 단계를 추가 |
| 2.0 | 2026-09-20 12:33 | README.md, decisions.md, learning-flow.md, learning-workspace.md | tutor 스킬 추가와 작업 계획 쓰기 주체 변경 |
| 1.1 | 2026-09-20 09:56 | README.md, decisions.md, learning-flow.md, learning-workspace.md | 작업 계획 문서 추가 |
| 1.0 | 2026-09-19 23:41 | README.md, decisions.md, learning-flow.md, learning-workspace.md, learning-principles.md | 첫 확정 |
