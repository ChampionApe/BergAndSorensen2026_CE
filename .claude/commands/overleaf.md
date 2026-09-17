---
description: Sync a writing project (paper|docs|quant) with Overleaf — pull edits, or push local changes
argument-hint: pull|push [project]
---

Sync one writing project with Overleaf using `writing/overleaf.py`. Registered projects: `paper`
(`writing/paper/` — the Overleaf project at <https://da.overleaf.com/project/6a4378918a3c3c23fe9d9afa>),
`docs` (`writing/docs/`, the theory note — the Overleaf project at
<https://da.overleaf.com/project/6a74e6678784f21dd0dbe8bc>) and `quant` (`writing/quant/`, the
quantitative note — the Overleaf project at <https://da.overleaf.com/project/6aabe8521dad1168d7b72885>).
Default is `paper` if none is given;
`notes/overleafSync.md` is the procedure this command follows, and §2 there is a cutover that has not
necessarily happened yet — check before a first push on `paper`.
Arguments: $ARGUMENTS

**Always dry-run first, and show the plan before writing anything.**

For `pull` (bringing co-authors' Overleaf edits into the repo):

1. Run `pull <project> --dry-run` and show the output.
2. Read the plan critically, not just for conflicts:
   - a file listed as `PROTECTED` carries the `%% GENERATED` banner — someone edited a generated file
     online. That edit must be reproduced at its source and rebuilt; say so explicitly rather than
     letting it disappear at the next build. Nothing is generated in this repository yet, so this line
     appearing means something new is.
   - `binary` lines are figures, deliberately not written: an older Overleaf zip must not roll back a
     figure that has since been rebuilt.
   - `only local` means a file exists here but not on Overleaf. Usually harmless; occasionally it means
     someone deleted a section.
3. If the plan is clean, run it for real, then show `git diff --stat` so the incoming edits are visible
   before they are committed.

For `push` (sending local changes to Overleaf):

1. Check `git status` first — push what is committed, not a half-finished edit.
2. Run `push <project>`. If it refuses because files were edited online since the last push, **do not
   reach for `--force`**: run `pull --dry-run`, resolve, and push again. `--force` discards a
   co-author's work.
3. `--force` is defensible exactly once per project, on the very first push, and only after
   `notes/overleafSync.md` §2 has been followed — which means after the Overleaf history has been
   checked by hand. Never propose it otherwise.

Report what moved in each direction, and never commit in this repository without being asked.
