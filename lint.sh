#!/bin/bash
# LaTeX lint (chktex). Skipped with a warning when chktex is not installed.

cd "$(dirname "$0")" || exit 1

if ! command -v chktex >/dev/null 2>&1; then
    echo "chktex not installed, skipping LaTeX lint (install with: tlmgr install chktex)" >&2
    exit 0
fi

chktex -q --inputfiles=0 resume.tex
