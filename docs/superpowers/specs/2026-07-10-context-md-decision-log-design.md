# CONTEXT.md as a Decision Log — Design

**Date:** 2026-07-10
**Status:** approved
**Repo:** `superpowers-j2v.git` (fork-specific; not for upstream)
**Replaces:** the current project-registry design (R-XXX/F-XXX registry with derived status)

## Problem

CONTEXT.md exists to prevent new work from silently contradicting prior decisions.
In practice it fails at four points (evidence: real registries across 9 projects;
worst case 448 lines / ~120 R-XXX):

1. **Only spec-derived constraints are recorded.** Rejected directions and answers
   given during sessions are not captured — the same questions get re-asked, and a
   direction explicitly condemned earlier gets re-proposed. Example: "do not build
   mssql-bulkcopy-overlap" buried in a 6-line STATE paragraph instead of being a
   first-class entry.
2. **Warning comes late and narrow.** The conflict check runs only inside
   brainstorming, and only after the full design is approved. Quick fixes,
   debugging, and refactors never consult the registry — a code change can
   silently reverse a recorded decision.
3. **Entries are unclear.** Multi-sentence walls mixing decision + rationale +
   implementation detail; entry status is *derived* (one must cross-read STATE
   and FEATURES to know whether an entry binds); STATE entries grow into
   mini-specs.
4. **Flags are advisory.** Easy to wave through — operator oversight is exactly
   the failure mode the registry exists to prevent.

## Goals

- Record decisions — adopted and rejected — so they are never re-asked and never
  silently reversed, whether by operator oversight or by an automatic AI
  assumption.
- Warn early: before questions and proposals in brainstorming, at plan and
  execution start, and on any out-of-cycle code change.
- Make every entry scannable: one line, explicit polarity, explicit inline status.

## Non-goals

- Recording project facts (architecture, stack, glossary) — they stay in the
  source repo (`Source of truth` block links to them).
- Recording merely-not-chosen alternatives — they stay in specs under
  "approaches considered"; re-proposing one collides with the winning ✓ entry,
  so the gate still fires.
- Upstreaming to obra/superpowers.

## Decisions made during brainstorming

1. **Write timing:** gate writes at spec approval, PLUS an immediate write the
   moment a direction is condemned or an existing decision reversed — in any
   skill, including quick-fix/debug sessions. Negative decisions never wait for
   a gate.
2. **Check points:** brainstorming start (active), writing-plans and
   executing-plans/SDD start, bootstrap guard in using-superpowers, and the
   existing pre-spec check kept as a safety net.
3. **Gate strength:** hard gate — explicit user choice required, no default,
   supersede recorded immediately.
4. **Format:** unified decision log (D-XXX with ✓/✗ polarity) + thin SHIPPED
   table. FEATURES section and derived status are removed.

## File format

Template (`references/project-template.md` is rewritten to this):

```markdown
# CONTEXT: <project>

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../<src-repo>/README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [<title>](specs/YYYY-MM-DD-<topic>-design.md) — <short status>

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ~~✓ <old decision>~~ [superseded → D-007, YYYY-MM-DD]

## SHIPPED

| When | What | Decisions |
|---|---|---|
| YYYY-MM-DD | <feature, 1 line> | D-001, D-002 |
```

### Entry grammar

1. **One line = one decision.** Declarative, no implementation detail — full
   rationale lives in the linked spec.
2. **Why is mandatory:** one short clause after an em-dash. Longer rationale
   belongs in the spec.
3. **Explicit polarity:** `✓` adopted; `✗` rejected direction, phrased
   "DO NOT …" — a tripwire for future sessions.
4. **Explicit inline status:** unstruck = binding; struck-through with
   `[superseded → D-NNN, YYYY-MM-DD]` or `[abandoned YYYY-MM-DD]` = not binding.
   No derived status — an entry's validity is visible in the entry itself.
5. **Flat chronological list.** No per-spec group headings; provenance is the
   date + link on each entry. Out-of-cycle decisions link `(session)` instead of
   a spec.
6. **Recording litmus:** "would contradicting this / re-asking this need a
   flag?" In: choices that constrain future work, explicitly condemned
   directions, answers that would otherwise be re-asked. Out: data-model shape,
   component structure, UI details (spec and code describe those).
7. **`✗` only for directions explicitly marked wrong** ("don't do X", "that was
   a mistake"). Alternatives that merely lost on trade-offs are not recorded.
8. **IDs sequential** D-001…, never reused. STATE: hard one line per spec.
   SHIPPED: one row per shipped feature.

## Operations (project-registry v2)

**Op 1 — Create.** First gate in a project (no CONTEXT.md): render template,
fill `Source of truth`, add STATE line, extract decisions from the approved
spec → `✓` entries + `✗` entries for directions explicitly condemned during the
session. Commit: `docs: create CONTEXT.md decision registry`.

**Op 2 — Record decisions (gate write).** Spec approved, file exists: append
D-entries (`✓`/`✗` per litmus), add STATE line. Commit:
`docs: record decisions for <feature> spec`.

**Op 3 — Immediate write (new).** Trigger: the moment — in ANY skill, including
quick-fix/debug work — a direction is condemned or an existing decision
reversed. Action:
- rejection → append `✗ DO NOT …` with date and source (spec link, or
  `(session)` when none exists);
- reversal → strike the old entry with `[superseded → D-NNN, date]`, append the
  new one.

Commit immediately: `docs: record D-NNN <slug>`. If CONTEXT.md does not exist,
offer to create a minimal registry — never create it silently.

**Op 4 — Conflict gate (strengthened; replaces old op 3).** Input: the intended
direction — clarifying-question set, proposed approaches, approved design, plan
tasks, or a requested code change. Match against ACTIVE (unstruck) entries,
both polarities:
- collision with `✗` — direction previously condemned;
- collision with `✓` — change contradicts an adopted decision.

Hit → hard gate (protocol below). No hit → proceed silently, no message.
Additionally, the "don't re-ask" mode: before asking a clarifying question,
check whether an active D-entry already answers it — if so, do not ask; declare
the assumption with its ID ("assuming per D-014: runner = operator").

**Op 5 — Register shipped (replaces old op 4).** Implementation complete:
remove the STATE line, add a SHIPPED row (`When | What | Decisions`). Commit:
`docs: register <feature> in SHIPPED`.

**Op 6 — Abandon (replaces old op 5).** Remove the STATE line; strike the
spec's unshipped `✓` entries with `[abandoned YYYY-MM-DD]`. **`✗` entries stay
active** — rejections are knowledge gained, not abandoned. Commit.

**Op 7 — Migrate (new, one-time per project).** On detecting the old format
(`## REQUIREMENTS` heading / R-XXX entries): offer migration, never silent.
Mapping:
- R-NNN → D-NNN, numbers preserved (R-015 → D-015);
- `[deprecated …]` → struck entry; all others → active `✓`;
- FEATURES rows → SHIPPED rows;
- STATE paragraphs → one-liners (detail stays in the linked specs — nothing is
  lost, links still resolve);
- ad-hoc sections (e.g. naming conventions) → flagged to the user for
  relocation into source-repo docs.

Commit: `docs: migrate CONTEXT.md to decision-log format`.

## Hard-gate protocol

Protocol text lives ONLY in project-registry; other skills reference it.

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
- No progress without an explicit a/b/c answer. No default.
- (a) triggers op 3 immediately (strike + new entry + commit), then work
  continues.
- Multiple collisions: one message listing all, per-item decision.
- The quote always carries ID, polarity, text, why, date, link — the operator
  sees the decision's full context at the warning site.
- Only the main agent / coordinator runs gates, never subagents (consistent
  with gated-testing R-009).

## Skill integrations

| Skill file | Change |
|---|---|
| `skills/project-registry/SKILL.md` | Full rewrite: new format, ops 1–7, gate protocol (single source of the protocol text). |
| `skills/project-registry/references/project-template.md` | Rewritten to the new template. |
| `skills/brainstorming/SKILL.md` | Step 2 goes from passive "read for awareness" to active op 4: (a) before clarifying questions — filter out questions already answered by a D-entry, declare assumptions instead; (b) before proposing approaches — an approach colliding with an active entry gates immediately, not at step 8. Step 8 stays as a safety net (op 4 against the approved design). Step 12 → ops 1/2. |
| `skills/writing-plans/SKILL.md` | Reads DECISIONS instead of R-XXX; plan header field `Decisions:`; embeds relevant D-XXX into task briefs (unchanged concept — executors don't see CONTEXT.md); self-review traceability over D-XXX. |
| `skills/executing-plans/SKILL.md` | At start: op 4 over the plan's tasks (cheap scan — the plan may predate a newer decision). Mid-execution reversal → op 3. At end: op 5 (replaces old op-4 reference). |
| `skills/subagent-driven-development/SKILL.md` | Same as executing-plans: coordinator gates, subagents unchanged. |
| `skills/using-superpowers/SKILL.md` | Bootstrap guard, 3–4 lines loaded every session: if `docs/superpowers/CONTEXT.md` exists and the task changes code/behavior → read DECISIONS before the first edit; on collision run the project-registry gate protocol. Catches quick fixes that bypass brainstorming. |

## Migration of existing registries

- Dogfood with the implementation: migrate
  `docs/superpowers/superpowers-j2v/CONTEXT.md` (R-001..R-012 → D-001..D-012).
- The remaining ~8 project registries: op 7 on first touch by any skill, with
  user consent — never in bulk.

## Evaluation

Repo policy: skill changes require eval evidence (pressure-testing via
`superpowers:writing-skills`). Scenarios:

| # | Scenario | Expectation |
|---|---|---|
| S1 | Clarifying question already answered by a D-entry | Assumption declared with ID, question not asked |
| S2 | Brainstorm proposes a `✗` direction | Gate fires before the proposal is presented |
| S3 | Quick fix reverses a `✓` decision | Bootstrap guard stops before the first edit |
| S4 | User answers (a) at a gate | Correct supersede + immediate commit |
| S5 | Op 7 on a copy of the 448-line registry | Lossless migration; spec links preserved |
| S6 | Project without CONTEXT.md | Zero behavior change |

## Scope

7 files in `superpowers-j2v.git` (6 skills + 1 template). One implementation
plan. Eval scenarios S1–S6 defined above; exact eval harness setup is decided
in the plan.
