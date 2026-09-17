# Style guide for the technical note

How `writing/docs/` is written — the reference description of the model, in discrete time, and the
document `model/src/` implements. `code_style.md` is the counterpart for the source, and
`paper_style.md` covers `writing/paper/`, which differs from this in register and in purpose rather
than in mechanics. `writing/docs/notation.tex` is the authority on symbols for this document and,
through `model/SYMBOLS.md`, for the source.

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
