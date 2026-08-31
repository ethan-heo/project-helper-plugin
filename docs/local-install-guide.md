# 로컬 테스트 설치

이 문서는 개발 중에 수정한 스킬을 확인하기 위해 플러그인을 로컬에서 설치하고 다시 설치하는 절차를 정한다. 사용자에게 배포하는 설치 방법은 저장소 `README.md`에 있다.

**스킬 파일을 고친 내용은 설치된 플러그인에 자동으로 반영되지 않는다. 아래 절차로 다시 설치한 뒤 새 세션에서 확인한다.**

## Claude Code

저장소 루트에서 아래 순서대로 실행하면 현재 작업 디렉터리의 파일이 그대로 다시 설치된다.

```
claude plugin uninstall project-helper@project-helpers
claude plugin marketplace update project-helpers
claude plugin install project-helper@project-helpers
```

`.claude-plugin/marketplace.json`이 이 저장소를 상대 경로로 가리키므로 원격 저장소를 거치지 않고 로컬 파일만 사용한다. 커밋하지 않은 변경분도 함께 설치된다.

설치 결과는 `claude plugin list`로 확인한다.

## Codex

Codex는 설치할 때 로컬 소스를 캐시에 복사한다. 캐시를 끄거나 파일 변경을 자동으로 반영하는 개발 모드는 없으므로 재설치가 유일한 방법이다.

```bash
codex plugin remove project-helper@project-helpers
rm -rf ~/.codex/plugins/cache/project-helpers/project-helper
codex plugin add project-helper@project-helpers
```

Codex는 이 저장소의 `.claude-plugin/marketplace.json`을 그대로 읽어 `project-helpers` 마켓플레이스로 인식한다. 마켓플레이스가 등록되어 있지 않으면 `codex plugin marketplace add`로 저장소 루트를 먼저 등록한다.

설치 결과는 `codex plugin list`로 확인한다.

플러그인을 삭제할 때는 해당 플러그인의 캐시 디렉터리만 함께 지운다. 전체 캐시 디렉터리는 지우지 않는다.

저장소가 아닌 별도 사본을 가리키는 마켓플레이스를 쓴다면 저장소의 플러그인 디렉터리를 그 경로에 심링크로 연결할 수 있다. 심링크는 재설치할 때 최신 소스를 사용하게 할 뿐, 실행 중인 캐시를 갱신하지는 않는다.

마켓플레이스 설정 파일은 직접 고치지 않고 플러그인 명령으로 다룬다.

## 반영 조건

| 조건 | 할 일 |
| --- | --- |
| Claude Code에서 변경을 버전으로 구분해야 한다 | `plugins/project-helper/.claude-plugin/plugin.json`의 버전을 올린 뒤 재설치한다 |
| Codex에서 변경을 버전으로 구분해야 한다 | `plugins/project-helper/.codex-plugin/plugin.json`의 버전을 올린 뒤 재설치한다. 두 환경이 각자의 매니페스트를 읽으므로 버전을 함께 올린다 |
| Claude Code CLI에서 확인한다 | 세션을 종료하고 다시 실행한다 |
| VS Code 확장에서 확인한다 | 명령 팔레트의 `Developer: Reload Window`로 창을 새로 고친 뒤 세션을 다시 시작한다 |
| Codex에서 확인한다 | 재설치 후 새 대화를 연다 |

재설치한 내용은 실행 중인 세션에 적용되지 않는다. 세션을 다시 시작해야 새 스킬 정의가 적용된다.
