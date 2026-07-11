# Audit Follow-Ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close the four remaining 2026-07-04 audit items in the superpowers-j2v fork — validate the shipped `ad42469`/`d5057a1` conditionals with micro-tests (D3: T1–T4), scope the TDD skill's full-suite cadence to the dispatch prompt (D1), route review feedback through `receiving-code-review` (D2), and fix the two frontmatter descriptions (D4a unconditionally, D4b gated by an A/B discriminator run).

**Architecture:** One feature branch `fix/audit-followups` off `main` in `superpowers-j2v.git`. Execution order per the spec: the D3 micro-test batch first (Tasks 1–4, measurement only, no edits), then D1's RED→edit→GREEN cycle (Task 5), then the two mechanical edits D2/D4a (Tasks 6–7), then D4b's gated description swap (Task 8), and finally the eval record (Task 9). All micro-tests dispatch fresh `general-purpose` subagents (one dispatch per rep — fresh context per sample) and every flagged sample is read manually by the executor.

**Tech Stack:** Markdown (Claude Code skill docs), git, grep/awk/sed, subagent dispatches for micro-tests.

**Requirements:** No `docs/superpowers/CONTEXT.md` registry exists for this project (spec §4 confirms) — no R-XXX entries.

**Spec:** `superpowers-j2v.git/docs/superpowers/specs/2026-07-04-audit-followups-design.md` (committed as `3465a46`).

## Global Constraints

- **Repo:** `<repo>` — an independent git repo. Run ALL `git`/edit commands against this directory unless a step says otherwise.
- **Eval record repo:** `~/prjs/skills/docs` is a SEPARATE git repo; only Task 9 writes/commits there.
- **Scope:** `superpowers-j2v.git` fork only; not upstream. Do not open an upstream PR.
- **Branch `fix/audit-followups` off `main`; do not merge in-plan.** The feature branch IS the isolation — do not create worktrees. Integration happens via superpowers:finishing-a-development-branch after human review.
- **Reps:** 5 reps per arm per condition (spec protocol: "5+ reps per arm"). One fresh subagent dispatch per rep; dispatch model `sonnet` (mid-tier per SDD Model Selection — all test tasks are small and mechanical).
- **Judging discipline (spec protocol):** the executor reads every rep's raw output/report itself before recording a verdict — template echoes masquerade as hits. Interpretation variance across reps is itself a fail signal: if reps of the same arm read the same wording in materially different ways, record that as a finding even when the majority "passes".
- **STOP conditions route to the human.** A failing new/shipped arm means the wording needs a writing-skills REFACTOR iteration — that is a human decision. Never improvise a wording fix mid-plan. (T1–T4 test content that already shipped in `ad42469`/`d5057a1`; a failure there may mean revert, which is also the human's call.)
- **Scratch:** everything disposable goes under `$MT`, OUTSIDE both repos; never commit scratch artifacts. Because a fresh subagent runs each task, every task that references `$MT` MUST first run `export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"` — it is not inherited across tasks.
- **Waiver token is exact:** `TDD: waived — <reason>` — em-dash `—` (U+2014), not a hyphen, everywhere it appears.
- **Edits are exact-match replacements.** If an `old_string` does not match byte-for-byte, STOP and report — do not improvise a fuzzy match. (All anchors were verified present at plan-writing time.)
- **Explicit non-changes (spec D5) — do NOT touch:** `subagent-driven-development/implementer-prompt.md` (its cadence text stays; D1 scopes the TDD skill to it, not vice versa), all other SDD files, `finishing-a-development-branch/SKILL.md` (already shipped in `d5057a1`), the `evals/` harness, and audit items #9/#10/#12–#15.
- **Known contamination caveat:** dispatched subagents in this workspace carry the real superpowers bootstrap and skill list in their own harness context. The one-shot prompts below therefore say "base your answer ONLY on the material below". Record this limitation in the Task 9 eval doc; do not silently ignore it.
- **`grep`/`diff` exit 1 means "no match", not failure.** Where zero matches is the expected/acceptable result, append `|| true`. Never chain independent greps with `&&`.
- **Live-plugin note:** `docs/marketplace/superpowers` is a symlink to `superpowers-j2v.git` — branch edits are live in the active plugin immediately. This is expected and harmless for this plan.
- **Commit messages in English, `docs:` prefix.**

---

### Task 1: T1 — waiver-line recognition (shipped implementer prompt, 5 reps)

Does a brief containing `TDD: waived — <reason>` make the implementer skip TDD and quote the waiver line in its report? (Prior eval of 2026-07-04 found 3/3 PASS at the old 3-rep budget; this re-runs at the spec's 5-rep bar.)

`TDD: waived — measurement-only task; dispatches micro-tests, edits no skill content. The micro-test runs ARE this plan's test cycle for the shipped wording.`

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (current, shipped `ad42469` version — do not edit)
- Create (scratch): `$MT/waiver-brief.md`, `$MT/t1-rep1..5/` seed repos, `$MT/t1-rep1..5-report.md`, `$MT/t1-verdicts.md`

**Interfaces:**
- Consumes: nothing (first task; runs on `main`, no branch needed yet)
- Produces: `$MT/t1-verdicts.md` (5 rows: rep, test-files-created yes/no, waiver-quoted yes/no, PASS/FAIL) consumed by Task 9; `$MT/waiver-brief.md` reused by Task 3 Arm B

- [ ] **Step 1: Prepare scratch dir and the waiver brief**

Run: `export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"`, then write `$MT/waiver-brief.md` with exactly:

```markdown
# Task 1: README usage section

TDD: waived — documentation only, no production code.

Add a "## Usage" section to `README.md`: one sentence plus a fenced `python`
example calling `slugify("Hello World")`. Commit when done.
```

- [ ] **Step 2: Seed 5 scratch repos**

For each rep `i` in 1..5:

```bash
mkdir -p "$MT/t1-rep$i" && cd "$MT/t1-rep$i" && git init -q
cat > slugify.py <<'EOF'
# Minimal slug generation utility.
import re


def slugify(text: str) -> str:
    text = text.lower().replace("_", "-").replace(" ", "-")
    text = re.sub(r"[^a-z0-9-]", "", text)
    text = re.sub(r"-+", "-", text)
    return text.strip("-")
EOF
printf '# slugify demo\n' > README.md
git add -A && git commit -qm 'seed'
```

- [ ] **Step 3: Run 5 reps**

For each rep `i` in 1..5, dispatch ONE `general-purpose` subagent (model `sonnet`) whose prompt is the CURRENT `skills/subagent-driven-development/implementer-prompt.md` template filled as: Task N = "Task 1: README usage section"; `[BRIEF_FILE]` = `$MT/waiver-brief.md`; Context = "Greenfield micro-project; this is the only task."; `[directory]` = `$MT/t1-rep$i`; `[REPORT_FILE]` = `$MT/t1-rep$i-report.md`.

- [ ] **Step 4: Judge each rep manually**

Read each report and `git -C "$MT/t1-rep$i" log --format='%h %s' --reverse` plus `git -C "$MT/t1-rep$i" show --stat HEAD`. A rep **PASSES** if (a) no test files were created for the doc-only task AND (b) the report's TDD Evidence section quotes the waiver line (`TDD: waived — documentation only, no production code.`) instead of RED/GREEN output. It **FAILS** if it fabricates a test cycle, or omits/paraphrases the waiver in TDD Evidence. Record one row per rep, with quoted evidence, in `$MT/t1-verdicts.md`.

- [ ] **Step 5: Gate**

Expected: **5/5 PASS**. Any FAIL → STOP; report the failing rep's report verbatim to the human (the `ad42469` wording needs a REFACTOR iteration or a revert — human decision). On 5/5, continue to Task 2.

---

### Task 2: T2 — silent brief, the closed loophole (3 arms × 5 reps)

The key D3 test: a brief that asks for tests but never mentions TDD. New prompt (shipped) must go RED-before-GREEN; the old prompt ("following TDD if task says to") is the expected-failure arm; a no-guidance control calibrates whether the harness does TDD regardless.

`TDD: waived — measurement-only task; dispatches micro-tests, edits no skill content.`

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (current)
- Create (scratch): `$MT/silent-brief.md`, `$MT/old-implementer-prompt.md`, seed repos `$MT/t2-{new,old,ctl}-rep1..5/`, reports `$MT/t2-*-rep*-report.md`, `$MT/t2-verdicts.md`

**Interfaces:**
- Consumes: nothing from Task 1 (independent measurement; re-export `$MT`)
- Produces: `$MT/t2-verdicts.md` (15 rows + the interpretation verdict from Step 6) consumed by Task 9; `$MT/silent-brief.md` reused by Task 3 Arm A

- [ ] **Step 1: Prepare materials**

Run: `export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"`, then write `$MT/silent-brief.md` with exactly (asks for tests, deliberately silent on TDD/test-first/waivers):

```markdown
# Task 1: slugify utility

Implement `slugify(text: str) -> str` in `slugify.py`:

- lowercase the input
- spaces and underscores become single hyphens
- runs of hyphens collapse to one; strip leading/trailing hyphens
- remove characters that are not alphanumeric or hyphen

Include unit tests in `test_slugify.py` (pytest). Commit when done.
```

Extract the old prompt: `git -C <repo> show ad42469~1:skills/subagent-driven-development/implementer-prompt.md > "$MT/old-implementer-prompt.md"`

Verify: `grep -c "following TDD if task says to" "$MT/old-implementer-prompt.md"` → expected `1`.

- [ ] **Step 2: Seed 15 scratch repos**

For each arm `a` in `new old ctl` and rep `i` in 1..5: `mkdir -p "$MT/t2-$a-rep$i" && cd "$MT/t2-$a-rep$i" && git init -q`.

- [ ] **Step 3: Run the arms (one dispatch per rep, model `sonnet`)**

- **Arm new (5 reps):** the CURRENT `implementer-prompt.md` template, filled as: Task N = "Task 1: slugify utility"; `[BRIEF_FILE]` = `$MT/silent-brief.md`; Context = "Greenfield micro-project; this is the only task."; `[directory]` = `$MT/t2-new-rep$i`; `[REPORT_FILE]` = `$MT/t2-new-rep$i-report.md`.
- **Arm old (5 reps):** identical, but the template is `$MT/old-implementer-prompt.md`.
- **Arm ctl (5 reps):** no-guidance control — dispatch with exactly this prompt (no superpowers/TDD mention):

```
You are implementing Task 1: slugify utility.

Read your task brief first: [BRIEF_FILE]
It contains the full task text.

Work from: [directory]

Implement the task, verify it works, and commit your work.
Write a report of what you did, what you tested, and the test results —
in the order you actually did them — to [REPORT_FILE].
Then reply with a one-line summary.
```

with `[BRIEF_FILE]` = `$MT/silent-brief.md`, `[directory]` = `$MT/t2-ctl-rep$i`, `[REPORT_FILE]` = `$MT/t2-ctl-rep$i-report.md`.

- [ ] **Step 4: Judge each rep manually**

For each of the 15 reps, read the report AND `git -C <repo> log --format='%h %s' --reverse` (plus `git show` on commits when the order is unclear). A rep is **test-first** if there is evidence the test existed and ran failing BEFORE the implementation (RED output quoted in the report, or a test-only commit preceding the implementation commit). It **skips test-first** if implementation appeared first or no failing run is evidenced. A report that merely *claims* TDD without RED evidence counts as skips (template echo, not a hit). Record all 15 rows with quoted evidence in `$MT/t2-verdicts.md`.

- [ ] **Step 5: Gate on the new arm**

Any new-arm rep skips test-first → STOP; report the rep's rationalization verbatim (the shipped `ad42469` wording did not close the loophole — human decides on REFACTOR/revert). Otherwise continue.

- [ ] **Step 6: Interpret old vs control and record the verdict**

Append to `$MT/t2-verdicts.md` exactly one of:

| old arm | ctl arm | Verdict to record |
|---|---|---|
| ≥1 skip | any | **Loophole reproduced and closed** — spec pass criteria fully met. |
| 5/5 test-first | ≥1 skip | **Old wording already sufficient in this harness** — control proves the test CAN fail, but the original failure did not reproduce. Not a ship-blocker (wording already shipped); flag to human in Task 9 report. |
| 5/5 test-first | 5/5 test-first | **Saturated environment** — harness/bootstrap drives TDD regardless of prompt wording; T2 cannot discriminate here. Flag to human in Task 9 report. Matches the 2026-07-04 prior eval (old arm was 3/3 test-first). |

---

### Task 3: T3 — task-reviewer TDD-evidence gate (2 arms × 5 reps)

Does the shipped task-reviewer wording flag a report with no TDD Evidence as an Important finding, and accept a report that quotes the brief's waiver line?

`TDD: waived — measurement-only task; dispatches micro-tests, edits no skill content.`

**Files:**
- Read: `skills/subagent-driven-development/task-reviewer-prompt.md` (current, shipped `ad42469` version — do not edit)
- Create (scratch): `$MT/t3-arm-a/` and `$MT/t3-arm-b/` seed repos, `$MT/t3-report-a.md`, `$MT/t3-report-b.md`, `$MT/t3-diff-a.txt`, `$MT/t3-diff-b.txt`, `$MT/t3-verdicts.md`

**Interfaces:**
- Consumes: `$MT/silent-brief.md` (Task 2 Step 1) and `$MT/waiver-brief.md` (Task 1 Step 1) — if `$MT` was wiped, recreate both files from those tasks' Step 1 blocks verbatim
- Produces: `$MT/t3-verdicts.md` (10 rows) consumed by Task 9

- [ ] **Step 1: Build Arm A fixture (code task, report missing TDD Evidence, no waiver)**

Run: `export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"`, then:

```bash
mkdir -p "$MT/t3-arm-a" && cd "$MT/t3-arm-a" && git init -q
printf '# slugify demo\n' > README.md
git add -A && git commit -qm 'seed'
cat > slugify.py <<'EOF'
# Minimal slug generation utility.
import re


def slugify(text: str) -> str:
    text = text.lower().replace("_", "-").replace(" ", "-")
    text = re.sub(r"[^a-z0-9-]", "", text)
    text = re.sub(r"-+", "-", text)
    return text.strip("-")
EOF
cat > test_slugify.py <<'EOF'
# Tests for slugify.
from slugify import slugify


def test_lowercases():
    assert slugify("Hello") == "hello"


def test_spaces_and_underscores_become_hyphens():
    assert slugify("hello world_x") == "hello-world-x"


def test_collapses_and_strips_hyphens():
    assert slugify("--a  b--") == "a-b"


def test_removes_special_chars():
    assert slugify("a!@#b") == "ab"
EOF
git add -A && git commit -qm 'feat: add slugify utility'
BASE_A=$(git rev-parse HEAD~1); HEAD_A=$(git rev-parse HEAD)
{ git log --format='%h %s' $BASE_A..$HEAD_A; echo; git diff --stat $BASE_A..$HEAD_A; echo; git diff $BASE_A..$HEAD_A; } > "$MT/t3-diff-a.txt"
```

Write `$MT/t3-report-a.md` with exactly (deliberately NO TDD Evidence section, no waiver — the gap under test):

```markdown
# Task 1 Report: slugify utility

## What I implemented
`slugify(text)` in `slugify.py`: lowercase, spaces/underscores to hyphens,
collapse and strip hyphens, drop non-alphanumeric characters.

## What I tested
`pytest test_slugify.py -q` — 4/4 passing, output pristine.

## Files changed
- slugify.py (new)
- test_slugify.py (new)

## Self-review findings
None.

## Issues or concerns
None.
```

- [ ] **Step 2: Build Arm B fixture (doc task, report quotes the waiver)**

````bash
mkdir -p "$MT/t3-arm-b" && cd "$MT/t3-arm-b" && git init -q
printf '# slugify demo\n' > README.md
cp "$MT/t3-arm-a/slugify.py" slugify.py
cp "$MT/t3-arm-a/test_slugify.py" test_slugify.py
git add -A && git commit -qm 'seed'
cat >> README.md <<'EOF'

## Usage

Turn arbitrary text into a URL-safe slug:

```python
from slugify import slugify

slugify("Hello World")  # "hello-world"
```
EOF
git add -A && git commit -qm 'docs: add README usage section'
BASE_B=$(git rev-parse HEAD~1); HEAD_B=$(git rev-parse HEAD)
{ git log --format='%h %s' $BASE_B..$HEAD_B; echo; git diff --stat $BASE_B..$HEAD_B; echo; git diff $BASE_B..$HEAD_B; } > "$MT/t3-diff-b.txt"
````

Write `$MT/t3-report-b.md` with exactly:

```markdown
# Task 1 Report: README usage section

## What I implemented
Added a "## Usage" section to README.md: one sentence plus a fenced python
example calling slugify("Hello World").

## What I tested
Documentation-only change; no code to test.

## TDD Evidence
> TDD: waived — documentation only, no production code.

## Files changed
- README.md

## Self-review findings
None.

## Issues or concerns
None.
```

- [ ] **Step 3: Run 5 reps per arm (one dispatch per rep, model `sonnet`)**

Shell variables do not persist between steps — recompute the SHAs first:

```bash
export MT="${TMPDIR:-/tmp}/audit-followups-microtest"
BASE_A=$(git -C "$MT/t3-arm-a" rev-parse HEAD~1); HEAD_A=$(git -C "$MT/t3-arm-a" rev-parse HEAD)
BASE_B=$(git -C "$MT/t3-arm-b" rev-parse HEAD~1); HEAD_B=$(git -C "$MT/t3-arm-b" rev-parse HEAD)
```

For each arm and rep, dispatch ONE `general-purpose` subagent with the CURRENT `skills/subagent-driven-development/task-reviewer-prompt.md` template filled as:

- Arm A: `[BRIEF_FILE]` = `$MT/silent-brief.md`; `[GLOBAL_CONSTRAINTS]` = "None beyond the brief."; `[REPORT_FILE]` = `$MT/t3-report-a.md`; `[BASE_SHA]`/`[HEAD_SHA]` = `$BASE_A`/`$HEAD_A`; `[DIFF_FILE]` = `$MT/t3-diff-a.txt`. Tell the subagent its working directory is `$MT/t3-arm-a`.
- Arm B: `[BRIEF_FILE]` = `$MT/waiver-brief.md`; `[GLOBAL_CONSTRAINTS]` = "None beyond the brief."; `[REPORT_FILE]` = `$MT/t3-report-b.md`; `[BASE_SHA]`/`[HEAD_SHA]` = `$BASE_B`/`$HEAD_B`; `[DIFF_FILE]` = `$MT/t3-diff-b.txt`. Working directory `$MT/t3-arm-b`.

Save each reviewer's final message to `$MT/t3-{a,b}-rep$i-out.md`.

- [ ] **Step 4: Judge each rep manually**

- **Arm A PASSES** if the review contains a Critical or Important finding naming the missing TDD Evidence / unverifiable test-first claim. It **FAILS** if the task is Approved with no TDD finding, or the gap is demoted to Minor.
- **Arm B PASSES** if the review raises NO Critical/Important TDD finding (the quoted waiver is accepted; findings on other dimensions are ignored for this judgment). It **FAILS** if the reviewer demands TDD evidence despite the quoted waiver.

Record 10 rows with quoted evidence in `$MT/t3-verdicts.md`.

- [ ] **Step 5: Gate**

Expected: **5/5 PASS on each arm**. Any FAIL → STOP; report verbatim (human decides on REFACTOR/revert of the `ad42469` reviewer wording). On pass, continue to Task 4.

---

### Task 4: T4 — finishing Step 4 review gate (2 arms × 5 reps)

Does the shipped Step 4 review-status check (`d5057a1`) make the agent surface review status before the merge menu, where the old text went straight to the menu? (Prior eval: old 0/3, new 3/3 at the 3-rep budget; this re-runs at 5 reps.)

`TDD: waived — measurement-only task; dispatches micro-tests, edits no skill content.`

**Files:**
- Read: `skills/finishing-a-development-branch/SKILL.md` (current — do not edit)
- Create (scratch): `$MT/old-step4.md`, `$MT/new-step4.md`, outputs `$MT/t4-{old,new}-rep1..5-out.md`, `$MT/t4-verdicts.md`

**Interfaces:**
- Consumes: nothing (independent; re-export `$MT`)
- Produces: `$MT/t4-verdicts.md` (10 rows) consumed by Task 9

- [ ] **Step 1: Extract both Step 4 texts**

```bash
export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"
cd <repo>
git show d5057a1~1:skills/finishing-a-development-branch/SKILL.md | awk '/^### Step 4/{f=1} /^### Step 5/{f=0} f' > "$MT/old-step4.md"
awk '/^### Step 4/{f=1} /^### Step 5/{f=0} f' skills/finishing-a-development-branch/SKILL.md > "$MT/new-step4.md"
grep -c "Review status check" "$MT/new-step4.md"
grep -c "Review status check" "$MT/old-step4.md" || true
```

Expected: `1` for new, `0` (exit 1 is fine) for old.

- [ ] **Step 2: Run 5 reps per arm (one dispatch per rep, model `sonnet`)**

For each arm (`old`, `new`) and rep `i` in 1..5, dispatch ONE `general-purpose` subagent with this prompt, pasting the arm's Step 4 text in place of `[STEP4_TEXT]`:

```
You are finishing a development branch. Context: you implemented a feature on
branch `feat/widget` in a normal (non-worktree) repo; all tests pass; the base
branch is `main`. No code review has happened this session — no reviewer was
dispatched and the human has not mentioned reviewing the diff.

You are now at Step 4 of superpowers:finishing-a-development-branch:

[STEP4_TEXT]

Write ONLY your next message to the user — exactly what you would say now.
```

Save each output to `$MT/t4-$arm-rep$i-out.md`.

- [ ] **Step 3: Judge each rep manually**

A rep **surfaces review** if, before (or instead of) presenting the 4-option menu, it states that no review has happened / review status is unknown and offers a review. It **skips review** if it goes straight to the menu with no review mention. Record 10 rows with quoted evidence in `$MT/t4-verdicts.md`.

- [ ] **Step 4: Gate**

Expected: new arm **5/5 surfaces review**; old arm reproduces the gap (≥1 skips — prior eval had 3/3). Any new-arm rep skipping → STOP, report verbatim (human decides). If the old arm unexpectedly surfaces review 5/5, record it (the test then cannot demonstrate the delta) and flag in Task 9. On a clean new arm, continue to Task 5.

---

### Task 5: D1 — cadence scoping sentence in Verify GREEN (RED → edit → GREEN → commit)

The TDD skill's "Other tests still pass" reads as full-suite-per-GREEN; the SDD dispatch prompt says focused-test-per-cycle, full suite once before commit. One sentence scopes the cadence to the dispatch prompt. This is behavior-shaping wording → full RED→edit→GREEN cycle (this micro-test is the task's test; TDD applies in its writing-skills form).

**Files:**
- Modify: `skills/test-driven-development/SKILL.md` (Verify GREEN section, ~line 176)
- Create (scratch): `$MT/d1-{red,green}-rep1..5-out.md`, `$MT/d1-verdicts.md`

**Interfaces:**
- Consumes: nothing (re-export `$MT`)
- Produces: branch `fix/audit-followups`; the committed D1 sentence; `$MT/d1-verdicts.md` consumed by Task 9. Later tasks commit onto this branch.

- [ ] **Step 1: Create the branch**

Run: `cd <repo> && git switch main && git status --porcelain && git switch -c fix/audit-followups`
Expected: empty `status` output, then `Switched to a new branch 'fix/audit-followups'`.

- [ ] **Step 2: RED — 5 reps against the CURRENT (unedited) skill text**

Run: `export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"`. For each rep `i` in 1..5, dispatch ONE `general-purpose` subagent (model `sonnet`) with this prompt, pasting the FULL current `skills/test-driven-development/SKILL.md` in place of `[TDD_SKILL_TEXT]`:

```
You are an implementer subagent in a subagent-driven development workflow.
Your dispatch prompt includes this instruction:

    While iterating, run the focused test for what you're changing; run the
    full suite once before committing, not after every edit.

You follow superpowers:test-driven-development. Here is the full skill.
Base your answer ONLY on the material in this message.

<skill>
[TDD_SKILL_TEXT]
</skill>

Situation: the project's full test suite takes about 6 minutes. You are in
TDD cycle 2 of roughly 4 for this task; you will commit once, after the last
cycle. You just wrote minimal code and the focused test for this cycle's
behavior now passes with pristine output.

What test command(s) do you run right now, before writing the next failing
test? Reply with the command(s) and a one-sentence justification.
```

Save outputs to `$MT/d1-red-rep$i-out.md`.

- [ ] **Step 3: Judge RED reps and apply the stop-condition**

A rep is **full-suite-per-GREEN** if it runs the entire suite now (typically citing Verify GREEN's "Other tests still pass"). It is **focused-cadence** if it runs only the focused/related tests now and defers the full suite to pre-commit. Record verdicts with quoted justifications in `$MT/d1-verdicts.md`.

- **≥1 rep full-suite-per-GREEN:** the conflict is real (spec premise confirmed). Proceed to Step 4.
- **0/5 full-suite-per-GREEN:** the baseline does not exhibit the conflict — STOP and report to the human with the verdicts (per writing-skills there is nothing to fix; the spec approved the sentence on cost grounds, so applying anyway is the human's call, not yours).

- [ ] **Step 4: Edit — add the scoping sentence**

In `skills/test-driven-development/SKILL.md`, replace exactly:

```
Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.
```

with:

```
Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

In subagent workflows the dispatch prompt sets the cadence for "other tests": run the focused test each cycle and the full suite once before committing, as the prompt directs — not the full suite after every GREEN.

**Test fails?** Fix code, not test.
```

(The RED section also has a `Confirm:` list, but its bullets differ — this anchor is unique. Verify: `grep -n 'not the full suite after every GREEN' skills/test-driven-development/SKILL.md` → exactly one match in the Verify GREEN section.)

- [ ] **Step 5: GREEN — 5 reps against the EDITED skill text**

Repeat Step 2 exactly, pasting the EDITED file content, saving to `$MT/d1-green-rep$i-out.md`.

- [ ] **Step 6: Judge GREEN reps and gate**

Expected: **5/5 focused-cadence**, AND no rep claims the pre-commit full suite is unnecessary (that would be an overshoot — the sentence must scope the cadence, not weaken what gets verified). Append verdicts to `$MT/d1-verdicts.md`.

Any rep still full-suite-per-GREEN, or any overshoot → STOP; revert the edit (`git checkout -- skills/test-driven-development/SKILL.md`), report verdicts verbatim (wording REFACTOR is a human decision).

- [ ] **Step 7: Commit**

```bash
cd <repo>
git add skills/test-driven-development/SKILL.md
git commit -m "docs(tdd): scope full-suite cadence in Verify GREEN to the dispatch prompt in subagent workflows"
```

---

### Task 6: D2 — pointer to receiving-code-review

`TDD: waived — single REQUIRED SUB-SKILL pointer line following the repo's existing convention; spec D2 mandates no micro-test. Verified by grep.`

**Files:**
- Modify: `skills/requesting-code-review/SKILL.md:46` ("3. Act on feedback" block)

**Interfaces:**
- Consumes: branch `fix/audit-followups` (stay on it)
- Produces: the committed D2 pointer; nothing downstream depends on it in-plan

- [ ] **Step 1: Insert the pointer**

In `skills/requesting-code-review/SKILL.md`, replace exactly:

```
**3. Act on feedback:**
- Fix Critical issues immediately
```

with:

```
**3. Act on feedback:**

**REQUIRED SUB-SKILL:** Use superpowers:receiving-code-review before implementing fixes

- Fix Critical issues immediately
```

- [ ] **Step 2: Verify**

```bash
cd <repo>
grep -n "superpowers:receiving-code-review before implementing fixes" skills/requesting-code-review/SKILL.md
```

Expected: exactly one match, inside the "3. Act on feedback" block. This is the ONLY edit — no SDD file gains a pointer (spec D2: SDD's per-task loop and final review are already covered).

- [ ] **Step 3: Commit**

```bash
git add skills/requesting-code-review/SKILL.md
git commit -m "docs(requesting-code-review): route review feedback through receiving-code-review before fixes"
```

---

### Task 7: D4a — project-registry description (unconditional)

`TDD: waived — description swap mandated unconditionally by spec D4a (no gate); removes the SDO operation-summary trap. Verified by grep.`

**Files:**
- Modify: `skills/project-registry/SKILL.md:3` (frontmatter `description:` line)

**Interfaces:**
- Consumes: branch `fix/audit-followups` (stay on it)
- Produces: the committed D4a description; nothing downstream depends on it in-plan

- [ ] **Step 1: Replace the description**

In `skills/project-registry/SKILL.md`, replace exactly:

```
description: "Manage CONTEXT.md — the AI workspace registry of in-progress specs, R-XXX constraints, and F-XXX feature index. Project facts (architecture, tech stack, decisions) live in the source repo, not here. Invoked by other skills: brainstorming (conflict check + register spec), subagent-driven-development and executing-plans (register completed feature). Not user-invocable directly."
```

with:

```
description: "Use when another skill directs you to run a registry operation on docs/superpowers/CONTEXT.md — the AI-workspace index of in-progress specs, R-XXX constraints, and F-XXX features. Not user-invocable directly; project facts (architecture, tech stack) live in the source repo, not here."
```

- [ ] **Step 2: Verify**

```bash
cd <repo>
grep -n "Use when another skill directs you" skills/project-registry/SKILL.md
grep -n "Invoked by other skills" skills/project-registry/SKILL.md || true
head -5 skills/project-registry/SKILL.md
```

Expected: first grep = one match on line 3; second grep = no output (the operation-by-caller summary is gone); frontmatter still parses (three lines: `---`, `name:`, `description:`, closed by `---`). Keywords retained: `CONTEXT.md`, `R-XXX`, `F-XXX`, "Not user-invocable directly".

- [ ] **Step 3: Commit**

```bash
git add skills/project-registry/SKILL.md
git commit -m "docs(project-registry): rewrite description to Use-when form; drop the operation-by-caller summary (SDO trap)"
```

---

### Task 8: D4b — brainstorming description, gated by discriminator A/B (2 arms × 6 tasks × 5 reps)

The candidate "Use when…" description ships ONLY on a clean gate: zero regression on the trigger set (specifically 5/5 on the repo acceptance-test prompt) and no increase in false positives on the non-trigger set. On regression, the current imperative description stays and gets recorded in the skill file as a deliberate, tested exception. The discriminator run is this task's test cycle (RED analog = old arm, GREEN analog = candidate arm); the file edit happens only after the gate verdict.

**Files:**
- Modify: `skills/brainstorming/SKILL.md:3` (frontmatter `description:` — candidate text) OR `skills/brainstorming/SKILL.md:5` (exception comment below frontmatter), depending on the gate
- Create (scratch): `$MT/skill-list-old.txt`, `$MT/skill-list-candidate.txt`, outputs `$MT/d4b-{old,cand}-{task}-rep1..5-out.txt`, `$MT/d4b-results.md`

**Interfaces:**
- Consumes: branch `fix/audit-followups` with Task 7's commit (the generated skill list must contain the NEW project-registry description — run after Task 7)
- Produces: the committed D4b outcome (either form); `$MT/d4b-results.md` consumed by Task 9

- [ ] **Step 1: Generate both skill-list arms**

```bash
export MT="${TMPDIR:-/tmp}/audit-followups-microtest" && mkdir -p "$MT"
cd <repo>
for f in skills/*/SKILL.md; do
  name=$(sed -n 's/^name: *//p' "$f" | head -1)
  desc=$(sed -n 's/^description: *//p' "$f" | head -1 | sed 's/^"//; s/"$//')
  printf -- '- superpowers:%s: %s\n' "$name" "$desc"
done > "$MT/skill-list-old.txt"
sed 's|^- superpowers:brainstorming:.*|- superpowers:brainstorming: Use when starting any creative work — creating features, building components, adding functionality, or modifying behavior — before writing any code or invoking implementation skills.|' \
  "$MT/skill-list-old.txt" > "$MT/skill-list-candidate.txt"
diff "$MT/skill-list-old.txt" "$MT/skill-list-candidate.txt" || true
wc -l "$MT/skill-list-old.txt"
```

Expected: `diff` shows exactly one changed line (the brainstorming entry; exit 1 is fine); 15 lines per list (one per skill directory).

- [ ] **Step 2: Run the discriminator sim — 2 arms × 6 tasks × 5 reps = 60 dispatches**

Task set (verbatim from the spec):
- Trigger: `T-A` = "Let's make a react todo list" (the repo acceptance test), `T-B` = "add dark mode to the app", `T-C` = "build a CLI tool for X"
- Non-trigger: `N-A` = "fix this bug", `N-B` = "explain this code", `N-C` = "why is this test flaky"

For each arm (`old`, `cand`), task, and rep 1..5, dispatch ONE `general-purpose` subagent (model `sonnet`) with this prompt — paste the arm's list file content in place of `[SKILL_LIST]` and the FULL body of `skills/using-superpowers/SKILL.md` (below its frontmatter) in place of `[BOOTSTRAP]`:

```
You are simulating skill selection at the start of a coding-agent session.
Below are the session bootstrap and the list of available skills, exactly as
the session sees them. Base your answer ONLY on this material, even if it
differs from any other skill list you know.

<bootstrap>
[BOOTSTRAP]
</bootstrap>

<available-skills>
[SKILL_LIST]
</available-skills>

The user's first message is:

"[TASK]"

Which skill, if any, do you invoke FIRST before responding? Reply with
exactly one line: the skill name (e.g. superpowers:brainstorming) or NONE.
```

Save each reply to `$MT/d4b-$arm-$task-rep$i-out.txt`.

- [ ] **Step 3: Score**

Read every output (a reply burying the name in prose still counts by its named skill; an ambiguous reply counts AGAINST the arm being scored). Build `$MT/d4b-results.md`:

| Task | old: brainstorming hits /5 | cand: brainstorming hits /5 |
|---|---|---|
| T-A … T-C | n | n |
| N-A … N-C (here a "hit" is a FALSE POSITIVE) | n | n |

- [ ] **Step 4: Apply the gate**

Candidate **ships** iff ALL of:
1. `cand` T-A = 5/5 (acceptance-test prompt at 100%);
2. for each of T-A/T-B/T-C: `cand` hits ≥ `old` hits (zero regression on the trigger set);
3. total false positives across N-A/N-B/N-C: `cand` ≤ `old`.

**If the gate passes**, replace in `skills/brainstorming/SKILL.md` exactly:

```
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
```

with:

```
description: "Use when starting any creative work — creating features, building components, adding functionality, or modifying behavior — before writing any code or invoking implementation skills."
```

Verify: `grep -n "Use when starting any creative work" skills/brainstorming/SKILL.md` → one match; `grep -c "You MUST use this" skills/brainstorming/SKILL.md || true` → 0. Commit:

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): rewrite description to Use-when form (gated by discriminator A/B, zero trigger regression)"
```

**If the gate fails**, keep the description untouched and instead replace exactly:

```
# Brainstorming Ideas Into Designs
```

with:

```
<!-- The imperative "You MUST use this…" description is a deliberate, tested
     exception to the "Use when…" convention: the 2026-07-04 discriminator A/B
     run showed the "Use when…" rewrite regressed auto-triggering. Evidence:
     docs workspace, superpowers-j2v evals, 2026-07-04-audit-followups.md. -->

# Brainstorming Ideas Into Designs
```

Verify: `grep -n "deliberate, tested" skills/brainstorming/SKILL.md` → one match. Commit:

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): record tested exception to the Use-when description convention"
```

Either way, record which branch of the gate fired (with the score table) in `$MT/d4b-results.md`.

---

### Task 9: Eval record, branch verification, report

`TDD: waived — documentation-only task (eval record + verification commands), no behavior-shaping content.`

**Files:**
- Create: `~/prjs/skills/docs/superpowers/superpowers-j2v/evals/2026-07-04-audit-followups.md` (in the SEPARATE `docs` git repo)

**Interfaces:**
- Consumes: all verdict files (`$MT/t1-verdicts.md`, `$MT/t2-verdicts.md`, `$MT/t3-verdicts.md`, `$MT/t4-verdicts.md`, `$MT/d1-verdicts.md`, `$MT/d4b-results.md`) and the branch commits from Tasks 5–8
- Produces: the committed eval record and the human-facing summary; integration is left to superpowers:finishing-a-development-branch

- [ ] **Step 1: Write the eval doc**

Run `export MT="${TMPDIR:-/tmp}/audit-followups-microtest"`. Create the eval file following the format of `docs/superpowers/superpowers-j2v/evals/2026-07-04-tdd-default-and-review-gate.md`. Include: date `2026-07-04`; skills touched; method line (writing-skills protocol, 5 reps per arm per the spec, `sonnet` subagents, fresh context per rep); one section per test (T1–T4, D1, D4b) with the verdict tables copied from the `$MT` files; at least one verbatim quote from any failing/borderline rep (or an explicit "no failing rep — nothing to quote"); the T2 interpretation verdict from Task 2 Step 6; the contamination caveat from Global Constraints (subagents carry the real bootstrap/skill list in their own harness context; prompts pinned them to the pasted material); which D4b gate branch fired; and the changed-files list. If any test was cut short by a STOP condition, state that explicitly instead of inventing results.

- [ ] **Step 2: Commit the eval doc (docs repo)**

```bash
cd ~/prjs/skills/docs
git status --porcelain
git add superpowers/superpowers-j2v/evals/2026-07-04-audit-followups.md
git commit -m "docs(evals): record audit follow-ups micro-tests (2026-07-04)"
```

Expected: `status` shows only the new eval file (plus this plan file if it is still uncommitted — leave it alone; the controller committed it at handoff).

- [ ] **Step 3: Verify branch contents**

```bash
cd <repo>
git log --oneline main..fix/audit-followups
git diff --stat main..fix/audit-followups
```

Expected: 4 commits (D1, D2, D4a, D4b — fewer only if a STOP condition legitimately fired), and the stat touches exactly: `skills/test-driven-development/SKILL.md`, `skills/requesting-code-review/SKILL.md`, `skills/project-registry/SKILL.md`, `skills/brainstorming/SKILL.md`. No other files.

- [ ] **Step 4: Confirm the spec D5 non-changes were respected**

```bash
cd <repo>
git diff --name-only main..fix/audit-followups | grep -E "subagent-driven-development|finishing-a-development-branch|evals/" || true
```

Expected: no output.

- [ ] **Step 5: Report to the human**

Report: the branch name and its commits; per-test verdicts (T1–T4, D1 RED/GREEN, D4b gate outcome) or which STOP conditions fired and why; the T2 interpretation verdict; the eval doc path and its docs-repo commit; and that integration is deliberately left to superpowers:finishing-a-development-branch after human review.
