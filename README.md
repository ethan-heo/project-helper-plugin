# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스다.

| 플러그인 | 목적 |
| --- | --- |
| `project-helper` | 기술적 문제의 해법을 사용자가 직접 설계하도록 돕고, 그 계획서대로 구현하며, 커밋 이력을 학습 문서로 남긴다 |

## 설치

마켓플레이스는 저장소 단위로 한 번만 등록하고, 그 뒤에 필요한 플러그인을 골라 설치한다. 설치 명령의 인자는 `<플러그인>@helpers` 형식이다.

### Claude Code

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@helpers
```

설치 결과는 `claude plugin list`로 확인한다.

### Codex

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@helpers
```

설치 결과는 `codex plugin list`로 확인한다.

### 갱신

마켓플레이스를 갱신한 뒤 설치해 둔 플러그인을 다시 설치한다.

```
claude plugin marketplace update helpers
claude plugin install project-helper@helpers
```

```
codex plugin marketplace upgrade
codex plugin add project-helper@helpers
```

설치와 갱신 모두 실행 중인 세션에는 적용되지 않는다. 새로 시작하는 대화부터 스킬을 쓸 수 있다.

## 사용법

스킬을 처음 쓴다면 [`docs/project-helper/스킬_사용법_튜토리얼.md`](docs/project-helper/스킬_사용법_튜토리얼.md)를 읽는다. Todo 리스트를 소재로 스킬 다섯 개를 부르는 순서와 각 스킬이 남기는 산출물을 순서대로 보여 준다.
