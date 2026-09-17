# Style guide for code

How `model/src/` is written: the notation it inherits from the documentation, the shape of a file, and
how much prose belongs in it. `docs_style.md` is the counterpart for `writing/docs/`, and the two are
meant to be read side by side, because the source implements the document equation for equation.

## 1. Notation is inherited, not chosen

`writing/docs/notation.tex` is the authority. It fixes what a symbol means, and `model/SYMBOLS.md` is
the one place the mathematical symbol and the Julia identifier are written beside each other. What the source adds:

- **ASCII identifiers, deliberately.** `tauW`, not `τ^W`. This is the opposite of the choice a project
  whose identifiers *are* its symbols would make, and it is made on purpose: a stray re-encoding on
  Windows silently corrupts Unicode operators in Julia source, and the corruption survives a passing
  test suite. The cost is that the document-to-source correspondence is a lookup rather than a search,
  which is exactly what `model/SYMBOLS.md` pays for. **A source file contains no
  byte above 127** — including no UTF-8 byte-order mark, which is invisible in an editor and is not a
  character the reader can see.
- **The transliteration is fixed once, not per file.** A superscript joins the name (`p^W` is `pW`,
  `phi^K` is `phiK`); a Greek letter is spelled out (`zeta`, `varpi`); a bar becomes the prefix
  `bar`... except where the established name reads better as a suffix, as in `Rbar` and `abar`. Where
  the document uses an accent the source cannot spell, the symbol table records the pair and no file
  invents a second spelling.
- **A clash in the document is disambiguated in the source, and the disambiguation is recorded at the
  top of the file that makes it.** `parameters.jl` is the precedent: `mu_h` is the handling share
  (document `mu`), `mu_F` the returns exponent, `beta_s` the CES capital share, and the discount factor
  is derived from `rho` and never called `beta`. Never resolve a clash silently, and never resolve the
  same clash two ways in two files.
- **A name that collides with `Base` is renamed, not qualified.** `recycling_yield`, not `yield`.

## 2. The shape of a file

- **One concern per file**, and the file map in `model/README.md` is the list. A new concern is a new
  file and a new row there, not an appendix to an existing one.
- **A module-level docstring states what the file determines and what it may depend on.** `period.jl`
  is the precedent: it names the acyclic ordering it implements, cites the equation block in
  `quant_model.tex` that fixes that ordering, and says what the ordering buys — the block-tridiagonal
  Jacobian. A reader who has that paragraph does not have to reconstruct the invariant from the code.
- **Index constants are declared once, next to the layout they index** (`IK, IS, IX, ...` in
  `period.jl`), and the layout is stated in a comment as a list of symbols in order. Positional
  unpacking then reads as the document's vector.
- **Rates are per period.** `dt` is years per period, and `annualise` / `perperiod` are the only
  conversions. A number that is annual anywhere else is a bug.

## 3. Equations in the source

- **A block of code implementing an equation of the document opens with the equation's label**, so the
  correspondence is greppable in both directions: `# Eq (eq:quant:euler)`. This is a convention to
  apply as blocks are touched, not a migration to run today, and it is what a mechanical checker would
  need if the document ever grows large enough to want one.
- **Write the equation, not a rearrangement of it.** Where a rearrangement is needed for conditioning
  or for a corner, the comment says which form the document has and why this one differs.
- **A residual is written from the condition it enforces**, and the two transcriptions — market and
  planner — stay independent. They are required to agree to machine precision at the planner corner,
  and that agreement is the decentralisation proposition tested as an algebraic identity. Sharing code
  between them to remove the duplication would delete the test.

## 4. Comments

Comments carry what the code cannot: why a form was chosen, what breaks without it, which document
equation is being implemented. Not what the next line does.

- **A guard that is load-bearing says so, and says what goes wrong without it.** The deviation tests
  refusing to run on a non-converged path is the precedent — applied to one, they report that some
  deviation beats it, which is true and useless.
- **A numerical constant has a reason beside it** (`EPS_T`, the homotopy's endpoint, a tolerance).
- **A known limitation lives in `model/README.md`, not in a comment**, so a reader meets the whole list
  at once. A comment may point at it.

## 5. Tests

- `julia --project=. test/runtests.jl`, from `model/`. One `@testset` per concern, all registered in
  that file. Write checks straight into the file that will keep them.
- **A test asserts a property the model should satisfy without having been told to**, wherever that is
  possible: the ledger holding period by period, cumulative extraction respecting the discovery bound,
  the two transcriptions agreeing, the solved path converging on the independently computed balanced
  growth path. These catch what a regression test on a stored number cannot.
- **A fragile branch is either covered or fenced.** `solve_with_shutdown` is neither today, which is why
  `notes/TODO.md` item 7 exists and why results from it are labelled provisional.
- **Something the code finds that the drafts had wrong goes into the document in the same change**, and
  into `model/README.md`'s list of such findings. Two are on that list; both are model facts, not bugs.
