# 학습 기록 계약

## 목적

세 스킬이 예제 폴더의 이름과 관계없이 같은 기록을 찾고 안전하게 갱신하게 합니다.

## 위치와 식별

**예제를 만들 때 UUID v4를 발급하고 두 위치에 같은 값을 기록합니다.**

| 위치 | 내용 |
| --- | --- |
| `<예제 폴더>/.study-id` | UUID 한 줄 |
| `<학습 공간>/.study/records/<UUID>.md` | 학습 기록 전체 |

기록의 `folder`는 학습 공간 기준 상대 경로입니다. 예제 폴더 이름이 바뀌면 `.study-id`로 기록을 찾고 `folder`만 현재 경로로 고칩니다.

## YAML 머리말

**기계가 읽고 분기하는 값은 YAML 머리말에 기록합니다.**

| 묶음 | 필드 | 형식 |
| --- | --- | --- |
| 식별 | `schema_version` | 정수 `2` |
| 식별 | `example_id` | UUID v4 |
| 식별 | `display_name` | `<기술> — <학습 활동>` |
| 식별 | `folder` | 상대 경로 |
| 상태 | `status` | `preparing`, `ready`, `in_progress`, `completed` |
| 수준 | `recommended_level` | `입문`, `초급`, `중급`, `숙련` |
| 수준 | `final_level` | `입문`, `초급`, `중급`, `숙련` |
| 수준 | `level_reason` | 추천 근거 한 문장 |
| 환경 | `language` | 언어 이름 |
| 환경 | `runtime` | 런타임 이름과 버전 |
| 시각 | `created_at` | ISO 8601 시각 |
| 시각 | `ready_at` | ISO 8601 시각 또는 `null` |
| 시각 | `started_at` | ISO 8601 시각 또는 `null` |
| 시각 | `completed_at` | ISO 8601 시각 또는 `null` |
| 복구 | `baseline_commit` | 커밋 해시 또는 `null` |
| 준비 | `preparation_step` | 마지막으로 성공한 준비 단계 |
| 준비 | `preparation_error` | 실패 원인 또는 `null` |
| 복습 | `next_supplemental_review_at` | `YYYY-MM-DD` 또는 `null` |

문자열은 YAML 문자열로 해석되도록 따옴표로 감쌉니다. 값이 아직 없으면 빈 문자열 대신 `null`을 씁니다.

## Markdown 본문

**사람이 읽고 이어서 작성하는 내용은 다음 네 절에 둡니다.**

| 절 | 쓰는 스킬 | 내용 |
| --- | --- | --- |
| 학습 목표와 진단 기준 | `init` | 목표 ID와 진단 기준·완성 조건 |
| 질문 이력 | `tutor` | 주제 ID와 최대 단계·해결 근거 |
| 배운 내용 | `manager` | 목표별 사용자 설명 |
| 복습 이력 | `manager` | 일정·질문·목표별 진단 |

질문 이력은 주제마다 행 하나를 유지합니다. 같은 주제에서는 최대 도움 단계만 높이고 다른 주제의 행을 덮어쓰지 않습니다.

## 상태와 시각

| 전이 | 갱신 값 |
| --- | --- |
| 기록 생성 | `status: preparing`, `created_at`, 준비 단계 |
| 준비 완료 | `status: ready`, `ready_at`, 오류 제거 |
| 첫 `tutor` 호출 | `status: in_progress`, `started_at` |
| 완성 조건 확인 | `status: completed`, `completed_at` |

실패하면 `status: preparing`을 유지하고 `preparation_step`과 `preparation_error`를 갱신합니다.

## 기존 기록 변환

**스키마 버전이 없거나 `2`보다 낮은 기록은 읽기 전에 한 번 변환합니다.**

1. 원본을 `.study/backups/<YYYY-MM-DD-HHMMSS>/` 아래 같은 파일 이름으로 복사합니다.
2. UUID v4를 발급하고 예제 폴더에 `.study-id`를 만듭니다.
3. 완료 날짜가 있으면 `completed`, 질문 이력이 있으면 `in_progress`, 나머지는 `ready`로 추론합니다.
4. 옛 기록의 기술과 학습 활동을 `display_name`으로 합칩니다.
5. 옛 목표, 질문 이력, 배운 내용, 복습 이력을 새 절로 옮깁니다.
6. 새 파일을 `<UUID>.md`로 쓴 뒤 옛 기록을 삭제합니다.

변환에 실패하면 새 기록과 `.study-id`를 제거하고 원본과 백업을 유지합니다. 변환한 것처럼 실행을 이어 가지 않습니다.

## 충돌과 복구

| 예외 조건 | 할 일 |
| --- | --- |
| `.study-id`가 없고 옛 기록이 있음 | 폴더 이름으로 한 번 찾은 뒤 변환 |
| `.study-id`와 기록 ID가 다름 | 어느 쪽도 수정하지 않고 두 경로 안내 |
| 같은 UUID의 기록이 둘 이상임 | 쓰지 않고 충돌한 파일 모두 안내 |
| 기록 변환이 실패함 | 원본과 백업 유지 후 스킬 실행 중단 |
| 기록 필수 필드가 없음 | 쓰지 않고 누락 필드 안내 |
