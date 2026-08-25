#!/usr/bin/env python3
"""계획서가 shared/plan-format.md 규격을 지키는지 검사한다.

사용법: python3 check_plan_format.py <계획서 경로>
위반이 하나라도 있으면 종료 코드 1을 반환한다.
"""

import argparse
import datetime
import re
import sys

SECTIONS = ["## 요약", "## 상태", "## 설계", "## 구현 순서", "## 테스트"]
STAGES = ["계획 확정", "구현 중", "구현 완료", "완료"]
STATUS_ROWS = ["단계", "마지막 갱신", "구현 진행률"]

ITEM_RE = re.compile(r"^- \[( |x)\] \*\*(\d+)\.\s*(.+?)\*\*(.*)$")
ROW_RE = re.compile(r"^\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$")
REVIEW_MARK = "<!-- 사용자 검토 필요 -->"


class Report:
    def __init__(self):
        self.errors = []
        self.notes = []

    def error(self, line, message):
        self.errors.append((line, message))

    def note(self, message):
        self.notes.append(message)


def check_sections(lines, report):
    """다섯 섹션이 정해진 문자열과 순서로 있는지 본다."""
    found = [(i + 1, ln.strip()) for i, ln in enumerate(lines) if ln.startswith("## ")]
    titles = [t for _, t in found]
    if titles != SECTIONS:
        report.error(0, f"섹션 구성이 규격과 다르다. 기대: {SECTIONS} / 실제: {titles}")
        return {}
    bounds = {}
    for idx, (line_no, title) in enumerate(found):
        end = found[idx + 1][0] - 1 if idx + 1 < len(found) else len(lines)
        bounds[title] = (line_no, end)
    return bounds


def check_status(lines, bounds, report):
    """상태 표의 세 행과 값 형식을 본다. 진행률은 (n, m)으로 돌려준다."""
    if "## 상태" not in bounds:
        return None
    start, end = bounds["## 상태"]
    rows = {}
    for i in range(start, end):
        m = ROW_RE.match(lines[i])
        if m and m.group(1) in STATUS_ROWS:
            rows[m.group(1)] = (i + 1, m.group(2))

    missing = [r for r in STATUS_ROWS if r not in rows]
    if missing:
        report.error(start, f"상태 표에 빠진 행: {', '.join(missing)}")
        return None

    line_no, stage = rows["단계"]
    if stage not in STAGES:
        report.error(line_no, f"단계 값이 잘못됐다: '{stage}'. 허용: {', '.join(STAGES)}")

    line_no, updated = rows["마지막 갱신"]
    try:
        datetime.date.fromisoformat(updated)
    except ValueError:
        report.error(line_no, f"마지막 갱신이 YYYY-MM-DD 형식의 날짜가 아니다: '{updated}'")

    line_no, progress = rows["구현 진행률"]
    m = re.match(r"(\d+)\s*/\s*(\d+)\s*(\(.*\))?$", progress)
    if not m:
        report.error(line_no, f"구현 진행률이 'n / m' 형식이 아니다: '{progress}'")
        return None
    return int(m.group(1)), int(m.group(2)), line_no


def check_items(lines, bounds, report):
    """구현 순서 항목의 표기, 번호 연속성을 본다. (전체 수, 체크된 수)를 돌려준다."""
    if "## 구현 순서" not in bounds:
        return None
    start, end = bounds["## 구현 순서"]
    items = []
    for i in range(start, end):
        line = lines[i]
        if not line.startswith("- ["):
            continue
        m = ITEM_RE.match(line)
        if not m:
            report.error(i + 1, "구현 항목 표기가 규격과 다르다. '- [ ] **n. 제목** — 설명' 형식을 쓴다")
            continue
        checked, number, title, rest = m.groups()
        if "—" not in rest:
            report.error(i + 1, f"항목 {number}에 설명이 없다. 제목 뒤에 '— 설명'을 붙인다")
        items.append((i + 1, checked == "x", int(number), title))

    if not items:
        report.error(start, "구현 순서에 항목이 하나도 없다")
        return None

    for expected, (line_no, _, number, _) in enumerate(items, start=1):
        if number != expected:
            report.error(line_no, f"항목 번호가 이어지지 않는다. 기대: {expected} / 실제: {number}")
            break

    done = sum(1 for _, checked, _, _ in items if checked)
    for line_no, checked, number, _ in items:
        if checked and not _has_record(lines, line_no, end):
            report.note(f"{line_no}행: 항목 {number}이 완료 표시됐지만 기록 줄이 없다")
    return len(items), done


def _has_record(lines, line_no, end):
    """완료된 항목 바로 아래에 두 칸 들여쓴 기록 줄이 있는지 본다."""
    i = line_no  # line_no는 1부터, lines는 0부터 → 다음 줄을 가리킨다
    while i < end and not lines[i].strip():
        i += 1
    return i < end and lines[i].startswith("  - ")


def check_review_marks(lines, report):
    """미해결 검토 표시를 찾는다.

    코드 블록과 인라인 코드 안의 표시는 규격을 설명하는 예시이므로 세지 않는다.
    """
    in_fence = False
    for i, line in enumerate(lines):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        stripped = re.sub(r"`[^`]*`", "", line)
        if REVIEW_MARK in stripped:
            report.error(i + 1, "미해결 검토 표시가 남아 있다. 사용자가 결정해야 넘어갈 수 있다")


def main():
    parser = argparse.ArgumentParser(description="계획서 규격 검사")
    parser.add_argument("path", help="계획서 파일 경로")
    args = parser.parse_args()

    try:
        text = open(args.path, encoding="utf-8").read()
    except OSError as exc:
        print(f"파일을 열 수 없다: {exc}", file=sys.stderr)
        return 2

    lines = text.splitlines()
    report = Report()

    bounds = check_sections(lines, report)
    status = check_status(lines, bounds, report)
    items = check_items(lines, bounds, report)

    if status and items:
        done_declared, total_declared, line_no = status
        total_actual, done_actual = items
        if total_declared != total_actual:
            report.error(line_no, f"진행률의 전체 수가 항목 수와 다르다. 표기: {total_declared} / 실제: {total_actual}")
        if done_declared != done_actual:
            report.error(line_no, f"진행률의 완료 수가 체크된 항목 수와 다르다. 표기: {done_declared} / 실제: {done_actual}")

    check_review_marks(lines, report)

    for line_no, message in report.errors:
        prefix = f"{args.path}:{line_no}" if line_no else args.path
        print(f"[위반] {prefix}: {message}")
    for message in report.notes:
        print(f"[참고] {message}")

    if report.errors:
        print(f"\n위반 {len(report.errors)}건. 진행하기 전에 고쳐야 한다.")
        return 1
    print(f"{args.path}: 규격을 만족한다.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
