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


if __name__ == "__main__":
    unittest.main()
