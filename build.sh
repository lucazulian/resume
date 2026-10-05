#!/bin/bash
# Build resume.pdf from resume.tex.
# Two passes are required: longtable (entry columns) and hyperref (links, metadata)
# need the .aux file produced by the previous pass.
set -euo pipefail

cd "$(dirname "$0")"

PDFLATEX="${PDFLATEX:-/Library/TeX/texbin/pdflatex}"
command -v "$PDFLATEX" >/dev/null 2>&1 || PDFLATEX="$(command -v pdflatex)"

for pass in 1 2; do
    if ! "$PDFLATEX" -interaction=nonstopmode -halt-on-error resume.tex >/dev/null; then
        echo "pdflatex failed on pass $pass, last lines of resume.log:" >&2
        tail -n 30 resume.log >&2
        exit 1
    fi
done

echo "Built resume.pdf ($(pdfinfo resume.pdf 2>/dev/null | awk '/^Pages:/ {print $2}') pages)"
