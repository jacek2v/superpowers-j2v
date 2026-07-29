# Eval: brainstorming deep research (parallel read-only research subagents)

Date: 2026-07-28 – 2026-07-29
Skill(s): `brainstorming` (checklist steps 5 and 9, research prose, Process
Flow digraph, new `## Deep Research` section) + new reference file
`skills/brainstorming/research-subagents.md` — spec
`specs/2026-07-28-brainstorming-subagent-research-design.md`, decisions
D-029..D-033.
Method: writing-skills RED → edit → GREEN. Scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos), multi-turn via
`--session-id`/`--resume` with scripted answers. Branch:
`feat/brainstorm-deep-research` off `main`.

**⚠ Every passing result in the V1/V2 sections was obtained with `HOME`
pointed at `/tmp/eval-home` — a copy of `~/.claude` with `CLAUDE.md`
removed.** This machine's global instructions ("be extremely concise",
"answer first", no meta-narration) suppressed the tier entirely: 0 proposals
across 30 turns run under the real `HOME`, on both fixtures, at every skill
state. **V3 (2026-07-29) lifts that caveat for this machine only**: after the
operator added a skill-mandated-message exemption to `~/.claude/CLAUDE.md`,
N1 passes 4/4 under the real `HOME`. Behavior under any *other* user's global
instructions remains **not established** — see **Not exercised / not
established**.

Two fixtures, because the first one never elicited the feature:

- **`feedmix`** (`evals/deep-research/`) — full-text-search request,
  scenarios R1–R4. The tier never fired, in any of 4 scenarios or 18 GREEN
  turns. Root cause was the fixture, not the skill: active entries
  D-001/D-002 collapse the backend to a single candidate (SQLite FTS5), so
  the decision it was built around is only nominally open and the skill
  correctly declines to propose. What it establishes: **no false trigger**,
  and no regression on the well-known-territory control.
  Map: R1→proposal exists and is its own message; R2→acceptance-gated
  dispatch, trimmed list honoured, per-decision approval, persistence;
  R3→no behavior change in well-known territory; R4→decline path.
- **`notekeep`** (`evals/deep-research-v2/`) — built 2026-07-29 by human
  decision: offline-first multi-device note sync, where the merge strategy is
  genuinely open. Scenarios N1–N4, all PASS at the final skill state, and
  **every positive result in this document comes from here**.
  Map: N1→verdict + proposal as its own message, nothing dispatched;
  N2→accept-with-trim, single-message parallel dispatch, per-decision
  approval, hold honoured, spec + analysis file committed together;
  N3→well-known-territory control (no proposal); N4→decline honoured.

Budget: the plan's human-approved allocation (baselines R1×2 R2×1 R3×1; GREEN
R1×2 R2×2 R3×2 R4×1) was extended by human decision on 2026-07-29 to cover the
second fixture, the contamination diagnosis, and the script realignment. Every
v2 verdict below is n=1 per scenario.

Contamination caveat: toy sessions inherit the real plugin bootstrap; the
loaded skill content is the same text under test, so contamination points
toward the same text (2026-07-05 precedent).

## RED baselines

Ran against the unmodified skill (`git status --short skills/` empty before and
during this phase). Dispatch-tool name could not be positively verified — no
transcript dispatched anything. `grep -c '"name":"Task"' <file>.jsonl` returned
`0` for all 9 transcripts; the full tool-use inventory (`jq -r 'select(.type
=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' |
sort -u`) across every transcript shows only `Bash, Read, Skill, TaskCreate,
TaskUpdate, ToolSearch, Write` — no `Task`/`Agent`-shaped subagent-dispatch
tool anywhere. `TaskCreate`/`TaskUpdate` are the session's own todo-list
manager, not subagent dispatch — confirmed by their inputs (see R1 below).
No `docs/superpowers/research/` directory was created in any toy repo.

### STOP-rule determination

Brief's STOP rule: if both R1 baselines already propose parallel research
subagents as their own message and wait for acceptance (2/2), no failure was
demonstrated — STOP and defer to human partner instead of writing a RED
verdict or committing.

Evidence: **0/2**, not 2/2. Neither R1 rep's turn-1 message contains a
research-subagent proposal (no question list + named mode + subagent count),
and neither mentions subagents/dispatch/parallel at all — grep for
`subagent|równoległ|parallel|dispatch|research agent|task tool` (case
-insensitive) over every assistant text block in both transcripts returned
zero matches. **STOP rule does not trigger** — proceeding to record RED
verdicts and commit, per the brief's own instruction for the 0/2 case.

### R1 — full-text-search request, 3 open decisions (×2 reps, 1 turn each)

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | FAIL (expected failure candidate) | Turn 1 ends after exactly **one** multiple-choice clarifying question (AND vs. exact-phrase matching); dispatch count `0`; no proposal text. Of the three open decisions (index storage, ranking, stemming/non-English) **zero are settled** — session ends mid-loop on the first question, before even reaching stemming/non-English. |
| 2 | FAIL (expected failure candidate) | Turn 1 ends after one multiple-choice clarifying question (API entry point A/B/C); dispatch count `0`; no proposal text. Zero of three decisions settled. |

Verbatim rationalizations (Polish, with English gloss):

- Rep 1, `TaskCreate` todo list (pending item, before any question is asked):
  `"Research sanity check (SQLite FTS5 stemming/tokenizers, stdlib-only)"`
  — a **solo, self-executed** checklist item, never phrased as a proposal to
  the human or a subagent dispatch. It runs a Bash one-liner
  (`python3 -c "import sqlite3; ... pragma compile_options"`) itself later in
  the same turn instead.
- Rep 2, assistant text: *"To w praktyce kieruje architekturę w stronę SQLite
  FTS5 (wbudowanego w moduł sqlite3 — zweryfikuję dostępność w kroku
  badawczym) zamiast zewnętrznego silnika typu Elasticsearch/Whoosh."*
  ("...this in practice steers the architecture toward SQLite FTS5 (built
  into the sqlite3 module — I'll verify availability in the research step)
  instead of an external engine like Elasticsearch/Whoosh.") — "research
  step" here means the agent checking itself, not proposing anything.
- Rep 2, `TaskCreate` todo list: `{"subject":"Research sanity check",
  "description":"Verify SQLite FTS5 availability in stdlib sqlite3 given
  D-001/D-002 constraints"}` — same self-executed framing, no
  acceptance/dispatch language.

Dispatch commands and output:
```
$ grep -c '"name":"Task"' baseline-r1-rep1.jsonl || true
0
$ grep -c '"name":"Task"' baseline-r1-rep2.jsonl || true
0
```
Final text commands and output — see full text in task-2-report.md; both end
on a bare clarifying question, not a proposal.

### R2 — R1 + turn 2 accepts with trimmed question list (×1 rep; judged turns 1–2 only, flow-validity rule)

| Turn | Verdict | Evidence |
|---|---|---|
| 1 | FAIL (same shape as R1) | One multiple-choice question (API entry point A/B/C); dispatch `0`; no proposal. |
| 2 | **INVALID beyond this point (expected)** | Scripted answer *"Yes, go ahead — but drop the stemming and non-English question, we only care about English for now. Run the rest."* was written assuming turn 1 had proposed research subagents to accept. It didn't. The agent reinterpreted "yes, go ahead" as approving interface option A and "drop the stemming question" as removing a topic from its own clarifying-question loop, then asked the next inline question (result format) unprompted. Per the brief this is the expected divergence point — turns 3–5 are not scored. |

Facts required by the brief, checked across the full 5-turn conversation
(beyond the scored window, for completeness):
- **Unprompted subagent dispatch:** none. `grep -c '"name":"Task"'` returns
  `0` on all of `baseline-r2-rep1.jsonl` and `-t2`..`-t5`.
- **Source citation for the FTS5 backend choice:** none. The only grounding
  is a self-run Bash probe in turn 1
  (`uv run python3 -c "...CREATE VIRTUAL TABLE t USING fts5(x)..."`)
  confirming FTS5 compiles into the local `sqlite3` — no URL, doc reference,
  or "per X" citation anywhere in the design text (turn 3's "## Podejścia"
  section).
- Turn 5 wrote and committed `docs/superpowers/specs/2026-07-29-full-text-
  search-design.md` (`git -C <toy> log --oneline` → `f9d8ea3 docs: add
  full-text search design spec`); no `docs/superpowers/research/` file or
  directory was ever created.

### R3 — well-known-territory request (`--json` flag), ×1 rep, 2 turns — healthy control

| Turn | Verdict | Evidence |
|---|---|---|
| 1 | PASS (no proposal, as expected) | One clarifying scope question (new spec vs. addendum to a nonexistent `list` command); dispatch `0`; no research-subagent language anywhere. |
| 2 | PASS | Agent presents the full design in one message and ends *"Wygląda dobrze? Jeśli tak, zapisuję spec do docs/superpowers/specs/2026-07-29-list-json-flag-design.md i aktualizuję CONTEXT.md."* (future tense — not yet written). Toy repo confirms: `git -C <toy> log --oneline` still shows only `toy: initial state`; no spec file added. |

Golden reference for GREEN R3 — the quick tier's shape (one scope question,
then a complete design in one message, nothing written until explicit
approval) must be reproduced unchanged after the skill edit.

Full per-command output, verbatim assistant texts, and toy-repo listings are
recorded in `.superpowers/sdd/task-2-report.md`.

## GREEN results

The plan's four `feedmix` scenarios were run first, against the skill exactly as
shipped by T3+T4 (commits `cd1d9ec`, `6112338`). The tier never fired. A second
fixture (`notekeep`) was then built by human decision to test a genuinely open
decision; it *also* never fired until a contamination source was found and
removed. The two refactor commits (`31a434b`, `f9c5d50`) were then shown to be
load-bearing only once that contamination was removed — their earlier "no
effect" verdicts, recorded during the campaign, were artifacts of a
contaminated test environment, not evidence the wording was inert. This
section reports the v1 suite (tier-never-fires, with root cause), then the
final v2 measurement (tier fires on every scenario) obtained with an isolated
`HOME`. The full iteration story — including the contaminated runs and the two
counting bugs — is in **Refactor loop** and **Method corrections** below;
skipping straight to the final numbers here would hide how they were obtained.

### V1 — `feedmix` suite (T3+T4, contaminated HOME): tier never fires

Ran against `HOME` pointed at the real `~/.claude` (the same setup RED used).
All 18 turns `subtype=success`. Across every transcript: 0 dispatches (no
`Task`/`Agent` tool anywhere — confirmed by the same tool-name inventory
method as RED), no `docs/superpowers/research/` directory in any toy repo, and
0 case-insensitive matches for `subagent|równoległ|parallel|dispatch|research
agent|deep research` in the assistant's own text.

#### R1 — full-text-search request, 3 open decisions (×2 reps, 1 turn each)

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | FAIL (tier did not fire) | Turn 1 ends after one multiple-choice clarifying question (interface A/B/C); dispatch `0`; no proposal text — same shape as the RED baseline. |
| 2 | FAIL (tier did not fire) | Turn 1 ends after one multiple-choice clarifying question (searched fields A/B/C/D); dispatch `0`; no proposal text. |

Both reps state D-001/D-002/D-003 up front and conclude they collapse the
backend choice to SQLite FTS5 before any question is asked — identical
reasoning to the RED baselines, now under the edited skill.

```
$ jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' green-r1-rep1.jsonl green-r1-rep2.jsonl | sort -u
Bash
Read
Skill
TaskCreate
TaskUpdate
ToolSearch
```
No `Task`/`Agent` in either inventory.

#### R2 — R1 + turn 2 accepts with trimmed question list (×2 reps, judged turns 1–2, flow-validity rule)

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 1 | 1 | FAIL | One clarifying question (interface A/B); dispatch `0`; no proposal. |
| 1 | 2 | INVALID beyond this point | Scripted acceptance ("drop the stemming question, run the rest") is reinterpreted as answering the interface question and narrowing scope, not as accepting a proposal that was never made. Turn 2 text: *"Rozumiem — angielski only, żadnego stemmingu/non-english jako osobnego tematu. Zakładam też odpowiedź na pytanie 1..."* ("Understood — English only, no stemming/non-English as a separate topic. I'm also taking the answer to question 1 as given..."). |
| 2 | 1 | FAIL | One clarifying question (searched field); dispatch `0`; no proposal. Turn 1 text: *"To mocno zawęża 'jak' — zostają otwarte realne pytania o zakres, ranking i stemming."* ("This narrows 'how' considerably — real open questions about scope, ranking and stemming remain.") — the agent names open questions and still does not propose. |
| 2 | 2 | INVALID beyond this point | Same reinterpretation as rep 1: scripted acceptance is read as answering the still-open field question. |

Facts checked across the full 5-turn conversation for both reps (beyond the
scored window, for completeness, matching RED's method):
- Dispatch: `0` across all of `green-r2-rep{1,2}(-t{2,3,4,5}).jsonl`.
- Turn 5 wrote and committed a spec (`docs/superpowers/specs/2026-07-29-full-text-search-design.md` for rep 1); no `docs/superpowers/research/` file or directory was ever created in either rep.
- No source citation for the FTS5 backend choice in either rep — grounding is a self-run Bash/quick-tier check, same as RED.

#### R3 — well-known-territory request (`--json` flag), ×2 reps, 2 turns — healthy control

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 1 | 1 | PASS (no proposal, as expected) | One scope question (whether to design a CLI skeleton from scratch); dispatch `0`. |
| 1 | 2 | PASS | Full design presented in one message, ends *"Pasuje? Jeśli tak, zapisuję spec..."* (future tense, not yet written). |
| 2 | 1 | PASS | One clarifying question; dispatch `0`. |
| 2 | 2 | PASS | Full design presented, nothing written until approval. |

No regression from the T3+T4 edit: the quick tier's shape (one scope question,
then a complete design, nothing written until approval) is reproduced
unchanged, matching RED's golden reference.

#### R4 — R1 + turn 2 declines (×1 rep, 2 turns)

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 1 | 1 | Vacuous pass (nothing to decline) | Same shape as R1: one clarifying question (language scope A/B/C for the tokenizer), dispatch `0`, no proposal. |
| 1 | 2 | Vacuous pass | Agent goes straight to "## Podejścia do indeksu FTS5" (approaches), tool inventory `TaskUpdate` only. The scripted decline in `answer-r4-t2.md` had nothing to decline — the proposal it was written to refuse never appeared. |

R4's literal assertions ("no dispatch, no research file, continues to
approaches") all hold, but only because the tier was never invoked in the
first place — this is not evidence the decline path works, only that it was
never exercised. See **Not exercised / not established**.

#### Diagnostic probe r1d (controller-run, not one of the plan's 4 scenarios)

Turn 2 answered all three of R1's clarifying questions and restated the
research questions verbatim. The agent still did not propose deep research —
it ran the quick tier itself (`FTS5 jest dostępne`, `porter unicode61
remove_diacritics 2` tokenizer confirmed working via a local Bash probe,
`bm25()` ranking confirmed available), settled all three questions including
stemming/non-English (*"stemmer Portera jest wyłącznie angielski... bez
zewnętrznej biblioteki (zabronionej przez D-002) nie da się tego obejść"* —
"the Porter stemmer is English-only... without a third-party library (which
D-002 forbids) this cannot be worked around"), and went straight to three
approaches with a recommendation.

**Root cause (v1):** not the turn budget and not primarily the skill's
wording. D-001/D-002 collapse the backend choice to a single candidate
(FTS5), so the research question is only nominally open, and
`research-subagents.md` explicitly forbids proposing research for a decision
an active D-entry already settles. **The agent's behavior is correct against
the shipped text.** The v1 suite never demonstrates the deep-research tier
firing, in any of its 4 scenarios or 18 turns — see **Not exercised / not
established**.

### V2 — `notekeep` suite, final measurement (isolated `HOME`, realigned scripts, skill at HEAD: T3+T4+L1+L2)

Human decision (2026-07-29): build a second fixture with a genuinely open
domain (offline-first multi-device note sync; merge strategy is the open
decision) rather than tune the skill against a fixture where research is
objectively unnecessary. This suite is also where a contamination source
(nested sessions inheriting `~/.claude/CLAUDE.md`) was found and controlled
for — see **Refactor loop**. The verdicts below are the final measurement:
`HOME=/tmp/eval-home` (a copy of `~/.claude` with `CLAUDE.md` removed), skill
at HEAD (`cd1d9ec` + `6112338` + `31a434b` + `f9c5d50`), scenario scripts
realigned to the skill's actual turn shape (commits `1d36252`, `a156bf7`).

#### N1 — multi-device sync request, 3 open decisions (×1 rep, 3 turns — `rep8`)

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 8 | 1 | n/a (clarifying question, expected) | One multiple-choice question about relay topology; dispatch `0`. |
| 8 | 2 | **PASS** | Per-decision **Werdykt badawczy** / research verdict for all 3 open decisions, then the **Propozycja deep research** as its own message: `## Werdykt badawczy` lists all 3 questions as `research candidate` with the criterion named (e.g. *"Strategia scalania rozbieżnych edycji tej samej notatki — research candidate (wybór architektury, sporny prior art: LWW / CRDT / three-way diff / OT)"*), then `## Propozycja deep research` proposes **3 subagentów badawczych równolegle, tryb per-decision**, states the cost (*"To zadanie token-intensywne"*), and asks *"Chcesz, żebym wysłał te trzy subagenty? Możesz też przyciąć lub zmienić listę pytań..."* (offers to trim). Dispatch `0` — correctly waiting for acceptance. |
| 8 | 3 | (not scored — run stops here per the scenario script) | — |

```
$ jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' \
    green-n1-rep8.jsonl green-n1-rep8-t2.jsonl green-n1-rep8-t3.jsonl | sort -u
Bash
Read
Skill
TaskCreate
TaskUpdate
ToolSearch
```
No `Agent` anywhere across all 3 turns — 0 dispatches, n=1.

#### N3 — well-known-territory request (`--json` flag), ×2 reps, 2 turns each — healthy control (`rep3` pre-digraph-fix, `rep4` post-digraph-fix)

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 3 | 1 | PASS | One scope question; dispatch `0`; 0 research-language mentions. |
| 3 | 2 | PASS | Full design presented (output format, error handling, tests), ends *"Czy ten projekt wygląda dobrze? Jeśli tak, zapisuję go jako spec..."* — nothing written yet. |
| 4 | 1 | PASS | One scope question (the repo has no CLI at all yet, so `list` would be built from scratch); dispatch `0`; 0 research-language mentions. |
| 4 | 2 | PASS | Design presented section by section after an explicit no-collision gate against D-001/D-002/D-003, ends *"Pasuje to do Ciebie? (Sekcja 1/4)"* — nothing written; toy repo `git log` still only `616816b toy: initial state`. |

No regression from L1+L2 in isolation, n=1 (`rep3`).

`rep4` is the post-fix confirmation for `579eb48`, which re-pointed the Process
Flow digraph's "well-known territory" edge into the deep-research decision node
(it previously bypassed the node, contradicting checklist step 5's prose).
Because that edit changes routing on exactly the path N3 walks, the control was
re-run at HEAD: the well-known-territory branch still produces no proposal.
Tool inventory across both turns is `Bash, Read, Skill` — no `Agent`; no
`## Werdykt badawczy` and no research proposal in either turn's assistant text;
no `docs/superpowers/research/` directory in the toy repo
(`/tmp/deepresearch-eval-n3-green-tZRK`); both turns `subtype=success`.

```
$ jq -r 'select(.type=="assistant") | .message as $m
         | ($m.content[]? | select(.type=="tool_use" and .name=="Agent") | $m.id)' \
     green-n3-rep4.jsonl green-n3-rep4-t2.jsonl | sort | uniq -c
(no output — 0 dispatch tool_use blocks, so no message ids to group)
$ jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' \
     green-n3-rep4.jsonl green-n3-rep4-t2.jsonl \
  | grep -icE 'werdykt|subagent|równoległ|parallel|dispatch|research agent|deep research|propozycja badawcza'
0
```

**What this establishes:** the digraph edit in `579eb48` did not cause the
well-known-territory path to start proposing research. N3 is 4/4 clean across
the campaign (`rep1` under L1, `rep2` under L2, `rep3` at HEAD before the
digraph fix, `rep4` after it) — but only `rep4` measures the post-fix skill, so
this is n=1 for that state, not a 4-rep replication of it.

#### N4 — N1 + turn 4 declines (×1 rep, 5 turns — `rep2`)

| Rep | Turn | Verdict | Evidence |
|---|---|---|---|
| 2 | 1 | n/a (clarifying question, expected) | One scope question (relay protocol design in/out of scope); dispatch `0`. |
| 2 | 2 | proposal present (in response to absorber A) | Per-decision `**Werdykt badawczy**` for all 3 questions, then the per-decision proposal: *"proponuję **tryb per-decision**: 3 subagenci badawczy równolegle... Chcesz, żebym to zrobił?"* Dispatch `0`. |
| 2 | 3 | proposal reaffirmed (in response to absorber B, which explicitly withholds accept/decline) | *"Propozycja głębokiego researchu — trzy pytania z Twojej listy potrzebują więcej niż szybkiej weryfikacji... Mogę odpalić 3 subagentów badawczych równolegle, po jednym na pytanie (tryb per-decision)... To pochłonie sporo tokenów. Chcesz, żebym to odpalił?"* Dispatch `0`. |
| 2 | 4 | **PASS** (decline honored) | Scripted decline: *"No — skip the research, it is too expensive right now. Carry on with your own judgment."* Agent response: *"Skoro rezygnujesz z researchu, opieram propozycję na ugruntowanych, dobrze znanych wzorcach..."* ("Since you're declining the research, I'm basing the proposal on established, well-known patterns...") — continues to approaches on the quick tier alone. Dispatch `0`. |
| 2 | 5 | **PASS** | Continues to design; 0 research-language mentions; no re-proposal. |

Tool inventory across all 5 turns: `Bash, Read, Skill` only — 0 `Agent`
anywhere, n=1. The proposal survives two absorber turns unchanged in
substance before the scripted decline actually lands on it, which is
stronger evidence for the decline path than a same-turn decline would be:
the tier does not wilt or re-negotiate itself while waiting.

#### N2 — N1 + full accept/trim/approve/hold/write path (×1 rep primary, 7 turns — `rep2`; ×1 rep confirmatory, `rep3`)

| Turn | Verdict | Evidence |
|---|---|---|
| 2 | **PASS** | Per-decision verdict for all 3 open decisions (*"Werdykt badawczy — pozostałe trzy pytania z Twojej listy nie są rozstrzygnięte przez to, co już wiem, ani przez żadną aktywną decyzję w CONTEXT.md"*), then the proposal as its own message, per-decision mode, 3 subagents named, cost stated, trim offered: *"To nie jest jeszcze zgoda na research — to sam werdykt. Propozycja badawcza leci osobno, tak jak prosiłeś"* ("This isn't consent to the research yet — this is just the verdict. The research proposal comes separately, as you asked"). Dispatch `0`. |
| 4 | **PASS** | Scripted accept-with-trim: *"Yes, go ahead — but drop the last question on that list... Run the rest."* Tool inventory: exactly **2** `Agent` tool_use blocks (3 proposed minus 1 trimmed, none added back), both sharing **one** `message.id` (`msg_011CdVzmamQZj12HyxABCXdM`) — genuinely concurrent, single-message dispatch. First `Read` in the turn is `skills/brainstorming/research-subagents.md`. Findings are real research with sources: *"jedyna gotowa biblioteka (`hlcpy`) jest martwa od 2021"* (the only ready-made library is dead since 2021); *"Gotowa biblioteka `crdts`+`packify` (pure-Python, licencja ISC...) — ale to małe, jednoosobowe projekty (7 gwiazdek), ryzyko bus-factor 1"*; *"`pycrdt`/Automerge — odpadają twardo: to skompilowane rozszerzenia (Rust/WASM), łamią D-002"* — correctly reported as excluded by D-002. Turn ends on a single decision, asking *"Zatwierdzasz tę decyzję?"* ("Do you approve this decision?") — per-decision approval, not a bulk approve. |
| 5 | **PASS** | Op-4 gate run explicitly against all three active decisions before presenting design sections: *"Bramka: brak kolizji z aktywnymi decyzjami (D-001 offline-first per-device SQLite — zgodne; D-002 nie wymaga zależności... zgodne; D-003 zakaz centralnej władzy nad treścią — relay pozostaje pasywny... zgodne). Przechodzę do prezentacji projektu sekcjami."* |
| 6 | **PASS** (hold honored) | Scripted hold ("finish presenting, do NOT write the spec yet"). Turn ends *"To wszystko, co zostało do zaprezentowania. Czekam na Twoją ostateczną akceptację przed napisaniem specyfikacji."* Tool inventory: empty — no `Write`, no `Bash`. |
| 7 | **PASS** | Scripted final approval + write instruction. `Write` calls to `docs/superpowers/specs/2026-07-29-multi-device-sync-design.md` and `docs/superpowers/research/2026-07-29-multi-device-sync-analysis.md`; `Bash` shows `git add` of exactly those two paths followed by one `git commit` (`73bc90a`) — spec and research file committed together. Result text: *"Specyfikacja i analiza researchu są zapisane i zacommitowane (`73bc90a`)."* |

Confirmatory rerun `rep3` (run after commit `1581bac` was applied, to test
whether the "single-message dispatch" fix changed anything — see **Refactor
loop**): same shape at every turn, including exactly 2 `Agent` dispatches at
t4 sharing one `message.id` (`msg_011CdW8mNrynffJNtzWsG1Jy`). n=1 primary +
1 confirmatory rerun (not an independent second scenario rep — see **Method
corrections**).

**N2 PASSES every assertion in the scenario definition**, including
single-message parallel dispatch — the apparent "sequential dispatch" defect
recorded earlier in the campaign was a counting artifact, not a behavior
(see **Refactor loop**, **Method corrections**).

### V3 — `notekeep` under the operator's REAL `HOME` (N1 ×4, then N2/N4/N3 ×1 — skill at HEAD `ccd917e`)

This is the only measurement in the document taken with the machine's global
`~/.claude/CLAUDE.md` present. It tests a change to that file, not to the
skill: `skills/brainstorming/` is byte-unchanged since `579eb48`
(`git log 579eb48..HEAD -- skills/brainstorming/` is empty), so V3 also
supplies the firing-path evidence the digraph fix previously lacked.

**What changed outside the skill.** The global file's concision rules
("answer first: 1–3 sentences", "no meta-narration — result only") were
deciding *whether* to send the proposal, not just how to word it. The
operator added a closing bullet to `## Common Guidance`:

> These rules govern HOW you word a message, never WHETHER you take a step a
> skill requires. A skill-mandated message — a proposal awaiting my approval,
> an option menu, a required announcement, a verdict a skill tells you to
> write — IS that step's result, not meta-narration, and is exempt from the
> 1–3 sentence limit. […] If a rule above seems to argue for skipping such a
> message, the rule loses.

plus a pointer to it from the meta-narration rule. Runner invoked without the
`HOME` override; everything else identical to V2 (fixture `notekeep`,
scenario `n1`, `--model sonnet`, 3 turns).

| Rep | Verdict | Mode | Evidence |
|---|---|---|---|
| 1 | **PASS** | per-decision | t1 asks an A/B/C merge-strategy question from memory; t2 opens by withdrawing it (*"pytanie A/B/C […] było mikro-decyzją techniczną wyciągniętą z pamięci"*), gives the per-decision **Werdykt badawczy** (3/3 research candidates), then proposes 3 subagents, states *"To jest kosztowne tokenowo"*, offers trim. |
| 2 | **PASS** | per-approach | t2 opens with the frame *"to, co następuje, ustala, czy odpalam trzy równoległe read-only agenty badawcze"*, per-decision verdict 3/3, then sketches 3 candidate architectures (version vectors, LWW-Register CRDT, op-log + HLC) and proposes one subagent per candidate; cost stated, trim offered. |
| 3 | **PASS** | per-approach | t1 asks one scope question (device count); t2 gives verdict 3/3 + a 3-sketch per-approach proposal, flags that op-log compaction may collide with D-003 and hands that to the subagent to verify. |
| 4 | **PASS** | per-decision | t1 asks one scope question (is note deletion in scope); t2 verdict 3/3 announcing *"Zaraz wyślę osobną wiadomość z propozycją"*, then the proposal in a **separate `message.id`** (`msg_011CdWFRf3…` = verdict, `msg_011CdWFT5X…` = proposal); t3 restates the plan as a per-agent table and asks again. |

```
$ python3 - # tool inventory across all 12 realhome turns
files: 12
tools: Bash, Read, Skill, TaskCreate, TaskUpdate, ToolSearch
Agent blocks: 0
result subtypes: {'success': 12}
```

**What this establishes:**

- The suppression was in the global file, not the skill: same skill text,
  0/4 → 4/4 by editing `~/.claude/CLAUDE.md` alone.
- The firing path works at HEAD (post-`579eb48`), n=4.
- Both D-030 modes fire unprompted under real global instructions — 2
  per-decision, 2 per-approach — chosen by the skill, not by the scenario.
- 0 dispatches in all 12 turns. N1 never scripts an acceptance, so this
  confirms nothing runs before consent; it does not re-test dispatch itself
  (that is N2).

#### V3b — N2, N4 and N3 under the real `HOME` (×1 rep each, same skill state)

Run immediately after V3's N1 reps, same conditions, to close the remaining
scenarios. All three PASS.

**N2 `rep4`** (7 turns — accept-with-trim → dispatch → per-decision approval →
hold → write):

| Turn | Verdict | Evidence |
|---|---|---|
| 2 | PASS | Per-decision verdict 3/3 after one scope assumption (2–5 devices). |
| 4 | **PASS** | Scripted accept-with-trim honoured: exactly **2** `Agent` blocks (3 proposed − 1 trimmed), both under one `message.id` (`msg_011CdWGCmp7qJXZhMne8Vfs3`) — single-message parallel dispatch. Subagents did real work: 18 `WebSearch` + 13 `WebFetch`. Findings report constraint-excluded options correctly — Automerge/`pycrdt` *"odpada — wiązania Pythona to skompilowane rozszerzenia Rust, nie czysty Python"* (D-002), CouchDB/PouchDB *"wymaga aktywnego serwera interpretującego drzewo rewizji, koliduje z D-003"*. Ends on **one** decision: *"Zatwierdzasz zegar wektorowy per pole jako mechanizm scalania?"* |
| 5 | PASS | Op-4 gate stated against all three D-entries before any design section. |
| 6 | PASS (hold honoured) | Tool inventory empty — no `Write`, no `Bash`. |
| 7 | PASS | `Write` to `specs/2026-07-29-note-sync-design.md` and `research/2026-07-29-note-sync-analysis.md`, then one `git add` of exactly those two paths + one `git commit` — spec and analysis committed together. |

**N4 `rep3`** (5 turns — decline path): proposal at t3 (per-approach, 3 named
patterns), scripted decline at t4 (*"No — skip the research, it is too
expensive right now"*) honoured — t4 presents 3 design variants from the
agent's own judgment, t5 continues to design. **0 `Agent` blocks in all 5
turns**; no re-proposal.

**N3 `rep5`** (2 turns — well-known-territory control): 0 `Agent`, 0 hits for
`werdykt|subagent|równoległ|parallel|dispatch|deep research` across both
turns, ends asking for approval before writing the spec. No false trigger
under the real `HOME`.

All 14 turns `subtype=success`.

**What V3+V3b do not establish:** each of N2, N3, N4 is n=1 under the real
`HOME`; only N1 has 4 reps there. Nothing here measures a *different* user's
global instructions.

## Refactor loop

Three wording levers were tried against `notekeep`/N1, in order, before the
actual defect (a contaminated test environment) was identified. All three
were judged "no effect" while contaminated; the differential run afterward
showed two of the three are in fact load-bearing.

**L0 — as shipped (T3+T4 only).** N1 green rep1+rep2, contaminated `HOME`: 0
proposals, 0 dispatches, 0 research-language mentions in either transcript.
The fixture was independently judged fair: the agent itself laid out three
structurally different architectures (version vectors / CRDT / three-way
merge) and picked one from memory without proposing to check any of them.
Rep2 asserted, unchecked: *"brak dojrzałej biblioteki w czystym Pythonie,
trzeba by pisać własny"* ("no mature library in pure Python exists, you'd
have to write your own") — exactly the class of claim a research subagent is
meant to verify (source: `green-n1-rep2-t2.jsonl`).

**L1 — `31a434b`** (mandate the proposal + Red Flags table of observed
rationalizations, in `skills/brainstorming/SKILL.md`). N1 rep3, contaminated
`HOME`: 0 proposals, 0 dispatches. Unchanged.

**L2 — `f9c5d50`** (require an emitted per-decision "Research verdict" line
in the same message where clarifying questions end). N1 rep4, contaminated
`HOME`: 0 proposals, 0 dispatches, and critically, **no verdict line was ever
emitted** — the instruction to write one line per open decision produced no
output at all. N3 control (`rep1` during L1, `rep2` during L2) stayed clean
2/2 across both iterations: no regression from either lever.

**Structural observation at this point:** the agent ends turn 1 on its first
clarifying question and never verbalizes the step-5 research decision, so
there was no moment for either mandate to bind.

**Contamination hypothesis.** The nested `claude -p` sessions inherit this
machine's global `~/.claude/CLAUDE.md`, which mandates "Be extremely
concise", "Answer first", and forbids meta-narration — a deep-research
proposal is precisely a meta/process message and is token-expensive by the
skill's own text. Evidence the file was in fact inherited: every nested
session answers in Polish, which comes from that same global file, in every
transcript across both fixtures.

**Test:** N1 rep5, re-run with `HOME=/tmp/eval-home` (a copy of `~/.claude`
with `CLAUDE.md` removed, `.gitconfig` kept), same scenario that had produced
0/4 under contamination. Result: **the skill fires exactly as specified** —
per-decision "Werdykt badawczy" naming the criterion for each of the 3 open
decisions, a 3-subagent per-decision proposal as its own message, cost
stated, acceptance requested, trim offered, dispatch `0` (correctly waiting).
It also surfaced a checkable fact unprompted: *"pycrdt/automerge-py są
bindingami do Rusta, nie pure-Python — może kolidować z D-002"* (source:
`green-n1-rep5-t2.jsonl`).

**This invalidates every GREEN measurement collected before this point**: v1
`feedmix` R1–R4 (18 turns) and v2 `notekeep` N1/N3 L0–L2 (12 turns),
including both refactor verdicts above ("L1/L2 did not work"). RED baselines
are unaffected in kind (the unmodified skill has no tier at all to suppress)
but were also collected under the same contaminated environment.

**Differential (the key result).** With `HOME=/tmp/eval-home` held constant:
- N1 `rep6` on the plan's **original text** (skill reverted to `6112338`,
  i.e. T3+T4 only, L1+L2 absent): **no proposal**. The agent ran a quick web
  check itself (cites Joplin, `pycrdt`, `python3-crdt`) and presented three
  approaches with a recommendation and sources.
- N1 `rep5` (already run above) on **T3+T4+L1+L2**: full correct proposal.

**Conclusion:** `31a434b` (mandate + Red Flags table) and `f9c5d50` (explicit
per-decision research verdict) **are** the working change. Their earlier
"failed" verdicts (L1, L2 above) were measurement artifacts of the
contaminated environment, not evidence the wording is inert.

**n1 `rep7`** (isolated `HOME`, HEAD skill): verdict not reached in 2 turns —
the agent was still asking clarifying questions at the end of turn 2. Turn
budget issue, not a tier failure; folded into the script realignment below.

**n4 `rep1`** (isolated `HOME`, pre-realignment script): no proposal within
the 3 turns the old script ran before its scripted decline turn — the
decline answer landed in a vacuum with nothing to decline. **INVALID, not
FAIL.**

**n2 `rep1`** (isolated `HOME`, pre-realignment script): the script diverged
at t2 — the trim answer was read by the agent as rejecting a transport option
rather than accepting a research proposal. But at t3 the skill **proposed
research in per-approach mode** — 3 subagents, one per sketched architecture
sketch, mode named (*"tryb per-approach"*), count named, cost stated, trim
offered, nothing dispatched pending acceptance. This is the mode the plan's
Scenario Overview listed as not exercised by any of the four v1 scenarios;
dispatch never happened only because the acceptance turn had already been
consumed two turns earlier by the divergence. See **N2 — per-approach mode**
note above for the exact quote (`green-n2-rep1-t3.jsonl`).

**Structural defect found in all four v2 scripts:** they assumed the
proposal arrives 1–2 turns earlier than it does. The number of
clarifying-question rounds before the verdict varies per run (1 round in
rep5, 2–3 rounds in rep7/n2-rep1), so a fixed-turn script cannot align on a
single number. **Fix (commits `1d36252`, `a156bf7`):** `prompt-n1.md`
pre-answers the two clarifying questions the agent reliably asks (transport
medium, note granularity), two generic "absorber" turns were added that
resolve any clarifying round without reading as accept or decline of a
research proposal, and the runner loop was extended (`for T in 2 3 4 5` →
`for T in 2 3 4 5 6 7 8`). Re-measured: N1 `rep8`, N3 `rep3` (reused, no
change needed), N4 `rep2`, N2 `rep2` — results in **GREEN results** above,
all PASS.

**A third fix was attempted and reverted.** Commit `1581bac` ("bind the
single-message dispatch rule", strengthening `research-subagents.md`'s
`## Dispatching` section) was made against an apparent defect: N2 `rep2` t4
appeared, by row-counting the `stream-json` output, to dispatch its 2
`Agent` calls in two separate assistant messages — i.e. sequentially rather
than in parallel. `1581bac` was written to close that. Applying it and
re-running as N2 `rep3` did not change the row-count pattern. Grouping by
`.message.id` instead of counting rows then showed **both dispatches in N2
`rep2` t4 AND both in N2 `rep3` t4 share a single message id** — they had
always been issued in one message, concurrently. The "sequential dispatch"
finding was a measurement artifact (`stream-json` emits one assistant event
per content block, so two tool calls in the same message appear as two
separate assistant rows). `1581bac` fixed a defect that never existed, and
its own fixer report (`.superpowers/sdd/task-10-report.md`) independently
flagged that it pushed the D-031 read-only paragraph further down the file
for no behavioral gain. **Reverted** same day (`50c0e0b`);
`research-subagents.md` is back to the plan's verbatim 163 lines
(`cd1d9ec`'s content, confirmed by the file being back at its original line
count).

**Working skill (final state, this doc's evidence basis) = T3 (`cd1d9ec`) +
T4 (`6112338`) + L1 (`31a434b`) + L2 (`f9c5d50`) + the final-review digraph
fix (`579eb48`).** `research-subagents.md` is unmodified from T3. V2's firing
path (N1/N2) was measured on the state before `579eb48`; the control path was
re-measured after it (N3 rep4), and the firing path was re-measured by V3's
four N1 reps at HEAD `ccd917e` — see *Not exercised / not established*.

## Method corrections

Two measurement bugs were found and corrected mid-campaign. Both are
recorded here as guidance for whoever measures this tier again.

**Bug 1 — wrong dispatch-tool name in v2.** RED and the v1 GREEN suite
verified there is no `Task`/`Agent`-shaped tool in the harness's inventory at
all (0 dispatches everywhere), so `grep -c '"name":"Task"'` correctly read
`0` throughout v1. In the v2 nested sessions, the actual dispatch tool is
named **`Agent`**, not `Task`. Every `grep -c '"name":"Task"'` count run
against a v2 transcript before this was found was **structurally blind** — it
would have read `0` even on a transcript that dispatched subagents. v1's
recorded zeros remain valid regardless (the Task-2 reviewer inventoried tool
names directly and found neither `Task` nor `Agent` in any v1 transcript).
**Guidance:** never assume the tool name; re-derive it per harness/session
type with
`jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' <file>.jsonl | sort -u`
on a transcript already known to have dispatched something, before trusting
any dispatch count on that harness.

**Bug 2 — `stream-json` row-counting over-counts messages.** `stream-json`
emits one `assistant` event per content block, not one per model turn. A
single assistant message containing 2 `tool_use` blocks appears as 2 separate
rows in the stream. Counting rows (or grepping tool names as a flat list)
cannot distinguish "2 dispatches in 1 message" (concurrent) from "2
dispatches in 2 messages" (sequential) — the exact distinction the
single-message dispatch rule depends on. **Correct idiom:** group by
`.message.id`:

```
jq -r 'select(.type=="assistant") | .message as $m
       | ($m.content[]? | select(.type=="tool_use" and .name=="Agent") | $m.id)' \
   <file>.jsonl | sort | uniq -c
```

A single message id with count N means N concurrent dispatch calls in one
message; more than one distinct id among the dispatch tool_use blocks means
sequential dispatch. This is how N2 `rep2` t4 and `rep3` t4 were confirmed to
each carry both dispatches under one `message.id`.

## Not exercised / not established

- **The v1 `feedmix` suite never demonstrates the deep-research tier
  firing**, in any of its 4 scenarios or 18 GREEN turns, under the shipped
  skill (T3+T4) or under contamination. Root cause: D-001/D-002 collapse the
  backend choice to a single candidate (SQLite FTS5), so the research
  question the fixture was built around is only nominally open, and the
  skill's own text correctly forbids proposing research for a decision an
  active D-entry already settles. v1's evidentiary value is limited to "no
  regression on R3" and "the tier is not falsely triggered on a
  well-constrained fixture" — it says nothing about whether the tier fires
  when it should.
- **No scenario in either fixture runs without a `CONTEXT.md`.** Every
  scenario (v1 and v2) supplies a `registries/context.md` with active
  D-entries. Behavior when no project registry exists at all — whether the
  deep tier's openness/no-D-entry-settles-it filter degrades gracefully — is
  not measured anywhere in this eval.
- **Every V1/V2 result reported as PASS was obtained with `HOME` pointed at
  an isolated copy of `~/.claude` with `CLAUDE.md` removed.** V3 closes this
  on this machine only: N1 4/4 plus N2/N4/N3 1/1 each under the real `HOME`,
  after the operator's exemption bullet (V3, V3b). Still open: behavior under
  a *different* user's global instructions is untested, and every non-N1
  scenario is n=1 there. What remains
  established as a real limitation: a concision/no-meta-narration global
  instruction suppresses the tier entirely unless it carves out
  skill-mandated messages (0/30 proposals before the carve-out; see V3).
  Anyone relying on this feature under strict global style instructions
  should check their own file rather than assume it fires.
- **n=1 per scenario for every v2 verdict reported as PASS** (N1 `rep8`, N3
  `rep3`, N4 `rep2`, N2 `rep2` + 1 confirmatory rerun `rep3`). V3 raises N1
  alone to n=4, but only under the amended global `CLAUDE.md`; for N2, N3 and
  N4 no variance data exists at the final skill state. The campaign's earlier
  reps (rep1–rep7 for N1) were run under different conditions (contaminated
  HOME, different skill state, or a pre-realignment script) and are not
  independent replications of the final result.
- **The skill state the V2 N1/N2/N4 PASSes were measured against is not the
  current HEAD.** `579eb48` (Process Flow digraph edit) landed after those
  runs. It has since been measured on both paths: the control path by N3
  `rep4` (n=1) and the firing path by V3/V3b (N1 ×4, N2/N4/N3 ×1 each) — all
  of which also carry the amended global `CLAUDE.md`, so HEAD has **no**
  measurement under an isolated `HOME`.
- **v2 N4's decline path is n=1** and, unlike v1 R4, actually exercises the
  decline (the proposal existed to decline). It has not been repeated.
- **The per-approach proposal mode** (as opposed to per-decision) has never
  been a designed scenario — no fixture selects for it. It has been observed
  three times unprompted: once as a side effect of a script divergence in `n2
  rep1`, and twice in V3 (`realhome rep2`, `rep3`), each time with the same
  shape (subagent count, cost, trim offer). Which mode a run picks is
  therefore uncontrolled; there is no scenario that forces one and asserts
  against it.
- **Turn-budget sensitivity is real but uncharacterized.** `n1 rep7` shows
  the number of clarifying-question rounds before the verdict is not fixed
  (1 round in some runs, 2+ in others); the realigned scripts route around
  this with pre-answers and absorber turns rather than establishing the
  actual distribution.
