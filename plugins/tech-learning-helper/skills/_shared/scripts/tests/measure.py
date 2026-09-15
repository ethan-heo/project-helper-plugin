#!/usr/bin/env python3
"""로컬 조회 명령을 측정한다. AI 응답 시간·토큰을 추정하지 않는다."""
import argparse
import json
import platform
import shutil
import statistics
import subprocess
import tempfile
import time
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent
FIXTURE = Path(__file__).resolve().parent / "fixtures/javascript"


def run(args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def measure(mode, repeats):
    samples = []
    for trial in range(1, repeats + 1):
        for scenario in ("start", "resume", "review", "answer", "finish"):
            with tempfile.TemporaryDirectory(prefix="learning-measure-") as tmp:
                repo = Path(tmp) / "javascript"
                shutil.copytree(FIXTURE, repo)
                run(["git", "init", "-q", str(repo)])
                package = repo / "packages/counter"
                script = lambda name, *args: ["bash", str(SCRIPTS / name), *map(str, args)]
                commands = []
                if scenario == "start":
                    commands = [script("resume-scan.sh", "repos", tmp),
                                script("resume-scan.sh", "packages", repo)]
                elif mode == "after" and scenario in ("resume", "review"):
                    commands = [script("learning-store.sh", "context" if scenario == "resume" else "review-data", package)]
                elif scenario == "resume":
                    commands = [["cat", str(repo / "state.json")],
                                ["cat", str(package / "state.json")],
                                ["cat", str(package / "README.md")],
                                script("questions-store.sh", "get", package, "javascript-counter-2")]
                elif scenario == "review":
                    commands = [["cat", str(package / "state.json")],
                                ["cat", str(package / "README.md")],
                                script("questions-store.sh", "toc", package)]
                    commands += [script("questions-store.sh", "get", package, f"javascript-counter-{n}") for n in (1, 2, 3)]
                started = time.perf_counter()
                output = b"".join(run(command) for command in commands)
                elapsed = time.perf_counter() - started
                samples.append({"trial": trial, "scenario": scenario,
                                "local_seconds": elapsed if commands else None,
                                "local_commands": len(commands) if commands else None,
                                "output_bytes": len(output) if commands else None,
                                "first_explanation_seconds": None,
                                "response_complete_seconds": None,
                                "save_complete_seconds": None,
                                "tool_calls": None, "input_tokens": None,
                                "output_tokens": None, "reasoning_tokens": None,
                                "unavailable_reason": "실제 AI 세션 미측정; 저장은 기존 AI 작성 명령과 동등한 고정 실행이 없어 로컬 비교 제외"})
    summary = {}
    for scenario in ("start", "resume", "review"):
        rows = [s for s in samples if s["scenario"] == scenario]
        seconds = [r["local_seconds"] for r in rows]
        summary[scenario] = {"median_local_seconds": statistics.median(seconds),
                             "min_local_seconds": min(seconds), "max_local_seconds": max(seconds),
                             "local_commands": rows[0]["local_commands"],
                             "output_bytes": rows[0]["output_bytes"]}
    return {"mode": mode, "repeats": repeats, "platform": platform.platform(),
            "git_revision": run(["git", "rev-parse", "HEAD"]).decode().strip(),
            "bash": run(["bash", "--version"]).decode().splitlines()[0],
            "jq": run(["jq", "--version"]).decode().strip(),
            "ai_environment": None, "user_reference": {"seconds": 30, "reasoning_tokens": 1000},
            "samples": samples, "summary": summary}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("before", "after"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--repeats", type=int, default=5)
    args = parser.parse_args()
    if args.repeats < 1:
        parser.error("repeats는 양수여야 합니다")
    args.output.write_text(json.dumps(measure(args.mode, args.repeats), ensure_ascii=False, indent=2) + "\n")
    print(f"로컬 측정 {args.repeats}회 완료; AI 응답·토큰은 미측정")
