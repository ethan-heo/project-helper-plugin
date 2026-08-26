# project-helper

Claude Code와 Codex에서 함께 사용할 수 있는 플러그인이다.

기술적 문제의 해법을 **사용자가 직접 설계하도록** 돕는 플러그인이다. AI는 답을 대신 내놓지 않는다. 경험 많은 엔지니어 검토자의 자리에서 질문하고, 반례를 제시하고, 결정을 기록한다.

## 스킬

| 스킬 | 하는 일 | 계획서 상태 |
| --- | --- | --- |
| `create-plan` | 요구사항을 받아 사용자와 함께 구현 계획서를 쓴다 | → 계획 확정 |
| `impl-plan` | 계획서의 구현 순서를 하나씩 실행하고 항목마다 커밋한다 | 계획 확정 → 구현 중 → 완료 |

두 스킬은 계획서를 매개로 협력하지만 서로의 파일을 참조하지 않는다. 형식의 정본은 `create-plan`의 `references/plan-format.md`에 둔다.

`impl-plan`은 실행에 필요한 전제만 본문에 적는다. 따라서 각 스킬은 독립적으로 사용할 수 있다.

## 왜 나눴나

계획을 세울 때 AI는 질문과 검토를 맡는다. 구현할 때는 코드를 작성하고 검증한다.

두 역할을 한 지시서에 섞지 않아야 각 스킬의 책임이 분명해진다. 구현 항목을 모두 마치면 `impl-plan`이 계획서 단계를 `완료`로 바꾼다.

## 설치

저장소 루트가 마켓플레이스이고, 플러그인은 그 안에 있다.

```
.claude-plugin/marketplace.json     Claude Code 마켓플레이스 매니페스트
plugins/project-helper/             플러그인
├── .claude-plugin/plugin.json       Claude Code용 매니페스트
├── .codex-plugin/plugin.json        Codex용 매니페스트
└── skills/{create-plan, impl-plan}/
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

Codex는 해당 디렉터리의 `.codex-plugin/plugin.json`과 `skills/`를 읽어 설치한다. 설치 후 새 Codex 대화에서 `create-plan`, `impl-plan` 스킬을 사용할 수 있다.

플러그인을 수정한 뒤에는 Codex의 플러그인 화면에서 해당 플러그인을 다시 설치하거나 새로고침한다.

## 진행 상황

구축 계획서는 `docs/plans/2026-08-25-plan-skills/`에 있다. 최상위 `README.md`에서 도메인 다섯을 훑고, 도메인 폴더 아래 기능 폴더로 내려가면 그 기능의 계획서가 있다.
