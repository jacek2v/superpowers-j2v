# op-3 Reversal → edit-in-place

Design spec. Changes how the project-registry skill records a **changed / reversed**
decision in `CONTEXT.md`: edit the existing entry in place instead of striking it and
minting a new D-ID.

## Problem

Today a reversal (op 3) strikes the old entry and appends a new entry with a fresh ID:

```
- **D-003** ~~✓ old decision — why [2026-05-01](specs/…)~~ [superseded → D-007, 2026-05-10]
- **D-007** ✓ new decision — why [2026-05-10](specs/…)
```

The current state of one topic is split across two lines, often far apart. A reader must
cross-reference to know what is binding, and the log fills with lines that look mutually
exclusive — the opposite of the scannability the log exists for.

## Decision

Scope: **op 3 "Reversal" only.** When an existing decision is changed or reversed, **edit
the entry in place**:

- keep the same **D-ID**;
- update its live text — including polarity `✓ ↔ ✗` if it flips — and the date to the new decision;
- append a compressed history note: `(prev: <compressed prior state — why>)`;
- do **not** mint a new ID; do **not** strike.

The `(prev: …)` note is **compressed for understanding, not verbatim**. It carries only
enough to make the change clear; `(prev: opposite)` is valid when that is enough.

Example:

```
- **D-042** ✓ forward @check_risky to check_table_metadata — cleaner routing [2026-05-01] (prev: ✗ DO NOT forward — result=1 collision)
```

Commit: `docs: change D-NNN <slug>`.

## The gate is preserved (unchanged)

Edit-in-place changes only **how** a reversal is recorded — never **whether** it is
confirmed first. The conflict gate (op 4) and the hard-gate a/b/c protocol are untouched:
**before any recorded decision is overwritten, the coordinator asks the human partner
explicitly (supersede / change direction / stop). No default, never silent.** This holds
for new reversals and for the rebuild operation below.

Hard-gate rule (a) now records the reversal via edit-in-place instead of strike+new; the
choice presented to the human partner is unchanged.

## New operation: Rebuild (one-time, conscious)

A one-time conversion of an existing log to edit-in-place. Offered explicitly, never run
silently (same principle as op 7 migration). It handles two cases.

**Case 1 — explicit superseded pairs (mechanical).** A struck old entry + its active
successor. Collapse into the surviving active entry, keeping its ID and current text; fold
the old entry's **ID + compressed text** into a `(prev: …)` note; remove the struck line.

```
- **D-007** ✓ new decision — why [2026-05-10](specs/…) (prev: D-003 ✗ DO NOT forward — result=1 collision)
```

**Case 2 — implicit reversals among active entries (judgment).** The log may hold two or
more **unstruck** entries where a later one changed an earlier one, but no one ever struck
the old one. These are un-recorded reversals. Rebuild must scan active entries for the same
topic / contradiction and flag every candidate pair.

Merging is overwriting a recorded decision, so it goes through the **gate**: Rebuild
presents each flagged pair and asks the human partner (supersede / change direction / stop)
— which entry is current, and whether they are truly the same topic. **Never merge
silently.** On confirmation, merge exactly as Case 1: keep the current entry's ID, fold the
older one's ID + text into `(prev: …)`. If the human says they are independent, leave both.

In both cases the retired number is never reused (gaps are fine). Nothing is lost: searching
the old ID still lands inside the merged entry.

## Invariants preserved

- **Never delete a D-entry** — reversal edits the same entry; abandon still strikes.
- **IDs never reused** — edit the existing one; retired numbers leave gaps, never reused.
- **One line per decision** (D-014) — the `(prev: …)` note stays inline, one line.
- **Validity visible in the entry itself** (D-013 core) — strengthened: one entry always
  shows the current, binding state; history is inline.
- **op 6 Abandon unchanged** — a struck entry (`[abandoned YYYY-MM-DD]`) now means exactly
  one thing: dropped work. Never "superseded".

## Backward compatibility

Existing `~~… [superseded → D-NNN]~~` entries in older logs stay valid and readable
("not binding, changed") until a Rebuild is run. Edit-in-place applies to reversals made
from now on. No automatic migration; Rebuild is opt-in per project.

## Affected surfaces (for the plan)

- `skills/project-registry/SKILL.md`
  - Entry Grammar rule 4 + the `D-003` struck example — strikethrough now means abandoned
    only; add the edit-in-place + `(prev: …)` form for changes.
  - op 3 "Reversal" bullet — replace strike+new with edit-in-place.
  - Key Principles — "supersede or abandon by striking" → "abandon by striking; change by
    editing in place"; keep "IDs never reused".
  - Hard-Gate rule (a) — "(strike + new entry + commit)" → "(edit in place + commit)".
  - op 7 Migrate — legacy superseded chains still map to struck entries (historical
    fidelity); note the two forms coexist until a Rebuild.
  - Add the new **Rebuild** operation.
- `skills/project-registry/references/project-template.md`
  - line 24 wording ("Never delete — supersede"), line 28 struck example.
- `skills/brainstorming/SKILL.md`, `skills/executing-plans/SKILL.md`,
  `skills/subagent-driven-development/SKILL.md` — reference op 3 / the a/b/c labels by
  name only; the hard-gate labels ("supersede / change direction / stop") stay. Confirm no
  edit needed during the plan.

## Non-goals

- No change to the gate behavior (op 4 / hard-gate) — only op 3's recording mechanism.
- No change to op 6 (abandon) or op 5 (register shipped).
- No new configuration or options beyond the Rebuild operation.

## Skill-change caveat

This is behavior-shaping skill content. Per the repo's contributor rules, changes to
project-registry / brainstorming skill text should be validated with the writing-skills
flow and evals before any upstream PR. This spec targets the local fork.
