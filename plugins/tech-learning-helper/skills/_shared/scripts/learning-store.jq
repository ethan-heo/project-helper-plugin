def strings: type == "array" and all(.[]; type == "string");
def valid_repo:
  type == "object" and (.discoveredConcepts | strings)
  and (.packages | type == "array" and all(.[];
    (.name | type == "string") and (.lastActivity | type == "string")));
def valid_state:
  type == "object"
  and ((has("activeQuestionId") | not) or (.activeQuestionId | type == "string"))
  and (.stage | IN("관찰 유도", "힌트", "부분 설명", "전체 설명", ""))
  and (.awaiting | type == "string")
  and (.lastTurn | type == "object")
  and (.lastTurn.speaker | IN("학습자", "assistant"))
  and (.lastTurn.type | type == "string")
  and (.discoveredConcepts | strings)
  and (.partialConcepts | type == "array" and all(.[];
    (.concept | type == "string") and (.remaining | type == "string")))
  and (.nextCandidates | strings);
def valid_questions($prefix):
  type == "array" and all(.[];
    (.id | type == "string" and startswith($prefix)
      and (ltrimstr($prefix) | test("^[1-9][0-9]*$")))
    and (.question | type == "string")
    and (.viewpoint | IN("구조", "실행", ""))
    and (.path | strings)
    and (.status | IN("진행", "완료"))
    and (.record | type == "string"))
  and ([.[].id] | length == (unique | length));
def bundle($repo; $state; $questions; $prefix):
  if ($repo | length) != 1 or ($state | length) != 1 or ($questions | length) != 1
    then error("파일마다 JSON 값 하나가 필요합니다")
  elif ($repo[0] | valid_repo | not) then error("저장소 상태 형식 오류")
  elif ($state[0] | valid_state | not) then error("패키지 상태 형식 오류")
  elif ($questions[0] | valid_questions($prefix) | not) then error("질문 형식 오류")
  else {repo: $repo[0], state: $state[0], questions: $questions[0]}
  end
  | . as $b
  | if .state.activeQuestionId != null and
      ([.questions[] | select(.id == $b.state.activeQuestionId)] | length) != 1
    then error("현재 질문 ID가 없습니다") else . end;
def context($goal; $package):
  . as $b | {
    package: $package, goal: $goal,
    currentQuestion: ([.questions[] | select(.id == $b.state.activeQuestionId)
      | . + {recordPath: (if .record == "" then null else $package + "/" + .record end)}] | first // null),
    state: .state,
    discoveredConcepts: .repo.discoveredConcepts
  };
