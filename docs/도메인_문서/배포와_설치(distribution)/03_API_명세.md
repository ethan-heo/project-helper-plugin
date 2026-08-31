# 배포와_설치(distribution) — API 명세

이 도메인의 인터페이스는 두 환경의 플러그인 명령줄이다.

## 엔드포인트 목록

| 메서드 | 경로 | 설명 | 인증 |
| --- | --- | --- | --- |
| `실행` | `claude plugin marketplace add <owner>/<repo>` | Claude Code에 마켓플레이스를 등록한다 | 저장소 접근 권한 |
| `실행` | `claude plugin install project-helper@project-helpers` | 플러그인을 설치한다 | 불필요 |
| `실행` | `claude plugin marketplace update project-helpers` | 마켓플레이스 소스를 갱신한다 | 불필요 |
| `실행` | `claude plugin uninstall project-helper@project-helpers` | 설치본을 지운다 | 불필요 |
| `실행` | `claude plugin list` | 설치 결과와 버전을 확인한다 | 불필요 |
| `실행` | `codex plugin marketplace add <owner>/<repo>` | Codex에 마켓플레이스를 등록한다 | 저장소 접근 권한 |
| `실행` | `codex plugin add project-helper@project-helpers` | 플러그인을 설치한다 | 불필요 |
| `실행` | `codex plugin remove project-helper@project-helpers` | 설치본을 지운다 | 불필요 |
| `실행` | `codex plugin marketplace upgrade` | 마켓플레이스를 갱신한다 | 불필요 |
| `실행` | `codex plugin list` | 설치 결과와 마켓플레이스 루트를 확인한다 | 불필요 |

## `배포`(마켓플레이스 등록과 설치)

사용자는 저장소 주소로 마켓플레이스를 등록한 뒤 플러그인을 설치한다. 두 환경의 절차는 명령 이름만 다르고 진입점은 같다.

### 요청

| 위치 | 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- | --- |
| 인자 | 저장소 소스 | string | 예 | 로컬 경로, `owner/repo[@ref]`, HTTPS Git URL, SSH Git URL을 받는다 |
| 옵션 | `--ref` | string | 아니오 | 특정 ref를 지정한다 |
| 옵션 | `--sparse` | flag | 아니오 | 저장소의 일부 경로만 받는다 |

```
/plugin marketplace add ethan-heo/project-helper-plugin
/plugin install project-helper@project-helpers
```

```
codex plugin marketplace add ethan-heo/project-helper-plugin
codex plugin add project-helper@project-helpers
```

### 응답

설치 결과는 목록 명령으로 확인한다. Codex의 마켓플레이스 등록은 `~/.codex/config.toml`에 남는다.

```toml
[marketplaces.project-helpers]
source = "/Users/ethanheo/Desktop/2026/projects/project-helper-plugin"
```

설치가 끝나면 새로 시작하는 대화에서 네 스킬을 모두 쓸 수 있다.

### 에러 코드

| 상태 코드 | 코드 | 발생 조건 |
| --- | --- | --- |
| 해당 없음 | 버전 불일치 | 두 매니페스트의 `version`이 달라 환경마다 다른 값이 표시된다 |
| 해당 없음 | 변경 미반영 | 소스를 고쳤으나 재설치하지 않았다 |
| 해당 없음 | 세션 미갱신 | 재설치했으나 실행 중인 세션이 옛 정의를 쓰고 있다 |

## 배포 절차

**두 매니페스트의 버전을 올린 뒤에 원격에 올리고 태그를 붙인다.**

1. 두 플러그인 매니페스트의 버전을 올린다.
2. 변경을 `main`에 올리고 버전 태그를 붙인다.
3. 사용자는 저장소 주소로 마켓플레이스를 등록한 뒤 플러그인을 설치한다.

| 환경 | 등록 명령 |
| --- | --- |
| Claude Code | `claude plugin marketplace add <owner>/<repo>` |
| Codex | `codex plugin marketplace add <owner>/<repo>` |

## `로컬 테스트 설치`

개발 중에 고친 스킬을 확인하는 절차다. 저장소 루트에서 실행하면 작업 디렉터리의 파일이 그대로 다시 설치되며, 커밋하지 않은 변경분도 포함된다.

**이 절차는 마켓플레이스가 로컬 경로로 등록되어 있을 때만 성립한다.** 원격 소스로 등록된 상태에서는 설치본이 저장소가 아니라 클론된 캐시에서 오므로, 작업 디렉터리의 변경이 반영되지 않는다. 개발용으로 되돌리려면 플러그인과 마켓플레이스를 지우고 저장소 경로로 다시 등록한다.

### 요청

Claude Code에서는 세 명령을 순서대로 실행한다.

```
claude plugin uninstall project-helper@project-helpers
claude plugin marketplace update project-helpers
claude plugin install project-helper@project-helpers
```

Codex에서는 캐시 디렉터리를 함께 지운다.

```bash
codex plugin remove project-helper@project-helpers
rm -rf ~/.codex/plugins/cache/project-helpers/project-helper
codex plugin add project-helper@project-helpers
```

### 응답

| 확인 대상 | 명령 |
| --- | --- |
| Claude Code 설치 결과 | `claude plugin list` |
| Codex 설치 결과 | `codex plugin list` |

### 에러 코드

| 상태 코드 | 코드 | 발생 조건 |
| --- | --- | --- |
| 해당 없음 | 캐시 잔존 | Codex에서 캐시 디렉터리를 지우지 않고 재설치했다 |
| 해당 없음 | 캐시 과다 삭제 | 전체 캐시 디렉터리를 지워 다른 플러그인까지 사라졌다 |
| 해당 없음 | 버전 오염 | 재설치를 위해 버전에 타임스탬프를 덧붙였다 |

## 이벤트 메시징

해당 없음. 배포와 설치는 사용자가 명령을 실행할 때만 일어나며, 갱신을 알리는 이벤트나 자동 반영 경로가 없다. 그래서 재설치와 세션 재시작이 유일한 반영 수단이다.
