# resume

For MacOS install [The MacTeX-2024 Distribution](https://www.tug.org/mactex/mainpage2024.html)

My resume in [pdf](resume.pdf) version, created from [LaTeX](https://www.latex-project.org/) template.

## Formats

| File | Purpose |
| --- | --- |
| [resume.tex](resume.tex) | Source of truth (LaTeX, class in [developercv.cls](developercv.cls)) |
| [resume.pdf](resume.pdf) | Print/share version, built from `resume.tex` (2 pages) |
| [resume.md](resume.md) | Plain-text version for humans, LLMs and parsers (more detailed for pre-2012 roles) |
| [resume.json](resume.json) | [JSON Resume](https://jsonresume.org/) version, derived from `resume.md` |

The PDF is built to be machine-readable: Unicode-mapped glyphs, no hyphenation, text labels for the contact icons, and document metadata (title, author, language).

## Workflow

```sh
./build.sh   # builds resume.pdf (two pdflatex passes)
./check.sh   # PDF readability + sync between .tex, .pdf, .md and .json
./lint.sh    # chktex (skipped if not installed)
```

When the content changes, update `resume.tex`, `resume.md` and `resume.json` together, then run `./build.sh` and `./check.sh`. The "Last updated" line in `resume.md` must match the month of the PDF build (`check.sh` enforces it). `check.sh` needs `python3` and `pdftotext`/`pdfinfo` (poppler, e.g. `brew install poppler`).
