# Overleaf sync

`writing/overleaf.py` moves a writing project to and from Overleaf. Three are registered:

- **`paper`** (`writing/paper/`) — the paper, co-authored with Peter Birch Sørensen. This **is** the
  Overleaf project at <https://da.overleaf.com/project/6a4378918a3c3c23fe9d9afa>.
- **`docs`** (`writing/docs/`) — the theory note. This **is** the Overleaf project at
  <https://da.overleaf.com/project/6a74e6678784f21dd0dbe8bc>.
- **`quant`** (`writing/quant/`) — the quantitative note, split from the theory note 2026-09-17. This
  **is** the Overleaf project at <https://da.overleaf.com/project/6aabe8521dad1168d7b72885>.

Every command takes the project name. The module's docstring is the full manual
(`python writing\overleaf.py --help`); it imports only the standard library, so any Python on the
machine runs it. `/overleaf` in Claude Code drives it with the dry-run discipline below.

## 1. Connecting a project to its Overleaf project (once)

All three registered projects are connected. The steps remain for the next one: create the empty
Overleaf project, add its line to `PROJECTS` in `overleaf.py`, then do the first push once, and the
day-to-day commands of §3 work from then on. `docs` below stands for the project name.

1. Check what is in the Overleaf project now. If it is empty or a stub, step 4 simply fills it. If
   anything has been written there, read it first — the first push overwrites.
2. **Menu → Git** in the project for the `https://git.overleaf.com/<id>` URL; token from **Account
   settings → Git integration** (needs Overleaf premium — without it, use the zip route in §4).
3. Dry-run, **from your own terminal** so the credential manager can prompt for the token:
   ```
   python writing\overleaf.py pull docs --url https://git.overleaf.com/<id> --dry-run
   ```
   The URL is remembered beside the clone under `writing/exports/`, so it is given once and never again.
4. Then the first push:
   ```
   python writing\overleaf.py push docs --force
   ```
   On a *first* push nothing is known about the online history, so every online file that differs counts
   as a conflict; `--force` once makes Overleaf match this folder. After that `--force` should never be
   needed again — if it seems to be, someone edited online and `pull` is the answer.

The push runs the same reference check as the export, and refuses if any `\input`, `\includegraphics`
or `\addbibresource` does not resolve — including a reference that matches only case-insensitively.
That is not pedantry: Overleaf runs on Linux, so `\addbibresource{references.bib}` finds
`References.bib` here and fails there. It caught exactly that in `docs/Packages.tex` on its first run.

## 2. The cutover for `paper` (once, and it has a trap)

The paper's Overleaf project was previously kept in step with the separate repository
`BergAndSorensen2026_circular` through **Overleaf's GitHub integration**, which is a different
mechanism from this script. Do not run both against one project.

**Before the first push, establish what is on Overleaf now.** The local copy is ahead: it carries the
$\zeta$ versus $\lambda^K$ normalisation and the installed-capital price $q = 1 + \phi^K p^M$, which
the GitHub repository does not. But Overleaf may equally carry a co-author's edits made since
2026-08-06 that never reached that repository. `--force` would discard them silently.

1. In the Overleaf project, **Menu → History** — check whether anyone has edited since 2026-08-06.
   If nobody has, the local copy is strictly newer and step 3 is safe.
2. If anyone has, bring those edits down first and merge them by hand:
   ```
   python writing\overleaf.py pull paper --url https://git.overleaf.com/<id> --dry-run
   ```
   Read the plan, take what belongs, and commit it separately so the co-author's edits stay legible in
   the history.
3. Then, once, from your own terminal:
   ```
   python writing\overleaf.py push paper --force
   ```
4. In Overleaf, **turn the GitHub integration off** for this project (Menu → GitHub → unlink), so there
   is one route in and one route out. The old repository stays on GitHub as history; nothing is deleted.

## 3. Day to day

**Bringing co-authors' edits back — always dry-run first:**
```
python writing\overleaf.py pull paper --dry-run
python writing\overleaf.py pull paper
git add -A; git commit -m "Overleaf edits, <date>"
```
Read the plan, not just the summary line:
- `PROTECTED` — a file carrying the `%% GENERATED` banner was edited online. The edit is **not**
  applied; reproduce it at its source and rebuild, or it vanishes at the next build. Nothing is
  generated in this repository yet, so this line should not appear — if it does, something new is.
- `binary` — a figure that differs, deliberately left alone, so an older upload cannot roll back a
  figure that has since been rebuilt. `--all` overrides, and is rarely what you want.
- `only local` — here but not on Overleaf. Usually harmless; occasionally a deleted section.

A pull never deletes anything locally. Commit it separately from your own work so the co-authors' edits
stay legible in the history.

**Sending changes up:**
```
python writing\overleaf.py push paper
```
Push refuses if a file was edited online since the last push. **Do not reach for `--force`** — run
`pull --dry-run`, resolve, push again. Force discards a co-author's work.

## 4. Without git access (free Overleaf)

The same two directions by zip: `export paper` and upload to the existing project; and Overleaf's
**Menu → Download → Source**, then `import paper <zip> --dry-run` and then for real. Identical
protections apply.

## Traps

- The clone of each Overleaf project lives in `writing/exports/git-<project>/`, which is **gitignored**
  — it is a second git repository and must not end up nested inside this one.
- `writing/paper/localfiles/` (co-authors' Word drafts) and `writing/_archive/` are excluded from the
  upload in `overleaf.py`'s `SKIP_DIRS`. Overleaf is a shared surface; neither belongs on it.
- **Line endings are not drift.** `writing/paper/` is LF and the old GitHub repository is CRLF, which
  made two nearly identical copies look like they differed by hundreds of lines. Compare with
  `diff --strip-trailing-cr` before believing a diff of tex between the two.
- Overleaf's git remote never touches this repository's history. A co-author's edit arrives through the
  import rules, reviewable, not as a merge nobody asked for.
- Compile artefacts (`.aux`, `.bbl`, `.synctex.gz`, the root `main.pdf`) are excluded in both directions.
- Each project folder must be self-contained: it is what gets uploaded, so a file it `\input`s from
  outside the folder compiles here and fails there. That is why `paper/` and `docs/` each carry their own
  `Packages.tex` and `References.bib` rather than sharing one. The reference check catches a violation
  before the upload, not after.
