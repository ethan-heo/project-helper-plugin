# 학습 재개 규칙

## 목적

새 세션은 이전 대화를 기억하지 못합니다. 이 문서는 새 세션에서 이어 할 학습을 고르게 하고, 중단된 설명 경로를 멈춘 단계에서 다시 시작하는 방법을 정합니다.

## 핵심 지시

**재개 여부는 기술 저장소 루트의 `state.json`으로 판단하고, 진행 중인 패키지가 있으면 그 패키지 안의 `state.json`으로 현재 질문을 판단합니다. 기록 파일 전문에서 추정하지 않습니다.**

누적 학습 상태(발견한 개념·부분 이해 개념·다음 탐색 후보)는 진행 중이거나 고른 패키지의 `state.json`에서 읽습니다. 기록 파일은 질의응답을 보존할 때 근거로 쓰는 파일이므로, 어떤 질문을 진행하던 중이었는지 판단하는 데는 쓰지 않습니다.

## 세션 상태

`sessionStatus`는 `idle`, `awaiting_selection`, `in_progress`, `recovery_required` 중 하나이고, `inputMode`는 `selection` 또는 `learning`입니다. 둘 다 저장소 `state.json`에 있습니다. `inputMode`는 저장소나 패키지 목록을 보여 준 직후에만 `selection`으로 두고, 선택을 마치면 곧바로 `learning`으로 바꿉니다.

| `inputMode` | 학습자가 입력한 번호의 뜻 |
| --- | --- |
| `selection` | 방금 보여 준 목록에서 고른 항목 |
| `learning` | 현재 공개 단계에 대한 학습 답변. 번호로 시작하는 답변도 목록 선택으로 처리하지 않음 |

학습자 입력 전후에는 진행 중인 패키지의 `state.json`에서 현재 질문, 공개 단계, 다음 기대 입력, 마지막 발화 유형을 갱신합니다. 설명 경로가 끝나면 저장소 `state.json`의 `activePackage`를 `null`로, `sessionStatus`를 `idle`로 바꿉니다([학습 기록 규칙](record.md#2-설명-경로-종료)).

## 절차 흐름

### 1. 세션 상태 읽기

**학습을 시작하면 저장소 `state.json`을 먼저 읽고, 아래 표로 재개 여부를 정합니다.**

| 발견한 것 | 할 일 |
| --- | --- |
| `in_progress`이고 `activePackage`가 있음 | 목록을 보여 주지 않고, 그 패키지 `state.json`의 `record`가 가리키는 질문 파일에서 `stage`와 `awaiting`부터 이어 감 |
| `idle`이나 `awaiting_selection` | 시작 절차대로 이어 하기 목록이나 학습 목표 판정으로 진행 |
| `recovery_required` | 2절의 복구 확인부터 진행 |
| 저장소 `state.json`이 없음 | 2절에 따라 기존 파일을 확인하고 상태 파일을 만듦 |
| JSON 형식이나 필수 필드가 잘못됨 | 어긋난 부분을 알리고, 학습자가 재개할 질문을 확인한 뒤에만 파일을 새로 씀 |
| `activePackage`가 가리키는 패키지의 `state.json`이 없음 | `recovery_required`로 보고 2절의 복구 확인부터 진행 |

### 2. 기존 저장소 복구와 이전

**저장소를 열었을 때 구형 루트 `state.json`(`package` 필드가 있는 형태)이나 `state.md`·`knowledge.md`·`summary.md`가 있으면, 아래 표대로 새 구조로 옮긴 뒤 옛 파일을 지우고 [중단된 변경 커밋](#4-중단된-변경-커밋)과 같은 방식으로 커밋합니다.**

| 옛 파일·필드 | 새 위치 |
| --- | --- |
| 구형 루트 `state.json`의 `package`·`record`·`activeQuestion`·`viewpoint`·`path`·`stage`·`awaiting`·`nextCandidates`·`lastTurn` | 그 패키지의 `state.json` |
| 구형 루트 `state.json`의 `sessionStatus`·`inputMode` | 저장소 `state.json`에 그대로 |
| `state.md`의 발견한 개념(패키지별) | 각 패키지 `state.json`의 `discoveredConcepts`. 이름만 모아 저장소 `state.json`의 `discoveredConcepts`에도 더함 |
| `state.md`의 부분 이해 개념·다음 탐색 후보 | `state.md`의 마지막 학습 패키지의 `state.json` |
| `state.md`의 미공개 개념, `knowledge.md` | 버림(어디에도 옮기지 않음) |
| `records/` 안 각 질문 기록 파일 | 구형 `state.json`이 가리키는 기록이면 `status: 진행`, 나머지는 `status: 완료` |
| `summary.md` | 버림(패키지 `state.json`이 같은 정보를 담음) |

이전 대상 파일이 서로 어긋나면(예: `state.md`는 있는데 구형 `state.json`이 없음) 자동으로 옮기지 않고 학습자에게 상태를 확인받습니다. 구형과 신형 상태 파일이 동시에 있으면 신형을 우선하고 구형은 지웁니다.

**이전할 구형 파일이 없고 저장소 `state.json`도 없거나 `recovery_required`이면, 기록 전문에서 현재 질문을 정하지 않고 커밋되지 않은 기록 변경을 기준으로 재개 상태를 만듭니다.**

| 발견한 것 | 할 일 |
| --- | --- |
| 진행 중인 기록 변경이 없음 | `sessionStatus: idle` 저장소 `state.json` 생성 |
| 기록 변경이 있고 현재 질문을 하나로 확인할 수 있음 | 그 질문과 공개 단계를 학습자에게 확인받은 뒤 `in_progress` 저장소 `state.json`과 해당 패키지 `state.json` 생성 |
| 기록 변경이 있지만 현재 질문이 모호함 | `recovery_required` 저장소 `state.json`을 만든 뒤 재개할 질문을 확인 |

복구를 확인하기 전에는 이어 하기 목록을 보여 주지 않습니다. 학습자가 재개할 질문을 고르면 그 질문·기록 파일을 해당 패키지 `state.json`에 저장하고, 저장소 `state.json`의 `activePackage`를 그 패키지로, `inputMode: learning`으로 시작합니다.

### 3. 이어 하기 목록

**새 세션에서 이어 할 학습을 고르게 할 때, 아래 두 목록 중 요청에 맞는 것을 번호 목록으로 보여 줍니다.**

| 목록 | 보여 주는 때 | 한 줄의 내용 | 정렬 |
| --- | --- | --- | --- |
| 기술 저장소 목록 | 기술 이름 없이 `learn`을 호출함 | 저장소 이름, 마지막 학습 패키지, 마지막 커밋 날짜 | 마지막 커밋 시각이 늦은 순 |
| 학습 패키지 목록 | 기술 이름만 주었는데 그 저장소가 있음 | 패키지 이름, 학습 목표, 마지막 학습 날짜 | 마지막 학습 패키지를 맨 위에 두고 나머지는 마지막 학습 날짜가 늦은 순 |

값은 아래에서 읽습니다.

| 값 | 읽는 곳 |
| --- | --- |
| 마지막 커밋 시각과 날짜 | 저장소마다 `git -C <저장소> log -1 --format=%ct` |
| 마지막 학습 패키지 | 그 저장소 `state.json`의 `lastPackage` |
| 학습 목표 | 저장소 `README.md`의 `## 학습 패키지` 표 |
| 패키지의 마지막 학습 날짜 | 패키지 `records/`에서 가장 늦은 날짜 디렉터리 이름 |

마지막 학습 패키지 줄에는 `(마지막 학습)`을 붙입니다. 목록이 5개를 넘으면 5개씩 끊어 보여 주고, 첫 줄에 `(1~5 / 전체 N개)`처럼 보이는 범위를 적습니다. 5개 이하면 끊지 않습니다. 목록을 보여 주면 `inputMode: selection`으로 바꿉니다.

```
이어서 학습할 저장소를 번호로 골라 주세요. (1~5 / 전체 8개)

1. react          — state-basics      · 2026-09-14
2. tanstack-query — query-cache       · 2026-09-12
3. python         — merge-sort        · 2026-09-10
4. typescript     — invoice-discount  · 2026-09-08
5. node           — event-loop        · 2026-09-05

"다음"을 입력하면 6~8번을 보여 줍니다.
새 기술을 배우려면 기술 이름을 입력하세요.
```

```
tanstack-query 저장소에 학습 패키지가 3개 있습니다.
이어서 학습할 패키지를 번호로 골라 주세요. (1~3 / 전체 3개)

1. query-cache (마지막 학습) — 같은 queryKey의 캐시 공유 · 2026-09-14
2. mutation-refresh          — 추가 뒤 목록 갱신         · 2026-09-11
3. loading-states            — 로딩·에러 상태 변화       · 2026-09-09

새 주제를 시작하려면 "새 주제"를 입력하세요.
```

| 학습자 입력 | 할 일 |
| --- | --- |
| 번호 | 저장소 목록이면 그 저장소의 마지막 학습 패키지에서, 패키지 목록이면 그 패키지에서 이어 감 |
| "다음", "이전" | 다음이나 이전 5개를 같은 모양으로 보여 줌 |
| 기술 이름 (저장소 목록에서) | 그 기술로 학습을 시작 |
| "새 주제" (패키지 목록에서) | [Example Builder](../roles/example-builder.md)로 예제 후보 2~3개를 제시 |
| 학습 폴더에 저장소가 없음 | 배울 기술이나 자료를 물음 |

### 4. 중단된 변경 커밋

**기술 저장소를 정한 직후, 커밋되지 않은 기록·상태 변경이 있으면 다른 작업보다 먼저 커밋합니다.**

`git -C <저장소> status --porcelain`으로 저장소 `state.json`, `packages/*/state.json`, `packages/*/records/`의 변경을 찾습니다. 설명 경로가 끝나기 전에 세션이 닫혀 남은 변경입니다.

```bash
git -C <저장소> add state.json packages/<주제>/state.json packages/<주제>/records
git -C <저장소> commit -m "learn(<주제>): 중단된 탐색 기록"
```

`<주제>`는 변경된 기록 파일이 속한 패키지 이름입니다. 여러 패키지에 걸치면 저장소 `state.json`의 `lastPackage`를 씁니다.

### 5. 누적 상태 읽기

**진행 중이거나 고른 패키지 `state.json`의 `questions`·`discoveredConcepts`·`partialConcepts`·`nextCandidates`를 읽어 누적 학습 상태로 넘깁니다.**

패키지 `state.json`이 없으면 [아래 양식](#패키지-statejson)대로 빈 값을 채워 만듭니다.

## 양식

### 저장소 state.json

```json
{
  "sessionStatus": "in_progress",
  "inputMode": "learning",
  "activePackage": "<주제>",
  "lastPackage": "<주제>",
  "discoveredConcepts": ["<발견한 개념 이름>"]
}
```

### 패키지 state.json

```json
{
  "record": "records/YYYY-MM-DD/01-question-slug.md",
  "activeQuestion": "<현재 질문>",
  "viewpoint": "<구조|실행>",
  "path": "<설명 경로>",
  "stage": "<관찰 유도|힌트|부분 설명|전체 설명>",
  "awaiting": "<다음에 기대하는 학습자 입력>",
  "lastTurn": { "speaker": "<학습자|assistant>", "type": "<발화 유형>" },
  "questions": [
    { "question": "<질문 원문>", "record": "records/YYYY-MM-DD/01-question-slug.md", "status": "완료" }
  ],
  "discoveredConcepts": ["<발견한 개념 이름>"],
  "partialConcepts": [{ "concept": "<개념>", "remaining": "<아직 공개하지 않은 부분>" }],
  "nextCandidates": ["<다음 탐색 후보>"]
}
```

## 예외 처리

| 예외 조건 | 할 일 |
| --- | --- |
| 설명 경로 도중 세션이 끝남 | 다음 학습 시작 때 4절로 커밋되지 않은 변경을 먼저 커밋 |
| 저장소 `state.json`이 손상됨 | 기존 파일을 조용히 덮어쓰지 않고, 1절의 마지막 행대로 확인받은 뒤 새로 씀 |
| 저장소 `state.json`은 있는데 `activePackage`가 가리키는 패키지 디렉터리가 없음 | `recovery_required`로 보고 학습자에게 재개할 패키지를 확인받은 뒤 다시 씀 |
