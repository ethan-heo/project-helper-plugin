import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent


class StoreCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="learning-test-")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "javascript"
        shutil.copytree(SCRIPTS / "tests/fixtures/javascript", self.repo)
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True, capture_output=True)
        self.package = self.repo / "packages/counter"

    def call(self, mode, payload=None, ok=True, env=None):
        result = subprocess.run(["bash", str(SCRIPTS / "learning-store.sh"), mode, str(self.package)],
                                input=json.dumps(payload, ensure_ascii=False) if payload is not None else None,
                                text=True, capture_output=True, env={**os.environ, **(env or {})})
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def edit(self, relative, fn):
        path = self.package / relative
        value = fn(json.loads(path.read_text()))
        path.write_text(json.dumps(value, ensure_ascii=False))

    def snapshot(self):
        return {str(p.relative_to(self.repo)): p.read_bytes() for p in self.repo.rglob("*")
                if p.is_file() and ".git" not in p.parts}

    def payload(self, operation="turn-1"):
        return {"operationId": operation, "questionId": "javascript-counter-2",
                "records": [{"questionId": "javascript-counter-2", "turns": [
                    {"speaker": "학습자", "type": "답변", "text": '"증가"가 먼저입니다.\n두 번째 줄\n'},
                    {"speaker": "assistant", "type": "관찰 유도", "text": '코드를 보세요.\n\n```js\nconsole.log(`$HOME`);\n```\n'}]}],
                "progress": {"stage": "관찰 유도", "awaiting": "다음 답변"},
                "learning": {"addDiscoveredConcepts": ["증가 연산"], "partialConcepts": []}}


class ReadTests(StoreCase):
    def test_review_keeps_questions_without_record(self):
        self.edit("questions.json", lambda qs: [{**q, "record": ""} for q in qs])
        value = self.call("review-data")
        self.assertEqual(len(value["questions"]), 3)
        self.assertTrue(all(q["date"] is None and q["recordPath"] is None for q in value["questions"]))

    def test_review_keeps_order_dates_and_last_step(self):
        before = self.snapshot()
        value = self.call("review-data")
        self.assertEqual([q["id"] for q in value["questions"]],
                         [f"javascript-counter-{n}" for n in (1, 2, 3)])
        self.assertEqual([q["date"] for q in value["questions"]], ["2026-09-15"] * 3)
        self.assertEqual(value["questions"][0]["lastStep"], "반환 값")
        self.assertIsNone(value["questions"][2]["lastStep"])
        self.assertNotIn("console.log", json.dumps(value))
        self.assertEqual(before, self.snapshot())

    def test_context_preserves_files_and_omits_transcript(self):
        before = self.snapshot()
        value = self.call("context")
        self.assertEqual(value["currentQuestion"]["id"], "javascript-counter-2")
        self.assertEqual(value["currentQuestion"]["path"], ["출력 관찰", "증가 시점", "반환 값"])
        self.assertEqual(value["goal"], "상태 변경과 출력 순서를 이해합니다.")
        self.assertNotIn("console.log", json.dumps(value))
        self.assertEqual(before, self.snapshot())

    def test_empty_and_completed(self):
        self.edit("state.json", lambda s: {**s, "activeQuestionId": "javascript-counter-1"})
        self.assertEqual(self.call("context")["currentQuestion"]["status"], "완료")
        self.edit("state.json", lambda s: {k: v for k, v in s.items() if k != "activeQuestionId"})
        self.edit("questions.json", lambda q: [])
        self.assertIsNone(self.call("context")["currentQuestion"])

    def test_invalid_json_and_reference(self):
        self.edit("state.json", lambda s: {**s, "activeQuestionId": "missing"})
        before = self.snapshot()
        self.call("context", ok=False)
        self.assertEqual(before, self.snapshot())
        (self.package / "state.json").write_text("{")
        self.call("context", ok=False)

    def test_missing_and_escaping_record(self):
        (self.package / "records/2026-09-15/02-question.md").unlink()
        self.call("context", ok=False)
        self.edit("questions.json", lambda qs: [{**q, "record": "records/../../state.json"} for q in qs])
        self.call("context", ok=False)


class WriteTests(StoreCase):
    def test_concurrent_existing_and_new_commands_are_rejected_then_retry(self):
        script = '''source "$1/store-common.sh"
source "$1/store-transaction.sh"
store_init "$2"
store_lock
echo ready
read -r release
'''
        holder = subprocess.Popen(["bash", "-c", script, "lock", str(SCRIPTS), str(self.package)],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.assertEqual(holder.stdout.readline().strip(), "ready")
            before = self.snapshot()
            self.assertIn("busy", self.call("save-turn", self.payload(), ok=False).stderr)
            old = subprocess.run(["bash", str(SCRIPTS / "questions-store.sh"), "start", str(self.package), "javascript-counter-1"], capture_output=True)
            self.assertNotEqual(old.returncode, 0)
            self.assertEqual(before, self.snapshot())
        finally:
            holder.communicate("release\n", timeout=5)
        self.call("save-turn", self.payload())
        old = subprocess.run(["bash", str(SCRIPTS / "questions-store.sh"), "start", str(self.package), "javascript-counter-1"], capture_output=True)
        self.assertEqual(old.returncode, 0, old.stderr)
        self.assertIn("증가 연산", self.call("context")["state"]["discoveredConcepts"])

    def test_committed_request_survives_missing_receipt_publication(self):
        self.call("finish-question", self.payload(), ok=False,
                  env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_KILL_COMMITTED": "1"})
        before = self.snapshot()
        self.call("finish-question", self.payload())
        self.assertEqual(before, self.snapshot())

    def test_finish_updates_all_states_and_accumulated_concepts(self):
        self.call("save-turn", self.payload())
        payload = self.payload("finish-1")
        del payload["learning"]
        result = self.call("finish-question", payload)
        self.assertEqual(len(result["changedFiles"]), 4)
        value = self.call("context")
        self.assertEqual(value["currentQuestion"]["status"], "완료")
        self.assertIn("증가 연산", value["discoveredConcepts"])
        before = self.snapshot()
        self.assertEqual(result, self.call("finish-question", payload))
        self.assertEqual(before, self.snapshot())
        checked = subprocess.run(["bash", str(SCRIPTS / "validate-learning-repo.sh"), str(self.repo)], capture_output=True)
        self.assertEqual(checked.returncode, 0, checked.stderr)

    def test_finish_rolls_back_each_of_four_files(self):
        before = self.snapshot()
        for position in (1, 2, 3, 4):
            self.call("finish-question", self.payload(), ok=False,
                      env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_FAIL_AFTER": str(position)})
            self.assertEqual(before, self.snapshot())
        self.call("finish-question", self.payload())

    def test_killed_finish_is_recovered_on_retry(self):
        payload = self.payload()
        self.call("finish-question", payload, ok=False,
                  env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_KILL_AFTER": "4"})
        self.call("context", ok=False)
        self.call("finish-question", payload)
        record = (self.package / "records/2026-09-15/02-question.md").read_text()
        self.assertEqual(record.count('"증가"가 먼저입니다.'), 1)

    def test_save_turn_preserves_transcript_and_replays(self):
        payload = self.payload()
        result = self.call("save-turn", payload)
        self.assertEqual(len(result["changedFiles"]), 2)
        state = json.loads((self.package / "state.json").read_text())
        self.assertEqual(state["discoveredConcepts"], ["변수", "증가 연산"])
        self.assertEqual(state["partialConcepts"], [])
        record = (self.package / "records/2026-09-15/02-question.md").read_text()
        self.assertIn(payload["records"][0]["turns"][1]["text"], record)
        self.assertIn('> "증가"가 먼저입니다.\n> 두 번째 줄\n> ', record)
        before = self.snapshot()
        self.assertEqual(self.call("save-turn", payload), result)
        self.assertEqual(before, self.snapshot())
        payload["progress"]["awaiting"] = "다른 값"
        self.assertIn("duplicate_id", self.call("save-turn", payload, ok=False).stderr)

    def test_save_rolls_back_both_files(self):
        before = self.snapshot()
        for position in (1, 2):
            self.call("save-turn", self.payload(), ok=False,
                      env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_FAIL_AFTER": str(position)})
            self.assertEqual(before, self.snapshot())
        self.call("save-turn", self.payload())

    def test_invalid_request_does_not_block_reads(self):
        payload = self.payload()
        payload["questionId"] = "unknown"
        before = self.snapshot()
        self.call("save-turn", payload, ok=False)
        self.assertEqual(before, self.snapshot())
        self.call("context")

    def test_question_switch_routes_each_record(self):
        payload = self.payload()
        payload["records"].insert(0, {"questionId": "javascript-counter-1", "turns": [
            {"speaker": "assistant", "type": "현상", "text": "이전 질문의 관찰 결과"}]})
        self.call("save-turn", payload)
        one = (self.package / "records/2026-09-15/01-question.md").read_text()
        two = (self.package / "records/2026-09-15/02-question.md").read_text()
        self.assertIn("이전 질문의 관찰 결과", one)
        self.assertNotIn("이전 질문의 관찰 결과", two)


class TransactionTests(StoreCase):
    def test_receipt_replay_and_id_conflict(self):
        script = '''set -euo pipefail
source "$1/store-common.sh"
source "$1/store-transaction.sh"
store_init "$2"
store_lock
store_recover
store_request probe "$3"
if [[ "$STORE_REPLAY" == 1 ]]; then printf '%s' "$STORE_RESULT"; exit; fi
store_begin
printf 'new\\n' > "$STORE_META/pending/value"
store_stage "packages/counter/records/2026-09-15/01-question.md" "$STORE_META/pending/value"
STORE_RESULT='{"saved":true}'
store_commit
printf '%s' "$STORE_RESULT"
'''
        def execute(value):
            return subprocess.run(["bash", "-c", script, "probe", str(SCRIPTS), str(self.package), value], capture_output=True)
        first = execute('{"operationId":"test","value":1}')
        self.assertEqual(first.returncode, 0, first.stderr)
        before = self.snapshot()
        second = execute('{"value":1,"operationId":"test"}')
        self.assertEqual(second.stdout, first.stdout)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(before, self.snapshot())
        self.assertNotEqual(execute('{"operationId":"test","value":2}').returncode, 0)

    def questions(self, mode, *args, env=None):
        return subprocess.run(["bash", str(SCRIPTS / "questions-store.sh"), mode, str(self.package), *args],
                              text=True, capture_output=True, env={**os.environ, **(env or {})})

    def legacy(self):
        qs = json.loads((self.package / "questions.json").read_text())
        self.edit("state.json", lambda s: {**s, "questions": qs, "activeQuestion": qs[1]["question"]})
        text = "\n".join(f'### {q["question"]}\n- 관점: {q["viewpoint"]}\n1. 관찰\n2. 원인' for q in qs)
        (self.package / "questions.md").write_text(text)

    def test_legacy_migration_rolls_back_each_file(self):
        self.legacy()
        before = self.snapshot()
        for position in (1, 2, 3):
            result = self.questions("migrate", env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_FAIL_AFTER": str(position)})
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(before, self.snapshot(), result.stderr)
        result = self.questions("migrate")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.package / "questions.md").exists())

    def test_killed_migration_requires_recovery(self):
        self.legacy()
        before = self.snapshot()
        result = self.questions("migrate", env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_KILL_AFTER": "2"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("recovery_required", self.call("context", ok=False).stderr)
        # 다음 저장은 먼저 복구한 뒤 요청을 검증한다. 잘못된 요청이면 복구한 원본만 남는다.
        self.questions("start", "unknown")
        self.assertEqual(before, self.snapshot())

    def test_existing_start_and_complete_share_transaction(self):
        before = self.snapshot()
        result = self.questions("start", "javascript-counter-1", env={"LEARNING_STORE_TESTING": "1", "LEARNING_STORE_FAIL_AFTER": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(before, self.snapshot())
        result = self.questions("start", "javascript-counter-1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.questions("complete", "javascript-counter-1").returncode, 0)


if __name__ == "__main__":
    unittest.main()
