#!/bin/bash
# Sanity checks for the resume: PDF machine-readability and sync between
# resume.tex (source of truth), resume.pdf, resume.md and resume.json.
#
# Usage: ./check.sh            (after ./build.sh)
#        MAX_PAGES=3 ./check.sh
# Requires: python3, pdftotext and pdfinfo (poppler).
# Exit code is 1 when at least one check fails.

cd "$(dirname "$0")" || exit 1

for tool in python3 pdftotext pdfinfo; do
    command -v "$tool" >/dev/null 2>&1 || { echo "missing tool: $tool" >&2; exit 2; }
done

exec python3 - "$@" <<'PY'
import json
import os
import re
import subprocess
import sys
import zlib

MAX_PAGES = int(os.environ.get("MAX_PAGES", "2"))
failures = []


def check(ok, label, detail=""):
    print(("PASS  " if ok else "FAIL  ") + label + (f" -> {detail}" if detail and not ok else ""))
    if not ok:
        failures.append(label)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


for path in ("resume.tex", "resume.pdf", "resume.md", "resume.json"):
    if not os.path.exists(path):
        check(False, f"{path} exists")
if failures:
    sys.exit(1)

tex, md = read("resume.tex"), read("resume.md")
try:
    data = json.loads(read("resume.json"))
    check(True, "resume.json is valid JSON")
except ValueError as e:
    data = {}
    check(False, "resume.json is valid JSON", str(e))

# --- PDF -------------------------------------------------------------------
info = run("pdfinfo", "resume.pdf")
field = lambda name: (re.search(rf"^{name}:\s*(.*)$", info, re.M) or [None, ""])[1].strip()

pages = int(field("Pages") or 0)
check(0 < pages <= MAX_PAGES, f"PDF has at most {MAX_PAGES} pages", f"{pages} pages")
check(bool(field("Title")) and bool(field("Author")), "PDF metadata has Title and Author")

pdf_bytes = open("resume.pdf", "rb").read()
lang_found = b"/Lang" in pdf_bytes
for m in re.finditer(rb"stream\r?\n(.*?)\r?\nendstream", pdf_bytes, re.S):
    if lang_found:
        break
    try:
        lang_found = b"/Lang" in zlib.decompress(m.group(1))
    except zlib.error:
        pass
check(lang_found, "PDF declares a document language (/Lang)")

newest_source = max(os.path.getmtime(p) for p in ("resume.tex", "developercv.cls"))
check(os.path.getmtime("resume.pdf") >= newest_source, "resume.pdf is newer than resume.tex and developercv.cls (run ./build.sh)")

raw = run("pdftotext", "-raw", "resume.pdf", "-")
lines = [l for l in raw.splitlines() if l.strip()]
check(lines[:2] == ["Luca", "Zulian"] or [l.strip() for l in lines[:2]] == ["Luca", "Zulian"], "name is extracted as 'Luca' 'Zulian'", repr(lines[:2]))
header = "\n".join(lines[:10])
check(all(label in header for label in ("Phone:", "Email:", "LinkedIn:", "GitHub:")), "contact icons are extracted as text labels")
check(header.isascii(), "no stray icon glyphs in the header text", repr([c for c in header if not c.isascii()]))
fused = sorted(set(re.findall(r"[A-Za-z]{25,}", raw)))
check(not fused, "no fused words in raw text extraction", ", ".join(fused))

# --- tex -------------------------------------------------------------------
last = [l for l in tex.splitlines() if l.strip()][-1].strip()
check(last == r"\end{document}", r"nothing after \end{document} in resume.tex", last)

# --- cross-file consistency --------------------------------------------------
BRITISH_FORBIDDEN = re.compile(r"\b\w*(analyz|optimiz|customiz|summariz|specializ|organiz|behavior|recogniz)\w*\b", re.I)
for name, text in (("resume.tex", tex), ("resume.md", md), ("resume.json", json.dumps(data))):
    bad = sorted({m.group(0) for m in BRITISH_FORBIDDEN.finditer(text)})
    check(not bad, f"British spelling in {name}", ", ".join(bad))

for name, text in (("resume.tex", tex), ("resume.md", md), ("resume.json", json.dumps(data))):
    check("Staff Engineer" in text and "18+ years" in (data.get("basics", {}).get("summary", "") if name == "resume.json" else text),
          f"{name} mentions 'Staff Engineer' and '18+ years'")

date_re = re.compile(r"\b(0[1-9]|1[0-2])/(\d{4})\b")
tex_dates = {m.group(0) for m in date_re.finditer(tex)}
md_dates = {m.group(0) for m in date_re.finditer(md)}
check(tex_dates == md_dates, "MM/YYYY dates match between resume.tex and resume.md",
      f"only in tex: {sorted(tex_dates - md_dates)}, only in md: {sorted(md_dates - tex_dates)}")

pdf_dates = {m.group(0) for m in date_re.finditer(raw)}
check(tex_dates == pdf_dates, "MM/YYYY dates match between resume.tex and resume.pdf",
      f"only in tex: {sorted(tex_dates - pdf_dates)}, only in pdf: {sorted(pdf_dates - tex_dates)}")

json_dates = set()
for item in data.get("work", []):
    for key in ("startDate", "endDate"):
        if item.get(key):
            y, m = item[key].split("-")
            json_dates.add(f"{m}/{y}")
md_work_dates = set()
experience = re.search(r"^## Experience\n(.*?)(?=^## )", md, re.S | re.M)
if experience:
    md_work_dates = {m.group(0) for m in date_re.finditer(experience.group(1))}
check(json_dates == md_work_dates, "work dates match between resume.md and resume.json",
      f"only in json: {sorted(json_dates - md_work_dates)}, only in md: {sorted(md_work_dates - json_dates)}")

md_orgs = set()
if experience:
    for head in re.findall(r"^### .*? — (.*)$", experience.group(1), re.M):
        md_orgs.add(re.sub(r"\s*\(.*\)$", "", head).strip())
tex_flat = re.sub(r"\\textnormal|[{}\\]", "", tex)
missing = sorted(o for o in md_orgs if o.split(" S.")[0] not in tex_flat)
check(not missing, "every company in resume.md appears in resume.tex", ", ".join(missing))
json_orgs = {w["name"] for w in data.get("work", [])}
check(json_orgs == {re.sub(r"\s*\(.*\)$", "", o) for o in md_orgs}, "companies match between resume.md and resume.json",
      f"only in json: {sorted(json_orgs - md_orgs)}, only in md: {sorted(md_orgs - json_orgs)}")

# --- freshness ---------------------------------------------------------------
created = field("CreationDate")
month_year = re.search(r"(\w{3})\s+(\w{3})\s+\d+\s+[\d:]+\s+(\d{4})", created)
if month_year:
    import calendar
    abbr = {m: calendar.month_name[i] for i, m in enumerate(calendar.month_abbr) if m}
    expected = f"{abbr[month_year.group(2)]} {month_year.group(3)}"
    check(f"Last updated: {expected}" in md, f"resume.md says 'Last updated: {expected}' (month of the PDF build)")
    check(f"Last updated: {expected}" in raw, f"resume.pdf says 'Last updated: {expected}'")

print()
if failures:
    print(f"{len(failures)} check(s) failed")
    sys.exit(1)
print("All checks passed")
PY
