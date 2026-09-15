# 학습 재개: 중단된 변경 커밋

## 핵심 지시

**기술 저장소를 정한 직후, 커밋되지 않은 기록·상태 변경이 있으면 다른 작업보다 먼저 커밋합니다.**

`git -C <저장소> status --porcelain`으로 저장소 `state.json`, `packages/*/state.json`, `packages/*/questions.json`, `packages/*/records/`의 변경을 찾습니다. 설명 경로가 끝나기 전에 세션이 닫혀 남은 변경입니다.

```bash
git -C <저장소> add state.json packages/<주제>/state.json packages/<주제>/questions.json packages/<주제>/records
git -C <저장소> commit -m "learn(<주제>): 중단된 탐색 기록"
```

`<주제>`는 변경된 기록 파일이 속한 패키지 이름입니다. 여러 패키지에 걸치면 그중 가장 최근에 변경된 패키지를 씁니다.
