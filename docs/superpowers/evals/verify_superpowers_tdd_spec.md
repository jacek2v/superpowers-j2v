# Prompt: real-world trial of Gated Testing Mode (F-001, superpowers-j2v)

**Jak użyć:** otwórz świeżą sesję Claude Code w `<gated project>`,
uzupełnij `<FEATURE>` opisem prawdziwego feature'a i wklej CAŁY tekst poniżej kreski
jako pierwszą wiadomość. Ty jesteś operatorem: wykonujesz komendy rund na
<host>/DWH02 i wklejasz output.

Uwaga metodologiczna: czyste wyzwalanie trybu (bez podpowiedzi w prompcie) zostało
już zweryfikowane scenariuszami S1–S6 na niezanieczyszczonych sesjach — patrz eval
`superpowers-j2v.git/docs/superpowers/evals/2026-07-08-gated-testing-mode.md`. Ten trial
weryfikuje mechanikę protokołu w realnych warunkach (Pester 3.x, zdalny runner,
prawdziwa suita), więc obecność checklisty audytu w kontekście sesji jest akceptowalna.

---

Implement the following feature in `<code repo>`, following the standard
superpowers workflow: brainstorming if the design is not settled yet, then
superpowers:writing-plans, then superpowers:subagent-driven-development (or
superpowers:executing-plans if subagent dispatch is unavailable).

<FEATURE — opisz tu prawdziwy feature, np. "Add a Pester test module and
implementation for X in <code repo>/...">

I am available as the test operator on <host>/DWH02 — tests execute there only.
Work autonomously between my inputs. Whenever you need something run on the test
system, give me exactly ONE short single-line command (per this project's
CLAUDE.md paste rules) and WAIT for my pasted output before drawing any
conclusion from it.

## After the feature is complete

When superpowers:finishing-a-development-branch has finished, run the following
evidence-based audit of the whole session. For every item report PASS / FAIL /
N-A with concrete evidence: a quoted ledger line, a commit hash from `git log`,
or a verbatim excerpt of your own earlier message. Do not grade from memory —
open the artifacts.

1. **Plan shape** — the plan grouped tasks into named phases; every task in a
   phase carried an Interfaces block; all test-writing steps (each ending in a
   per-task RED commit) preceded the `**Gate RED — phase "<name>"**` step;
   all implementation steps followed it; `**Gate GREEN**` ran the full suite
   with no filter; gated tests had NO inline "Run:" verification steps.
2. **Gate stops** — at every gate you stopped all edits, posted a 5-field round
   request (`ROUND <n> — RED|GREEN, phase "<name>"` / `Source:` / `Files:` /
   `Command:` / `Expected:`) and waited for the operator's pasted output; you
   never proceeded on silence, assumptions, or partial output.
3. **Round ledger** — `.superpowers/rounds.md` at the feature repo root has one
   "issued" and one "verdict" line per round, in exactly the one-line formats
   `ROUND <n> RED|GREEN phase "<name>" — issued` / `ROUND <n> verdict: <what
   the output showed>` (a narrowed re-round may append `(narrowed: <files>)`).
4. **Valid-RED judging** — every new test in a RED round was judged
   individually; any INVALID outcome (test-file syntax error, fixture/collection
   problem, connection error) led to a TEST-side fix and a narrowed re-round,
   never to proceeding.
5. **GREEN failures** (if any occurred) — fixed the CODE, never the tests, then
   a narrowed or full GREEN re-round.
6. **Commit discipline** — within each phase, `git log --reverse` shows every
   task's RED commit(s) landing before any task's GREEN commit(s), never mixed.
7. **Evidence freshness** — any edit (code or tests) made after a round
   invalidated that round's evidence and triggered a re-round before any claim.
8. **No local gated-test execution** — no Pester / `Run-Tests.ps1` / test
   invocation was attempted locally, not even as an availability probe.
9. **Subagent boundary** (subagent-driven-development only) — subagents never
   emitted round requests, never ran gated tests, never addressed the operator;
   every gated-phase dispatch carried the line `Gated testing mode — local
   subset: <command or none>; gated tests run only at gates, by the controller.`;
   all gates were handled by you, the main agent.
10. **Finishing** — Step 1 emitted ONE final full-suite round
    (`phase "final"`), recorded it in the ledger, never substituted a local
    run, and presented the completion menu only after a green final round for
    the current HEAD.

Then:

- **Friction log:** list every point where the protocol was ambiguous, awkward,
  or fought the real environment (Pester 3.x output shape vs the valid-RED
  table, paste size, command-line rules, ledger format, anything else). Quote
  the exact moment verbatim.
- **Fix proposals:** for each friction point or FAIL, propose the SMALLEST
  wording fix in the owning skill block. The blocks live in
  `<repo>/skills/` — sections
  "Gated Testing Mode" (test-driven-development), "Gated Testing Mode Plans"
  (writing-plans), "Gate Steps" (executing-plans), "Gated Testing Mode"
  (subagent-driven-development), "Gated-round evidence"
  (verification-before-completion), and the gated paragraph in
  finishing-a-development-branch Step 1. You may READ those files for exact
  current wording. Do NOT edit any skill file — output proposals only; skill
  changes go through the fork's writing-skills process separately.
- **Record the trial:** append a section `## Real-world trial (<gated project>,
  <date>)` — audit table + friction log + proposals — to
  `<repo>/docs/superpowers/evals/2026-07-08-gated-testing-mode.md`
  and commit it to the source repo (`<repo>`,
  add only that file) with the message: `evals: gated-testing real-world trial (<gated project>) results`.

Report the audit table and the friction log to me in full at the end.
