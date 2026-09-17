# Style guide for the technical notes

How `writing/docs/` and `writing/quant/` are written — the reference description of the model, in
discrete time, in two documents: the theory note and the quantitative note, which is the document
`model/src/` implements. §5 says how the two relate. `code_style.md` is the counterpart for the source,
and `paper_style.md` covers `writing/paper/`, which differs from this in register and in purpose rather
than in mechanics. `writing/docs/notation.tex` is the authority on symbols for both notes and, through
`model/SYMBOLS.md`, for the source.

## 1. Main conventions

- **Short and succinct text.**
- **Short and succinct math, but allow for elaboration.** To explain a result allow for a few derivations to better understand the mechanism. Put longer and more detailed derivations and proofs in appendices.
- **Plain academic register.** Keep content tight, drop meta-commentary.
- **First person, present tense.**
- **No dashes.**
- **No narration of the process.** Never discuss development history or what was tried and abandoned, unless explicitly called for (e.g. a section on a trap to avoid going forward).
- **"ALMOST DONE":** Sections carrying this remark should only be edited minimally invasive if important things change or if explicitly asked to edit. The remark is a `%%` comment block at the top of
  the file, so it never prints, and it is repeated in every file a marked part `\input`s — a session
  opens one file at a time and would not see a marker kept only in the wrapper. Marked today: the whole
  planner part (`theory_planner*.tex`).

## 2. Latex conventions

- **Equations**: Use `align`, collect related equations with in `subequations`.
- **Labelling**: Use structure `<prefix>:<section>:<id>` to label equations, figures, etc. Sections are simply declared `sec:<id>` with id referencing the specific section.
- **Tables and figures**: `\input{Tables/Name}` on its own line after the discussing paragraph.
  Figures: `\caption` above `\includegraphics`, `\label` after the caption, `[!htb]`, width
  `\linewidth` (or `0.7\linewidth` for a single panel); notes via `threeparttable` +
  `\tablenotes` in `\footnotesize`, opening "\textit{Note:}". A single note is `\begin{tablenotes}[flushleft]` + `\item[]`, set as a paragraph with no list indent; the list form with `\item` is only for notes carrying labelled markers keyed to cells. A note carries what the main text does not — it never
  restates the section's own description of the exercise — and where several tables share a preamble,
  one anchors it and the rest say. Figure notes live in the `.tex` beside the `\includegraphics`, not drawn
  inside the PDF.

## 3. What a section must contain

- **One owner per fact.** Where a fact belongs in two sections, one section states it and the other cites that section.
- **Declare before use.** No symbol appears before the equation or table that introduces it. Where
   the order of exposition forces it, the forward reference is explicit.
- **A term is defined once, in bold, at first use**, and never redefined. Terms that carry across
   modules are collected in the notation section.

## 4. Prose discipline

- **One term per concept.** No synonyms for variety.
- **No positional cross-references.** Not *above*, *below*, *the previous section*, *as we saw*.
    Always a named reference, so that a reader who entered in the middle can follow it.
- **A number in a table is not repeated in prose.** The text says what the table shows and cites it.

## 5. Two notes, and where the data goes

- **`writing/docs/` is the theory note and `writing/quant/` the quantitative note.** One document
  split in two, so that the theory, which is nearly frozen, is not re-exported every time the
  calibration moves. Each is a self-contained Overleaf project, and a `\ref` does not resolve across
  them.
- **A reference across the boundary names its target.** `\theory{Section}{The long run}` in the
  quantitative note, `\quant{Section}{Paths that hit the floor}` in the theory note; both print the
  section title and the other note's name, and both are defined in the folder's `Packages.tex`. An
  equation is referred to by what it is, never by number: "the collected ledger of Section *Aggregate
  material balances* of the theory note". Where the quantitative note leans on an equation, it
  restates it: it is the document the source implements and must be readable with the source alone.
- **Data documentation has three homes, split by one rule: what a reader needs to reproduce or
  interpret a number goes in tex; why we chose this over that goes in a note.**
  - *The data appendix of the quantitative note.* One subsection per calibration target or series:
    source, what was taken, the transformation in words, the resulting number. Tables are emitted by
    the pipeline under a `%% GENERATED` banner and never hand-edited. Written to survive into the
    final note, because it is what makes the results reproducible.
  - *`notes/data/`.* One file per decision area, not per session: which materials, base year and
    backcast, treatment of gaps. Each records the alternatives, the reason and the date, and points at
    the pipeline script rather than restating what it does. This is where the process lives, which
    the tex never narrates (§1).
  - *The pipeline script* owns the transformations. Neither the appendix nor a note repeats a formula
    the script implements.
  - *`data/SOURCES.md`* keeps provenance (citation, URL, access date, licence). The appendix cites it
    rather than repeating it.

  When in doubt, the appendix: it is cheap to cut or move later, and a note never is.
