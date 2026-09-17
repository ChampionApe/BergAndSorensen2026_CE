---
description: End-of-session pass — write the log entry, update the docs that drifted, check the size caps
---

Close out this working session. Do these in order, and do them from what actually happened in the
session rather than from what was planned:

1. **Decide where the entry goes.** Cross-cutting or structural work (repository organisation,
   conventions, decisions spanning theory and code) and all work on the theory or the writing → the root
   `RESEARCH_LOG.md`. Work inside the quantitative implementation → `model/RESEARCH_LOG.md`. If the
   session did both, write both, and keep each to its own scope rather than repeating one in the other.

2. **Write the entry: at most ~10 lines.** What changed, why, and where to look — a file, a note, a
   results path. Not a transcript, not a list of every command run. Newest entry first, dated.

3. **Update what drifted**, and only what materially changed: `CLAUDE.md`'s "Docs that must stay
   current" is the list, plus `model/README.md`'s file map and status, and `notes/TODO.md` — open items
   only, since closed work moves to the log rather than being ticked off in place.

4. **Check the size caps** in `CLAUDE.md`'s context budget. A `README.md` over ~100 lines, or a live
   note under `notes/` that has become a long-form investigation, goes to `archive/` with a pointer left
   behind — `git mv`, and index it in `archive/INDEX.md`. Superseded *writing* goes to
   `writing/_archive/` instead, with a `DESCRIPTION.md`, since that is where the theory history lives.

5. **Report** what you wrote and what you deliberately did not, then stop. Do not commit unless asked.
