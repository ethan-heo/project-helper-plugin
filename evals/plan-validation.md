# 계획서 검증 시나리오

검증 스크립트의 회귀 사례는 다음 기준을 따른다.

| 사례 | 입력 | 기대 결과 |
| --- | --- | --- |
| 정상 계획서 | 최상위 README, 도메인 README, 기능 계획서, `계획 확정`, 검토 표시 없음 | 통과 |
| 단일 초안 | 날짜 디렉터리 바로 아래의 `.md` | `impl-plan` 검사 실패 |
| 검토 미완료 | 기능 계획서에 `<!-- 사용자 검토 필요 -->` 포함 | 검사 실패 |
| 진행률 오류 | 구현 항목 수와 상태 표의 전체 수 불일치 | 정합성 검사에서 확인 필요 |

기본 문법 검증은 다음 명령으로 실행한다.

```sh
bash -n plugins/project-helper/skills/create-plan/scripts/validate-plan.sh
bash -n plugins/project-helper/skills/impl-plan/scripts/validate-plan.sh
```
