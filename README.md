# project-helper

Claude Code와 Codex에서 함께 사용할 수 있는 플러그인이다.

기술적 문제의 해법을 **사용자가 직접 설계하도록** 돕는 플러그인이다. AI가 답을 대신 내놓지 않고, 경험 많은 엔지니어 검토자의 자리에서 질문하고 반박하고 기록한다.

## 스킬

| 스킬 | 하는 일 | 계획서 상태 |
| --- | --- | --- |
| `create-plan` | 요구사항을 받아 사용자와 함께 구현 계획서를 쓴다 | → 계획 확정 |
| `impl-plan` | 계획서의 구현 순서를 하나씩 실행하고 항목마다 커밋한다 | 계획 확정 → 구현 중 → 완료 |
| `verify-plan` | 완료된 계획서의 테스트 시나리오와 변경점을 사용자와 확인한다 | 완료 상태 확인 |

세 스킬은 계획서 한 편을 주고받되 서로의 파일을 참조하지 않는다. 형식의 정본은 문서를 쓰는 `create-plan`이 갖고(`references/plan-format.md`), `impl-plan`과 `verify-plan`은 받는 문서가 만족해야 할 전제만 자기 본문에 적어 둔다. 스킬 하나만 떼어 가도 동작한다.

## 왜 나눴나

계획을 세울 때 AI는 뒤로 물러서서 질문만 하고, 구현할 때는 앞에 나서서 코드를 쓴다. 정반대의 자세를 한 지시서에 담으면 어느 쪽도 선명해지지 않는다. 구현 항목을 모두 마치면 `impl-plan`이 계획서를 `완료`로 바꾸고, `/verify-plan`은 그 결과를 확인한다.

## 설치

저장소 루트가 마켓플레이스이고, 플러그인은 그 안에 있다.

```
.claude-plugin/marketplace.json     Claude Code 마켓플레이스 매니페스트
plugins/project-helper/             플러그인
├── .claude-plugin/plugin.json       Claude Code용 매니페스트
├── .codex-plugin/plugin.json        Codex용 매니페스트
└── skills/{create-plan, impl-plan, verify-plan}/
```

### Claude Code

저장소를 마켓플레이스로 등록한 뒤 플러그인을 설치한다.

```
/plugin marketplace add <저장소 경로>
/plugin install project-helper@project-helpers
```

터미널에서 등록 없이 바로 띄우려면 플러그인 디렉터리를 가리킨다.

```
claude --plugin-dir <저장소 경로>/plugins/project-helper
```

### Codex

Codex 앱의 플러그인 화면에서 로컬 플러그인 설치를 선택하고 다음 디렉터리를 지정한다.

```
<저장소 경로>/plugins/project-helper
```

Codex는 해당 디렉터리의 `.codex-plugin/plugin.json`과 `skills/`를 읽어 설치한다. 설치 후 새 Codex 대화에서 `create-plan`, `impl-plan`, `verify-plan` 스킬을 사용할 수 있다.

플러그인을 수정한 뒤에는 Codex의 플러그인 화면에서 해당 플러그인을 다시 설치하거나 새로고침한다.

## 진행 상황

구축 계획서는 `docs/plans/2026-08-25-plan-skills/`에 있다. 최상위 `README.md`에서 도메인 다섯을 훑고, 도메인 폴더 아래 기능 폴더로 내려가면 그 기능의 계획서가 있다.
