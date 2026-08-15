# CONTEXT: superpowers-j2v

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

_(none in flight)_

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ no `## Gated testing` declaration → modified skills behave exactly as before; only the tdd Anti-Improvisation STOP applies regardless — zero classic-mode regression [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-002** ✓ gated activation is explicit only: CLAUDE.md heading or in-session declaration CC offers to persist — CC never enters the mode silently [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-003** ✓ gated defaults fixed in skills: runner = operator, all tests gated; only `Runner:`/`Local subset:` overridable — no other configuration [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-004** ✓ phase cycle: all RED commits → Gate RED → all GREEN commits → Gate GREEN → refactor — batching is the mode's core [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-005** ✓ no implementation for a task before the phase RED gate confirms its tests fail for the right reason — gated Iron Law [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-006** ✓ standard round request: source root, file list, single one-line command, expected outcome — operator pastes stay small [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-007** ✓ valid-RED analysis per test (assertion failure or clean object-missing error); invalid RED → fix tests → narrowed re-round — RED must fail for the right reason [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-008** ✓ Gate GREEN runs the full suite, no filter; failures → code fix → re-round; a phase ends only green — full suite is the completion bar [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-009** ✓ gates are legitimate stops in both executors; only the main agent handles gates, never subagents — single gate owner [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-010** ✓ round output is verification evidence only for the exact code state it was generated for — any later edit invalidates it [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-011** ✓ every round and its verdict is recorded in the round ledger — survives context compaction [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-012** ✓ in gated mode finishing-a-development-branch verifies via one final full-suite round — never a local substitute [2026-07-08](specs/2026-07-08-gated-testing-mode-design.md)
- **D-013** ✓ CONTEXT.md is a unified decision log: D-XXX with ✓/✗ polarity and explicit inline status; FEATURES and derived status removed, thin SHIPPED table — validity visible in the entry itself [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-014** ✓ entry grammar: one line per decision + mandatory one-clause why; flat chronological list; STATE hard-capped at one line per spec — scannability [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-015** ✓ `✗` only for directions explicitly marked wrong; merely-not-chosen alternatives stay in specs — re-proposing one collides with the winning ✓ [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-016** ✓ write timing: gate writes at spec approval + immediate op-3 write on any rejection/reversal in any skill; never create CONTEXT.md silently — negative decisions never wait [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-017** ✓ conflict gate is hard: explicit supersede / change direction / stop, no default, supersede recorded immediately; only main agent/coordinator gates — operator oversight is the failure mode [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-018** ✓ check points: brainstorming start (active: no re-asking, gate before proposing), plan and execution start, using-superpowers bootstrap guard, pre-spec safety net — warn early, not only pre-spec [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-019** ✓ migration (op 7) is offered never silent; R-NNN → D-NNN preserving numbers; per-project on first touch — no bulk migration [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-020** ✓ projects without CONTEXT.md see zero behavior change — every new behavior keyed on the file existing [2026-07-10](specs/2026-07-10-context-md-decision-log-design.md)
- **D-021** ✓ brainstorming gates every direction before presenting it (question set, approaches, composed design, revisions); pre-spec check is a conditional re-check only — never approve-then-warn [2026-07-11](specs/2026-07-11-brainstorming-early-gate-design.md)
- **D-022** ✓ op-3 reversals edit the entry in place (same D-ID + inline `(prev: <compressed>)`); strikethrough reserved for op-6 abandon; gate (op 4 / a-b-c) unchanged — one entry per topic, no scattered mutually-exclusive lines [2026-07-14](specs/2026-07-14-op3-edit-in-place-design.md)
- **D-023** ✓ new Rebuild op converts legacy superseded chains (mechanical) and gated implicit reversals between active entries (Case 2) to edit-in-place — one-time, offered never silent [2026-07-14](specs/2026-07-14-op3-edit-in-place-design.md)
- **D-024** ✓ parallel SDD is a separate full-copy skill `subagent-driven-development-parallel`; sequential and parallel are synchronized copies — shared changes land in both, byte-freeze lifted — fork evolution outranks a frozen baseline [2026-07-28](session) (prev: sequential skill stays byte-identical — sequential fallback, eval baseline, upstream mergeability [2026-07-24](specs/2026-07-24-sdd-parallel-design.md))
- **D-025** ✓ parallel skill is the default executor via routing (writing-plans handoff + plan header), not explicit activation — speed goal outranks the activation pattern; escape hatch = invoke sequential skill [2026-07-24](specs/2026-07-24-sdd-parallel-design.md)
- **D-026** ✓ task dependencies declared at plan time: mandatory `Depends on:` per task + Dependency overview in header, no runtime inference — plan author holds the whole-system view [2026-07-24](specs/2026-07-24-sdd-parallel-design.md)
- **D-027** ✓ unit of parallelism = task, event-driven ready-set scheduling, no wave barriers; in-task TDD stays sequential — a slow task must not block independent DAG branches [2026-07-24](specs/2026-07-24-sdd-parallel-design.md)
- **D-028** ✓ worktree-per-task with controller-serialized merges; dependents unblock on merge, not review-clean — they need merged interfaces; shared worktree races git state and voids test evidence [2026-07-24](specs/2026-07-24-sdd-parallel-design.md)
- **D-029** ✓ brainstorming deep research is propose-then-accept: the proposal is the only thing in its message your human partner must answer — the research verdict may head it — and dispatch happens only on approval — answerability, not the message boundary, is what protects consent [2026-07-30](specs/2026-07-28-brainstorming-subagent-research-design.md) (prev: proposal had to be its own message — 6 of 8 eval reps put the verdict in that same message with no loss of answerability, and the rule gave no ruling when the human's answer ended the clarifying questions)
- **D-030** ✓ two research modes picked by the skill and named in the proposal: per-decision (before approaches) and per-approach (after sketch) — unit must fit the question shape [2026-07-28](specs/2026-07-28-brainstorming-subagent-research-design.md)
- **D-031** ✓ research subagents are read-only fact-finders returning findings + recommendation; human partner approves each decision separately — only the main agent decides and gates [2026-07-28](specs/2026-07-28-brainstorming-subagent-research-design.md)
- **D-032** ✓ research persistence: decision summary in spec + full findings in `docs/superpowers/research/YYYY-MM-DD-<topic>-analysis.md` committed with the spec — future sessions need the rationale [2026-07-28](specs/2026-07-28-brainstorming-subagent-research-design.md)
- **D-033** ✓ research mechanism lives in reference file `research-subagents.md` loaded on acceptance (visual-companion pattern) — keeps SKILL.md lean; one exception: the consent guard on an unmappable trim is duplicated in SKILL.md, because the load precondition measures 11/12 and a skipped load leaves no count check in context at all [2026-07-30](specs/2026-07-28-brainstorming-subagent-research-design.md) (prev: no exceptions — the whole mechanism sat in the reference file)
- **D-034** ✗ DO NOT add an informational-claims section to verification-before-completion — RED micro-tests 18/18 clean (sonnet+opus, false-premise and version-precision probes, under time pressure): current models already abstain, no failure to fix; factual-claims layer lives in the operator's global CLAUDE.md instead [2026-08-05](session)
- **D-035** ✓ `requesting-code-review` dispatches the `sdd-reviewer` agent (sonnet/xhigh) in SDD and standalone alike, `general-purpose`+`model: sonnet` only when that agent is missing from the registry — the old "most capable available model" + "always general-purpose" wording predated the 2026-07-19 model/effort migration and sent standalone reviews to opus (RED 5/5) while forcing SDD runs to adjudicate the conflict (RED 5/5 flagged it); GREEN 5/5 after the fallback clause was tied to the registry, not to the workflow [2026-08-05](evals/2026-08-05-reviewer-dispatch-consistency.md)
- **D-036** ✓ systematic-debugging delegates all four phases to subagents, modified in place (no variant skill) — main context must stop growing with evidence reads [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)
- **D-037** ✓ debugging delegation is unconditional, no simple-bug exception — a trivial-case escape hatch reopens the "this bug is simple" rationalization [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)
- **D-038** ✓ hypotheses, attempt ledger, 3-failure counter, final full-suite verification, and human-partner talks stay in the main session; subagents return raw evidence (exact command + verbatim lines), never decisions — self-report alone is not verification [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)
- **D-039** ✓ subagent model by work character, not cost: sonnet for relay paths (errors, repro, git, experiments), session model for reasoning paths (data-flow, pattern analysis, fixer) — sonnet is faster and hallucinates less on simple work [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)
- **D-040** ✓ fixer failure ladder: re-dispatch with ledger → sdd-rescue → STOP and question architecture with human partner — one attempt per subagent, the loop belongs to the main agent [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)
- **D-041** ✓ in gated projects debugging subagents never run tests; test commands go through operator gates — single gate owner per D-009 [2026-08-15](specs/2026-08-15-systematic-debugging-subagents-design.md)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-07-09 | Gated Testing Mode — batched RED/GREEN gates across 6 skills + 2 templates, eval-validated | D-001..D-012 |
| 2026-07-10 | CONTEXT.md decision log — D-XXX format, ops 1–7, hard gate across 6 skills | D-013..D-020 |
| 2026-07-11 | Brainstorming early gate — every direction gated before presentation, conditional pre-spec re-check | D-021 |
| 2026-07-15 | op-3 edit-in-place — reversals edit the D-entry in place (same ID + `(prev: …)`), strikethrough = op-6 abandon, new op 8 Rebuild converts legacy logs | D-022, D-023 |
| 2026-07-24 | subagent-driven-development-parallel skill — DAG-scheduled concurrent SDD (full copy of sequential; the byte-freeze on the sequential copy was lifted later the same week, see D-024) + writing-plans mandatory Depends-on routing; eval-validated RED→GREEN→REFACTOR | D-024..D-028 |
| 2026-07-29 | Brainstorming deep research — propose-then-accept parallel read-only research subagents, per-decision approval, research analysis files; eval-validated on a second fixture under an isolated HOME | D-029..D-033 |
| 2026-07-30 | Brainstorming deep research follow-ups — research-guide load precondition (11/12), dispatch-count check when a trim cannot lower the count (4/4), proposal answerability criterion (4/4), new eval scenario N5; all measured under the operator's real global CLAUDE.md | D-029 (changed) |
| 2026-07-30 | Pre-push independent review of the whole unpushed range (no Critical, 8 Important) and its fixes — per-approach ordering stated once + count guard duplicated into SKILL.md (both 2/2, elicitation 2/3, V11); parallel-SDD digraph dispatch order, task-worktree convention and declined-worktree fallback, task evidence copied out before worktree removal, topological task numbering, `Paste back:` in both embedded gate templates — probes afterwards confirmed the digraph dispatch order, the evidence copy and the `Paste back:` line, and caught `git worktree remove` needing `--force`; the declined-worktree fallback and the numbering rule under pressure stay unmeasured | D-033 (changed) |
| 2026-08-15 | systematic-debugging subagent delegation — all four phases dispatched, attempt ledger and final verification in the main session, eval-validated | D-036..D-041 |
