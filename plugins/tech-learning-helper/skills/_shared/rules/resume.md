# 학습 재개 규칙

## 목적

새 세션은 이전 대화를 기억하지 못합니다. 이 문서는 새 세션이 이어 할 학습을 고르게 하고, 패키지를 고른 뒤에는 멈춘 단계에서 다시 시작하는 방법을 정합니다.

## 핵심 지시

**새 세션은 저장소 `state.json`으로 재개 지점을 판단하지 않고, 항상 이어 하기 목록에서 패키지를 고르게 합니다. 패키지를 고른 뒤의 재개 지점은 그 패키지의 `state.json`으로만 판단합니다.**

저장소 `state.json`은 그 저장소의 패키지 이름과 마지막 활동 날짜를 모은 인덱스이며, 어느 패키지가 지금 진행 중인지는 담지 않습니다. 누적 학습 상태(발견한 개념·부분 이해 개념·다음 탐색 후보)도 패키지를 고른 뒤 그 패키지의 `state.json`에서 읽습니다. 기록 파일 전문에서 추정하지 않습니다.

## 번호 입력 해석

**목록을 보여 준 직후의 번호 입력은 그 목록 선택으로 처리하고, 패키지를 고른 뒤의 번호 입력은 그 패키지 `state.json`의 `awaiting`이 기대하는 대로 해석합니다.**

| 상황 | 번호 입력의 뜻 | 판단 근거 |
| --- | --- | --- |
| 방금 이어 하기 목록(저장소·패키지)을 보여줌 | 그 목록에서 고른 항목 | 지시사항. 파일에 남기지 않습니다 |
| 패키지를 고른 뒤, 설명 경로 진행 중 | 현재 공개 단계에 대한 학습 답변 | 그 패키지 `state.json`의 `awaiting` |
| 패키지를 고른 뒤, 다음 탐색 후보를 보여준 직후 | 그 후보 목록에서 고른 항목 | 그 패키지 `state.json`의 `awaiting` |

패키지가 정해지기 전에는 어떤 파일도 번호의 뜻을 판단하는 근거로 쓰지 않습니다. 방금 보여 준 목록이 무엇이었는지는 대화 맥락으로 판단합니다.

## 절차 흐름

### 1. 이어 하기 목록 표시

**학습을 시작하면 항상 이어 하기 목록부터 보여 줍니다. 저장소나 패키지를 스캔하는 계산은 [`resume-scan.sh`](../scripts/resume-scan.sh)로 하고, 그 결과를 목록으로 옮기는 일만 직접 합니다.**

```bash
bash <플러그인 경로>/skills/_shared/scripts/resume-scan.sh repos <학습폴더>
```

이 결과의 `repos` 배열은 마지막 커밋 시각 내림차순으로 이미 정렬되어 있습니다. 목록 없이 특정 질문으로 들어가지 않습니다.

| 발견한 것(`status`) | 할 일 |
| --- | --- |
| 기술 이름 없음 | 위 명령 결과로 2절의 기술 저장소 목록을 보여 줌 |
| 기술 이름이 있고 그 저장소가 있음 | `resume-scan.sh packages <저장소>`로 2절의 학습 패키지 목록을 보여 줌 |
| `missing_state` | [`resume-legacy.md`](resume-legacy.md)에 따라 기존 파일을 확인하고 인덱스를 만듦 |
| `invalid_state` | 어긋난 부분을 알리고, `packages/` 디렉터리를 다시 스캔해 인덱스를 새로 씀 |
| `legacy` | [`resume-legacy.md`](resume-legacy.md)에 따라 `legacyFiles`가 가리키는 파일을 새 구조로 옮김 |
| `staleEntries`에 이름이 있음 | 그 항목을 지우고 다시 씀. 재개 지점을 담지 않으므로 확인 없이 정리합니다 |

### 2. 이어 하기 목록

**새 세션에서 이어 할 학습을 고르게 할 때, 아래 두 목록 중 요청에 맞는 것을 번호 목록으로 보여 줍니다.**

| 목록 | 보여 주는 때 | 만드는 명령 | 한 줄의 내용 |
| --- | --- | --- | --- |
| 기술 저장소 목록 | 기술 이름 없이 `learn`을 호출함 | `resume-scan.sh repos <학습폴더>` | 저장소 이름, 마지막 학습 패키지(`lastPackage`), 마지막 커밋 날짜(`lastCommitDate`) |
| 학습 패키지 목록 | 기술 이름만 주었는데 그 저장소가 있음 | `resume-scan.sh packages <저장소>` | 패키지 이름, 학습 목표(`goal`), 마지막 활동 날짜(`lastActivity`) |

두 명령 모두 정렬을 마친 배열(`repos`, `packages`)을 내므로 다시 정렬하지 않습니다. `isLast`(패키지 목록) 또는 `lastPackage`와 이름이 같은 저장소 줄에는 `(마지막 학습)`을 붙입니다. 목록이 5개를 넘으면 5개씩 끊어 보여 주고, 첫 줄에 `(1~5 / 전체 N개)`처럼 보이는 범위를 적습니다. 5개 이하면 끊지 않습니다.

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
| 번호(저장소 목록에서) | 그 저장소의 학습 패키지 목록을 이어서 보여 줌 |
| 번호(패키지 목록에서) | 그 패키지의 `state.json`을 읽어 3절의 패키지 재개로 이어 감 |
| "다음", "이전" | 다음이나 이전 5개를 같은 모양으로 보여 줌 |
| 기술 이름 (저장소 목록에서) | 그 기술로 학습을 시작 |
| "새 주제" (패키지 목록에서) | [Example Builder](../roles/example-builder.md)로 예제 후보 2~3개를 제시 |
| 학습 폴더에 저장소가 없음 | 배울 기술이나 자료를 물음 |

### 3. 패키지 재개

**패키지를 고르면 그 패키지의 `state.json`을 읽어, 열린 질문이 있으면 이어 가고 없으면 새로 시작합니다.**

| 발견한 것 | 할 일 |
| --- | --- |
| `questions`에 `status: 진행`인 항목이 있음 | 목록을 다시 보여 주지 않고, `record`가 가리키는 질문 파일에서 `stage`와 `awaiting`부터 이어 감 |
| `questions`에 `status: 진행`인 항목이 없음 | `nextCandidates`가 있으면 후보를 제시하고, 없으면 학습 목표 판정으로 새 설명 경로를 시작 |
| 패키지 `state.json`이 없거나 손상됨 | 학습자에게 상태를 확인받은 뒤 다시 씀 |

### 4. 누적 상태 읽기

**진행 중이거나 고른 패키지 `state.json`의 `questions`·`discoveredConcepts`·`partialConcepts`·`nextCandidates`를 읽어 누적 학습 상태로 넘깁니다.**

패키지 `state.json`이 없으면 [아래 양식](#패키지-statejson)대로 빈 값을 채워 만듭니다.

## 양식

### 저장소 state.json

```json
{
  "packages": [
    { "name": "<주제>", "lastActivity": "YYYY-MM-DD" }
  ],
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
| 설명 경로 도중 세션이 끝남 | 다음 학습 시작 때 [`resume-commit.md`](resume-commit.md)로 커밋되지 않은 변경을 먼저 커밋 |
| 저장소 `state.json`이 손상됨 | `packages/` 디렉터리를 다시 스캔해 인덱스를 새로 씀. 재개 지점을 담지 않으므로 확인 없이 복구합니다 |
| 패키지 `state.json`이 손상됨 | 조용히 덮어쓰지 않고, 3절의 마지막 행대로 확인받은 뒤 새로 씀 |
