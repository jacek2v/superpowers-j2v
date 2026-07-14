# op-3 Reversal → edit-in-place Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change how `project-registry` records a reversed/changed decision — edit the existing D-entry in place (same ID + inline `(prev: …)` note) instead of striking it and minting a new ID — and add a one-time Rebuild operation to convert legacy logs.

**Architecture:** Pure behavior-shaping documentation edits to two files in `skills/project-registry/` (`SKILL.md`, `references/project-template.md`). No executable code. Strikethrough is narrowed to mean op-6 abandon (plus legacy/backward-compat and op-7 migration strikes); changes become in-place edits carrying a compressed `(prev: <state — why>)` history note. The conflict gate (op 4 / hard-gate a-b-c) is untouched.

**Tech Stack:** Markdown skill files. Verification is by targeted `grep` (removed strings gone, new strings present) plus a full read-through — there is no runtime to test-drive.

**Decisions:** D-022 (op-3 reversals edit in place; strikethrough reserved for abandon; gate unchanged), D-023 (new Rebuild op converts legacy superseded chains + implicit active-entry reversals, one-time, offered never silent). Both are active `✓` entries sourced from this spec — the plan implements them.

## Global Constraints

- **Behavior-shaping skill content.** These edits change tuned agent-behavior text. Per the repo contributor rules and the spec's skill-change caveat, validate via the `superpowers:writing-skills` flow + evals **before any upstream PR**. This plan targets the **local fork** only.
- **The gate is preserved, unchanged.** Do not alter op 4 (conflict gate) behavior or the hard-gate a/b/c protocol semantics. Edit-in-place changes only *how* a confirmed reversal is recorded, never *whether* it is confirmed first.
- **Invariants that must still hold after every task:** never delete a D-entry; IDs are never reused (retired numbers leave gaps); one line per decision — the `(prev: …)` note stays inline; an entry's validity is visible in the entry itself.
- **Commit convention:** a reversal recorded via op 3 commits as `docs: change D-NNN <slug>` (a rejection still commits as `docs: record D-NNN <slug>`).
- **Compressed history note grammar (used verbatim across tasks):** `(prev: <compressed prior state — why>)`. It is compressed for understanding, not verbatim — `(prev: opposite)` is valid when that is enough.
- English in all artifacts. Match the existing terse, imperative voice of the skill files — no restructuring of unrelated content (surgical edits only).

---

## File Structure

| File | Change |
|---|---|
| `skills/project-registry/SKILL.md` | Grammar rule 4 + examples; op 3 Reversal bullet + commit line; Hard-Gate rule (a); Key Principles; DECISIONS structure blurb; op 7 Migrate note; **new op 8 Rebuild**. |
| `skills/project-registry/references/project-template.md` | DECISIONS blurb wording; struck `D-003` example → edit-in-place `(prev: …)` form. |

No new files. No changes to `brainstorming`, `executing-plans`, `subagent-driven-development` (Task 5 confirms this).

---

### Task 1: Record decision changes via edit-in-place (SKILL.md core)

Rewrite every place in `SKILL.md` that describes recording a reversal so it uses edit-in-place. These five regions are one coherent semantic change — an intermediate state where the grammar says "strike" but op 3 says "edit in place" would be self-contradictory, so they land together in one commit.

**Files:**
- Modify: `skills/project-registry/SKILL.md` (regions: line 18, lines 23–32, lines 60–64, lines 130–132, line 141)

**Interfaces:**
- Produces (later tasks must match verbatim): the compressed-history note grammar `(prev: <compressed prior state — why>)`; strikethrough now means **abandon only** (plus legacy superseded + op-7 format-reservation strikes). Task 3 (Rebuild) and Task 4 (template) reuse this exact `(prev: …)` form.

TDD: waived — documentation-only; no production code. Verification is grep + read-through.

- [ ] **Step 1: Edit the DECISIONS structure blurb (line 18)**

Old string:
```markdown
- **DECISIONS** — flat chronological list of D-XXX entries, both polarities. Never delete — supersede.
```
New string:
```markdown
- **DECISIONS** — flat chronological list of D-XXX entries, both polarities. Never delete — change by editing in place, abandon by striking.
```

- [ ] **Step 2: Replace the struck example in the Entry Grammar block (lines 23–27)**

Old string:
```markdown
- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ~~✓ <old decision> — <why> [YYYY-MM-DD](specs/…)~~ [superseded → D-007, YYYY-MM-DD]
```
New string:
```markdown
- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ✓ <changed decision> — <why> [YYYY-MM-DD](specs/…) (prev: <compressed prior state — why>)
- **D-004** ~~✓ <abandoned decision> — <why> [YYYY-MM-DD](specs/…)~~ [abandoned YYYY-MM-DD]
```

- [ ] **Step 3: Rewrite grammar rule 4 (line 32)**

Old string:
```markdown
4. **Explicit inline status:** unstruck = binding. Struck-through — the whole entry body including its date/link, with `[superseded → D-NNN, YYYY-MM-DD]` or `[abandoned YYYY-MM-DD]` appended (format-reservation strikes during op-7 migration use `[superseded → decision-log migration, YYYY-MM-DD]`) — = not binding. No derived status: an entry's validity is visible in the entry itself.
```
New string:
```markdown
4. **Explicit inline status:** unstruck = binding — it always shows the current text; a changed decision keeps its ID and carries an inline `(prev: <compressed prior state — why>)` note (one line, appended after the link). Struck-through — the whole entry body including its date/link, with `[abandoned YYYY-MM-DD]` appended — = not binding, dropped work (op 6). Legacy `[superseded → D-NNN, YYYY-MM-DD]` strikes in pre-Rebuild logs stay valid and readable ("changed, not binding"); format-reservation strikes during op-7 migration use `[superseded → decision-log migration, YYYY-MM-DD]`. No derived status: an entry's validity is visible in the entry itself.
```

- [ ] **Step 4: Rewrite the op 3 Reversal bullet + commit line (lines 63–64)**

Old string:
```markdown
- Reversal → strike the old entry (`~~…~~ [superseded → D-NNN, YYYY-MM-DD]`), append the new entry.
- Commit immediately: `docs: record D-NNN <slug>`. Then continue the interrupted work.
```
New string:
```markdown
- Reversal → **edit the entry in place**: keep its D-ID, update the live text (including polarity `✓ ↔ ✗` if it flips) and the date to the new decision, and append a compressed history note `(prev: <compressed prior state — why>)`. Do **not** mint a new ID; do **not** strike. The note is compressed for understanding, not verbatim — `(prev: opposite)` is enough when it is.
- Commit immediately — rejection: `docs: record D-NNN <slug>`; reversal: `docs: change D-NNN <slug>`. Then continue the interrupted work.
```

- [ ] **Step 5: Update Hard-Gate rule (a) (line 132)**

Old string:
```markdown
- (a) → run op 3 immediately (strike + new entry + commit), then continue the work.
```
New string:
```markdown
- (a) → run op 3 immediately (edit in place + commit), then continue the work.
```

- [ ] **Step 6: Update Key Principles (line 141)**

Old string:
```markdown
- Never delete a D-entry — supersede or abandon by striking; IDs are never reused.
```
New string:
```markdown
- Never delete a D-entry — change by editing the entry in place (op 3), abandon by striking (op 6); IDs are never reused.
```

- [ ] **Step 7: Verify the edits mechanically**

Run each — check the expected result:
```bash
cd skills/project-registry
grep -c "strike the old entry" SKILL.md          # expect 0
grep -c "supersede or abandon by striking" SKILL.md   # expect 0
grep -c "(strike + new entry + commit)" SKILL.md      # expect 0
grep -n "edit the entry in place" SKILL.md            # expect the op-3 bullet
grep -n "(edit in place + commit)" SKILL.md           # expect hard-gate (a)
grep -n "(prev: <compressed prior state — why>)" SKILL.md  # expect grammar block, rule 4, op 3
```
Expected: the three `-c` counts are `0`; the three `-n` greps each return the described line(s). (Bare `grep` exit 1 on zero matches is fine — see the workspace grep note.)

- [ ] **Step 8: Read the whole Operations + Grammar + Key Principles sections once**

Read `skills/project-registry/SKILL.md` end-to-end. Confirm no remaining sentence still implies a change is recorded by strike+new, and that op 3, grammar rule 4, and Key Principles agree on the edit-in-place model.

- [ ] **Step 9: Commit**

```bash
git add skills/project-registry/SKILL.md
git commit -m "docs(project-registry): record decision changes via edit-in-place"
```

---

### Task 2: Note legacy superseded strikes coexist until Rebuild (op 7 Migrate)

Migration must keep converting legacy `[superseded → …]` chains to **struck** entries (historical fidelity) — it does not apply edit-in-place. Record that the two forms coexist until a Rebuild (op 8) is run.

**Files:**
- Modify: `skills/project-registry/SKILL.md` (op 7, after line 102)

TDD: waived — documentation-only.

- [ ] **Step 1: Add the coexistence note to op 7**

Old string:
```markdown
- Entries carrying `[deprecated …, superseded by R-NNN]` → struck entries with `[superseded → D-NNN, <original date>]`; `[deprecated …]` without a successor → `[abandoned <original date>]`. All others → active `✓`.
```
New string:
```markdown
- Entries carrying `[deprecated …, superseded by R-NNN]` → struck entries with `[superseded → D-NNN, <original date>]`; `[deprecated …]` without a successor → `[abandoned <original date>]`. All others → active `✓`.
- Migration preserves legacy superseded chains as struck entries (historical fidelity) — it does **not** apply edit-in-place. The legacy `[superseded → D-NNN]` form and the edit-in-place `(prev: …)` form coexist until a later Rebuild (op 8) converts the chains; Rebuild is opt-in per project, never automatic.
```

- [ ] **Step 2: Verify**

```bash
grep -n "coexist until a later Rebuild" skills/project-registry/SKILL.md   # expect the new bullet
```
Expected: returns the new op-7 bullet line.

- [ ] **Step 3: Commit**

```bash
git add skills/project-registry/SKILL.md
git commit -m "docs(project-registry): note legacy superseded strikes coexist until Rebuild"
```

---

### Task 3: Add op 8 Rebuild operation

Add the new one-time Rebuild operation after op 7 and before the `## Hard-Gate Protocol` heading. Case 1 is mechanical; Case 2 routes each flagged pair through the existing hard gate.

**Files:**
- Modify: `skills/project-registry/SKILL.md` (insert after op 7, before `## Hard-Gate Protocol`)

**Interfaces:**
- Consumes: the `(prev: …)` grammar and hard-gate a/b/c protocol established/kept in Task 1. The Rebuild examples must use the exact `(prev: …)` form.

TDD: waived — documentation-only.

- [ ] **Step 1: Insert the Rebuild operation**

Insert this block immediately before the line `## Hard-Gate Protocol`:
```markdown
### 8. Rebuild (one-time, conscious)

**When:** your human partner asks to convert an existing log to edit-in-place form. Offer it explicitly; **never run it silently** (same principle as op 7). It handles two cases.

- **Case 1 — explicit superseded pairs (mechanical).** A struck old entry (`~~…~~ [superseded → D-NNN, …]`) plus its active successor `D-NNN`. Collapse into the surviving active entry: keep its ID and current text, fold the struck entry's **ID + compressed text** into a `(prev: …)` note, and remove the struck line.

  ```
  - **D-007** ✓ new decision — why [2026-05-10](specs/…) (prev: D-003 ✗ DO NOT forward — result=1 collision)
  ```

- **Case 2 — implicit reversals among active entries (judgment).** The log may hold two or more **unstruck** entries where a later one changed an earlier one but no one struck the old one — un-recorded reversals. Scan active entries for the same topic / contradiction and flag every candidate pair. Merging overwrites a recorded decision, so each flagged pair goes through the **hard gate** (protocol below): present the pair and ask supersede / change direction / stop — which entry is current, and whether they are truly the same topic. **Never merge silently.** On confirmation, merge exactly as Case 1 (keep the current entry's ID, fold the older one's ID + text into `(prev: …)`). If your human partner says they are independent, leave both.

- The retired number is never reused (gaps are fine); searching the old ID still lands inside the merged entry — nothing is lost.
- Commit: `docs: rebuild CONTEXT.md to edit-in-place form`.

```

- [ ] **Step 2: Verify placement and content**

```bash
grep -n "### 8. Rebuild (one-time, conscious)" skills/project-registry/SKILL.md   # expect the new heading
grep -n "Never merge silently" skills/project-registry/SKILL.md                   # expect Case 2
awk '/### 8. Rebuild/{r=NR} /## Hard-Gate Protocol/{h=NR} END{print "rebuild@"r" gate@"h}' skills/project-registry/SKILL.md
```
Expected: heading and `Never merge silently` found; the `awk` line shows `rebuild@` line number **less than** `gate@` line number (Rebuild sits before the Hard-Gate Protocol section).

- [ ] **Step 3: Commit**

```bash
git add skills/project-registry/SKILL.md
git commit -m "docs(project-registry): add Rebuild operation for edit-in-place conversion"
```

---

### Task 4: Update project-template.md for edit-in-place grammar

Mirror the new grammar into the create-time template so op 1 renders the edit-in-place form, not the struck `[superseded → …]` example.

**Files:**
- Modify: `skills/project-registry/references/project-template.md` (DECISIONS blurb + `D-003` example inside the fenced template)

**Interfaces:**
- Consumes: the `(prev: <compressed prior state — why>)` form from Task 1 — used verbatim.

TDD: waived — documentation-only.

- [ ] **Step 1: Update the DECISIONS blurb**

Old string:
```markdown
One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.
```
New string:
```markdown
One decision per line. ✓ adopted, ✗ rejected direction. Never delete — change by editing in place, abandon by striking.
```

- [ ] **Step 2: Replace the struck `D-003` example**

Old string:
```markdown
- **D-003** ~~✓ <old decision>~~ [superseded → D-007, YYYY-MM-DD]
```
New string:
```markdown
- **D-003** ✓ <changed decision> — <why> [YYYY-MM-DD](specs/…) (prev: <compressed prior state — why>)
```

- [ ] **Step 3: Verify**

```bash
cd skills/project-registry/references
grep -c "Never delete — supersede" project-template.md   # expect 0
grep -c "superseded → D-007" project-template.md          # expect 0
grep -n "(prev: <compressed prior state — why>)" project-template.md   # expect the D-003 line
```
Expected: both `-c` counts `0`; the `-n` grep returns the new `D-003` line.

- [ ] **Step 4: Commit**

```bash
git add skills/project-registry/references/project-template.md
git commit -m "docs(project-registry): update template for edit-in-place grammar"
```

---

### Task 5: Consistency sweep + confirm referencing skills unchanged

Final QA gate. Confirm the two edited files are internally consistent and that the three referencing skills genuinely need no edit (spec: they name op 3 / the a-b-c labels only). No production code — no commit.

**Files:**
- Read only: `skills/project-registry/SKILL.md`, `skills/project-registry/references/project-template.md`, `skills/brainstorming/SKILL.md`, `skills/executing-plans/SKILL.md`, `skills/subagent-driven-development/SKILL.md`

TDD: waived — verification-only task, no production code.

- [ ] **Step 1: Sweep the edited files for stale strike-based change wording**

```bash
cd skills/project-registry
grep -rn "superseded" SKILL.md references/project-template.md
```
Expected: every remaining `superseded` occurrence is a **legacy / op-7 migration** reference (rule 4's "Legacy `[superseded → D-NNN]`", op 7's mapping bullets + coexistence note, op 8 Case 1's legacy-pair description). None describes op 3's normal recording path. Eyeball each hit and confirm.

- [ ] **Step 2: Confirm the three referencing skills mention op 3 / labels by name only**

```bash
cd ../..
grep -n -iE "supersede|change direction|stop|op.?3" skills/brainstorming/SKILL.md skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md
```
Expected: every hit is a by-name reference to op 3 or the `supersede / change direction / stop` hard-gate labels — none describes the strike+new-entry mechanism. Confirm no edit is required (spec §"Affected surfaces": "Confirm no edit needed during the plan").

- [ ] **Step 3: Full read-through of SKILL.md**

Read `skills/project-registry/SKILL.md` once more start to finish. Confirm: (a) grammar rule 4, op 3, op 8, Hard-Gate (a), and Key Principles all agree that a change edits in place and strikethrough means abandon/legacy; (b) the invariants (never delete, IDs never reused, one line per decision, validity visible) are intact; (c) op 4 and the hard-gate a/b/c protocol semantics are unchanged.

- [ ] **Step 4: Report**

State the outcome: edits consistent (yes/no), stale-wording sweep clean (yes/no), three referencing skills confirmed unchanged (yes/no). If any check fails, fix in the owning task's file and re-run its verification before completing.

---

## Notes for the executor

- These are behavior-shaping skill edits on the **local fork**. Do not open an upstream PR from this plan — the spec's skill-change caveat requires `writing-skills` + eval validation first, which is out of this plan's scope.
- Registry lifecycle for this spec (STATE → SHIPPED, D-022/D-023 already recorded) is handled by `project-registry` ops during finish, not by these tasks.
