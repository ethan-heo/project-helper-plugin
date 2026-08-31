# 플러그인 배포 규격

이 문서는 `project-helper` 플러그인을 Claude Code와 Codex의 마켓플레이스로 배포할 때 저장소가 갖춰야 할 조건을 정한다. 로컬에서 테스트용으로 설치하는 절차는 [`docs/local-install-guide.md`](local-install-guide.md)에 있다.

**두 환경 모두 저장소 루트의 `.claude-plugin/marketplace.json` 하나를 마켓플레이스 진입점으로 읽는다. Codex 전용 마켓플레이스 매니페스트는 필요하지 않다.**

## 저장소가 갖출 것

| 파일 | 역할 | 읽는 환경 |
| --- | --- | --- |
| `.claude-plugin/marketplace.json` | 마켓플레이스 진입점. 플러그인 이름과 소스 경로를 담는다 | Claude Code, Codex |
| `plugins/project-helper/.claude-plugin/plugin.json` | 플러그인 매니페스트. Claude Code의 버전 표시가 이 값을 따른다 | Claude Code |
| `plugins/project-helper/.codex-plugin/plugin.json` | 플러그인 매니페스트. Codex의 버전 표시와 `interface` 정보가 이 값을 따른다 | Codex |
| `plugins/project-helper/skills/` | 스킬 본체 | 양쪽 |

마켓플레이스 매니페스트의 `source`는 저장소 루트 기준 상대 경로다. 원격 저장소로 옮겨도 그대로 동작한다.

두 플러그인 매니페스트의 버전은 항상 함께 올린다. 환경마다 서로 다른 파일을 읽으므로 한쪽만 올리면 같은 소스가 다른 버전으로 표시된다.

## 확인한 근거

`codex plugin list`의 출력에서 `project-helpers` 마켓플레이스의 루트가 이 저장소의 `.claude-plugin/marketplace.json`으로 표시된다. Codex가 별도 매니페스트 없이 같은 파일을 읽는다는 뜻이다.

`~/.codex/config.toml`에 등록된 형태는 아래와 같다. `source`는 저장소 루트를 가리킨다.

```toml
[marketplaces.project-helpers]
source = "/Users/ethanheo/Desktop/2026/projects/project-helper-plugin"
```

`codex plugin marketplace add --help`은 소스로 로컬 경로, `owner/repo[@ref]`, HTTPS Git URL, SSH Git URL을 받는다고 밝힌다. `--ref`로 특정 ref를, `--sparse`로 일부 경로만 받을 수 있다.

Codex의 `personal` 마켓플레이스는 `~/.agents/plugins/marketplace.json`을 진입점으로 쓴다. 곧 Codex는 두 경로를 모두 인식하지만, 이 저장소는 `.claude-plugin/marketplace.json` 하나로 두 환경을 함께 처리한다.

## 배포 절차

1. 두 플러그인 매니페스트의 버전을 올린다.
2. 변경을 `main`에 올리고 버전 태그를 붙인다.
3. 사용자는 저장소 주소로 마켓플레이스를 등록한 뒤 플러그인을 설치한다.

| 환경 | 등록 명령 |
| --- | --- |
| Claude Code | `claude plugin marketplace add <owner>/<repo>` |
| Codex | `codex plugin marketplace add <owner>/<repo>` |

## 미확인 사항

원격 Git 소스로 등록하는 경로는 아직 확인하지 않았다. 저장소를 공개로 올린 뒤 두 환경에서 각각 등록해 확인한다. 비공개 저장소에서 인증이 어떻게 처리되는지도 그때 함께 확인한다.
