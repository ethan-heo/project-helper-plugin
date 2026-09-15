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
def review_data($goal; $package):
  {
    package: $package, goal: $goal,
    questions: [.questions[] | {
      id, question, viewpoint, status, record,
      recordPath: (if .record == "" then null else $package + "/" + .record end),
      date: ((try (.record | capture("^records/(?<date>[0-9]{4}-[0-9]{2}-[0-9]{2})(/|\\.md$)").date) catch null) // null),
      lastStep: (.path | last // null)
    }],
    discoveredConcepts: .state.discoveredConcepts,
    partialConcepts: .state.partialConcepts,
    nextCandidates: .state.nextCandidates
  };

def valid_learning:
  type == "object"
  and (keys - ["addDiscoveredConcepts", "partialConcepts", "nextCandidates"] | length == 0)
  and ((has("addDiscoveredConcepts") | not) or (.addDiscoveredConcepts | strings))
  and ((has("partialConcepts") | not) or (.partialConcepts | type == "array" and all(.[];
    (.concept | type == "string") and (.remaining | type == "string"))))
  and ((has("nextCandidates") | not) or (.nextCandidates | strings));
def valid_payload:
  type == "object"
  and (keys - ["operationId", "questionId", "records", "progress", "learning"] | length == 0)
  and (.operationId | type == "string" and length > 0 and length <= 128)
  and (.questionId | type == "string")
  and (.records | type == "array" and length > 0 and all(.[];
    (keys - ["questionId", "turns"] | length == 0)
    and (.questionId | type == "string")
    and (.turns | type == "array" and length > 0 and all(.[];
      (keys - ["speaker", "type", "text"] | length == 0)
      and (.speaker | IN("학습자", "assistant"))
      and (.type | type == "string" and length > 0 and test("^[^\\r\\n*()]+$"))
      and (if .speaker == "assistant" then (.type | IN("관찰 유도", "힌트", "부분 설명", "전체 설명", "현상", "실험")) else true end)
      and (.text | type == "string")))))
  and ([.records[].questionId] | length == (unique | length))
  and (.progress | type == "object"
    and (keys - ["stage", "awaiting"] | length == 0)
    and (.stage | IN("관찰 유도", "힌트", "부분 설명", "전체 설명"))
    and (.awaiting | type == "string"))
  and ((has("learning") | not) or (.learning | valid_learning));
def validate_request($p):
  . as $b
  | if ($p | valid_payload | not) then error("저장 입력 형식 오류")
    elif ([.questions[] | select(.id == $p.questionId and .status == "진행")] | length) != 1
      then error("진행 중인 대상 질문이 없습니다")
    elif any($p.records[]; .questionId as $id | ([$b.questions[] | select(.id == $id and .record != "")] | length) != 1)
      then error("기록 대상 질문이 없습니다")
    elif ([$p.records[] | select(.questionId == $p.questionId)] | length) != 1
      then error("현재 질문의 발화가 필요합니다")
    elif ([$p.records[] | select(.questionId == $p.questionId) | .turns[-1].speaker] | first) != "assistant"
      then error("마지막 설명 발화가 필요합니다")
    else . end;
def apply_turn($p):
  .state |= (
    .activeQuestionId = $p.questionId
    | .stage = $p.progress.stage | .awaiting = $p.progress.awaiting
    | .lastTurn = ([$p.records[] | select(.questionId == $p.questionId) | .turns[-1] | {speaker,type}] | first)
    | .discoveredConcepts = reduce ($p.learning.addDiscoveredConcepts // [])[] as $name (.discoveredConcepts;
        if index($name) == null then . + [$name] else . end)
    | if $p.learning | has("partialConcepts") then .partialConcepts = $p.learning.partialConcepts else . end
    | if $p.learning | has("nextCandidates") then .nextCandidates = $p.learning.nextCandidates else . end
  );
def render_turns:
  map(if .speaker == "학습자" then
    "**학습자**\n\n" + (.text | split("\n") | map("> " + .) | join("\n"))
  else "**설명(" + .type + ")**\n\n" + .text end) | join("\n\n") + "\n";
