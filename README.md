# helpers

Claude Code와 Codex에서 함께 쓰는 플러그인 마켓플레이스다. 저장소 루트가 마켓플레이스이고, 플러그인은 `plugins/` 아래에 하나씩 들어간다.

## 플러그인

| 플러그인 | 하는 일 | 문서 |
| --- | --- | --- |
| `project-helper` | 기술적 문제의 해법을 사용자가 직접 설계하도록 돕고, 그 계획서대로 구현한 뒤 결과를 개발 문서로 남긴다 | [`docs/project-helper/글로벌_아키텍처_가이드.md`](docs/project-helper/글로벌_아키텍처_가이드.md) |

각 플러그인이 제공하는 스킬과 설계 근거는 해당 플러그인의 글로벌 아키텍처 가이드에서 확인한다.

## 저장소 구조

```
.claude-plugin/marketplace.json     마켓플레이스 매니페스트
plugins/<플러그인>/                  플러그인 본체. 설치본에 그대로 복사된다
├── .claude-plugin/plugin.json       Claude Code용 매니페스트
├── .codex-plugin/plugin.json        Codex용 매니페스트
└── skills/                          스킬 정의
docs/                                저장소 공통 기준
└── <플러그인>/                       플러그인별 개발 문서와 계획서
```

플러그인 매니페스트에는 복사 대상을 제외하는 필드가 없다. 설치본은 `plugins/<플러그인>/` 전체를 복사하므로, 배포에 싣지 않을 문서는 `docs/` 아래에 둔다.

## 설치

마켓플레이스는 저장소 단위로 한 번만 등록하고, 그 뒤에 필요한 플러그인을 골라 설치한다.

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

설치 결과는 `codex plugin list`로 확인한다. 새로 시작하는 대화부터 해당 플러그인의 스킬을 쓸 수 있다.

두 환경 모두 설치 명령의 인자는 `<플러그인>@helpers` 형식이다. 플러그인을 여럿 쓰려면 등록은 그대로 두고 설치 명령만 플러그인마다 실행한다.

## 갱신

마켓플레이스를 갱신한 뒤, 설치해 둔 플러그인을 각각 다시 설치한다.

```
claude plugin marketplace update helpers
claude plugin install project-helper@helpers
```

```
codex plugin marketplace upgrade
codex plugin add project-helper@helpers
```

갱신한 내용은 실행 중인 세션에 적용되지 않는다. 세션을 다시 시작해야 새 스킬 정의가 적용된다.

## 저장소를 고쳐 쓰는 경우

플러그인을 직접 수정하며 시험하는 절차는 플러그인마다 다르다. `project-helper`는 [`docs/project-helper/도메인_문서/배포와_설치(distribution)/03_API_명세.md`](docs/project-helper/도메인_문서/배포와_설치%28distribution%29/03_API_명세.md)의 로컬 테스트 설치 절을 따른다. 배포 규격과 확인 근거는 같은 도메인의 [`02_도메인_모델.md`](docs/project-helper/도메인_문서/배포와_설치%28distribution%29/02_도메인_모델.md)와 [`04_도메인_특화_가이드.md`](docs/project-helper/도메인_문서/배포와_설치%28distribution%29/04_도메인_특화_가이드.md)에 있다.

## 문서

저장소 전체에 적용하는 기준은 최상위 `docs/`에 둔다.

- [`docs/문서_작성_기준.md`](docs/문서_작성_기준.md) — 문서 구조, 배치, 문체, 표기
- [`docs/프롬프트_작성_가이드.md`](docs/프롬프트_작성_가이드.md) — 스킬 본문과 참조 문서를 쓸 때의 기준
