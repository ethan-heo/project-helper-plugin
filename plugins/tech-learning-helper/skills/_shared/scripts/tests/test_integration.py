import json
import re
import subprocess
import unittest
from pathlib import Path

from test_store import SCRIPTS, StoreCase


class IntegrationTests(StoreCase):
    def test_resume_switch_finish_experiment_and_review(self):
        value = self.call("context")
        self.assertTrue(value["needsPositionConfirmation"])
        new_record = self.package / "records/2026-09-15/04-structure.md"
        new_record.write_text("# 2026-09-15\n\n## 함수의 역할\n")
        added = subprocess.run(["bash", str(SCRIPTS / "questions-store.sh"), "add", str(self.package),
                                "구조", "records/2026-09-15/04-structure.md", "함수의 역할은 무엇인가요?",
                                "함수의 위치", "입력과 출력"], capture_output=True, text=True, check=True)
        question = added.stdout.strip()
        payload = self.payload("switch")
        payload["questionId"] = question
        payload["records"][0]["questionId"] = question
        payload["progress"]["stepIndex"] = 1
        payload["learning"]["nextCandidates"] = [{"kind": "resume", "label": "출력 질문 이어 하기",
                                                    "questionId": "javascript-counter-2", "resumeStep": 2}]
        self.call("save-turn", payload)
        payload["operationId"] = "finish-structure"
        payload["progress"]["stepIndex"] = 2
        self.call("finish-question", payload)
        experiment = self.payload("experiment-structure")
        experiment["questionId"] = question
        experiment["records"][0]["questionId"] = question
        experiment["records"][0]["turns"][-1]["type"] = "실험"
        experiment["progress"]["stepIndex"] = None
        self.call("save-turn", experiment)
        result = self.call("review-data")
        self.assertEqual(result["questions"][-1]["status"], "완료")
        self.assertEqual(result["nextCandidates"][0]["resumeStep"], 2)
        resumed = self.payload("resume-output")
        resumed["progress"]["stepIndex"] = result["nextCandidates"][0]["resumeStep"]
        resumed["learning"]["nextCandidates"] = []
        self.call("save-turn", resumed)
        context = self.call("context")
        self.assertEqual(context["state"]["stepIndex"], 2)
        self.assertEqual(context["currentQuestion"]["id"], "javascript-counter-2")
        subprocess.run(["bash", str(SCRIPTS / "validate-learning-repo.sh"), str(self.repo)],
                       check=True, capture_output=True)

    def test_skill_reference_paths_and_store_contract(self):
        skills = SCRIPTS.parent.parent
        for path in skills.rglob("*.md"):
            if "tests" in path.parts:
                continue
            text = path.read_text()
            for target in re.findall(r"\]\(([^)]+)\)", text):
                relative = target.split("#")[0]
                if not relative or "://" in relative or relative.startswith("records/"):
                    continue
                self.assertTrue((path.parent / relative).exists(), (path, relative))
        for name in ("learn", "trace", "structure", "experiment", "review"):
            text = (skills / name / "SKILL.md").read_text()
            self.assertIn("rules/store.md", text)
            self.assertIn("disable-model-invocation: true", text)
        review = (skills / "_shared/rules/review.md").read_text()
        self.assertIn("learning-store.sh review-data", review)
        record = (skills / "_shared/rules/record.md").read_text()
        self.assertIn("save-turn", record)
        self.assertIn("finish-question", record)


if __name__ == "__main__":
    unittest.main()
