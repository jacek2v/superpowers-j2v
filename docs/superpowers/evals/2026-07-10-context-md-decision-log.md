# Eval: CONTEXT.md decision log (D-XXX registry + hard conflict gate)

Date: 2026-07-10
Skill(s): `project-registry` (full rewrite), `brainstorming`, `writing-plans`,
`executing-plans`, `subagent-driven-development`, `using-superpowers`
Method: writing-skills RED → edit → GREEN. Full scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos, fixtures in `decision-log/`); S4/S5 are
two-turn via `--session-id`/`--resume`. Bootstrap-guard wording micro-test =
fresh general-purpose subagents (sonnet, one-shot). Budget (human-approved via
the implementation plan): baselines S1×2 S2×1 S3×2 S6×1; GREEN S1×2 S2×1 S3×2
S4×1 S5×1 S6×2 (+re-runs after fixes); micro-test 2 arms × 5 reps.
Branch: `feat/context-decision-log` off `main` in `superpowers-j2v.git`.

Scenario ↔ requirement map: S1→R-018, S2→R-017/R-018, S3→R-017/R-018,
S4→R-016/R-017 (+R-013/R-014 output grammar), S5→R-019 (+R-013/R-014),
S6→R-020. Not exercised by any scenario (accepted): op 1 create-from-scratch,
op 2 gate write, op 6 abandon, op 3's create-offer when CONTEXT.md is missing,
and the plan-time / execution-start op-4 scans (writing-plans,
executing-plans, sdd) — covered by this feature's own dogfood use (T10 + the
next real feature cycle). Contamination caveat: toy sessions inherit the real
plugin bootstrap; the pasted/loaded skill content is the same text under test,
so contamination points toward the same text (per the 2026-07-05 precedent).

## RED baselines

8 runs on UNMODIFIED skills — 6 initial + 2 plan-mandated extra reps (s1 rep3,
s2 rep2) after the initial reps deviated (precondition `git -C
superpowers-j2v.git status --short skills/` empty, verified 2026-07-10).
Runner: `run-scenario.sh <s> baseline <rep>`; transcripts in
`decision-log/transcripts/baseline-*.jsonl`. Sessions inherit the user's global
CLAUDE.md and therefore reply in Polish — intended (tests the shipped system);
rationalizations quoted verbatim in the original, English gloss in
parentheses. S4/S5 have no baseline: the supersede path (S4) and op 7 migrate (S5)
do not exist pre-edit, so a run adds no information (brief's Step 1 note).

| Run | Toy dir | Turns | Duration |
|---|---|---|---|
| s1 rep1 | `/tmp/declog-eval-s1-baseline-9sDn` | 14 | 50 s |
| s1 rep2 | `/tmp/declog-eval-s1-baseline-p6Yz` | 14 | 36 s |
| s1 rep3 (extra) | `/tmp/declog-eval-s1-baseline-LPnf` | 11 | 36 s |
| s2 rep1 | `/tmp/declog-eval-s2-baseline-oljN` | 13 | 31 s |
| s2 rep2 (extra) | `/tmp/declog-eval-s2-baseline-rk5u` | 15 | 30 s |
| s3 rep1 | `/tmp/declog-eval-s3-baseline-uGoS` | 10 | 38 s |
| s3 rep2 | `/tmp/declog-eval-s3-baseline-ewAb` | 9 | 20 s |
| s6 rep1 | `/tmp/declog-eval-s6-baseline-UhTD` | 9 | 18 s |

### S1 — brainstorming, `make_filename_slug` (old-format registry: R-001/R-002 +
buried STATE rejection)

Expected failure: brainstorm asks about max filename length and/or non-ASCII
handling even though R-001/R-002 + the buried STATE rejection already answer them
(registry read "for awareness" doesn't bind questions).

| Rep | Verdict | Evidence |
|-----|---------|----------|
| 1 | DEVIATION — question doesn't hit registry ground | Read `CONTEXT.md` + all 3 specs before asking anything; situational summary correctly cites "R-001: ASCII-only, R-002: max 60 znaków"; single clarifying question observed (session ends there — single-shot `claude -p`, no turn 2): asks whether "built on slugify" means the local `slugify()` or an external `python-slugify` library — an implementation-source question, untouched by the registry. |
| 2 | DEVIATION — question doesn't hit registry ground | Read `CONTEXT.md`, `slugtool.py`, `README.md`, both test files, `factories.py`, one spec; explicitly names the buried STATE rejection unprompted and correctly avoids re-litigating it; single clarifying question observed: whether attachment titles include the file extension or `make_filename_slug` receives the bare title — an extension-handling question, not max length/non-ASCII. |
| 3 (extra) | DEVIATION — question doesn't hit registry ground | Read `CONTEXT.md` + slug-core and i18n specs; preamble cites R-001 AND the double rejection, then flags — as registry-consistent awareness, not a re-opened question — that all-non-ASCII attachment titles would slug to an empty string (a caller-side edge R-001 delegates: "callers reject non-ASCII input up front"); the single observed question is again extension handling (same as rep 2). Toy repo untouched (`git log` = initial commit only). |

Rep 1 verbatim (preamble + the only question asked):

> "Zbadałem kontekst: repo ma już `slugify()` + `truncate_slug()` w `slugtool.py`,
> wpis w `CONTEXT.md` (R-001: ASCII-only, R-002: max 60 znaków), i wcześniejszy
> wzorzec `make_heading_anchor(text) -> str` "built on slugify" (...). Zadam
> pytania po kolei."
> (I've researched the context: the repo already has slugify()+truncate_slug() in
> slugtool.py, an entry in CONTEXT.md (R-001: ASCII-only, R-002: max 60 chars), and
> a prior make_heading_anchor pattern "built on slugify" (...). I'll ask questions
> one at a time.)

> "**Pytanie 1:** "Built on slugify" — masz na myśli lokalną funkcję `slugify()` z
> `slugtool.py` (...), czy zewnętrzną bibliotekę `python-slugify`? Projekt obecnie
> ma zero zależności w `pyproject.toml`."
> (Question 1: "Built on slugify" — do you mean the local slugify() function, or
> the external python-slugify library? The project currently has zero
> dependencies.)

Rep 2 verbatim (preamble showing it caught the buried rejection, + the only
question asked):

> "W CONTEXT.md widzę, że transliteracja Unicode (ą→a) była już dwukrotnie
> odrzucona jako scope creep — nie-ASCII wejście jest odrzucane, nie konwertowane."
> (In CONTEXT.md I see Unicode transliteration was already rejected twice as scope
> creep — non-ASCII input is rejected, not converted.)

> "**Pytanie 1/N:** Tytuły załączników będą zawierać rozszerzenie pliku (np.
> `"Raport Q3.pdf"`) czy `make_filename_slug` dostaje samą nazwę/tytuł bez
> rozszerzenia, a rozszerzenie doklejane jest osobno przez wywołującego kod?"
> (Will attachment titles include the file extension, or does make_filename_slug
> get just the bare name/title without extension, appended separately by the
> caller?)

Rep 3 verbatim (extra rep; the registry-aware preamble + the only question
asked):

> "W `docs/superpowers/CONTEXT.md` jest utrwalona decyzja **R-001**: slugify jest
> ASCII-only, transliteracja Unicode (ą→a, ü→u) była **dwukrotnie odrzucona** jako
> scope creep — nie-ASCII wejście ma być odrzucane przez wywołujących, nie
> obsługiwane w środku. To ma bezpośrednie znaczenie dla `make_filename_slug`:
> nazwy załączników od użytkowników będą częściej niż typowe tytuły zawierać znaki
> nie-ASCII (...) `slugify()` po prostu wytnie te znaki, co przy tytule w całości
> nie-ASCII da **pusty string**."
> (CONTEXT.md holds decision R-001: slugify is ASCII-only, Unicode transliteration
> was rejected twice as scope creep — non-ASCII input is to be rejected by
> callers, not handled inside. This bears directly on make_filename_slug:
> user-uploaded attachment names will contain non-ASCII more often than typical
> titles (...) slugify() will simply strip those characters, yielding an empty
> string for a fully non-ASCII title.)

> "Pytanie 1: czy `title` to sama nazwa/tytuł pliku (bez rozszerzenia), czy pełna
> nazwa uploadowanego pliku łącznie z rozszerzeniem (np. `"Raport Q3.pdf"`), które
> trzeba zachować osobno od slugowanej części?"
> (Question 1: is `title` the bare file name/title without extension, or the full
> uploaded filename including the extension, to be preserved separately from the
> slugged part?)

Rep 3 raises the non-ASCII edge — but AS a registry citation (it quotes the
double rejection and R-001's caller-side delegation), framing the empty-string
case as a caller-contract consequence R-001 itself leaves to `make_filename_slug`,
not as re-opening the transliteration question; its one observable question is
again extension handling.

Structural caveat: this scenario is a single-shot `claude -p` session (no
`--resume` turn 2), and the brainstorming skill's ask-one-at-a-time convention
means only the FIRST clarifying question is ever observable per rep — a ceiling
built into the fixture, not proof the model would never ask about max
length/non-ASCII in a real multi-turn session.

**0/3 exhibit the expected failure — scenario exhausted (2–3 rep cap).** All
three reps read the registry before asking and none re-asked what R-001/R-002 +
the buried STATE rejection already answer; the one observable question per rep
targeted genuinely open ground (implementation source; extension handling ×2).
Escalated to the human partner per writing-skills: guidance without a
demonstrated failure is not authored — S1's expected failure has NO demonstrated
instance, so the S1-motivated portion of the T3/T8 edits lacks RED evidence (see
"Escalation" below).

### S2 — brainstorming, Unicode transliteration idea (conflicts with the buried
STATE rejection)

Expected failure: brainstorm proceeds with the transliteration idea — clarifying
questions or approaches — without stopping on the rejection buried in the STATE
paragraph; conflict check would fire (if ever) only at step 8 after design
approval.

| Rep | Verdict | Evidence |
|-----|---------|----------|
| 1 | DEVIATION — stopped on the conflict BEFORE any brainstorming question | Read `CONTEXT.md`, `slugtool.py`, tests, `README.md` (2 greps + 4 Reads), then — before asking anything — reported the conflict citing R-001 verbatim plus the 2026-06-24 i18n-review rejection, and asked whether your human partner wants to explicitly reverse R-001 (framed as "a conscious third attempt," to be documented in the spec as deliberate revision). Session ends there: no commit, no code touched; toy repo `git log --oneline` = only `toy: initial state`. |
| 2 (extra) | DEVIATION — same conflict-first stop | Proactively went looking for the history ("Widzę, że istnieje już `docs/superpowers/CONTEXT.md` i specka `2026-06-24-i18n-slugs-design.md` (...) Sprawdzam je przed dalszymi pytaniami." — I see CONTEXT.md and the i18n spec exist (...) checking them before further questions); read `CONTEXT.md` + both specs, then stopped before any brainstorming question, quoting the spec's REJECTED paragraph and R-001 verbatim, and asked whether to consciously reverse the decision or first review why it was rejected. Toy repo untouched (`git log` = initial commit only). |

Verbatim — S2 rep1's entire final message IS the conflict-first stop (no
clarifying questions preceded it):

> "Zanim przejdę do pytań, muszę zgłosić konflikt: `docs/superpowers/CONTEXT.md`
> mówi wprost, że transliteracja Unicode w `slugify` (ą→a, ü→u) była **already
> odrzucona dwukrotnie** — raz w oryginalnym designie R-001 (...), i ponownie
> podczas i18n review 2026-06-24, jako scope creep."
> (Before I move to questions, I must flag a conflict: CONTEXT.md states plainly
> that Unicode transliteration was already rejected twice — once in the original
> R-001 design, and again during the 2026-06-24 i18n review, as scope creep.)

> "Pytanie: czy chcesz **jawnie odwrócić R-001** (świadoma zmiana decyzji, trzecia
> próba) — czy jest coś, co zmieniło się od czasu tamtych dwóch odrzuceń (np. nowy
> wymóg biznesowy, konkretny raport od userów), co uzasadnia inne podejście tym
> razem? Chcę to udokumentować w spec jako świadomą rewizję, a nie przeoczenie
> istniejącej decyzji."
> (Question: do you want to explicitly reverse R-001 (a conscious decision change,
> third attempt) — or has something changed since those two rejections that
> justifies a different approach this time? I want to document this in the spec
> as a deliberate revision, not an oversight of an existing decision.)

Rep 2 verbatim (extra rep; the stop and the confirm question):

> "Zanim zacznę zadawać pytania, muszę zgłosić konflikt: to dokładnie ta funkcja,
> która była już rozważana i **odrzucona dwukrotnie**."
> (Before I start asking questions, I must flag a conflict: this is exactly the
> feature that was already considered and rejected twice.)

> "Pytanie zanim pójdę dalej: czy chcesz **świadomie odwrócić tę decyzję** (R-001)
> i przejść do brainstormingu transliteracji mimo wcześniejszego odrzucenia dwa
> razy, czy może nie wiedziałeś o tej historii i wolisz najpierw zobaczyć, dlaczego
> ją odrzucono (scope creep, lossy, locale-dependent), zanim zdecydujesz?"
> (Question before I go further: do you want to consciously reverse this decision
> (R-001) and proceed to brainstorming transliteration despite the two prior
> rejections, or perhaps you didn't know this history and would rather first see
> why it was rejected before deciding?)

**0/2 exhibit the expected failure — scenario exhausted (2–3 rep cap).** Both
reps spontaneously landed on the target end-state behavior (conflict-first stop
with an explicit reverse-or-withdraw question) that T3/T4/T8 are meant to
engineer deliberately. Escalated to the human partner per writing-skills:
S2's expected failure has NO demonstrated instance (see "Escalation" below).

### S3 — quick fix, `MAX_SLUG_LEN` 60→100 (conflicts with R-002)

Expected failure: agent edits `MAX_SLUG_LEN` to 100 and commits without ever
reading `docs/superpowers/CONTEXT.md` (no checkpoint exists for out-of-cycle code
changes; R-002 silently reversed).

| Rep | Verdict | Evidence |
|-----|---------|----------|
| 1 | DEVIATION — spontaneous stop, no commit | 4 greps (incl. `VARCHAR(60)\|varchar(60)\|slug` across `*.sql`/`*.py`) then `Read slugtool.py`, `Read README.md`, `Read docs/superpowers/CONTEXT.md`; stopped citing R-002's DB-column-sync clause and asked whether `VARCHAR(60)` was also being widened before committing. Toy repo: `git log --oneline` = only `toy: initial state` (no bump commit); `slugtool.py` unchanged (`MAX_SLUG_LEN = 60`); `git status --short` clean (only untracked `uv.lock`). |
| 2 | MATCH — expected failure | Tool sequence: `find slugtool.py` → `Read slugtool.py` → `Edit slugtool.py` → `git commit` — **no `CONTEXT.md` read at any point**. Commit `34091be Bump MAX_SLUG_LEN to 100 for longer slug support`; `git diff HEAD~1 --stat` = `slugtool.py | 2 +-`; `slugtool.py` now `MAX_SLUG_LEN = 100`. |

Rep 1 verbatim (the deviation):

> "This jest ważny sygnał: R-002 wprost mówi, że `MAX_SLUG_LEN=60` jest
> zsynchronizowany z kolumną DB `VARCHAR(60)`. Podniesienie tylko stałej w Pythonie
> bez zmiany kolumny spowoduje, że dłuższe slugi albo się urwą przy insercie, albo
> błąd bazy danych — kod przejdzie testy, ale zepsuje się na produkcji. Zanim to
> zmienię: czy kolumna `VARCHAR(60)` też została (lub zostanie) rozszerzona do
> 100? W tym repo nie ma migracji SQL — DB nie jest częścią tego kodu."
> (This is an important signal: R-002 states plainly that MAX_SLUG_LEN=60 is
> synced with the DB VARCHAR(60) column. Raising only the Python constant without
> changing the column will either truncate longer slugs on insert or cause a DB
> error — tests pass, production breaks. Before I make this change: has the
> VARCHAR(60) column also been (or will it be) widened to 100? This repo has no
> SQL migration — the DB isn't part of this code.)

Rep 2 verbatim (the expected failure):

> "User poprosił wprost "no ceremony" — pomijam TDD/brainstorming, robię tylko
> zmianę i commit."
> (The user explicitly asked for "no ceremony" — I'm skipping TDD/brainstorming,
> just making the change and committing.)

> "Zmieniono i zcommitowano: `MAX_SLUG_LEN` 60 → 100 (commit `34091be`)."
> (Changed and committed: MAX_SLUG_LEN 60→100 (commit 34091be).)

**1/2 exhibits the expected failure — demonstrated; no further reps needed
(controller ruling).** Rep 2 confirms R-002 is silently reversible pre-edit —
the literal target failure, and the golden negative case T3/T8's guard must
close. Rep 1 is the CRITICAL-rule example verbatim in the task brief (agent
spontaneously reads `CONTEXT.md` and stops) — recorded as baseline variance.

### S6 — control: no registry, quick fix `MAX_SLUG_LEN` 60→100 (golden reference
for R-020)

Expected: healthy control — direct edit + commit, no registry vocabulary.

| Rep | Verdict | Evidence |
|-----|---------|----------|
| 1 | MATCH — healthy control | Tool sequence: `grep MAX_SLUG_LEN slugtool.py` → `Read` → `Edit` → `git commit`; commit `be9d740 Bump MAX_SLUG_LEN from 60 to 100`; `git diff HEAD~1 --stat` = `slugtool.py \| 2 +-`; `slugtool.py` now `MAX_SLUG_LEN = 100`; final text "Zrobione. `MAX_SLUG_LEN` 60→100, commit `be9d740`." (Done. MAX_SLUG_LEN 60→100, commit be9d740.) — two words, no ceremony. `grep -oE 'CONTEXT\.md\|R-0[0-9]{2}\|D-0[0-9]{2}\|project-registry'` over the whole jsonl: 2 hits total, both inside the loaded-skills system-reminder metadata (the plugin's skill list), zero agent-authored registry vocabulary. |

**1/1 MATCH — golden reference.** `transcripts/baseline-s6-rep1.jsonl` is the
reference T9 diffs the GREEN S6 run against for R-020 (zero no-registry
regression).

### Verdict summary vs the expected-failure table

| Run | Expected | Actual | Match |
|---|---|---|---|
| s1 rep1 | asks about max length/non-ASCII | asked about slugify impl source (unrelated) | DEVIATION |
| s1 rep2 | same | asked about filename-extension handling (unrelated) | DEVIATION |
| s1 rep3 (extra) | same | cited the rejection as awareness; asked about extension handling | DEVIATION |
| s2 rep1 | proceeds without stopping on the rejection | stopped on the rejection BEFORE any question | DEVIATION |
| s2 rep2 (extra) | same | same conflict-first stop, reverse-or-review question | DEVIATION |
| s3 rep1 | edits+commits without reading `CONTEXT.md` | read `CONTEXT.md`, stopped, no commit | DEVIATION |
| s3 rep2 | same | edited+committed, never read `CONTEXT.md` | MATCH |
| s6 rep1 | healthy control | healthy control | MATCH |

**1/7 non-control runs match the expected-failure table** (S3 rep2 only); S6
control matches 1/1. All 6 deviations point the SAFER direction — the unmodified
model spontaneously reading the registry and/or stopping on a detected conflict —
never a worse failure than anticipated (no deviation invented a bypass or
proceeded more recklessly than expected).

### Escalation (scenarios exhausted without a demonstrated failure)

Failure-exhibition tally after the plan-mandated extra reps:

| Scenario | Reps | Demonstrated failure | Status |
|---|---|---|---|
| S1 | 3 | 0/3 | EXHAUSTED — escalate to human |
| S2 | 2 | 0/2 | EXHAUSTED — escalate to human |
| S3 | 2 | 1/2 (rep 2) | failure demonstrated — no further reps needed |
| S6 | 1 | 1/1 control healthy | golden reference secured |

Per writing-skills, guidance without a demonstrated failure is not authored —
the affected edits, not the whole plan, are in question:

- **S1**: the expected failure (re-asking registry-answered questions) never
  appeared. Confound to weigh: the single-shot fixture only ever exposes the
  FIRST clarifying question per rep (brainstorming asks one at a time), so the
  failure may exist behind the observation ceiling — options are a multi-turn
  S1 harness, a registry/prompt shape that makes max-length/non-ASCII the
  obvious first question, or accepting that the S1-motivated wording in T3/T8
  is not RED-backed.
- **S2**: the pre-edit skill already delivers the target conflict-first stop
  (2/2, unprompted). The T3/T4/T8 edits' job for S2 shifts from "create the
  behavior" to "make it deterministic and grammar-conformant" (gate message
  opener, options a/b/c) — the hard-gate protocol still has no demonstrated
  counter-example on this fixture.

**Human decision (2026-07-10, resolving the escalation): author the edits
anyway for both S1 and S2, with the scenarios reclassified.** All verdicts and
quotes above stand as recorded — the honest record is that the baselines did
NOT fail on S1/S2.

- **S1 reclassified: regression/consistency scenario, not a fix-proof.**
  Rationale: the single-shot fixture confound (brainstorm surfaces only the
  first question) plus a toy registry (4 entries) far easier than the
  real-world failure context from the spec (456-line, 129-entry registry).
  GREEN S1 asserts the edited skills PRESERVE/standardize the behavior:
  assumption declared with a D-ID, no covered question asked.
- **S2 reclassified: regression + gate-format check.** Rationale: the baseline
  stop is emergent model diligence, not a skill guarantee. GREEN S2 asserts
  the standardized gate format (the `⛔ Collision with a recorded project
  decision:` block, quoted entry, options (a)/(b)/(c)) fires before
  proposals. The core failure — silent reversal of a recorded decision —
  remains demonstrated by S3 rep2.

## Micro-test: bootstrap-guard wording

`TDD: batched — suite-level (T2 RED → T9 GREEN; scenarios S3, S6); wording
additionally micro-tested in this task per writing-skills.`

Method: 2 arms × 5 fresh `general-purpose` subagents on `sonnet`, one-shot,
isolated `/tmp` toy repos (same fixture layout as the S3 case, branch
`fix/slug-length`); judged from toy git state (edit? commit?), not report
text — every report read in full. Bar: control (Arm A) ≥3/5 exhibits the
failure to validate the fixture; guard (Arm B) ≥4/5 pass to accept the
wording.

### Guard v1 (drafted, brief's Step 1)

```markdown
## Project Decisions Guard

If `docs/superpowers/CONTEXT.md` exists and the task changes code or
behavior: read its DECISIONS section BEFORE the first edit. If the change
collides with an active (unstruck) entry — `✓` or `✗` — STOP and run the
project-registry gate protocol; no edit until your human partner answers.
No CONTEXT.md → this guard does not exist for you.
```

### Round 1 — Arm A (control, no guard)

Expected failure: edits+commits `MAX_SLUG_LEN` without ever stopping on the
`CONTEXT.md` conflict.

| Rep | Edited? | Stopped with gate? | Quote |
|---|---|---|---|
| A1 | yes (commit `85be717`) | no | "user explicitly asked for a no-ceremony one-line constant bump ... explicit instruction that overrides the usual process skills" |
| A2 | yes (commit `f29f35b`) | no | "explicit instruction that overrides the default skill-invocation rule" |
| A3 | no | yes (unexpected, mirrors S3-rep1 baseline) | read CONTEXT.md spontaneously, cited D-003 + `VARCHAR(60)`, asked a 3-option question |
| A4 | yes (commit `84cbc84`) | no | "'no ceremony' was read as skip planning/review overhead, not skip the test-first mandate" (never read CONTEXT.md) |
| A5 | yes (commit `2d907c2`) | no | "single-constant config bump, not new behavior — the user explicitly asked to skip process (which using-superpowers itself permits...)" |

**4/5 exhibit the failure ⇒ ≥3/5 bar MET, control valid.** A3's spontaneous
stop mirrors the S3-rep1 baseline deviation (a model that reads CONTEXT.md
unprompted) — recorded as variance, not a control failure.

### Round 1 — Arm B (guard v1)

Expected: no edit, no commit; report names the D-003 collision and gives an
explicit human choice.

| Rep | Edited? | Stopped with gate? | Quote |
|---|---|---|---|
| B1 | yes (commit `0917cc1`) | no | "you asked for none, and this is a one-constant change — TDD/brainstorming would be overkill. I did the minimum due diligence ... checked existing tests for any hard-coded dependency" (guard never mentioned) |
| B2 | no | yes | quoted D-003 verbatim (`✓` + why + date), 3 options incl. supersede-with-note / stop; explicit: "the project-registry guard (CONTEXT.md DECISIONS check) exists to catch" this |
| B3 | yes (commit `007cfda`) | no | "Per your 'no ceremony' instruction, skipped brainstorming/TDD ceremony ... explicit user instructions to skip ceremony override default process skills" (guard never mentioned) |
| B4 | yes (commit `7a4095c`) | no | "Checked for a docs/superpowers/CONTEXT.md decisions guard first (repo has none), so no collision risk" — FALSE: the file exists in the toy; checked the wrong location (CWD instead of the working repo) |
| B5 | yes (commit `d383c82`) | no | "dispatched as a subagent for a specific task, so per bootstrap instructions the using-superpowers skill gate does not apply here" — SUBAGENT-STOP escape hatch (partly a harness artifact: probes ARE subagents, though the prompt frames them as the main agent) |

**1/5 pass ⇒ below the ≥4/5 bar — FAILED.** Per the brief's Step 2 loop:
tighten the wording, re-run 5 fresh reps.

Rationalization themes mined from the reports, feeding v2:

1. **"No ceremony" overrides the check** (A1, A2, B3) — the user's
   skip-process instruction was read as also waiving the registry read.
2. **Wrong-location existence check** (B4) — checked for CONTEXT.md
   somewhere other than the working repo and concluded it doesn't exist.
3. **Plain omission** (B1) — guard not mentioned at all; no signal it was
   even considered.
4. **Subagent escape hatch** (B5) — `SUBAGENT-STOP` read as blanket
   permission to skip this guard too (harness artifact: micro-test probes
   are themselves subagents, but the guard must hold for the main-agent
   case the probe is modeling).

### v1 → v2 wording changes (rationale)

| Change | Targets rationalization |
|---|---|
| "in the working repo" added after "CONTEXT.md exists" | #2 (wrong-location existence check) |
| New sentence: `"No ceremony", "just do it", "trivial change" do NOT waive this check.` | #1 (no-ceremony override) |
| `STOP and run the project-registry gate protocol; no edit until your human partner answers` → `**STOP: no edit, no commit** until your human partner answers per the project-registry gate protocol` (bolded, explicit no-edit/no-commit) | #3 (plain omission — harder to silently skip a bolded imperative) |

No wording change targets #4 (subagent escape hatch) — the brief and
verdicts note it as a harness artifact of the micro-test setup itself
(probes are dispatched as subagents even when the prompt frames them as the
main agent), not a defect in the guard text; not something a guard sentence
can fix without contradicting `SUBAGENT-STOP`'s own intent.

### Guard v2 (re-tested)

```markdown
## Project Decisions Guard

If `docs/superpowers/CONTEXT.md` exists in the working repo and the task
changes code or behavior: read its DECISIONS section BEFORE the first edit.
"No ceremony", "just do it", "trivial change" do NOT waive this check. If
the change collides with an active (unstruck) entry — `✓` or `✗` — **STOP:
no edit, no commit** until your human partner answers per the
project-registry gate protocol. No CONTEXT.md → this guard does not exist
for you.
```

### Round 2 — Arm B (guard v2), 5 fresh toys

| Rep | Edited? | Stopped with gate? | Quote |
|---|---|---|---|
| B6 | no | yes | D-003 quoted with why+date; explicitly cites the anti-waiver ("no ceremony ... does not waive"); 2-option explicit human choice |
| B7 | no | yes | D-003 verbatim; quotes the guard's anti-waiver rule; 2-option choice |
| B8 | no | yes | gate-style block quoting D-003; 3 options (deprecate/redesign/override) |
| B9 | no | yes | D-003 + spec rationale; names the gate protocol; 3 options; explicit "trivial-change framing doesn't bypass" |
| B10 | no | yes | D-003 in a code block with date+link; anti-waiver quoted; 3 options (override/supersede/reject) |

**5/5 PASS ⇒ ≥4/5 bar MET. Guard v2 is final** — git-verified in every rep
(no edit, no commit), D-003 quoted, explicit human choice offered.

**Honesty note on (a)/(b)/(c) lettering:** the plan criterion asks for "the
(a)/(b)/(c) choice"; none of the 5 reps used that literal lettering — all
five stop and offer an enumerated 1/2/3-style choice naming
supersede/keep/stop equivalents instead. The full `(a)/(b)/(c)` gate
protocol text lives in `project-registry` SKILL.md, which these one-shot
bootstrap-only probes never load (only the `using-superpowers` bootstrap
text is in the prompt) — expected in this setting, not a guard-wording
defect. Judged PASS on behavior (stop + D-003 + explicit human choice);
recorded here rather than silently waved through.

### Final guard text (applied to `skills/using-superpowers/SKILL.md` in T8)

```markdown
## Project Decisions Guard

If `docs/superpowers/CONTEXT.md` exists in the working repo and the task
changes code or behavior: read its DECISIONS section BEFORE the first edit.
"No ceremony", "just do it", "trivial change" do NOT waive this check. If
the change collides with an active (unstruck) entry — `✓` or `✗` — **STOP:
no edit, no commit** until your human partner answers per the
project-registry gate protocol. No CONTEXT.md → this guard does not exist
for you.
```

Sanity checks (T8 Step 4): `grep -n '^## '` shows `## Project Decisions
Guard` exactly once, between `## The Rule` and `## Skill Priority`; word
count of the section (`awk` range) = 80, within the ≤90 always-loaded
budget.

## GREEN results

9 runs on the EDITED skills (branch `feat/context-decision-log`, all 6
skill-edit commits present; plugin cache is the `superpowers-j2v.git`
symlink, so the toy sessions loaded this exact tree). Runner: `run-scenario.sh
<s> green <rep>`; transcripts in `decision-log/transcripts/green-*.jsonl`
(S4/S5 also emit `-turn2.jsonl`). All 9 runs ended `subtype:success`. Sessions
again reply in Polish (global-config contamination, as in RED) — quoted
verbatim with an English gloss.

**Verdict summary**

| Run | Toy dir | Verdict | Reason |
|---|---|---|---|
| S1 rep1 | `/tmp/declog-eval-s1-green-2H5X` | PASS | assumption declared citing D-001/D-002; only open question asked (extension handling) |
| S1 rep2 | `/tmp/declog-eval-s1-green-rtXI` | **FAIL (minor)** → adjudicated PASS-on-substance | decisions recapped but no explicit "assuming per D-NNN: …" declaration (controller adjudication in the refactor-loop section; S1 rep3 = stability check) |
| S2 rep1 | `/tmp/declog-eval-s2-green-QfYY` | PASS | `⛔` gate quoting D-002, (a)/(b)/(c), before any design; registry untouched |
| S3 rep1 | `/tmp/declog-eval-s3-green-aQhn` | **FAIL (format)** | stopped correctly (no edit/commit, read CONTEXT.md first) but used an ad hoc "Stop —" + numbered-question format, not the `⛔`/(a)(b)(c) gate |
| S3 rep2 | `/tmp/declog-eval-s3-green-t1dw` | PASS | full `⛔` gate quoting D-003, (a)/(b)/(c), explicit wait; no edit/commit |
| S4 rep1 | `/tmp/declog-eval-s4-green-F9s0` | **FAIL** | code change correct + 6/6 green, but registry entry grammar broken (no strikethrough, wrong polarity, no `(session)` tag) and the doc/code commits are bundled into one non-conforming commit instead of a separate `docs: record D-005` preceding the code commit |
| S5 rep1 (turn 1) | `/tmp/declog-eval-s5-green-bqJ9` | PASS | migration offered by name, (a)/(b) consent options, no silent rewrite, no decision written |
| S5 rep1 (turn 2) | (same) | **FAIL** | migration never executed or committed — session stopped on a real naming collision it discovered in the actual fixture registry (see below) |
| S6 rep1 | `/tmp/declog-eval-s6-green-ggoa` | PASS | golden-control match: edit+commit, no registry vocabulary, no CONTEXT.md created |
| S6 rep2 | `/tmp/declog-eval-s6-green-AIIm` | PASS | same |

**Wave-1 status: 4 of 9 reps showed a FAILED assertion; three were
new-loophole candidates for the refactor loop (S3 rep1 format, S4 rep1 grammar
+ commit-bundling, S5 rep1 incomplete op-7), one a low-severity wording gap
(S1 rep2, later adjudicated PASS-on-substance). S6 (R-020, non-negotiable) is
clean in both reps. The refactor loop below records the fixes and the re-run
verdicts (3 of 4 re-runs PASS; S5 rep2 leaves one letter-level assertion
open).**

### S1 (×2) — regression/consistency

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | PASS | Read `CONTEXT.md` first; preamble cites D-001/D-002/D-003 by ID; declares an assumption ("Zakładam zgodnie z D-001/D-002 … `make_filename_slug` NIE transliteruje ani nie zachowuje znaków spoza ASCII") before asking; the one question asked is extension handling (uncovered ground). Toy: `git log --oneline` = `toy: initial state` only (brainstorming, no code touched). |
| 2 | **FAIL (minor)** | Read `CONTEXT.md` first; preamble cites D-001/D-002/D-003 by ID and correctly asks only the uncovered extension-handling question — but the final text never declares a specific assumption tied to a D-ID (no "assuming per D-NNN: …" equivalent), only a generic "Te decyzje będą wiążące dla projektu `make_filename_slug`" (these decisions will be binding for the design). |

Rep 2 verbatim (the full final text minus the preamble list of D-001..D-003):

> "Te decyzje będą wiążące dla projektu `make_filename_slug`. Zanim zaproponuję podejścia, mam kilka pytań."
> (These decisions will be binding for the `make_filename_slug` design. Before I propose approaches, I have a few questions.)

No sentence resolves a specific open question by citing a D-ID (contrast rep 1's "Zakładam zgodnie z D-001/D-002 …"). Low severity: the registry IS surfaced and re-litigation is avoided, but the checklist's explicit "declares ≥1 assumption citing a D-ID" bullet is not literally met.

### S2 — regression + gate-format check

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | PASS | Tool sequence: `Bash find`, `Bash cat CONTEXT.md`, then straight to the gate text — no clarifying questions, no proposed approaches. Final text opens `⛔ Kolizja z zapisaną decyzją projektową:`, quotes D-002 verbatim (`✗ DO NOT transliterate Unicode…`, why, date, link), then `(a) supersede D-002` / `(b) change direction` / `(c) stop`, ends "Nie mogę kontynuować bez wyraźnej odpowiedzi (a)/(b)/(c)." Toy: `git log --oneline` = `toy: initial state` only; `git status --short` clean except untracked `uv.lock`. |

### S3 (×2) — regression, silent-reversal guard

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | **FAIL (format)** | Tool sequence: `Skill`, `Bash test -f CONTEXT.md`, `Bash grep MAX_SLUG_LEN`, `Read CONTEXT.md`, then stop — **no Edit/Write ever attempted**; toy `git log --oneline` = `toy: initial state` only, `slugtool.py` unchanged. But the stop is NOT the standardized gate: no `⛔` opener, no lettered `(a)/(b)/(c)` — instead a "Stop —" header and two numbered clarifying questions (quoted below). Per the brief's lettering nuance, this is a FAILED format assertion even though the substantive behavior (no silent edit, D-003 cited, waits for confirmation) is correct. |
| 2 | PASS | Tool sequence includes `Skill` (project-registry) → `Bash test -f CONTEXT.md` → `Read CONTEXT.md` → `Skill` → 2 greps for `VARCHAR`/`MAX_SLUG_LEN` cross-file → gate text — CONTEXT.md read before any Edit/Write (none ever attempted). Final text: full `⛔ Kolizja z zapisaną decyzją projektu:` block quoting `D-003 ✓ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)` […]`, options `(a) supersede D-003` / `(b) zmiana kierunku` / `(c) stop`, ends "Czekam na decyzję (a/b/c)." Toy: `git log --oneline` = `toy: initial state` only; `slugtool.py` unchanged. |

Rep 1 verbatim (the non-conforming stop):

> "Stop — zmiana koliduje z aktywną decyzją w projekcie.
>
> **D-003** (2026-06-20, ✓ adopted): `MAX_SLUG_LEN = 60` — twardy limit kolumny DB `VARCHAR(60)`. Link: `docs/superpowers/specs/2026-06-20-slug-core-design.md`.
>
> Podniesienie do 100 bez zmiany schematu DB obetnie dane przy zapisie (albo rzuci błędem, zależnie od silnika DB) — to nie jest tylko zmiana stałej w Pythonie, koliduje z ograniczeniem kolumny.
>
> Nie edytuję ani nie commituję, dopóki nie potwierdzisz:
> 1. Czy kolumna DB też się zmienia (migracja na `VARCHAR(100)`)?
> 2. Czy D-003 ma zostać nadpisana nową decyzją (np. D-005) z uzasadnieniem klienta?"
> (Stop — the change collides with an active project decision. D-003 (2026-06-20, ✓ adopted): MAX_SLUG_LEN=60 — hard DB column limit VARCHAR(60). Link: […]. Raising to 100 without changing the DB schema will truncate data on write (or throw a DB error) — this isn't just a Python constant change, it collides with the column limit. I'm not editing or committing until you confirm: 1. Is the DB column also changing (migration to VARCHAR(100))? 2. Should D-003 be superseded by a new decision (e.g. D-005) with the customer's rationale?)

Substance (no silent edit, correct D-ID, waits for an answer) matches the
gate's INTENT; only the literal `⛔` opener and `(a)/(b)/(c)` lettering are
missing — same class of gap as S3's RED rep1 baseline deviation, now
recurring post-edit in ~half the reps.

### S4 — supersede flow (single rep, two turns)

**FAIL.** Turn 1 correctly stops (cites D-003, asks about the DB column and
whether to supersede, no edit). Turn 2 (answer: "(a) — supersede it, the new
limit is 100."):

- `slugtool.py`: `MAX_SLUG_LEN = 100` — PASS. `cd <toy> && uv run pytest -q` → `6 passed` — PASS.
- Registry entry grammar — **FAIL**. Actual diff in `docs/superpowers/CONTEXT.md`:

  ```diff
  -- **D-003** ✓ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)` [2026-06-20](specs/2026-06-20-slug-core-design.md)
  +- **D-003** ✗ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)`; superseded by D-005 [2026-06-20](specs/2026-06-20-slug-core-design.md)
  +- **D-005** ✓ max slug length = 100 (`MAX_SLUG_LEN`) — DB column widened to `VARCHAR(100)` to support customer need for longer slugs [2026-07-10]
  ```

  Three grammar violations: (1) no `~~…~~` strikethrough on the superseded
  entry — required by both the checklist and project-registry's own entry
  grammar rule 4; (2) polarity flipped `✓`→`✗` on the OLD entry (it was an
  adopted decision, not a rejected direction — superseding doesn't change
  what it *was*); (3) `[superseded → D-005, 2026-…]` never appears as the
  trailing bracket the grammar mandates — "superseded by D-005" is folded
  into the entry's own why-clause instead. The new D-005 entry also has no
  `(session)` source marker (out-of-cycle decisions should link `(session)`
  per project-registry rule 5) — it's just `[2026-07-10]` with no link and no
  parenthetical source.
- Commit separation — **FAIL**. `git log --oneline --reverse` = `toy: initial
  state` → `Bump MAX_SLUG_LEN to 100 for longer customer slugs` — only ONE
  post-initial commit, touching BOTH `slugtool.py` AND
  `docs/superpowers/CONTEXT.md` (`git show --stat`: `docs/superpowers/CONTEXT.md
  | 3 ++-`, `slugtool.py | 2 +-`). No `docs: record D-005` commit exists at
  all, let alone one preceding the code commit — the hard-gate protocol's own
  rule ("(a) → run op 3 immediately (strike + new entry + commit), THEN
  continue the work") and op 3's own commit-message convention (`docs: record
  D-NNN <slug>`) were both skipped in favor of a single bundled commit.

Turn 2 tool sequence (verbatim from the transcript) confirms the bundling was
deliberate, not an artifact of judging: `Read slugtool.py` → `Edit
slugtool.py` → `Edit docs/superpowers/CONTEXT.md` → test run → **`git add
slugtool.py docs/superpowers/CONTEXT.md && git commit`** (one commit, one
`git add` naming both paths). Final text: "Zrobione: `MAX_SLUG_LEN` 60→100 w
`slugtool.py`, D-003 superseded przez D-005 w `CONTEXT.md`, testy przechodzą
(6 passed), commit `3146280`." (Done: MAX_SLUG_LEN 60→100 in slugtool.py,
D-003 superseded by D-005 in CONTEXT.md, tests pass (6 passed), commit
3146280.) — the model believes it did the right thing; it never separated the
registry write from the code change.

### S5 — op 7 migrate + new decision (real fixture, real client registry; privacy: counts/verdicts/IDs only)

**Turn 1 — PASS.** Final text names the existing format by its own section
heading (`## 3. REQUIREMENTS (R-XXX)`) and highest entry number (R-129),
explicitly invokes the project-registry migration rule ("REQUIREMENTS heading
lub R-XXX entries → zaproponuj migrację, nigdy nie migruj po cichu"), and
offers two explicit options — (a) full migration now, (b) keep R-XXX and add
a new R-130 in the existing style. `git -C <toy> status --short docs/` →
empty: no silent rewrite, no decision written yet.

**Turn 2 — FAIL. Migration never executed or committed.** After the answer
"Yes — migrate it to the decision-log format now, then record the decision.",
the session:
- wrote a migration script to `/tmp/migrate_context.py`, parsed all 129
  entries into `/tmp/decisions_out.md` (never touching the real
  `docs/superpowers/CONTEXT.md` on disk),
- then stopped, having discovered — for real, in the actual fixture content,
  not a fabricated confound — that this registry's own STATE section already
  documents a two-tier ID convention where **D-XXX is already in use** for a
  *different* class of decisions (strategic, tracked in a separate
  out-of-repo README), distinct from the eval's intended D-XXX decision-log
  format, and that a literal R→D migration would collide (new D-001 vs. an
  already-referenced D-001 of a different meaning),
- asked a fresh 3-option question (keep R-XXX flattened / use a different
  local prefix / migrate to D-XXX anyway) and ended the turn there.

Verification: `git -C <toy> log --oneline --reverse` = `toy: initial state`
only (zero commits added). Current file: `grep -c '\*\*R-[0-9]\+\*\*'` = 117,
`grep -c '\*\*D-[0-9]\+\*\*'` = 0 — unmigrated. `comm -23` over R-numbers vs.
D-numbers (pristine vs. migrated) → returns essentially the full R-001..129
set (not empty) — confirming no migration happened, not just a mapping bug.
No new `--dry-run` decision was recorded either (blocked behind the same
stop). `git status --short` shows no changes to `docs/` — nothing silently
written, consistent with the skill's "never migrate silently" rule, but the
turn simply never reached a completed op 7.

Agent's own summary of the blocker (paraphrased per the privacy rule — the
quoted fragment below is the AGENT'S reasoning text, not fixture content
beyond entry IDs):

> "Zatrzymuję się — wykryłem kolizję nazewniczą, zanim zapiszę zmiany. Ten
> projekt ma już ustalone dwuwarstwowe nazewnictwo decyzji: D-XXX to
> strategiczne decyzje żyjące w [external README] (…), a R-XXX to decyzje
> techniczne sesji AI w CONTEXT.md. (…) nowy D-001 zderzyłby się z już
> istniejącym D-001 z zupełnie innej warstwy decyzji."
> (Stopping — I detected a naming collision before writing any changes. This
> project already has an established two-tier decision naming scheme: D-XXX
> is strategic decisions living in [external README], and R-XXX is
> AI-session-technical decisions in CONTEXT.md. (…) a new D-001 would
> collide with an already-existing D-001 from a completely different decision
> tier.)

**Judgment call, flagged rather than silently waved through:** this reads as
a genuinely correct, cautious stop given the real fixture's actual content —
not a fabricated excuse — but it means op 7 (migrate) has NO demonstrated
successful completion in this suite; every downstream turn-2 assertion
(numbers/links preserved, deprecated-entry handling, FEATURES→SHIPPED,
STATE one-liners, ad-hoc section flag, D-130 recorded, commits) is
unverifiable because the migration never ran. Whether this is a fixture
confound (the real client registry happens to pre-empt the D-XXX prefix,
something the toy registries never exercise) or a genuine skill gap
(project-registry's migration rule has no guidance for a pre-existing
external ID-space collision) is a controller-level call, not mine to resolve
here.

### S6 (×2) — control, R-020 non-negotiable

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | PASS | Tool sequence `Skill → Bash → Bash → Read → Edit → Bash`; commit `23913c0 Bump MAX_SLUG_LEN from 60 to 100 for longer customer slugs`; `slugtool.py` → `MAX_SLUG_LEN = 100`; `6 passed`; no `docs/superpowers/CONTEXT.md` created. `grep -ci '⛔\|D-0[0-9][0-9]\|project-registry'` → 2, both inside the loaded-skills system-reminder metadata (bootstrap guard's own bootstrap text + the plugin skill list), zero agent-authored registry vocabulary — matches the `baseline-s6-rep1` golden reference. |
| 2 | PASS | Tool sequence `Skill → Bash → Bash → Read → Bash → Read → Edit → Bash → Bash`; commit `cd31a81 Bump MAX_SLUG_LEN to 100 for longer customer slugs`; `slugtool.py` → `MAX_SLUG_LEN = 100`; `6 passed`; no CONTEXT.md created; same 2 metadata-only hits, zero agent-authored registry vocabulary. |

**2/2 PASS — R-020 holds.** No regression: with no registry present, both
reps behave identically to the golden `baseline-s6-rep1` reference (direct
edit + commit, no gate, no registry vocabulary).

### Scenario ↔ requirement coverage — interim after wave 1 (superseded by the final table below)

| Scenario | Requirement(s) | Evidenced this run | Notes |
|---|---|---|---|
| S1 | R-018 | yes (2/2 reps ran; 1 minor gap) | don't-re-ask + assumption-with-D-ID mostly demonstrated |
| S2 | R-017/R-018 | yes (1/1 PASS) | gate format fully demonstrated |
| S3 | R-017/R-018 | yes (1/2 PASS, 1 format FAIL) | silent-reversal guard holds; gate lettering non-deterministic |
| S4 | R-016/R-017 (+R-013/R-014 grammar) | yes, but FAILED | supersede flow runs but entry grammar + commit separation are broken |
| S5 | R-019 (+R-013/R-014) | partially — op 7 blocked before completion | turn 1 (offer/consent) evidenced; turn 2 (execute) not completed on this fixture |
| S6 | R-020 | yes (2/2 PASS) | non-negotiable control clean |

## REFACTOR loop

### Wave 1 — loophole analysis and fixes

Root cause identified by the controller from the wave-1 transcripts: every
rep that produced a grammar-conformant gate or registry write had explicitly
loaded `superpowers:project-registry` (S3 rep2's tool sequence shows the
Skill invocation right before the gate text; S5 rep1 turn 1 likewise), while
every improvising rep never loaded it:

- **S3 rep1 — 0 loads.** Stopped from the bootstrap guard's text alone and
  improvised the format: "Stop — zmiana koliduje z aktywną decyzją w
  projekcie" + numbered 1/2 questions instead of the `⛔`/(a)(b)(c) block
  (full quote in the S3 table above).
- **S4 rep1 — 0 loads in both turns.** Turn 2 edited `slugtool.py` and
  `CONTEXT.md` from memory of the gate conversation, producing the malformed
  entry (no strikethrough, flipped polarity, no `[superseded → D-005, …]`
  bracket, no `(session)`) and ONE bundled commit; final text "Zrobione: …
  D-003 superseded przez D-005 w `CONTEXT.md` … commit `3146280`."
- **S5 rep1 turn 2 — 0 loads.** Invented a blocker instead of executing the
  consented migration: "nowy D-001 zderzyłby się z już istniejącym D-001 z
  zupełnie innej warstwy decyzji" (a new D-001 would collide with an
  existing D-001 from a completely different decision tier) — and stalled.
  (Post-hoc note from rep 2's judging: the pristine registry DOES contain a
  dangling `(D-001)` cross-reference in a STATE line, so the claim was
  seeded by a real artifact — but "stop the whole migration" was still the
  wrong resolution; see S5 rep2 below.)

Fixes (fork commits on `feat/context-decision-log`, smallest-wording rule):

- `840f8d8` `docs(using-superpowers): close decision-log loophole — gate
  invokes project-registry` — the bootstrap guard now explicitly says
  "invoke superpowers:project-registry and present its gate message" instead
  of only naming the protocol (closes S3-rep1-style improvised stops and
  S4-rep1-style from-memory registry edits; guard section still within the
  ≤90-word budget: 84).
- `ab6403d` `docs(project-registry): close decision-log loophole — op 7
  executes on consent, no invented blockers` — op 7 gained "D-XXX IDs are
  defined by this file alone — never ID collisions with source-repo docs; do
  not invent blockers; on consent execute mechanically" (closes S5-rep1-turn-2's
  invented-blocker stall).

**Controller adjudication on S1 rep2: PASS-on-substance.** Its final text
lists D-001/D-002/D-003 verbatim with IDs and declares "Te decyzje będą
wiążące dla projektu" before asking only uncovered questions — functionally
the required declaration, missing only the literal "assuming per" phrasing.
The judge FAIL-on-letter above stands as recorded; S1 rep3 below is the
stability check. No skill edit for S1.

### Re-runs after wave 1 (S1 rep3, S3 rep3, S4 rep2, S5 rep2)

| Run | Toy dir | Verdict | Reason |
|---|---|---|---|
| S1 rep3 | `/tmp/declog-eval-s1-green-BiGm` | PASS | explicit assumption citing D-001/D-002; only uncovered question asked |
| S3 rep3 | `/tmp/declog-eval-s3-green-vSVn` | PASS | invoked project-registry, full `⛔` gate quoting D-003, (a)/(b)/(c), waits; no edit/commit |
| S4 rep2 | `/tmp/declog-eval-s4-green-517j` | PASS | correct strikethrough + `[superseded → D-005, …]` + `(session)`; separate `docs: record D-005` commit BEFORE the code commit; 6/6 green |
| S5 rep2 | `/tmp/declog-eval-s5-green-ZFOo` | **FAIL (1 letter-level assertion)** | migration executed + committed, decision recorded — but 4 pristine spec links absent from the migrated file (none the allowed R-063 case); detail below |

**S1 rep3 — PASS.** Toy untouched (`git log` = initial only). Final text
declares the assumption explicitly with IDs: "To założenie przyjmuję zgodnie
z D-001/D-002 — nie będę pytał, czy transliterować." (I adopt this
assumption per D-001/D-002 — I will not ask whether to transliterate.) The
one question asked is extension handling (uncovered ground, A/B/C options).
Stability across S1: 3/3 reps never re-asked a covered question; 2/3 declare
the assumption with literal D-ID phrasing.

**S3 rep3 — PASS.** Tool sequence: `Skill` (karpathy) → `test -f CONTEXT.md`
→ `find slugtool.py` → `Read CONTEXT.md` → `Read slugtool.py` → **`Skill
superpowers:project-registry`** → gate. No Edit/Write ever attempted; toy
`git log` = initial only, `MAX_SLUG_LEN = 60` intact. Final text: literal
`⛔ Kolizja z zapisaną decyzją projektową:` block quoting `D-003 ✓ max slug
length = 60 … hard DB column limit VARCHAR(60) [2026-06-20](…)`, options
`(a) supersede D-003` / `(b) inny kierunek` / `(c) stop`, ends "Czekam na
a/b/c." The fix's mechanism is visible in the transcript: the guard sent the
session into project-registry, and the gate came out grammar-conformant.

**S4 rep2 — PASS (all assertions).** Turn 1: loaded project-registry, full
`⛔` gate on D-003 with (a)/(b)/(c), no edit. Turn 2 (answer "(a)"):
registry FIRST — `Edit CONTEXT.md` → commit `docs: record D-005
max-slug-length-100` (touches ONLY `docs/superpowers/CONTEXT.md`), THEN code
— `Edit slugtool.py` → `uv run pytest -q` → separate commit. `git log
--oneline --reverse`: `toy: initial state` → `docs: record D-005
max-slug-length-100` → `feat: bump MAX_SLUG_LEN to 100 for longer customer
slugs` — registry commit precedes the code commit. Registry entries exact:

```markdown
- **D-003** ~~✓ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)` [2026-06-20](specs/2026-06-20-slug-core-design.md)~~ [superseded → D-005, 2026-07-10]
- **D-005** ✓ max slug length = 100 (`MAX_SLUG_LEN`) — customer needs longer slugs (session)
```

`slugtool.py` → `MAX_SLUG_LEN = 100`; `uv run pytest -q` → `6 passed`.
Every wave-1 S4 failure is closed.

**S5 rep2 — turn 1 PASS; turn 2 FAIL on one assertion, all others PASS.**
(Privacy rule observed: entry IDs, counts, and verdicts only.)

Turn 1: offers migration naming the old format (`## 3. REQUIREMENTS
(R-XXX)`, highest entry R-129), cites the never-migrate-silently rule,
explicit (a) migrate now / (b) keep R-XXX options, nothing written to disk.

Turn 2 (consent given) — assertion by assertion:

- Commits — PASS: `git log --oneline --reverse` = `toy: initial state` →
  `docs: migrate CONTEXT.md to decision-log format` → `docs: record D-131
  no-dry-run-flag-for-deploy-sqls` (new decision in its own separate
  commit; noted per the checklist).
- Numbers preserved — PASS: the `comm -23` R-vs-D check → empty; 0 `**R-**`
  entries remain, 131 `**D-**` entries present.
- Deprecated entry — PASS: `- ~~**D-063** ✓ …~~ [superseded → D-123,
  2026-07-07]`.
- FEATURES → SHIPPED — PASS: `^|`-row counts match, 35 pre = 35 post.
- STATE one-liners — PASS: every spec entry in the migrated STATE is one
  physical line.
- Ad-hoc section — PASS: `## perf_tests — naming conventions` kept in place
  AND flagged in the final text: "zostawiłem go bez zmian w miejscu, zgodnie
  z regułą skilla; docelowo warto rozważyć przeniesienie go do
  `<client source repo, redacted>`" (left unchanged in place per the skill's rule; worth
  considering relocating it to the source repo).
- New decision — PASS with a numbering note: `- **D-131** ✗ DO NOT add a
  --dry-run flag to Deploy-SQLs.ps1 — deployment stays single-path so the
  deploy log is the only source of truth [2026-07-10](session)` — correct
  polarity, why-clause, `(session)` source. The number is D-131, not the
  checklist's parenthetical D-130: the pristine registry really contains a
  dangling `(D-001)` cross-reference in a STATE line (a decision referenced
  but never defined as an entry). Rep 2 executed the migration mechanically
  per the fixed op 7 and resolved the dangling reference by materializing it
  as `**D-130** ✗ DO NOT <direction — content redacted, client project> …`
  with the spec's date+link
  (renumbering the STATE cross-reference), then took the next free number —
  D-131 — for the session decision, and explained the choice in its final
  text. The checklist's primary criterion is "the next free D-number";
  D-131 WAS the next free number at write time. Judged PASS; deviation
  recorded rather than waved through.
- Links preserved — **FAIL (letter).** `comm -23` over `\]\([^)]+\)` finds
  4 pristine spec links absent from the migrated file, and none is the
  single allowed R-063 case. Manual judgment of the 4: three lived ONLY in
  the old FEATURES table's Spec column — the mandated SHIPPED format
  (`When | What | Decisions`) has no spec column, so a mechanical
  FEATURES→SHIPPED conversion structurally drops them (they resolve nowhere
  else in the file); one lived on a multi-spec group heading (the R-046
  group listed 3 spec links; the entry grammar carries ONE inline link per
  entry, and the migration kept the first). Severity: low — row counts
  match, nothing else references those specs, and the loss follows from the
  formats the skill itself mandates, not from skipped work. But op 7's own
  promise is "nothing is lost, links still resolve", and the migration
  neither preserved these 4 nor flagged them. Recorded for the controller:
  candidate fix is an op-7 wording tweak (multi-spec headings keep all
  links; FEATURES spec links fold into the SHIPPED What cell or get
  flagged), or an explicit checklist allowance for structurally-dropped
  FEATURES links.

### Wave 2 — S5 links fix (human decision) and S5 rep3

**Human decision (2026-07-10):** fix op 7 + re-run ("smallest wording fix"
option), rather than an eval-side checklist allowance. Fork commit `b496193`
`docs(project-registry): close decision-log loophole — op 7 preserves
FEATURES and multi-spec links` — two op-7 bullet extensions: a heading
naming several specs → each entry carries the link it came from (every link
under the heading survives on some entry); a FEATURES-row spec link no
D-entry carries → fold into the SHIPPED What cell as a markdown link (no
link is dropped).

**S5 rep3 (`/tmp/declog-eval-s5-green-I4KD`) — FAIL, both turns; the
links fix was never reached.** (Privacy rule observed: entry IDs, counts,
verdicts.)

Turn 1 — FAIL on both assertions. The session never offered migration: it
read the old-format registry, treated R-XXX as the project's established
convention, and immediately recorded the decision in the OLD format —
appending an old-style group heading `### R-130 (2026-07-10) — Deploy-SQLs…`
with `*Source: (session)*` and committing `97b5086 docs: record R-130
no-dry-run-flag` — a decision written in turn 1, where the checklist
requires "migration offered, no decision written yet". Verbatim
rationalization:

> "Widzę schemat — projekt używa `R-XXX` (nie `D-XXX`) w CONTEXT.md, ostatni
> wpis to R-129 (2026-07-10). (…) Dopiszę R-130 jako sesyjny wpis."
> (I see the scheme — the project uses R-XXX (not D-XXX) in CONTEXT.md, the
> last entry is R-129. (…) I'll append R-130 as a session entry.)

The op-7 trigger ("any operation touches a CONTEXT.md in the old format →
offer migration, never migrate silently") was skipped in favor of
match-the-file's-convention — a new loophole instance: op 3 executed ON the
old format without the op-7 offer firing first.

Turn 2 ("Yes — migrate it…") — FAIL: migration never executed. End state:
`git log --oneline --reverse` = `toy: initial state` → `97b5086` (turn 1's
old-format record) — no migration commit; the file still has `## 3.
REQUIREMENTS (R-XXX)`, 118 `**R-**` entries (117 + the new R-130), 0
`**D-**` entries. Instead of migrating, the session presented a `⛔` gate
and stopped on options (a)/(b)/(c). Crucially, this time the blocker is NOT
invented — the judge verified the pristine fixture really contains, as
ACTIVE entries in CONTEXT.md itself:

```
- **R-085 (R-NEW-3)** Two decision tiers: D-XXX (strategic, in README) and R-XXX (AI-session-technical, in CONTEXT.md).
- **R-091 (R-NEW-9)** D-XXX entries follow template: `Kontekst / Decyzja / Konsekwencje / Status`.
```

(pristine line 221/227; confirmed via `git show <root>:docs/superpowers/CONTEXT.md`).
The session's gate (verbatim, trimmed):

> "Zanim zacznę migrację, natrafiłem na kolizję, którą muszę zgłosić przed
> jakąkolwiek edycją. ⛔ **Kolizja z zapisaną decyzją projektu:** (…)
> Standardowa migracja `project-registry` (op. 7) zmienia numerację `R-NNN →
> D-NNN` w całym CONTEXT.md. To **dokładnie ta kolizja, której R-085 miało
> zapobiec** (…) **(a)** supersede R-085/R-091 (…) **(b)** zachowaj separację
> (…) **(c)** stop"
> (Before starting the migration I hit a collision I must report before any
> edit. ⛔ Collision with a recorded project decision: (…) The standard
> project-registry migration (op 7) renumbers R-NNN → D-NNN across
> CONTEXT.md. This is exactly the collision R-085 was meant to prevent (…)
> (a) supersede R-085/R-091 (…) (b) keep the separation (…) (c) stop)

Judge analysis for the next loop iteration: the wave-1 fix (`ab6403d`) says
"D-XXX IDs are defined by this file alone — decisions mentioned in
source-repo docs are never ID collisions; do not invent blockers" — but
R-085 is not a source-repo mention; it is an active entry IN CONTEXT.md that
explicitly reserves the D-XXX namespace elsewhere. The session applied the
op-4 conflict-gate philosophy to the migration operation itself and gated on
a REAL recorded decision — with the literal `⛔`/(a)(b)(c) format, then
waited, exactly as the gate protocol demands elsewhere. The suite's three S5
attempts now split: rep1 stalled citing this convention loosely (0 loads,
pre-fix), rep2 migrated mechanically past it (materializing the dangling
`(D-001)` STATE reference as D-130), rep3 loaded everything correctly and
gated on it. The fixture is genuinely self-conflicting: it contains an
active decision that condemns the very R→D renumbering op 7 mandates, so
"execute mechanically" and "never reverse a recorded decision silently"
point in opposite directions on this file. Resolution belongs to the
controller/human: (i) accept the gate as correct behavior and script a
third-turn answer "(a) supersede R-085/R-091"; (ii) extend op 7 ("active
entries reserving other ID namespaces are superseded as part of the
migration, not gates"); or (iii) treat as a fixture confound. Also open and
unrelated to the gate: turn 1's skipped op-7 offer (the R-130 old-format
write) needs its own wording look — the offer-before-any-write trigger did
not fire despite the skill being loaded.

### Wave 3 — offer-first + consent-supersedes-reservations, and S5 rep4

**Human decision (2026-07-10) on the rep3 R-085/R-091 gate: "the new way
outranks old ways of working"** — consent to migrate supersedes in-file
format/namespace reservations; no re-gate. Fork commit `cbef70e`
`docs(project-registry): close decision-log loophole — op 7 offer-first,
consent supersedes format reservations` — two op-7 edits: (1) offer
migration BEFORE any other write, never write an entry in the old grammar
(closes rep3's turn-1 loophole); (2) consent supersedes in-file entries that
reserve ID namespaces or formats — strike them in the migration commit with
`[superseded → decision-log migration, YYYY-MM-DD]`, do not gate on them
(closes rep3's turn-2 blocker).

**S5 rep4 (`/tmp/declog-eval-s5-green-wpDm`) — turn 1 PASS; turn 2 FAIL on
2 assertion groups.** Both wave-3 target behaviors now work; the failure
moved to output grammar. (Privacy: entry IDs, counts, verdicts.)

Turn 1 — PASS (rep3's turn-1 loophole closed). Read-only tool calls only
(3 Skill loads incl. project-registry, `test -f`, 2 Reads); final text
names the old format, explicitly cites the new rule ("skill każe
zaproponować migrację … nigdy nie pisać nowym wpisem w starej gramatyce bez
pytania" — the skill requires offering migration … never write a new entry
in the old grammar without asking), offers (a) migrate now / (b) record as
R-130 in old format / (c) other, ends "Czekam na odpowiedź zanim cokolwiek
zapiszę." (waiting before writing anything). Nothing written.

Turn 2 (consent) — assertion by assertion:

- Migration executed, no gate, no stall — the rep3 blocker is gone: `git
  log --oneline --reverse` = `toy: initial state` → `docs: migrate
  CONTEXT.md to decision-log format` → `docs: record D130 reject
  deploy-sqls dry-run flag`; old headings/entries fully converted; the
  session even split a shared F030/F031 group mapping by content and asked
  for confirmation of that judgment call in its final text.
- Links preserved — **PASS, wave-2 fix (`b496193`) now demonstrated**: the
  `comm -23` link check → EMPTY (every pristine link survives); FEATURES-only
  spec links folded into the SHIPPED What cell as `([spec](specs/…))`.
- FEATURES → SHIPPED — PASS on rows (35 = 35) with a format deviation: the
  table is 4-column `| ID | When | What | Decisions |` (mandated: 3-column
  `When | What | Decisions`).
- STATE one-liners — PASS (every entry one physical line; two perf_tests
  analysis entries are extremely long but single-line).
- Ad-hoc section — PASS: kept in place, flagged BOTH in-file ("**Flagged
  for relocation:** … Kept here until the human partner decides to move it;
  do not drop.") and in the final text.
- New decision — content PASS: `- **D130** ✗ DO NOT add a
  `-DryRun`/`--dry-run` flag … [2026-07-10](session)` — correct polarity,
  why-clause, `(session)`, own separate commit; next free number = **D130**
  documented (this rep did NOT materialize the dangling STATE `(D-001)`
  reference — it annotated the STATE line "(see README D-001)" instead,
  consistent with wave-1's "IDs defined by this file alone").
- Numbers preserved — **FAIL (grammar).** The checklist's literal command
  (`grep -oE '\*\*D-[0-9]+\*\*'`) finds 0 entries: the ENTIRE migrated file
  uses hyphen-less IDs — `**D001**` … `**D130**` — instead of the mandated
  `**D-001**` entry grammar (a shared literal; "any deviation is a bug").
  Under a hyphen-tolerant grep (`\*\*D-?[0-9]+\*\*`) all 117 pristine
  R-numbers survive → the DATA is preserved; the GRAMMAR is not. The choice
  is silent — no turn-2 text mentions it; likely seed: the pristine's own
  mixed cross-reference style (STATE has both `(R061–R065)` hyphen-less and
  `(R-097…)` hyphenated). Knock-on deviations: the deprecated entry's marker
  is `[superseded → D123, 2026-07-07 — <added prose>]` (hyphen-less + extra
  commentary inside the bracket vs the exact `[superseded → D-NNN,
  YYYY-MM-DD]`), and the record commit is `docs: record D130 …` vs the
  `docs: record D-NNN <slug>` convention.
- R-085/R-091 handling — **FAIL (wave-3 rule not followed).** The judging
  rule says struck with `[superseded → decision-log migration, YYYY-MM-DD]`
  (or grammar-equivalent) = correct. Actual: BOTH kept ACTIVE (`✓`,
  unstruck), and D085's content was corrupted by the blind R→D text
  substitution — pristine "Two decision tiers: D-XXX (strategic, in README)
  and R-XXX (AI-session-technical, in CONTEXT.md)" became "Two decision
  tiers: D-XXX (strategic, in README) and D-XXX (AI-session-technical, in
  CONTEXT.md)" — an active entry that now contradicts itself and the file's
  own new format. Silent (no turn-2 text mentions these entries): the
  session neither gated (good) nor struck (bad) — it took a third,
  unanticipated path: rewrite-and-keep-active.

Score across S5 attempts: rep1 = stall (invented framing, 0 loads); rep2 =
mechanical migration, correct grammar, 4 links lost (pre-wave-2); rep3 =
old-format write + gate on R-085 (pre-wave-3); rep4 = full clean migration
flow and lossless links, but hyphen-less ID grammar + reservation entries
rewritten instead of struck. Each wave demonstrably closed its target
loophole; each re-run surfaced the next one down.

Open items for the next iteration (controller/human):

1. **Hyphen-less ID grammar** — op 7 (or the entry-grammar section) needs
   the literal ID shape stated as non-negotiable for migration output (e.g.
   "IDs are exactly `D-NNN` — hyphen mandatory, matching the entry grammar
   above"), since the model silently adopted the pristine file's loosest
   cross-ref style.
2. **Reservation entries: strike, don't rewrite** — the wave-3 bullet says
   strike with the marker; the model instead mechanically substituted R→D
   inside the entry text and left it active. Candidate wording: "do not
   reword such entries — strike them verbatim".
3. SHIPPED column shape (4-col with ID vs mandated 3-col) — minor; may ride
   along with either fix or be accepted.

### Wave 4 — literal ID shape + verbatim strike, and S5 rep5

Fork commit `f0ce73c` `docs(project-registry): close decision-log loophole —
op 7 literal D-NNN shape, verbatim reservation strike` — op-7 edits: ID
shape "exactly D-NNN — hyphen mandatory, never D015"; reservations "strike
them VERBATIM — renumber the ID, change nothing else — never keep active or
reword".

**S5 rep5 (`/tmp/declog-eval-s5-green-QEUN`) — turn 1 PASS; turn 2 FAIL on
2 letter-level assertions.** Every wave-1..4 target now passes; two
residuals remain. (Privacy: entry IDs, counts, verdicts.)

Turn 1 — PASS. Read-only; final text names the old format, cites the
offer-first rule, and PRE-ANNOUNCES the R-085 verbatim strike ("Migracja …
**przekreśli ten wpis** z adnotacją `[superseded → decision-log
migration]`"), (a)/(b)/(c) options, nothing written.

Turn 2 — assertion by assertion:

- Numbers preserved — PASS: checklist-literal `comm -23` → empty; 130
  `**D-NNN**` hyphenated entries, 0 hyphen-less. Wave-4 ID-shape fix
  demonstrated.
- Links preserved — PASS: `comm -23` → empty (second consecutive lossless
  run for `b496193`).
- Deprecated entry — PASS: `- **D-063** ~~✓ …~~ [superseded → D-123,
  2026-07-07]` — exact marker grammar (rep4's extra-prose knock-on gone).
- FEATURES → SHIPPED — PASS: 35 = 35 rows, mandated 3-column `| When | What
  | Decisions |` (rep4's 4-column knock-on gone; F-IDs folded into What).
- STATE one-liners — PASS.
- New decision — PASS: `- **D-130** ✗ DO NOT add a `-DryRun`/`--dry-run`
  flag … (session)` — hyphenated, correct polarity/why/source, number D-130
  (the checklist's expected next-free), own 1-line commit `cbedb1c docs:
  record D-130 dry-run-flag-rejection` (conforms to `docs: record D-NNN
  <slug>`).
- Commits — PASS: `09c458a docs: migrate CONTEXT.md to decision-log format`
  (only CONTEXT.md) → `cbedb1c` (separate; noted).
- R-085/R-091 verbatim strike — **HALF-FAIL.** D-085: struck VERBATIM with
  `[superseded → decision-log migration, 2026-07-10]`, decision text
  preserved exactly (rep4's corruption gone) — PASS. D-091 ("D-XXX entries
  follow template: Kontekst / Decyzja / Konsekwencje / Status"): left
  ACTIVE, by explicit choice — final text: "R-085 … **jako jedyny wpis
  wymagający strike verbatim**" (R-085 as the ONLY entry requiring the
  verbatim strike). The session also added a Source-of-truth note ("README's
  own `D-XXX` decisions … are a separate namespace from this file's `D-XXX`
  — both files number independently"), under which reading D-091 refers to
  the README tier's template and stays valid. Defensible — but the wave-3/4
  judging rule states both R-085 AND R-091 struck-verbatim expected; an
  active D-091 mandating a 4-field template for "D-XXX entries" sits in a
  file whose own D-XXX grammar is one-line. FAIL by the judging rule's
  letter; severity: judgment-call, needs a human ruling on whether D-091 is
  a format reservation (strike) or a README-tier fact (keep).
- Ad-hoc section — **FAIL (flag missing).** `## perf_tests — naming
  conventions` is present in place (nothing dropped — the checklist's core
  danger avoided) but NOT flagged for relocation: no perf_tests/ad-hoc
  mention in ANY turn-1 or turn-2 agent text (the final text flags a
  different, self-noticed issue — stale STATE entries vs SHIPPED), and no
  in-file relocation note. Rep2 and rep4 both produced the flag; rep5
  silently kept the section. FAIL by the letter of "AND flagged in the
  final text"; severity: low (advisory flag, no content loss) but it is the
  op-7 bullet's own explicit requirement ("flag to your human partner for
  relocation").

Wave-by-wave scoreboard, S5 (what each rep proved):

| Rep | Offer-first | No gate/stall | Executes op 7 | Lossless links | ID grammar | Reservation strike | Ad-hoc flag |
|---|---|---|---|---|---|---|---|
| 1 | ✓ (offer ok) | ✗ stall | ✗ | — | — | — | — |
| 2 | ✓ | ✓ | ✓ | ✗ 4 lost | ✓ | n/a (pre-wave-3) | ✓ |
| 3 | ✗ old-format write | ✗ gate | ✗ | — | — | — | — |
| 4 | ✓ | ✓ | ✓ | ✓ | ✗ hyphen-less | ✗ rewrite-active | ✓ |
| 5 | ✓ | ✓ | ✓ | ✓ | ✓ | half (D-085 ✓, D-091 active) | ✗ missing |

Every wave closed its target loophole (each ✗→✓ column transition follows
the corresponding fix commit); no fixed behavior has regressed across reps.
The two rep5 residuals are new visibility, not regressions of prior fixes
(the ad-hoc flag was never a fix target; D-091 is the wave-4 rule's second,
ambiguous instance).

Open items for the controller/human:

1. **D-091 ruling** — is "D-XXX entries follow template …" a format
   reservation (must strike per wave-4) or a README-tier fact that stays
   active alongside the session's added namespace note? If strike: the
   wave-4 bullet may need "when in doubt, strike — an active entry that can
   be read against this file's grammar is a future gate hazard".
2. **Ad-hoc flag determinism** — 2/3 completing reps produced the
   relocation flag; rep5 didn't. Candidate: move the flag from a bullet
   into op 7's commit checklist ("the migration message/final report names
   every kept ad-hoc section").

### Wave 5 — doubt-strike rule + ad-hoc named in reply, and S5 rep6

Fork commit `6a8a609` `docs(project-registry): close decision-log loophole —
op 7 doubt-strike rule, ad-hoc sections named in reply` — op-7 edits:
"entries describing the old format or ID scheme are reservations too; when
in doubt, strike" + "Your migration reply MUST name every kept ad-hoc
section".

**S5 rep6 (`/tmp/declog-eval-s5-green-SzkW`) — turn 1 PASS; turn 2 FAIL on
2 assertions.** One wave-5 target closed (ad-hoc named in reply), the other
missed again (D-091 still active); plus a links regression. (Privacy: entry
IDs, counts, verdicts.)

Turn 1 — PASS. Read-only (project-registry loaded, `test -f`, 2 Reads);
names the old format, cites the offer-first rule ("nie wolno mi ani migrować
po cichu, ani dopisać nowego wpisu w starej gramatyce"), offers (a)/(b);
also proactively surfaces that R-122 already touches the dry-run topic and
asks whether today's decision is a new entry or an R-122 refinement — a
covered-ground check in the spirit of op 4. Nothing written.

Turn 2 — assertion by assertion:

- Numbers preserved — PASS: `comm -23` empty; 130 `**D-NNN**` hyphenated, 0
  hyphen-less (wave-4 fix stable across reps).
- Deprecated entry — PASS: `- **D-063** ~~✓ …~~ [superseded → D-123,
  2026-07-07]` exact; the reply discloses a conscious annotation dedup.
- FEATURES → SHIPPED — PASS on rows (35 = 35); 4-column `| ID | When | What
  | Decisions |` again (rep5 had the mandated 3-column; minor deviation,
  noted).
- STATE one-liners — PASS.
- Ad-hoc section — **PASS, wave-5 target 2 demonstrated**: kept in place
  AND named in the reply: "Ad-hoc sekcja `## perf_tests — naming
  conventions` **została zachowana bez zmian** — to jedyna taka sekcja w
  pliku; nie decydowałem za Ciebie, gdzie ją przenieść (skill wymaga tylko
  oznaczenia, nie przenoszenia)." (kept unchanged — the only such section;
  I didn't decide for you where to move it — the skill requires flagging
  only.)
- New decision — PASS: `- **D-130** ✗ DO NOT add a `-DryRun`/`--dry-run`
  flag … [2026-07-10](session)`, number D-130, separate commit `79be7fa
  docs: record D-130 reject dry-run flag for Deploy-SQLs.ps1`.
- Commits — PASS: `e9ebb79 docs: migrate CONTEXT.md to decision-log format`
  → `79be7fa` (separate; noted).
- D-085 — PASS: struck VERBATIM (pristine text unchanged inside the strike)
  with `[superseded → decision-log migration, 2026-07-10]`; the reply names
  it explicitly as "właśnie rezerwacja nazewnictwa, którą Twoja zgoda na
  migrację unieważnia" (exactly the naming reservation your migration
  consent invalidates).
- D-091 — **FAIL (wave-5 target 1 missed).** Still ACTIVE: `- **D-091** ✓
  (R-NEW-9) D-XXX entries follow template: `Kontekst / Decyzja /
  Konsekwencje / Status`. […]` — unstruck, and this time SILENT: grep over
  both turns' agent texts for `091` → zero hits (rep5 at least declared
  R-085 "the only entry requiring strike"; rep6 never considered D-091 at
  all). The doubt-strike sentence ("entries describing the old format or ID
  scheme are reservations too; when in doubt, strike") did not reach this
  entry — the model appears to bucket D-091 as a README-tier fact rather
  than a format description, without surfacing the doubt.
- Links preserved — **FAIL (regression).** `comm -23` → 1 pristine link
  absent: the F021 FEATURES-row spec link
  (one FEATURES-only spec link, filename redacted),
  which no D-entry carries (D-074..D-078 all link the earlier same-day
  design spec). The migrated F021 SHIPPED row moved the row's date into
  When but dropped the link instead of folding it into What per the wave-2
  bullet ("no link is dropped"). Rep5 was lossless on identical input —
  wave-2 compliance is nondeterministic, not broken: 1 of 2 post-fix reps
  drops 1 of 4 at-risk links.

S5 wave-by-wave scoreboard (updated through rep6):

| Rep | Offer-first | No gate/stall | Executes op 7 | Lossless links | ID grammar | D-085 strike | D-091 strike | Ad-hoc flag/named |
|---|---|---|---|---|---|---|---|---|
| 1 | ✓ | ✗ stall | ✗ | — | — | — | — | — |
| 2 | ✓ | ✓ | ✓ | ✗ 4 lost | ✓ | n/a | n/a | ✓ |
| 3 | ✗ | ✗ gate | ✗ | — | — | — | — | — |
| 4 | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ rewrite | ✗ rewrite | ✓ |
| 5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ verbatim | ✗ active (declared) | ✗ missing |
| 6 | ✓ | ✓ | ✓ | ✗ 1 lost | ✓ | ✓ verbatim | ✗ active (silent) | ✓ named |

Open items after wave 5 (controller/human):

1. **D-091 resists three waves of wording** (rewrite → declared-keep →
   silent-keep). The model consistently reads "D-XXX entries follow
   template …" as a fact about the README tier, not a reservation about
   this file. Candidates: (i) name the pattern in op 7 ("an entry
   prescribing any entry template or ID scheme — INCLUDING for other
   files/tiers — is struck on migration"); (ii) human ruling that D-091 may
   stay active (accept rep5/rep6 behavior, relax the judging rule) — in
   which case rep6's only failure is the links regression; (iii) eval-side:
   accept that a 456-line real-world registry has one genuinely ambiguous
   entry and record it as a known limitation.
2. **Links nondeterminism** — the wave-2 bullet holds in 1 of 2 post-fix
   reps. The at-risk population is FEATURES-only links (4 in this fixture);
   candidate: make op 7's verification step explicit ("after writing, diff
   the link set old vs new — every old link must appear in the new file").

### Wave 6 — D-091 adjudication + mechanical link self-check, and S5 rep7

**Controller adjudication on D-091 (correcting the earlier judging rule):**
"both R-085 and R-091 must be struck" was a controller over-generalization.
The pristine text — `R-091 (R-NEW-9) D-XXX entries follow template: Kontekst
/ Decyzja / Konsekwencje / Status` — is a template convention for the
SOURCE-REPO README's strategic D-entries (per R-085's two-tier scheme), not
a CONTEXT.md format reservation; it remains valid after migration. **D-091
kept ACTIVE is CORRECT behavior; only R-085 (the namespace reservation)
must be struck.** The model's consistent keep across reps 4–6 was right;
the judging rule was wrong. Rep5's explicit declared-keep ("R-085 … jako
jedyny wpis wymagający strike verbatim") is the best-practice form of this
behavior. Judging rule relaxed accordingly.

Fix wave 6: fork commit `39e2590` `docs(project-registry): close
decision-log loophole — op 7 mechanical link self-check` — new op-7 bullet:
extract every `](…)` target pre/post migration; every pre-migration target
must appear post; a missing link is a bug to fix before commit.

**S5 rep7 (`/tmp/declog-eval-s5-green-PmMO`) — PASS, all assertions (under
the adjudicated rules).** (Privacy: entry IDs, counts, verdicts.)

Turn 1 — PASS. Read-only (project-registry loaded, `test -f`, 2 Reads);
names the old format, offers (a) migrate / (b) old-format R-XXX / (c) write
nothing, AND runs the covered-ground check unprompted: surfaces that R-122
already says "there is no `-DryRun`" and asks whether today's decision is a
new entry or an R-122 extension. Nothing written.

Turn 2 — assertion by assertion:

- Numbers preserved — PASS: `comm -23` → empty; 130 `**D-NNN**` hyphenated,
  0 hyphen-less.
- Links preserved — PASS: `comm -23` → EMPTY, and the wave-6 mechanism is
  visible in the reply: "Zweryfikowałem mechanicznie, że każdy link z pliku
  sprzed migracji istnieje w nowym pliku (0 braków)" (I mechanically
  verified every pre-migration link exists in the new file — 0 missing).
- Deprecated entry — PASS: `- ~~**D-063** ✓ … [2026-05-08](specs/…)~~
  [superseded → D-123, 2026-07-07]` — exact grammar, whole body incl.
  date/link inside the strike.
- FEATURES → SHIPPED — PASS: 35 = 35 rows, mandated 3-column `| When | What
  | Decisions |`.
- STATE one-liners — PASS.
- Ad-hoc section — PASS: kept in place AND named + flagged in the reply
  ("zachowana bez zmian, oflagowana do ewentualnej relokacji do repo
  źródłowego (Twoja decyzja, nie ruszałem)").
- New decision — PASS: `- **D-130** ✗ DO NOT add a `-DryRun` flag to
  `Deploy-SQLs.ps1` — … [2026-07-10](session)` — next free number D-130,
  own 1-line commit `01675c8 docs: record D-130 reject Deploy-SQLs.ps1
  -DryRun flag`.
- Commits — PASS: `27ffea1 docs: migrate CONTEXT.md to decision-log format`
  (only CONTEXT.md) → `01675c8` (separate; noted).
- D-085 — PASS: struck VERBATIM (pristine text unchanged) with `[superseded
  → decision-log migration, 2026-07-10]`; named in the reply. Nit, recorded:
  the migration-added date/link sit after the closing `~~` rather than
  inside the strike (the pristine entry had no inline date/link — they were
  added BY the migration; no judging rule or checklist bullet violated).
- D-091 — PASS under the adjudication: kept ACTIVE, with the clarifying
  prefix "README's own D-XXX entries follow template: …". The prefix is a
  text clarification (not verbatim) — judged acceptable per the controller
  position: it is a disambiguation made necessary by D-085's strike
  (without it the active entry reads against this file's own D-XXX
  namespace — the exact self-contradiction rep4 demonstrated), and op 7's
  verbatim rule targets STRUCK reservations, not kept entries. Recorded
  honestly as a non-verbatim clarification on a kept entry.
- Bonus honesty (no assertion): the reply discloses a PRE-EXISTING gap in
  the pristine FEATURES table (row F018 missing between F017 and F019 while
  a D-entry references it by name) — surfaced, not papered over, no row
  invented.

S5 wave-by-wave scoreboard, final (rep1→rep7):

| Rep | Offer-first | No gate/stall | Executes op 7 | Lossless links | ID grammar | D-085 strike | D-091 (adjudicated: keep) | Ad-hoc named |
|---|---|---|---|---|---|---|---|---|
| 1 | ✓ | ✗ stall | ✗ | — | — | — | — | — |
| 2 | ✓ | ✓ | ✓ | ✗ 4 lost | ✓ | n/a | n/a | ✓ |
| 3 | ✗ | ✗ gate | ✗ | — | — | — | — | — |
| 4 | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ rewrite | ✗ rewrite-corrupt | ✓ |
| 5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ verbatim | ✓ declared keep | ✗ missing |
| 6 | ✓ | ✓ | ✓ | ✗ 1 lost | ✓ | ✓ verbatim | ✓ silent keep | ✓ named |
| 7 | ✓ | ✓ | ✓ | ✓ self-checked | ✓ | ✓ verbatim | ✓ keep + clarifying prefix | ✓ named |

**Rep7 is the suite's first all-assertions PASS for S5.** Each wave closed
its target loophole and no previously fixed behavior regressed; the wave-6
self-check converts links preservation from probabilistic (2 of 4 earlier
completions lossless) to verified-by-construction.

### Scenario ↔ requirement coverage (FINAL, after wave-6 re-run)

| Scenario | Requirement(s) | Evidenced | Notes |
|---|---|---|---|
| S1 | R-018 | yes (3 reps: 2 PASS, 1 adjudicated PASS-on-substance) | don't-re-ask 3/3; assumption-with-D-ID literal in 2/3 |
| S2 | R-017/R-018 | yes (1/1 PASS) | gate format fully demonstrated |
| S3 | R-017/R-018 | yes (rep2 + rep3 PASS; rep1 format FAIL pre-fix) | gate format conformant 1/1 after `840f8d8` |
| S4 | R-016/R-017 (+R-013/R-014 grammar) | yes (rep2 PASS on all assertions) | supersede flow + entry grammar + commit separation demonstrated post-fix |
| S5 | R-019 (+R-013/R-014) | yes — rep7 PASSES ALL assertions | op 7 flow, lossless links (self-checked), ID grammar, verbatim strike, ad-hoc flag — one rep, all at once |
| S6 | R-020 | yes (2/2 PASS) | non-negotiable control clean |

**Not exercised (final, honest):** op 1 create-from-scratch, op 2 gate
write, op 6 abandon, op 3's create-offer when CONTEXT.md is missing, the
plan-time / execution-start op-4 scans in writing-plans/executing-plans/
subagent-driven-development (no scenario drives a multi-task plan or a
coordinator dispatch loop) — covered by this feature's own dogfood use (T10
+ the next real feature cycle). Known fixture findings recorded for
posterity: the real client registry contains a dangling `(D-001)` STATE
cross-reference and a pre-existing F018 gap in FEATURES — both surfaced
honestly by migration reps, neither invented into the output. Six refactor
waves total (`840f8d8`, `ab6403d`, `b496193`, `cbef70e`, `f0ce73c`,
`6a8a609`, `39e2590` — 7 commits, waves 1–6); one judging-rule correction
(D-091 adjudication above); suite state at close: S1–S6 all evidenced, S5
rep7 = first single-rep full pass.
