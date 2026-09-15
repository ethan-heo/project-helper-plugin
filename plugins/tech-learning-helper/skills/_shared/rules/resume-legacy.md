# 학습 재개: 기존 저장소 이전

`resume.md`의 1절에서 `resume-scan.sh`의 `status`가 `missing_state`나 `legacy`일 때만 읽습니다.

## 구형 파일 이전

**저장소를 열었을 때 구형 루트 `state.json`(`package`·`sessionStatus`·`activePackage` 같은 필드가 있는 형태)이나 `state.md`·`knowledge.md`·`summary.md`가 있으면, 아래 순서로 새 구조로 옮긴 뒤 옛 파일을 지우고 [중단된 변경 커밋](resume-commit.md)과 같은 방식으로 커밋합니다.**

1. 구형 루트 `state.json`의 `record`·`activeQuestion`·`viewpoint`·`path`·`stage`·`awaiting`·`nextCandidates`·`lastTurn`이 있으면 그 패키지의 `state.json`으로 옮깁니다. `package`·`sessionStatus`·`inputMode`·`activePackage`·`lastPackage` 필드는 버립니다.
2. `state.md`의 발견한 개념(패키지별)을 각 패키지 `state.json`의 `discoveredConcepts`로 옮기고, 이름만 모아 저장소 `state.json`의 `discoveredConcepts`에도 더합니다.
3. `state.md`의 부분 이해 개념·다음 탐색 후보를 `state.md`의 마지막 학습 패키지의 `state.json`으로 옮깁니다. `state.md`의 미공개 개념과 `knowledge.md`는 버립니다.
4. `records/` 안 각 질문 기록 파일을 확인해, 구형 `state.json`이 가리키던 기록이면 `status: 진행`, 나머지는 `status: 완료`로 그 패키지 `state.json`의 `questions`에 적습니다.
5. 각 패키지의 `records/`에서 가장 늦은 날짜를 찾아 저장소 `state.json`의 `packages[].lastActivity`로 씁니다.
6. `summary.md`는 버립니다. 패키지 `state.json`이 같은 정보를 담습니다.

이전 대상 파일이 서로 어긋나면(예: `state.md`는 있는데 구형 `state.json`이 없음) 자동으로 옮기지 않고 학습자에게 상태를 확인받습니다. 구형과 신형 상태 파일이 동시에 있으면 신형을 우선하고 구형은 지웁니다.

## 인덱스 없이 복구

**이전할 구형 파일이 없고 저장소 `state.json`도 없으면, 기록 전문에서 현재 질문을 정하지 않고 커밋되지 않은 기록 변경을 기준으로 인덱스를 만듭니다.**

| 발견한 것 | 할 일 |
| --- | --- |
| 진행 중인 기록 변경이 없음 | `packages/` 디렉터리를 스캔해 인덱스 생성 |
| 기록 변경이 있고 현재 질문을 하나로 확인할 수 있음 | 그 질문과 공개 단계를 학습자에게 확인받은 뒤 해당 패키지 `state.json` 생성 |
| 기록 변경이 있지만 현재 질문이 모호함 | 재개할 질문을 학습자에게 확인 |

복구를 확인하기 전에는 이어 하기 목록을 보여 주지 않습니다. 학습자가 재개할 질문을 고르면 그 질문·기록 파일을 해당 패키지 `state.json`에 저장합니다.
