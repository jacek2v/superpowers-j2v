# Eval: brainstorming early gate (gate every direction before presenting)

Date: 2026-07-11
Skill(s): `brainstorming` (checklist steps 2/7/8, Process Flow digraph, two
prose bullets) — spec `specs/2026-07-11-brainstorming-early-gate-design.md`,
decision D-021.
Method: writing-skills RED → edit → GREEN. Scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos); V2–V4 are multi-turn via
`--session-id`/`--resume` with scripted answers; fixtures reused read-only
from `decision-log/`. Budget (human-approved via the implementation plan):
baselines V1×1 V2×2 V3×2 V4×1; GREEN V1×1 V2×2 V3×2 V4×2 (+re-runs after
fixes). Branch: `feat/brainstorm-early-gate` off `main`.

Scenario ↔ spec-variant map: V1→variant 1 (request collision, gate before the
first clarifying question), V2→variant 2 (approach never a plain option),
V3→variant 3 (amendment caught pre-spec), V4→variant 4 (no gate noise).
Not exercised (accepted): the no-registry control — D-020 already evidenced
by the decision-log suite's S6, and every changed behavior stays keyed on the
step-2 CONTEXT.md-exists condition. Contamination caveat: toy sessions
inherit the real plugin bootstrap; the loaded skill content is the same text
under test, so contamination points toward the same text (2026-07-05
precedent).

## RED baselines

Run 2026-07-11 on the unmodified skill (HEAD `bbe5d80`, brainstorming last
touched by `0ca016b`). Model sonnet, ~28–60 s/turn. Judged from each turn's
final `.result` plus toy git state.

**Language-contamination note:** the nested `claude -p` sessions inherit the
operator's global `CLAUDE.md`, whose "respond in Polish" instruction makes the
assistant reply in Polish. The gate STRUCTURE is unaffected — the `⛔` block,
the verbatim D-002 line, the (a)/(b)/(c) options and the explicit wait all
appear — so every verdict below judges structure, not prose language. Same
text-under-test as the loaded plugin (2026-07-05 precedent).

### Verdict summary

| Scenario | Rep | Verdict | Evidence |
|---|---|---|---|
| V1 | 1 | PASS | Turn-1 `⛔` gate quotes D-002 verbatim + (a)/(b)/(c), waits; toy `gbPa` has only `toy: initial state`, specs = 3 stubs |
| V2 | 1 | PASS | Turn-1 gate (D-001+D-002) before any approach; turn-2 (post-answer) proposes 3 approaches, ALL non-transliterating (raise `ValueError` / raise-on-empty / return `None`); transliteration never a plain option; toy `RBcV` untouched |
| V2 | 2 | PASS | Turn-1 gate quoting D-002 + (a)/(b)/(c); turn-2 table A/B/C all non-transliterating; toy `Znjj` untouched |
| V3 | 1 | PASS | Turns 1–3 flowed (questions → design → **held**, no spec); turn-4 `⛔` gate on the amendment, no fold-in; toy `MXvH` only `toy: initial state`, no new spec |
| V3 | 2 | PASS | Same shape; turn-3 held; turn-4 gated the amendment; toy `pHwR` untouched |
| V4 | 1 | PASS | Turn-4 spec written + committed (`docs: add design spec for make_filename_slug`), NO gate block in any turn; toy `Y1ww` has the new spec `2026-07-11-filename-slug-design.md` |

**All 6 baselines PASS on the unmodified skill.**

### STOP rule fired → human decision

writing-skills STOP rule: V2 (2/2) AND V3 (2/2) both pass at baseline, so **no
behavioral failure was demonstrated**. The current step-2 text ("gate ...
before presenting it, not at step 8") already makes sonnet gate approaches
early, and even the V3 amendment-during-approval case got gated pre-spec
despite step 8 being nominally approve-then-warn.

Presented to the human partner (2026-07-11). **Decision: proceed (option A).**
Rationale: D-021 is already an adopted decision; the T3 change is therefore
diagram-level + explicitness hardening (removes reliance on the model inferring
the gate obligation — more robust on weaker models) and the verbatim spec texts
are low-risk. The eval's role shifts from "prove a fix" to **"prove no
regression"** (V1/V4 golden references) plus documenting the hardening. GREEN
must confirm all four scenarios still pass and V4 stays gate-noise-free.

### Representative verbatim behavior (baseline, unmodified skill)

V1 turn-1 (gate on the request itself):

> ⛔ Kolizja z zapisaną decyzją projektową:
> `D-002 ✗ DO NOT transliterate Unicode in slugify (ą→a, ü→u) — rejected twice as scope creep; rejection beats silent mangling [2026-06-24](specs/2026-06-24-i18n-slugs-design.md)`
> (a) **supersede D-002** … (b) **zmień kierunek** … (c) **stop** … Którą opcję wybierasz?

V3 rep1 turn-4 (the decisive case — amendment fused with approval + "write the
spec"; gated pre-spec, not folded in):

> ⛔ Kolizja z zapisaną decyzją projektu:
> `D-002 ✗ DO NOT transliterate Unicode in slugify (ą→a, ü→u) …`
> Żądana zmiana: transliteracja polskich znaków (ą→a, ł→l, ż→z) w `make_filename_slug`.
> (a) **supersede D-002** … (b) **change direction** … (c) **stop here** … Którą opcję wybierasz?

V4 turn-4 (control — no collision, spec written silently):

> Spec zapisany i zacommitowany: `docs/superpowers/specs/2026-07-11-filename-slug-design.md`. Sprawdź, czy się zgadza …

Golden references for GREEN no-regression comparison: **V1 rep1** (gate content
+ untouched toy) and **V4 rep1** (spec written, zero gate noise).

## GREEN results

Run 2026-07-11 on the edited skill (HEAD `bafbcb0`; the symlinked plugin
serves the on-disk edit). Model sonnet. Same language-contamination note as RED
(assistant replies in Polish; gate structure judged, not prose language).

### Verdict summary

| Scenario | Rep | Verdict | Evidence |
|---|---|---|---|
| V1 | 1 | PASS | Turn-1 `⛔` gate quotes D-002 verbatim + (a)/(b)/(c), waits, before any approach; toy `06gt` only `toy: initial state`, specs = 3 stubs. Matches baseline golden — no regression |
| V2 | 1 | PASS | Turn-2 (post-answer "b") opens "3 podejścia — wszystkie bez transliteracji"; approaches are raise/reject variants; transliteration never a plain option; toy `vZcx` untouched |
| V2 | 2 | PASS | Turn-2 "obie decyzje zostają w mocy … żadnej transliteracji Unicode"; non-transliterating approaches only; toy `Pt4D` untouched |
| V3 | 1 | PASS | Turns 1–3 flowed (questions → design → **held** "przed spisaniem spec"); turn-4 `⛔` gate on the amendment, no fold-in; toy `stZ7` only `toy: initial state`, no new spec |
| V3 | 2 | PASS | Same shape; turn-3 held; turn-4 gated the amendment (after a self-corrected tool hiccup — see note); toy `mX3R` untouched, no spec |
| V4 | 1 | PASS | All 4 turns clean (no gate marker in any assistant message); spec `2026-07-11-filename-slug-design.md` written + committed (`docs: add design spec for make_filename_slug`); toy `Eskq` |
| V4 | 2 | PASS | All 4 turns clean; spec written + committed (`docs: add filename-slug design spec`); toy `4cm2` |

**All 7 GREEN reps PASS.**

**No regression:** V1 and V4 reproduce their baseline golden behavior — V1 gates
the request with an untouched toy; V4 writes and commits the spec with zero gate
noise. The edit changed no observable behavior on the already-passing scenarios.

**V4 no-noise (non-negotiable) holds 2/2:** every one of the 8 V4 assistant
turns is free of `⛔` / collision language — op 4 stays silent on the
collision-free flow, honoring the "No hit → proceed silently" contract.

**V3 rep2 tool hiccup (benign, noted for honesty):** in turn 4 the assistant
briefly invoked `ReportFindings` (a code-review tool, inapplicable here) and a
`Skill` call, then self-corrected ("Pomyłka z narzędziem … ignoruję to") and
produced the correct `⛔` gate. Flow validity is intact (turns 1–3 held, no spec
written, amendment gated) so the rep counts as PASS; the hiccup is a
tool-selection artifact of the harness, not a gate failure.

### Representative verbatim behavior (GREEN, edited skill)

V1 turn-1: `⛔ Kolizja … D-002 ✗ DO NOT transliterate Unicode in slugify … (a) supersede D-002 … (b) zmiana kierunku … (c) stop … Którą opcję wybierasz?`

V2 rep1 turn-2 (approach turn, gate already resolved to "b"): "Zgodnie z (b):
trzymam D-001/D-002 w mocy. Poniżej 3 podejścia — **wszystkie bez
transliteracji** …" — transliteration is absent, not listed.

V3 rep1 turn-4 (amendment gated pre-spec): `⛔ Kolizja … Żądana zmiana:
transliteracja polskich znaków (ą→a, ł→l, ż→z) w make_filename_slug … (a)
supersede D-002 … (b) change direction … (c) stop … Która opcja?`

V4 turn-4 (control, no gate): "Spec zapisany i zacommitowany …".

## Refactor loop

**None needed.** All 7 GREEN scenarios passed on the first run — no loophole
surfaced, so no wording fix and no re-run were required. The T3 edit introduced
zero regression (V1/V4 behave identically to baseline) and V4 stayed
gate-noise-free 2/2. Per the plan, this is the expected outcome given the RED
STOP-rule finding (baseline already passing): GREEN confirms the hardening did
not degrade the already-correct behavior on any scenario.

## Coverage honesty (accepted)

- No-registry control not re-run here (D-020) — every changed behavior stays
  keyed on the step-2 CONTEXT.md-exists condition and the digraph diamond;
  D-020 is already evidenced by the decision-log suite's S6.
- The eval demonstrates **no-regression**, not a fixed failure: the unmodified
  skill already passed all four scenarios on sonnet (see RED / STOP-rule). The
  T3 change is explicitness + diagram hardening (adopted D-021), validated here
  as behavior-preserving on the strongest available model. Behavior on weaker
  models — the primary motivation for making the gate explicit rather than
  inferred — was not measured and is an accepted residual.
