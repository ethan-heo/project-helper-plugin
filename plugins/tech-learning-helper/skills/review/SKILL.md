---
name: review
description: 학습자가 `/tech-learning-helper:review`로 직접 호출할 때만 사용한다. Claude Code의 내장 `/review`(코드 리뷰)와 이름이 겹치므로 플러그인 이름을 붙여 부른다. 학습 패키지 하나의 학습 목표, 다룬 질문, 발견한 개념, 부분 이해 개념, 다음 탐색 후보를 그 패키지의 상태 파일에서 모아 채팅으로 보여 준다. 새 파일을 만들거나 커밋하지 않는다. 새 세션에서도 예제를 만들지 않고 정리할 학습을 고르게 하며, 정리 뒤에는 다음 탐색 후보에서 학습을 이어 간다. 학습자가 호출하지 않은 일반 질문이나 코드 작업에는 사용하지 않는다.
disable-model-invocation: true
---

# review

## 역할과 목적

`review`는 학습 패키지 하나에서 배운 내용을 채팅으로 보여 줍니다.

호출 명령은 `/tech-learning-helper:review`입니다. Claude Code의 내장 `/review`는 코드 리뷰 명령이므로 플러그인 이름을 붙입니다.

## 실행 원칙

**정리할 내용과 표시 방법은 [학습 정리 규칙](../_shared/rules/review.md)을 따릅니다.**

## 참조 문서 규칙

이 문서가 `review`의 실행 절차를 정하는 기준 문서입니다. 아래 표의 시점에 지정한 문서만 읽습니다.

| 문서 | 맡는 일 | 읽는 시점 |
| --- | --- | --- |
| [`rules/session.md`](../_shared/rules/session.md) | 학습 상태 판정, 경로 중단, 학습 재개 | 호출하자마자와 정리 뒤 학습을 이어 갈 때 |
| [`rules/workspace.md`](../_shared/rules/workspace.md) | 설정 파일과 학습 폴더 | 진행 중인 학습이 없을 때 |
| [`rules/resume.md`](../_shared/rules/resume.md) | 번호 입력 해석, 이어 하기 목록 | 정리할 학습을 고를 때 |
| [`rules/resume-commit.md`](../_shared/rules/resume-commit.md) | 중단된 변경 커밋 | 커밋되지 않은 변경이 있을 때만 |
| [`rules/review.md`](../_shared/rules/review.md) | 학습 정리 값 옮기기와 표시 순서 | 정리할 때 |
| [`roles/knowledge-navigator.md`](../_shared/roles/knowledge-navigator.md) | 끝나지 않은 경로와 다음 탐색 후보 | 경로 도중에 불렸을 때와 정리가 끝날 때 |

## 실행 절차

**[진행 중인 학습의 판정](../_shared/rules/session.md#진행-중인-학습의-판정)에 따라 정리할 패키지를 선택합니다.**

| 호출 상황 | 할 일 |
| --- | --- |
| 진행 중인 학습이 있음 | 지금 학습하는 패키지를 정리 |
| 진행 중인 학습이 없음 | `session.md`의 이어 하기 목록 확인과 목록 선택 뒤 고른 패키지를 정리 |
| 학습 폴더에 기술 저장소가 하나도 없음 | 정리할 학습이 없다고 알리고 끝냄. 저장소를 만들지 않음 |
| 설명 경로 도중에 호출 | [경로 중단 처리](../_shared/rules/session.md#경로-중단-처리) 뒤 현재 패키지 정리 |

진행 중인 학습이 없으면 아래 절차로 기존 패키지를 선택합니다. 저장소·패키지를 새로 만들거나 예제를 준비하지 않습니다.

1. **학습 폴더를 확인한다** — `session.md`의 1단계를 따릅니다.
2. **정리할 학습을 고른다** — 기술 이름 없이 부르면 기술 저장소 목록에서, 기술 이름과 함께 부르면 학습 패키지 목록에서 고르게 합니다(`resume.md`의 이어 하기 목록). 저장소 목록에서 고르면 그 저장소의 마지막 학습 패키지를 정리합니다.
3. **학습 상태를 읽는다** — `session.md`의 6단계를 따릅니다.

### 정리

**[학습 정리 규칙](../_shared/rules/review.md#2-값-옮기기)에 따라 값을 옮기고, [표시 절차](../_shared/rules/review.md#3-표시)를 따릅니다.**

### 정리 뒤

정리를 마치면 패키지 `state.json`의 `nextCandidates`에서 2~3개를 번호로 제시합니다.

학습자가 후보를 고르면 `session.md`의 7단계로 예제와 지식을 준비한 뒤, 그 후보의 설명 경로를 관찰 유도로 시작합니다. 이후 질문은 `session.md`의 배정 표로 받습니다.

## 경계

- 학습자가 `/tech-learning-helper:review`로 호출하지 않은 질문이나 코드 작업에는 이 스킬을 쓰지 않습니다.
- 학습 폴더와 범위 밖 기능의 경계는 `session.md`를 따릅니다.
