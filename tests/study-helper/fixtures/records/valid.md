---
schema_version: 2
example_id: "123e4567-e89b-42d3-a456-426614174000"
display_name: "HTTP — 캐시 동작 관찰"
folder: "http-cache-observe"
status: "ready"
recommended_level: "초급"
final_level: "초급"
level_reason: "응답 헤더를 읽고 결과를 설명할 수 있습니다."
language: "JavaScript"
runtime: "Node.js 24"
created_at: "2026-09-23T10:00:00+09:00"
ready_at: "2026-09-23T10:05:00+09:00"
started_at: null
completed_at: null
baseline_commit: "0123456789abcdef"
preparation_step: "ready"
preparation_error: null
next_supplemental_review_at: null
---

# HTTP — 캐시 동작 관찰

## 학습 목표와 진단 기준

### G1 — 캐시 재검증

- 목표: 캐시가 만료되면 재검증 요청이 발생하는 이유를 설명한다.
- 배경 문제: 불필요한 본문 전송을 구분해야 한다.
- 필수 개념: 조건부 요청
- 필수 근거: 304 응답
- 대표 오개념: 만료되면 항상 본문을 다시 받는다.
- 완성 조건: 304 응답을 재현한다.

## 질문 이력

| 주제 ID | 질문 주제 | 연결 목표 | 최대 도움 단계 | 해결 여부 | 확인 근거 |
| --- | --- | --- | --- | --- | --- |

## 배운 내용

### G1


## 복습 이력

| 예정일 | 실행일 | 질문 | 목표별 진단 | 비고 |
| --- | --- | --- | --- | --- |
