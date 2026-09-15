---
name: experiment
description: 학습자가 `/experiment`로 직접 호출할 때만 사용한다. 방금 이해한 내용을 예제의 값이나 호출 순서를 바꿔 실행하거나 구조를 비교해 직접 확인하게 한다. 확인 내용과 함께 부르면 그 내용으로, 확인 내용 없이 부르면 마지막으로 끝낸 설명 경로를 찾아 확인 방법을 제안한다. 학습자가 호출하지 않은 일반 질문이나 코드 작업에는 사용하지 않는다.
disable-model-invocation: true
---

# experiment

## 역할과 목적

`experiment`는 설명을 듣고 이해한 내용을 예제 실험으로 확인하게 하는 단축키입니다.

## 실행 원칙

**첫 설명만 확인 방법 제안과 실험으로 시작하고, 실험이 끝난 뒤에는 [`session.md`](../_shared/rules/session.md)의 배정 표로 질문을 이어 받습니다.**

## 참조 문서 규칙

이 문서가 `experiment`의 실행 절차를 정하는 기준 문서입니다. 아래 표의 시점에 지정한 문서만 읽고, 나머지 문서는 `session.md`의 참조 문서 표가 정한 시점에 읽습니다.

| 문서 | 맡는 일 | 읽는 시점 |
| --- | --- | --- |
| [`rules/store.md`](../_shared/rules/store.md) | 공용 조회·저장 명령 | 첫 상태 조회·저장 시 |
| [`rules/session.md`](../_shared/rules/session.md) | 시작 절차, 질문 배정, 경로 마무리 | 호출하자마자 |
| [`rules/record.md`](../_shared/rules/record.md) | 기록 파일, 실험 기록, 실험 커밋 | 확인 대상을 찾을 때와 실험을 기록할 때 |
| [`roles/experiment-designer.md`](../_shared/roles/experiment-designer.md) | 확인 방법 제안, 전후 비교, 실험 커밋 | 확인 방법을 제안할 때와 실험이 끝날 때 |
| [`roles/knowledge-navigator.md`](../_shared/roles/knowledge-navigator.md) | 끝나지 않은 경로와 다음 탐색 후보 | 경로 도중에 불렸을 때와 실험이 끝날 때 |

## 실행 절차

**[단축키 호출 처리](../_shared/rules/session.md#단축키-호출-처리)에 따라 첫 설명을 준비합니다.**

### 첫 설명

"배열에 직접 넣으면 어떻게 돼?"처럼 확인 내용과 함께 부르면 그 내용으로 실험합니다. 확인 내용 없이 부르면 확인 대상을 아래 순서로 찾고, Experiment Designer로 그 대상의 확인 방법을 제안합니다.

1. 이 세션에서 마지막으로 끝낸 설명 경로
2. 학습 패키지 `records/` 아래 날짜 디렉터리와 순번 파일 가운데 가장 늦은 질문 파일
3. 둘 다 없으면 확인할 설명이 아직 없다고 알리고, 탐색 질문 후보 2~3개를 번호로 제시

2번에서 찾은 질문은 확인 방법을 제안하기 전에 학습자에게 알립니다.

3번에서 학습자가 후보를 고르면 그 질문의 설명 경로를 관찰 유도로 시작합니다.

### 실험 뒤

**[Experiment Designer](../_shared/roles/experiment-designer.md)의 결과 비교·기록·커밋 절차를 따릅니다.**

이후 질문은 [질문 유형별 배정](../_shared/rules/session.md#질문-유형별-배정)으로 받습니다.

## 경계

- 학습자가 `/experiment`로 호출하지 않은 질문이나 코드 작업에는 이 스킬을 쓰지 않습니다.
- 학습 폴더와 범위 밖 기능의 경계는 `session.md`를 따릅니다.
