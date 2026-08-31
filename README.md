# project-helper

Claude Code와 Codex에서 함께 사용할 수 있는 플러그인이다.

기술적 문제의 해법을 **사용자가 직접 설계하도록** 돕는 플러그인이다. AI는 답을 대신 내놓지 않는다. 경험 많은 엔지니어 검토자의 자리에서 질문하고, 반례를 제시하고, 결정을 기록한다.

## 스킬

| 스킬 | 하는 일 | 계획서 상태 |
| --- | --- | --- |
| `create-prd` | 무엇을 왜 만드는지 질의응답으로 확정해 PRD로 남긴다 | 해당 없음 |
| `create-plan` | 요구사항을 받아 사용자와 함께 구현 계획서를 쓴다 | 초안 작성 → 계획 완료 |
| `impl-plan` | 계획서의 구현 순서를 하나씩 실행하고 항목마다 커밋한다 | 계획 완료 → 완료 |
| `create-docs` | 구현이 끝난 계획서와 코드를 근거로 개발 문서를 만든다 | 완료 이후 |

네 스킬은 PRD와 계획서를 매개로 이어지지만 서로의 파일을 참조하지 않는다. 형식의 정본은 `create-plan`의 `references/plan-format.md`에 둔다.

문서의 권한은 저장소 규칙, 스킬 본문, 조건부 참조 자료, 실행 자료의 순서로 구분한다. `SKILL.md`가 각 스킬의 실행 정본이며, `references/`는 지정된 절차에서만 읽는 근거와 세부 기준이다. `assets/`는 템플릿, `scripts/`는 검증 도구이므로 독립적인 실행 지시사항으로 해석하지 않는다.

`impl-plan`은 `create-plan`의 파일을 실행 중 참조하지 않지만, 확정 계획서가 `create-plan` 규격으로 작성되었다는 공통 전제를 따른다. 이 전제와 계획서 형식은 각 스킬 본문에 필요한 범위만 선언한다.

문서 참조 구조를 검토할 때는 다음 세 가지를 확인한다.

- 각 스킬의 실행 절차가 해당 스킬의 `SKILL.md`에 있고, 정본이 다른 스킬의 파일에 있지 않은가.
- `references/`의 각 파일이 `SKILL.md`에 읽는 시점과 적용 범위를 갖고 있는가.
- `assets/`와 `scripts/`가 템플릿·검증 도구로만 사용되고, 스킬 본문에 없는 실행 범위를 만들고 있지 않은가.

`impl-plan`은 `create-plan`의 실행 문서나 참조 문서를 읽지 않고, 공통 계획서 규격을 입력 전제로 사용한다. 두 스킬은 실행 문서 기준으로 독립적이지만 계획서 형식은 공유한다.

## 왜 나눴나

계획을 세울 때 AI는 질문과 검토를 맡는다. 구현할 때는 코드를 작성하고 항목별 검증을 수행한 뒤 계획서를 `완료`로 바꾸고 종료한다.

두 역할을 한 지시서에 섞지 않아야 각 스킬의 책임이 분명해진다. 구현 항목을 모두 마치면 `impl-plan`이 계획서 단계를 `완료`로 바꾼다.

## 설치

저장소 루트가 마켓플레이스이고, 플러그인은 그 안에 있다. Claude Code와 Codex 모두 같은 매니페스트를 읽는다.

```
.claude-plugin/marketplace.json     마켓플레이스 매니페스트
plugins/project-helper/             플러그인
├── .claude-plugin/plugin.json       Claude Code용 매니페스트
├── .codex-plugin/plugin.json        Codex용 매니페스트
└── skills/{create-prd, create-plan, impl-plan, create-docs}/
```

### Claude Code

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@project-helpers
```

설치 결과는 `claude plugin list`로 확인한다.

### Codex

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@project-helpers
```

설치 결과는 `codex plugin list`로 확인한다. 새로 시작하는 대화에서 네 스킬을 모두 사용할 수 있다.

### 갱신

마켓플레이스를 갱신한 뒤 플러그인을 다시 설치한다.

```
claude plugin marketplace update project-helpers
codex plugin marketplace upgrade
```

갱신한 내용은 실행 중인 세션에 적용되지 않는다. 세션을 다시 시작해야 새 스킬 정의가 적용된다.

### 저장소를 고쳐 쓰는 경우

플러그인을 직접 수정하며 시험하려면 [`docs/도메인_문서/배포와_설치(distribution)/03_API_명세.md`](docs/도메인_문서/배포와_설치%28distribution%29/03_API_명세.md)의 로컬 테스트 설치 절차를 따른다. 배포 규격과 확인 근거는 같은 도메인의 [`02_도메인_모델.md`](docs/도메인_문서/배포와_설치%28distribution%29/02_도메인_모델.md)와 [`04_도메인_특화_가이드.md`](docs/도메인_문서/배포와_설치%28distribution%29/04_도메인_특화_가이드.md)에 있다.

## 진행 상황

구축 계획서는 `docs/plans/2026-08-25-plan-skills/`에 있다. 최상위 `README.md`에서 도메인을 훑고, 도메인 폴더 아래의 기능 계획서 파일로 내려가면 해당 기능의 계획을 확인할 수 있다.
