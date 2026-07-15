---
name: project-registry
description: "Use when another skill directs you to run a registry operation on docs/superpowers/CONTEXT.md — the AI-workspace decision log of D-XXX decisions (adopted and rejected), specs in flight, and shipped features. Not user-invocable directly; project facts (architecture, tech stack) live in the source repo, not here."
---

# Project Registry

Manage `docs/superpowers/CONTEXT.md` as a decision log. It records decisions — adopted AND rejected — so they are never re-asked and never silently reversed, whether by operator oversight or by an automatic AI assumption.

Project facts — overview, architecture, tech stack, source structure, development setup — live in the source repo (`README.md`, optionally `STATUS.md` / `OPERATIONS.md`). CONTEXT.md links to them via the `## Source of truth` block; it never duplicates them.

## CONTEXT.md Structure

Four sections (full template: `references/project-template.md`):

- **Source of truth** — table of links to source-repo files.
- **STATE** — specs in flight. Hard rule: ONE line per spec — link + status ≤10 words.
- **DECISIONS** — flat chronological list of D-XXX entries, both polarities. Never delete — change by editing in place, abandon by striking.
- **SHIPPED** — one row per shipped feature: `When | What | Decisions`.

## Entry Grammar

```markdown
- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ✓ <changed decision> — <why> [YYYY-MM-DD](specs/…) (prev: <compressed prior state — why>)
- **D-004** ~~✓ <abandoned decision> — <why> [YYYY-MM-DD](specs/…)~~ [abandoned YYYY-MM-DD]
```

1. **One line = one decision.** Declarative, no implementation detail — full rationale lives in the linked spec.
2. **Why is mandatory:** one short clause after an em-dash. Longer rationale belongs in the spec.
3. **Explicit polarity:** `✓` adopted; `✗` rejected direction, phrased "DO NOT …" — a tripwire for future sessions.
4. **Explicit inline status:** unstruck = binding — it always shows the current text; a changed decision keeps its ID and carries an inline `(prev: <compressed prior state — why>)` note (one line, appended after the link). Struck-through — the whole entry body including its date/link, with `[abandoned YYYY-MM-DD]` appended — = not binding, dropped work (op 6). Legacy `[superseded → D-NNN, YYYY-MM-DD]` strikes in pre-Rebuild logs stay valid and readable ("changed, not binding"); format-reservation strikes during op-7 migration use `[superseded → decision-log migration, YYYY-MM-DD]`. No derived status: an entry's validity is visible in the entry itself.
5. **Flat chronological list.** No per-spec group headings; provenance is the date + link on each entry. Decisions made outside a spec cycle link `(session)` instead.
6. **Recording litmus:** would contradicting this / re-asking this need a flag? In: choices that constrain future work, explicitly condemned directions, answers that would otherwise be re-asked. Out: data-model shape, component structure, UI details — spec and code describe those.
7. **`✗` only for directions explicitly marked wrong** ("don't do X", "that was a mistake"). Alternatives that merely lost on trade-offs are NOT recorded — they stay in the spec's "approaches considered"; re-proposing one collides with the winning `✓` entry, so the gate still fires.
8. **IDs sequential** D-001…, never reused. Scan DECISIONS for the highest ID (struck entries included), increment.

## Operations

### 1. Create

**When:** a registry write is due (op 2 or op 3) and no CONTEXT.md exists.

- Render `references/project-template.md`; fill `Source of truth` with the source repo's `README.md` path (add `STATUS.md` / `OPERATIONS.md` rows only if those files exist).
- Add the spec's STATE line.
- Extract decisions from the approved spec → `✓` entries; add `✗` entries for directions explicitly condemned during the session (grammar rules 6–7).
- SHIPPED table empty.
- Commit: `docs: create CONTEXT.md decision registry`.

### 2. Record decisions (gate write)

**When:** spec approved (end of brainstorming), CONTEXT.md exists.

- Append D-entries: `✓` per litmus from the approved spec, `✗` for directions explicitly condemned during the session. Date + spec link on each.
- Add the spec's STATE line (one line, status ≤10 words).
- Commit: `docs: record decisions for <feature> spec`.

### 3. Immediate write

**When:** the moment — in ANY skill, including quick-fix/debug work — a direction is condemned or an existing decision reversed. Negative decisions never wait for a gate.

- Rejection → append `✗ DO NOT …` with date and source: the spec link, or `(session)` when none exists.
- Reversal → **edit the entry in place**: keep its D-ID, update the live text (including polarity `✓ ↔ ✗` if it flips) and the date to the new decision, and append a compressed history note `(prev: <compressed prior state — why>)`. Do **not** mint a new ID; do **not** strike. The note is compressed for understanding, not verbatim — `(prev: opposite)` is enough when it is.
- Commit immediately — rejection: `docs: record D-NNN <slug>`; reversal: `docs: change D-NNN <slug>`. Then continue the interrupted work.
- No CONTEXT.md? Offer to create a minimal registry (op 1) — never create it silently.

### 4. Conflict gate

**When:** another skill hands you an intended direction — a clarifying-question set, proposed approaches, an approved design, plan tasks, or a requested code change.

Match the direction against ACTIVE (unstruck) entries, both polarities:

- collision with `✗` — the direction was previously condemned;
- collision with `✓` — the change contradicts an adopted decision.

Hit → hard gate (protocol below). No hit → proceed silently, no message.

**Don't-re-ask mode:** before asking a clarifying question, check whether an active D-entry already answers it — if so, do NOT ask; declare the assumption with its ID ("assuming per D-014: runner = operator").

### 5. Register shipped

**When:** implementation complete, before finishing-a-development-branch.

- Remove the spec's STATE line.
- Add a SHIPPED row: `| YYYY-MM-DD | <feature, 1 line> | D-XXX, D-YYY |`.
- Commit: `docs: register <feature> in SHIPPED`.

### 6. Abandon

**When:** your human partner abandons in-progress work.

- Remove the spec's STATE line.
- Strike the spec's unshipped `✓` entries with `[abandoned YYYY-MM-DD]`.
- **`✗` entries stay active** — rejections are knowledge gained, not abandoned.
- Commit: `docs: abandon <feature> in CONTEXT.md`.

### 7. Migrate (one-time per project)

**When:** any operation touches a CONTEXT.md in the old format (a `REQUIREMENTS` heading or `R-XXX` entries). Offer migration BEFORE any other write — never migrate silently, and never write an entry in the old grammar; the interrupted operation waits for the answer. On consent:

- R-NNN → D-NNN, numbers preserved and the ID shape is exactly `D-NNN` — hyphen mandatory (R-015 → D-015, never `D015`). Drop the per-spec group headings; put each entry's date + spec link inline on the entry (flat list, grammar rule 5). A heading naming several specs: each entry carries the link it came from — every link under the heading survives on some entry.
- Entries carrying `[deprecated …, superseded by R-NNN]` → struck entries with `[superseded → D-NNN, <original date>]`; `[deprecated …]` without a successor → `[abandoned <original date>]`. All others → active `✓`.
- Migration preserves legacy superseded chains as struck entries (historical fidelity) — it does **not** apply edit-in-place. The legacy `[superseded → D-NNN]` form and the edit-in-place `(prev: …)` form coexist until a later Rebuild (op 8) converts the chains; Rebuild is opt-in per project, never automatic.
- FEATURES rows → SHIPPED rows (`When | What | Decisions`). A spec link from the FEATURES row that no D-entry carries: fold it into the What cell as a markdown link — no link is dropped.
- STATE paragraphs → one-liners; detail stays in the linked specs — nothing is lost, links still resolve.
- Ad-hoc sections (e.g. naming conventions) → flag to your human partner for relocation into source-repo docs; keep them in place until your human partner decides — never drop content silently. Your migration reply MUST name every kept ad-hoc section — kept-but-unmentioned is a silent-drop risk.
- D-XXX IDs are defined by this file alone — decisions mentioned in source-repo docs are never ID collisions. Do not invent blockers; on consent, execute the mapping mechanically and commit.
- Consent to migrate also supersedes in-file entries that reserve ID namespaces or formats (e.g. "D-XXX lives in README, R-XXX here"): strike them VERBATIM — renumber the ID, change nothing else in the entry text — with `[superseded → decision-log migration, YYYY-MM-DD]` in the migration commit; never keep them active or reword them. Do not gate on them; your human partner's consent already answered it. The new format outranks old in-file conventions — entries describing the old format or ID scheme are reservations too; when in doubt, strike.
- Before committing, self-verify links mechanically: extract every `](…)` target from the pre-migration file and from the migrated file; every pre-migration target must appear in the migrated file (active or struck entry, or folded into a SHIPPED What cell). A missing link is a bug — fix it before the commit.
- Commit: `docs: migrate CONTEXT.md to decision-log format`. Then continue the interrupted operation.

## Hard-Gate Protocol

The protocol text lives ONLY here; other skills reference it. On an op-4 hit, present:

```
⛔ Collision with a recorded project decision:

D-042 ✗ DO NOT forward @check_risky to check_table_metadata
      — result=1 collision [2026-04-15](specs/2026-04-15-check-risky-design.md)

The requested change forwards @check_risky.

(a) supersede D-042 — I record the reversal and proceed
(b) change direction — keep D-042, adjust approach
(c) stop here
```

Rules:

- **No progress without an explicit a/b/c answer. No default.** Waiting is the correct state — do not pick for your human partner, do not proceed "provisionally".
- (a) → run op 3 immediately (edit in place + commit), then continue the work.
- (b) → keep the entry binding; adjust the question, approach, plan, or change so it respects the decision.
- (c) → stop; leave the registry untouched.
- Multiple collisions: ONE message listing all of them, with a per-item (a)/(b)/(c) decision.
- The quote always carries ID, polarity, text, why, date, link — your human partner sees the decision's full context at the warning site.
- Only the main agent / coordinator runs gates, never subagents.

## Key Principles

- STATE is transient — presence means "in flight", absence means "shipped or abandoned".
- Never delete a D-entry — change by editing the entry in place (op 3), abandon by striking (op 6); IDs are never reused.
- An entry's validity is visible in the entry itself; there is no derived status.
- This skill manages `CONTEXT.md` only; it never touches source-repo files (README, STATUS, OPERATIONS).
