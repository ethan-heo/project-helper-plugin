---
name: structure
description: 학습자가 `/structure`로 직접 호출할 때만 사용한다. 학습 중인 예제를 구조 관점으로 곧바로 전환해, 파일·컴포넌트·모듈이 어떻게 나뉘어 있고 각 부분이 무엇을 맡는지 학습자가 찾게 한다. 질문과 함께 부르면 그 질문을, 질문 없이 부르면 구조 관점 탐색 질문 후보에서 시작한다. 학습자가 호출하지 않은 일반 질문이나 코드 작업에는 사용하지 않는다.
disable-model-invocation: true
---

# structure

## 역할과 목적

`structure`는 학습 중인 예제의 설명을 구조 관점으로 곧바로 전환하는 단축키입니다. 학습자가 질문 문장에 관점을 드러내지 않아도, 역할·책임·경계·의존성·데이터 소유권처럼 코드를 실행하지 않아도 보이는 구조부터 설명합니다.

## 실행 원칙

**첫 설명만 구조 관점으로 시작하고, 그 설명 경로가 끝난 뒤에는 [`session.md`](../_shared/rules/session.md)의 배정 표로 질문을 이어 받습니다.**

## 참조 문서 규칙

이 문서가 `structure`의 실행 절차를 정하는 기준 문서입니다. 아래 표의 시점에 지정한 문서만 읽고, 나머지 문서는 `session.md`의 참조 문서 표가 정한 시점에 읽습니다.

| 문서 | 맡는 일 | 읽는 시점 |
| --- | --- | --- |
| [`rules/store.md`](../_shared/rules/store.md) | 공용 조회·저장 명령 | 첫 상태 조회·저장 시 |
| [`rules/session.md`](../_shared/rules/session.md) | 시작 절차, 질문 배정, 경로 마무리 | 호출하자마자 |
| [`roles/knowledge-navigator.md`](../_shared/roles/knowledge-navigator.md) | 설명 경로 선택과 끝나지 않은 경로 | 첫 설명의 경로를 고를 때 |
| [`roles/example-builder.md`](../_shared/roles/example-builder.md) | 구조 관점 경로와 탐색 질문 생성 | 저장된 구조 관점 경로가 없을 때 |
| [`roles/question-gate.md`](../_shared/roles/question-gate.md) | 공개 단계와 전이 표 | 경로의 단계마다 |
| [`roles/structure-explainer.md`](../_shared/roles/structure-explainer.md) | 구조 관점 설명 | 경로의 단계마다 |

## 실행 절차

**[단축키 호출 처리](../_shared/rules/session.md#단축키-호출-처리)에 따라 첫 설명을 준비합니다.**

### 첫 설명

| 호출 | 할 일 |
| --- | --- |
| 질문과 함께 호출 | 그 질문의 구조 관점 설명 경로를 관찰 유도로 시작 |
| 질문 없이 호출 | 아래 설명 경로 선택 규칙에 따라 후보 제시 |

**[설명 경로 선택](../_shared/roles/knowledge-navigator.md#1-설명-경로-선택)에 따라 구조 관점의 경로를 고릅니다.**

경로 진행은 [Knowledge Navigator](../_shared/roles/knowledge-navigator.md#3-경로-진행)를, 경로가 끝난 뒤에는 [경로 마무리](../_shared/rules/session.md#경로-마무리)를 따릅니다.

## 경계

- 학습자가 `/structure`로 호출하지 않은 질문이나 코드 작업에는 이 스킬을 쓰지 않습니다.
- 학습 폴더와 범위 밖 기능의 경계는 `session.md`를 따릅니다.
