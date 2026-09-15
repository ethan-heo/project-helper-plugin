# 학습 상태 명령

## 목적

조회·저장 명령의 입출력과 실패 처리를 정합니다. 설명과 상태 변경의 판단은 AI가 맡고, 파일 처리는 스크립트가 맡습니다.

## 호출

**필요한 명령을 한 번 호출하고 JSON 결과를 사용합니다. 스크립트 구현 전문을 읽거나 같은 파일 처리를 직접 반복하지 않습니다.**

스크립트는 `<플러그인 경로>/skills/_shared/scripts/learning-store.sh`입니다. 실행 환경은 Bash·jq·Git입니다.

| 명령 | 호출 시점 | 결과 |
| --- | --- | --- |
| `context <패키지>` | 선택한 패키지 재개 | 현재 질문·상태·학습 목표 |
| `review-data <패키지>` | 학습 정리 | 질문별 정보·누적 상태 |
| `save-turn <패키지>` | 일반 답변 또는 실험 기록 | 요청 ID·변경 파일 |
| `finish-question <패키지>` | 질문의 설명 경로 종료 | 요청 ID·변경 파일 |

조회 결과의 `recordPath`는 기록 파일 경로입니다. 대화 맥락이 부족할 때만 필요한 부분을 추가로 읽습니다. 현재 세션에서 이미 받은 상태와 지침이 유효하면 다시 조회하지 않습니다.

## 저장 입력

**저장 명령은 표준 입력으로 JSON 객체 하나를 받습니다. 설명을 저장할 때 줄이거나 다시 작성하지 않습니다.**

```bash
bash <플러그인 경로>/skills/_shared/scripts/learning-store.sh save-turn <패키지> < <요청 JSON 파일>
```

요청 JSON은 인용된 heredoc으로 같은 도구 호출 안에서 전달해도 됩니다. 발화 내용을 셸 코드로 실행하거나 해석하지 않도록 전달합니다. 요청 파일은 커밋에 포함하지 않습니다.

```json
{
  "operationId": "turn-20260915-001",
  "questionId": "javascript-counter-2",
  "records": [{
    "questionId": "javascript-counter-2",
    "turns": [
      {"speaker": "학습자", "type": "답변", "text": "증가가 먼저 일어납니다."},
      {"speaker": "assistant", "type": "관찰 유도", "text": "다음 출력값도 확인해 보세요."}
    ]
  }],
  "progress": {"stepIndex": 2, "stage": "관찰 유도", "awaiting": "학습 답변"},
  "learning": {"addDiscoveredConcepts": ["증가 연산"], "partialConcepts": []}
}
```

| 필드 | 규칙 |
| --- | --- |
| `operationId` | 저장마다 새 ID, 재시도는 같은 ID |
| `questionId` | 진행 상태를 갱신할 질문 |
| `records` | 질문별 발화, 기존 기록에 추가 |
| `progress` | 현재 단계·공개 수준·기대 입력 |
| `learning` | 판단한 학습 상태 변경분 |

`progress.awaiting`에는 학습자가 반드시 해야 할 입력 하나를 명사구로 적습니다. 실험 결과처럼 선택 입력은 넣지 않고 `lastTurn.type`으로 판단합니다. 값의 예시는 [패키지 state.json 양식](resume.md#패키지-statejson)을 따릅니다.

`records`에는 해당 응답에서 기록할 발화만 넣습니다. 현재 질문의 마지막 발화는 assistant의 설명이어야 합니다. 학습자 발화는 원문 그대로, 설명의 `type`은 공개 수준·`현상`·`실험` 중 하나입니다. 학습자 인용문과 발화 제목은 스크립트가 만듭니다. 예제 파일의 링크는 기록 파일을 기준으로 작성합니다.

질문을 바꿀 때는 이전 질문의 현상 설명과 새 질문의 질의응답을 각각 별도 `records` 항목으로 전달합니다. 이전 질문의 남은 위치는 `learning.nextCandidates`에 포함합니다. 학습자의 새 질문을 이전 질문 기록에 중복해서 넣지 않습니다.

`learning.addDiscoveredConcepts`는 기존 이름에 합쳐지고, `partialConcepts`와 `nextCandidates`는 전달된 배열로 교체됩니다. 생략한 값은 유지하며 빈 배열은 비우라는 뜻입니다. `lastTurn`은 마지막 발화에서 계산합니다.

`finish-question`에는 마지막 발화와 다음 후보를 함께 전달합니다. 같은 응답에 `save-turn`을 먼저 부르지 않습니다. 마지막 기록·질문 완료·패키지 상태·저장소 인덱스가 함께 저장됩니다. 실험은 `save-turn`으로 기록하며, 완료한 질문도 `type: 실험`, `stepIndex: null`로 저장할 수 있습니다. 실험 절 제목은 스크립트가 추가합니다.

## 재개 위치와 후보

현재 위치 `stepIndex`와 중단한 질문의 `resumeStep`은 1부터 셉니다. 공개 수준 `stage`와 구분합니다.

| 후보 종류 | 값 |
| --- | --- |
| 새 탐색 질문 | `kind: new`, `label` |
| 중단한 질문 | `kind: resume`, `label`, `questionId`, `resumeStep` |
| 미분류 기존 후보 | `kind: legacy`, `label` |

`context.needsPositionConfirmation`이 참이면 해당 질문을 재개할 때 위치를 확인합니다. `resumeStep: null`인 후보나 `legacy` 후보는 선택된 때에만 질문과 위치를 확인합니다. 그 전에는 원문을 보존하고 다른 질문의 학습을 진행할 수 있습니다. 새 후보의 설명 경로는 선택받은 뒤 만듭니다.

기존 문자열 후보는 조회 때 변환된 값으로 반환되고 다음 저장 때 반영됩니다. 질문 ID와 단계가 명시되지 않은 문장에서 위치를 임의로 추정하지 않습니다.

## 실패 처리

**오류를 저장 성공으로 보고하지 않습니다. 저장 요청의 ID와 원문은 재시도할 때까지 유지합니다.**

| 오류 | 할 일 |
| --- | --- |
| `busy` | 다른 저장 종료 후 같은 요청 재시도 |
| `recovery_required` | 아래 복구 절차 후 조회 재시도 |
| `duplicate_id` | 기존 요청과 새 응답을 구분해 ID 확인 |
| 입력·참조 오류 | 원본을 유지한 채 잘못된 입력 확인 |
| `write_failed` | 복구 결과 확인 후 같은 요청 재시도 |
| `recovery_failed` | 새 저장 중단, 원본 사본 보존 안내 |

조회 중 `recovery_required`가 나오면, 진행 중인 다른 저장이 끝난 뒤 `questions-store.sh migrate <패키지>`를 호출합니다. 이 명령은 남은 저장 작업을 먼저 복구하며, 구형 질문이 없으면 질문 이전은 하지 않습니다. 저장 실패라면 원래 저장 명령에 같은 JSON을 다시 전달해도 복구 후 재시도합니다.

복구용 데이터와 요청 기록은 Git 관리 디렉터리에 보관됩니다. 이를 학습 자료로 읽거나 커밋하지 않습니다. 전체 검증과 커밋 시점은 [학습 기록 규칙](record.md#커밋-규칙)을 따릅니다.
