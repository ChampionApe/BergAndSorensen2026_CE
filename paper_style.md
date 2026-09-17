# Style guide for the paper

How `writing/paper/` is written. `docs_style.md` is the counterpart for the two technical notes, `writing/docs/` and `writing/quant/`, and this file
**does not repeat it**: everything in `docs_style.md` §1–§4 applies here unless a section below says
otherwise. Read that file first; this one is the list of differences.

The two documents are the same model for two readers. The technical note is a reference, consulted in
the middle by someone who wants one derivation. The paper is an argument, read front to back once by
someone who will decide in the first two pages whether to continue. Almost every difference below
follows from that.

## 1. Where the paper differs

- **First person plural, and it is a real voice.** "We show", "we may state the conditions as follows".
  The technical note is impersonal because nobody is speaking in it. The paper has two authors and they
  are making a case.
- **Continuous time.** The paper's model is stated in continuous time; the technical note is discrete,
  because the quantitative model is. A symbol therefore does not always mean the same object in the two
  documents, and neither may silently borrow a passage from the other. Where they correspond, the
  correspondence is stated rather than assumed.
- **The result comes before the derivation.** A section states what it establishes, then establishes it.
  In the technical note the order is the model's; here it is the reader's.
- **A long derivation goes to the appendix or to a technical note**, and the paper says which. The
  online appendix is the paper's own; a technical note is a separate document and is cited as one,
  never `\input` across the folder boundary.
- **Motivation is part of the writing, not a preface to it.** The technical note forbids meta-commentary
  outright. The paper needs to say why a mechanism matters — once, where the mechanism appears, not in a
  paragraph of throat-clearing before it.

## 2. What the paper owes the reader that the note does not

- **An economic reading of every formal result.** An equation that the paper states but does not
  interpret should be in the appendix. The precedent is the treatment of the Keynes–Ramsey rule: the
  rule, then what each new term is — the capital-gain term on the materials embodied in capital, and
  the condition under which it vanishes and the rule collapses to the standard one.
- **The limiting case, every time.** A generalised result states what it reduces to when the new
  ingredient is switched off ($\phi^K = 0$, or $p^M = 0$, or $\bar R = 0$), because that is how a reader
  locates it against what they already know.
- **A claim about the literature is checked against what the cited paper actually does**, not against
  what it is generally taken to do. This is the one that costs a referee report.
- **Every number is either illustrative and labelled so, or calibrated and sourced.** The parameters in
  `model/src/calibration.jl` are placeholders today (`notes/TODO.md` item 6), so every quantitative
  statement in the paper is currently of the first kind and must say so.

## 3. Sections marked "ALMOST DONE"

A section carrying this remark is settled prose. Edit it only where something it states has actually
changed, and then minimally. Do not restyle it, do not tighten it, do not renumber its equations in
passing. It is the co-authors' agreed text, and a diff on it costs both of them a read.

## 4. Mechanics

- `writing/paper/` is self-contained: its own `main.tex`, `Packages.tex`, `References.bib`. It is what
  gets uploaded to Overleaf, so a file it `\input`s from outside the folder compiles here and fails
  there.
- **Overleaf is the shared surface, and the co-author edits there.** Anything written here reaches them
  only after a push, and anything they write reaches the repository only after a pull:
  `notes/overleafSync.md`. Pull before a substantial edit, so the edit is not made against a stale copy.
- **Do not compile.** Add the file and let the user compile locally.
- `writing/paper/localfiles/` holds the co-authors' Word drafts and the conversion scratch. It is
  gitignored and excluded from the Overleaf upload. Read it for what a co-author meant; never cite it.
