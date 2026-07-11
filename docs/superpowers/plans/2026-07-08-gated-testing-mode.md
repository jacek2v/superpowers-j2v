# Gated Testing Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> **Workspace exception (overrides the default worktree flow):** execute this plan on a new branch `feat/gated-testing-mode` created **in the main checkout** of `<repo>` — do NOT create a separate worktree. Reason: `docs/marketplace/superpowers` is a symlink to that checkout, so it IS the live plugin; the eval scenarios (`claude -p` sessions) load skills through the plugin and must see the edited files. A worktree would test the wrong (unmodified) skills.

**Goal:** Add an explicitly-activated "Gated Testing" mode to six superpowers-j2v skills (+2 prompt templates) so TDD verification batches at per-phase RED/GREEN gates when tests run on a system CC cannot reach, with zero behavior change when the mode is not declared.

**Architecture:** Each skill file gains exactly one self-contained block (small upstream-merge surface). The `test-driven-development` block is the source of truth for activation, defaults, batch cycle, round format, valid-RED criteria and the round ledger; the other five blocks reference it and adapt their own workflow. Validation follows the fork's established eval method: scenario baselines (RED) on unmodified skills → edits (GREEN) → scenario re-runs + refactor loop, using real `claude -p` toy sessions plus subagent micro-tests.

**Tech Stack:** Markdown skills (superpowers-j2v fork), `claude -p` headless sessions (model `sonnet`), bash fixture runner, uv/pytest toy project, git.

**Requirements:** R-001..R-012 from `docs/superpowers/superpowers-j2v/CONTEXT.md` (Gated Testing Mode, spec `specs/2026-07-08-gated-testing-mode-design.md`). Traceability: R-001→T2/T10 (S3 control), R-002/R-003→T3, R-004→T3+T4, R-005→T3 (S1/S6), R-006→T3 (S1), R-007→T3+T5 (S2), R-008→T3+T5 (S2), R-009→T6 (S6), R-010→T7, R-011→T3/T5/T6 (ledger), R-012→T8 (S5).

## Global Constraints

Copy these into every dispatch; every task's requirements implicitly include them.

- **One self-contained block per skill file.** No edits outside the new block. Exceptions (sanctioned by the spec): `implementer-prompt.md` and `task-reviewer-prompt.md` each get exactly ONE inserted line inside an existing section. Frontmatter (`name:`/`description:`) of every skill stays untouched — conscious decision to keep the upstream merge surface minimal.
- **Fork voice:** "your human partner" (never "the user"); imperative, second person; English only. Match each file's existing heading style and tone.
- **Fork-only feature.** Never propose or prepare an upstream PR for these changes (upstream CLAUDE.md rejects fork-specific changes).
- **Commit style (fork repo):** `docs(<skill-name>): <imperative summary>` — matches `git log` convention.
- **Zero classic-mode regression (R-001):** without the literal heading `## Gated testing` in the project CLAUDE.md (or an in-session declaration), every modified skill must behave exactly as before. Every block therefore begins with its activation condition and states that without it the block does not apply.
- **Shared literals** — use these EXACT strings everywhere (tasks, fixtures, blocks). Any deviation is a bug:
  - Activation heading (project CLAUDE.md): `## Gated testing`
  - Override lines beneath the heading: `Runner: claude` (default runner: operator) and `Local subset: <command/filter>` (default: none — all tests gated). No other configuration exists.
  - Mode name in prose: `Gated Testing Mode`; cross-reference phrase: `superpowers:test-driven-development — Gated Testing Mode`
  - Round request block (5 lines):

    ```
    ROUND <n> — RED|GREEN, phase "<name>"
    Source:  <worktree root>
    Files:   <relative paths of files to copy>
    Command: <single short one-line command>
    Expected: <e.g. "6 failed, 0 errors — all new tests">
    ```

  - Round ledger: `.superpowers/rounds.md` at the repo root; append one line when a round is issued and one when its verdict is judged: `ROUND <n> RED|GREEN phase "<name>" — issued` / `ROUND <n> verdict: <what the output showed>`
  - Gate step titles in plans: `**Gate RED — phase "<name>"**` and `**Gate GREEN — phase "<name>"**`
  - Gated Iron Law text: `NO IMPLEMENTATION FOR A TASK BEFORE THE PHASE'S RED GATE CONFIRMS ITS TESTS FAIL FOR THE RIGHT REASON`
  - Dispatch marker line (sdd, gated phases): `Gated testing mode — local subset: <command or none>; gated tests run only at gates, by the controller.`
- **Multi-repo plan.** Tasks commit to different repos; never cross-commit:

  | Tasks | Repo | Path |
  |---|---|---|
  | T1, T2, T3 (eval doc), T10 | docs | `~/prjs/skills/docs` |
  | T3–T8, T10 (fixes) | fork | `<repo>` |
  | T9 | none (home auto-commit cron) | `~/.claude/CLAUDE.md` |
  | T11 | <gated project> workspace | `<gated project>` |

- **Eval method (fork precedent, `evals/2026-07-04-tdd-default-and-review-gate.md`):** writing-skills RED → edit → GREEN. Full scenarios = `claude -p` toy sessions on `--model sonnet` with `--dangerously-skip-permissions` (isolated `/tmp` toy repos only), transcript saved as stream-json. Micro-tests = fresh `general-purpose` subagents on `sonnet`, one-shot, isolated `/tmp` repos. Budget: S1/S3 2 reps per phase, S2/S4/S5/S6 1 rep per phase (+re-runs after fixes), micro-test 5 reps per arm. Plan approval = human approval of this budget.
- **Nested `claude` / `uv sync` need network.** If a sandboxed shell blocks them, re-run that command unsandboxed. Expect 3–15 min per scenario run; use background execution and a `timeout` wrapper, never kill a run early.
- **Session-contamination warning:** eval sessions inherit the user's global config (plugins, `~/.claude/CLAUDE.md`) — this is intended (tests the shipped system). While `feat/gated-testing-mode` is checked out, other concurrent Claude sessions on this machine see in-progress skill edits; avoid parallel superpowers work until merge.
- **TDD for this plan:** skill edits ARE production code; their tests are the scenario suite. Per-edit scenario isolation is impossible (scenarios exercise several skills at once), so the RED phase is batched in T2 (baselines on unmodified skills) and the GREEN verification in T10 — mirroring the very batch cycle this feature implements. Tasks marked `TDD: batched — suite-level (T2 RED → T10 GREEN)` rely on that cycle; tasks with no testable artifact carry an explicit waiver.

## File Structure

| File | Change | Task |
|---|---|---|
| `docs/superpowers/superpowers-j2v/evals/gated-testing/` (new: fixtures, prompts, runner, transcripts) | Create | T1 |
| `docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` (eval results doc) | Create | T1 (skeleton), T2, T3, T10 |
| `superpowers-j2v.git/skills/test-driven-development/SKILL.md` | One block appended at end of file | T3 |
| `superpowers-j2v.git/skills/writing-plans/SKILL.md` | One block after "## TDD Is the Default; Waivers Are Explicit" | T4 |
| `superpowers-j2v.git/skills/executing-plans/SKILL.md` | One block after "### Step 2: Execute Tasks" | T5 |
| `superpowers-j2v.git/skills/subagent-driven-development/SKILL.md` | One block after "## Verification Contract" | T6 |
| `superpowers-j2v.git/skills/subagent-driven-development/implementer-prompt.md` | One line after "Work from: [directory]" | T6 |
| `superpowers-j2v.git/skills/subagent-driven-development/task-reviewer-prompt.md` | One line at start of "## Tests" section body | T6 |
| `superpowers-j2v.git/skills/verification-before-completion/SKILL.md` | One block after the existing verification-contract paragraph | T7 |
| `superpowers-j2v.git/skills/finishing-a-development-branch/SKILL.md` | One block inside "### Step 1: Verify Tests" | T8 |
| `~/.claude/CLAUDE.md` | Extend the strict-TDD bullet | T9 |
| `<gated project>/CLAUDE.md` | Remove old TDD-server bullet; add `## Gated testing` section | T11 |

## Scenario Overview (used by T1, T2, T10)

| ID | Tests | Setup | Core assertions |
|---|---|---|---|
| S1 | tdd + executing-plans, operator runner | Toy, no pytest locally. Baseline: old <gated project>-style CLAUDE.md line + classic plan. GREEN: `## Gated testing` + gated plan | (a) no implementation before Gate RED; (b) round request format |
| S2 | full batch cycle + valid-RED + re-rounds, `Runner: claude` | Toy with pytest, sabotaged `tests/factories.py` | (c) invalid RED detected → test-side fix → narrowed re-round; GREEN full-suite; RED-first commit order |
| S3 | control — classic mode | Toy with pytest, NO declaration, classic plan | (d) zero behavior change: classic TDD, no "ROUND" anywhere |
| S4 | writing-plans plan shape | Toy + declaration + toy-spec.md | plan has phases, gate steps with round blocks, test steps before Gate RED, no inline runs for gated tests |
| S5 | finishing-a-development-branch | Toy with completed feature, declaration, operator | Step 1 emits ONE final full-suite round request; no local test attempt (R-012) |
| S6 | subagent-driven-development | Toy like S1-GREEN, sdd execution | main agent dispatches test-writer, stops at Gate RED with round request; subagents never emit rounds (R-009) |

---

### Task 1: Eval scaffolding — toy fixtures, prompts, runner script

**Files:**
- Create: `docs/superpowers/superpowers-j2v/evals/gated-testing/` (all files below relative to it)
  - `base/pyproject-nopytest.toml`, `base/pyproject-pytest.toml`
  - `base/factories.py` (healthy), `base/factories-sabotaged.py`
  - `base/slugtool.py`, `base/test_slugify.py`, `base/test_truncate.py` (reference implementation + tests — S5 fixture and S2 oracle)
  - `claude-md/baseline.md`, `claude-md/gated-operator.md`, `claude-md/gated-runner-claude.md`, `claude-md/control.md`
  - `plans/plan-classic.md`, `plans/plan-gated.md`
  - `prompts/prompt-s1.md` … `prompts/prompt-s6.md`, `base/toy-spec.md`
  - `run-scenario.sh`, `transcripts/.gitkeep`
- Create: `docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` (skeleton)

**Interfaces:**
- Consumes: shared literals from Global Constraints (heading, round block, gate titles, ledger path).
- Produces: `run-scenario.sh <s1..s6> <baseline|green> [rep]` — assembles a toy repo in `/tmp`, runs `claude -p`, writes `transcripts/<phase>-<scenario>-rep<k>.jsonl`, prints the toy dir path on stdout (T2/T10 judge from the toy dir + transcript). Fixture file names above are consumed verbatim by the script's case-block.

`TDD: waived — test harness itself; every scenario run in T2/T10 exercises it.`

- [ ] **Step 1: Create the directory tree and toy Python fixtures**

`base/pyproject-nopytest.toml` (S1/S6: gated tests must be un-runnable locally):

```toml
[project]
name = "toyslug"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[tool.pytest.ini_options]
pythonpath = ["."]
```

`base/pyproject-pytest.toml` (S2/S3/S5): same plus dev group —

```toml
[project]
name = "toyslug"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = ["pytest>=8"]

[tool.pytest.ini_options]
pythonpath = ["."]
```

`base/factories.py` (healthy):

```python
# tests/factories.py -- shared test data builders
def make_long_text(words: int) -> str:
    return " ".join(["lorem"] * words)
```

`base/factories-sabotaged.py` (S2 — missing closing paren, guarantees a collection-time SyntaxError):

```python
# tests/factories.py -- shared test data builders
def make_long_text(words: int) -> str:
    return " ".join(["lorem"] * words
```

`base/slugtool.py` (reference implementation; S5 fixture):

```python
# slugtool.py -- toy slug utilities for gated-testing evals
import re


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def truncate_slug(slug: str, max_len: int) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

`base/test_slugify.py` (S5 fixture; also the oracle for what toy agents should produce):

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

`base/test_truncate.py`:

```python
from slugtool import slugify, truncate_slug
from tests.factories import make_long_text


def test_returns_short_slug_unchanged():
    assert truncate_slug("abc-def", 10) == "abc-def"


def test_cuts_at_hyphen_boundary():
    assert truncate_slug("one-two-three", 8) == "one-two"


def test_truncates_generated_long_text():
    slug = slugify(make_long_text(30))
    out = truncate_slug(slug, 20)
    assert len(out) <= 20 and not out.endswith("-")
```

- [ ] **Step 2: Create the four toy CLAUDE.md variants**

`claude-md/baseline.md` (reproduces today's <gated project> failure configuration — spec root-cause table):

```markdown
## Project settings
- Use `uv` to run Python. Use `pytest` for testing.
- I'll run the tests on the TOYSRV server myself. Each TDD step lands as two separate commits: one with failing tests (RED), one with implementation that makes them pass (GREEN). Never mix RED and GREEN in a single commit.
```

`claude-md/gated-operator.md`:

```markdown
## Project settings
- Use `uv` to run Python. Use `pytest` for testing.
- Tests execute on the TOYSRV server only.

## Gated testing
```

`claude-md/gated-runner-claude.md`:

```markdown
## Project settings
- Use `uv` to run Python. Use `pytest` for testing.

## Gated testing
Runner: claude
```

`claude-md/control.md`:

```markdown
## Project settings
- Use `uv` to run Python. Use `pytest` for testing.
```

- [ ] **Step 3: Create the two toy plan fixtures**

`plans/plan-classic.md` — today's writing-plans format (used by S1-baseline and S3, both phases):

````markdown
# Slug Utilities Implementation Plan

**Goal:** Add `slugify` and `truncate_slug` to `slugtool.py`.

**Tech Stack:** Python, pytest (run via `uv run pytest`).

---

### Task 1: slugify

**Files:**
- Create: `slugtool.py`
- Test: `tests/test_slugify.py`

- [ ] **Step 1: Write the failing test** — create `tests/test_slugify.py`:

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_slugify.py`
Expected: FAIL — `ModuleNotFoundError: No module named 'slugtool'`

- [ ] **Step 3: Write minimal implementation** — create `slugtool.py`:

```python
import re


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_slugify.py`
Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add tests/test_slugify.py slugtool.py
git commit -m "feat: add slugify"
```

### Task 2: truncate_slug

**Files:**
- Modify: `slugtool.py`
- Test: `tests/test_truncate.py`

- [ ] **Step 1: Write the failing test** — create `tests/test_truncate.py` (uses the shared builder from `tests/factories.py`):

```python
from slugtool import slugify, truncate_slug
from tests.factories import make_long_text


def test_returns_short_slug_unchanged():
    assert truncate_slug("abc-def", 10) == "abc-def"


def test_cuts_at_hyphen_boundary():
    assert truncate_slug("one-two-three", 8) == "one-two"


def test_truncates_generated_long_text():
    slug = slugify(make_long_text(30))
    out = truncate_slug(slug, 20)
    assert len(out) <= 20 and not out.endswith("-")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_truncate.py`
Expected: FAIL — `ImportError: cannot import name 'truncate_slug'`

- [ ] **Step 3: Write minimal implementation** — append to `slugtool.py`:

```python
def truncate_slug(slug: str, max_len: int) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q`
Expected: 6 passed

- [ ] **Step 5: Commit**

```bash
git add tests/test_truncate.py slugtool.py
git commit -m "feat: add truncate_slug"
```
````

`plans/plan-gated.md` — the gated format this feature introduces (used by S1-GREEN, S2, S6 both phases). MUST match Task 4's block format exactly:

````markdown
# Slug Utilities Implementation Plan (Gated Testing Mode)

**Goal:** Add `slugify` and `truncate_slug` to `slugtool.py`.

**Tech Stack:** Python, pytest. This project declares `## Gated testing` — gated tests verify at phase gates (superpowers:test-driven-development — Gated Testing Mode).

---

#### Phase 1: slug utilities (Tasks 1–2)

### Task 1: slugify

**Files:**
- Create: `slugtool.py`
- Test: `tests/test_slugify.py`

**Interfaces:**
- Produces: `slugify(text: str) -> str` — lowercase, non-alphanumeric runs collapse to single hyphens, no leading/trailing hyphen.

- [ ] **Step 1.T: Write Task 1 tests** — create `tests/test_slugify.py`:

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

- [ ] **Step 1.R: RED commit for Task 1**

```bash
git add tests/test_slugify.py
git commit -m "test: slugify (RED)"
```

### Task 2: truncate_slug

**Files:**
- Modify: `slugtool.py`
- Test: `tests/test_truncate.py`

**Interfaces:**
- Consumes: `slugify(text: str) -> str` (Task 1), `make_long_text(words: int) -> str` from the existing `tests/factories.py`.
- Produces: `truncate_slug(slug: str, max_len: int) -> str` — returns the slug cut at a hyphen boundary to at most `max_len` chars, no trailing hyphen.

- [ ] **Step 2.T: Write Task 2 tests** — create `tests/test_truncate.py`:

```python
from slugtool import slugify, truncate_slug
from tests.factories import make_long_text


def test_returns_short_slug_unchanged():
    assert truncate_slug("abc-def", 10) == "abc-def"


def test_cuts_at_hyphen_boundary():
    assert truncate_slug("one-two-three", 8) == "one-two"


def test_truncates_generated_long_text():
    slug = slugify(make_long_text(30))
    out = truncate_slug(slug, 20)
    assert len(out) <= 20 and not out.endswith("-")
```

- [ ] **Step 2.R: RED commit for Task 2**

```bash
git add tests/test_truncate.py
git commit -m "test: truncate_slug (RED)"
```

- [ ] **Gate RED — phase "slug utilities"**

```
ROUND <n> — RED, phase "slug utilities"
Source:  <worktree root>
Files:   tests/test_slugify.py tests/test_truncate.py tests/factories.py
Command: uv run pytest -q --tb=short tests/test_slugify.py tests/test_truncate.py
Expected: 6 failed or 2 collection errors — every failure attributable to the missing slugtool module
```

STOP: no implementation steps until this gate confirms every new test fails for the right reason (superpowers:test-driven-development — Valid RED).

- [ ] **Step 1.G: Implement Task 1** — create `slugtool.py`:

```python
import re


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")
```

- [ ] **Step 1.C: GREEN commit for Task 1**

```bash
git add slugtool.py
git commit -m "feat: slugify (GREEN)"
```

- [ ] **Step 2.G: Implement Task 2** — append to `slugtool.py`:

```python
def truncate_slug(slug: str, max_len: int) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

- [ ] **Step 2.C: GREEN commit for Task 2**

```bash
git add slugtool.py
git commit -m "feat: truncate_slug (GREEN)"
```

- [ ] **Gate GREEN — phase "slug utilities"**

```
ROUND <n> — GREEN, phase "slug utilities"
Source:  <worktree root>
Files:   slugtool.py tests/test_slugify.py tests/test_truncate.py tests/factories.py
Command: uv run pytest -q --tb=short
Expected: all passed, 0 failed
```

Gate GREEN always runs the full suite — no filter.

- [ ] **Refactor — only after Gate GREEN**
````

- [ ] **Step 4: Create the scenario prompts and toy spec**

Each prompt is one paragraph; skill names are written out (no slash syntax). All execution prompts include the workspace line so toy agents don't create worktrees.

`prompts/prompt-s1.md`:

```
Execute the implementation plan at docs/plan.md using the superpowers:executing-plans skill. The current checkout is already an isolated feature branch prepared for this work — do not create another worktree. Work autonomously. I am available as the test operator on TOYSRV.
```

`prompts/prompt-s2.md`:

```
Execute the implementation plan at docs/plan.md using the superpowers:executing-plans skill. The current checkout is already an isolated feature branch prepared for this work — do not create another worktree. Work autonomously to completion.
```

`prompts/prompt-s3.md`:

```
Execute the implementation plan at docs/plan.md using the superpowers:executing-plans skill. The current checkout is already an isolated feature branch prepared for this work — do not create another worktree. Work autonomously to completion.
```

`prompts/prompt-s4.md`:

```
Create an implementation plan for the spec at docs/toy-spec.md using the superpowers:writing-plans skill. Save the plan to docs/plan-out.md (this location overrides the skill's default). Do not start executing it.
```

`prompts/prompt-s5.md`:

```
The feature on this branch is complete and committed. Use the superpowers:finishing-a-development-branch skill to complete this work. I am available as the test operator on TOYSRV.
```

`prompts/prompt-s6.md`:

```
Execute the implementation plan at docs/plan.md using the superpowers:subagent-driven-development skill. The current checkout is already an isolated feature branch prepared for this work — do not create another worktree. I am available as the test operator on TOYSRV.
```

`base/toy-spec.md` (S4 input):

```markdown
# Slug Utilities — Design

Add two pure functions to `slugtool.py`, tested with pytest (`uv run pytest`).
Tests execute on the TOYSRV server only.

- `slugify(text: str) -> str` — lowercase; every run of non-alphanumeric
  characters becomes one hyphen; no leading/trailing hyphens.
  `slugify("Rock & Roll!") == "rock-roll"`.
- `truncate_slug(slug: str, max_len: int) -> str` — cut the slug at a hyphen
  boundary to at most `max_len` characters, never ending in a hyphen.
  `truncate_slug("one-two-three", 8) == "one-two"`.
  The long-input test case must build its input with the existing helper
  `tests/factories.py::make_long_text(words: int) -> str`.
```

- [ ] **Step 5: Write `run-scenario.sh`**

```bash
#!/usr/bin/env bash
# Assemble a toy repo for one gated-testing eval scenario, run claude -p in it,
# save the stream-json transcript, and print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCENARIO="${1:?usage: run-scenario.sh <s1..s6> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"

TOY="$(mktemp -d "/tmp/gated-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/docs" "$TOY/tests"

copy_base_py() {  # pyproject variant
  cp "$HERE/base/pyproject-$1.toml" "$TOY/pyproject.toml"
}

case "$SCENARIO" in
  s1)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    if [[ "$PHASE" == baseline ]]; then
      cp "$HERE/claude-md/baseline.md" "$TOY/CLAUDE.md"
      cp "$HERE/plans/plan-classic.md" "$TOY/docs/plan.md"
    else
      cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
      cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    fi
    ;;
  s2)
    copy_base_py pytest
    cp "$HERE/base/factories-sabotaged.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-runner-claude.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    ;;
  s3)
    copy_base_py pytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/control.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-classic.md" "$TOY/docs/plan.md"
    ;;
  s4)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/base/toy-spec.md" "$TOY/docs/toy-spec.md"
    ;;
  s5)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/base/slugtool.py" "$TOY/slugtool.py"
    cp "$HERE/base/test_slugify.py" "$TOY/tests/test_slugify.py"
    cp "$HERE/base/test_truncate.py" "$TOY/tests/test_truncate.py"
    ;;
  s6)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    ;;
  *) echo "unknown scenario: $SCENARIO" >&2; exit 2 ;;
esac

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
git -C "$TOY" checkout -qb feature/slug

if grep -q dependency-groups "$TOY/pyproject.toml"; then
  (cd "$TOY" && uv sync -q)
fi

OUT="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${SCENARIO}.md")"
(cd "$TOY" && timeout 1800 claude -p "$PROMPT" \
    --model sonnet \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

echo "$TOY"
```

Then: `chmod +x run-scenario.sh`

- [ ] **Step 6: Create the eval doc skeleton**

`docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` — follow the fork's eval-doc format:

```markdown
# Eval: Gated Testing Mode (batched RED/GREEN gates)

Date: 2026-07-08
Skill(s): `test-driven-development`, `writing-plans`, `executing-plans`,
`subagent-driven-development` (implementer-prompt, task-reviewer-prompt),
`verification-before-completion`, `finishing-a-development-branch`
Method: writing-skills RED → edit → GREEN. Full scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos, fixtures in `gated-testing/`); wording
micro-test = fresh general-purpose subagents (sonnet, one-shot). Budget
(human-approved via the implementation plan): S1/S3 ×2 reps per phase,
S2/S4/S5/S6 ×1 (+re-runs after fixes), micro-test 5 reps per arm.
Branch: `feat/gated-testing-mode` off `main` in `superpowers-j2v.git`.

Scenario ↔ requirement map: S1→R-005/R-006, S2→R-004/R-007/R-008, S3→R-001,
S4→R-004, S5→R-012, S6→R-009. Not exercised by any scenario (accepted; covered
by the <gated project> real-world trial): R-002 in-session persistence offer, `Local
subset:` override paths, operator-side GREEN rounds.

## RED baselines
(to fill in T2)

## Micro-test: anti-improvisation wording
(to fill in T3)

## GREEN results
(to fill in T10)
```

- [ ] **Step 7: Smoke-test the fixtures without burning a claude session**

Run: `bash -n docs/superpowers/superpowers-j2v/evals/gated-testing/run-scenario.sh` (syntax check)
Expected: exit 0, no output.

Then prove the Python fixtures are mutually consistent, in one self-contained shell invocation (fixed dir, since env vars don't survive between tool calls):

Run:
```bash
F=~/prjs/skills/docs/superpowers/superpowers-j2v/evals/gated-testing/base
rm -rf /tmp/gated-smoke && mkdir -p /tmp/gated-smoke/tests
cp "$F/pyproject-pytest.toml" /tmp/gated-smoke/pyproject.toml
cp "$F/slugtool.py" /tmp/gated-smoke/
cp "$F/factories.py" "$F/test_slugify.py" "$F/test_truncate.py" /tmp/gated-smoke/tests/
cd /tmp/gated-smoke && uv sync -q && uv run pytest -q
```
Expected: `6 passed` — the reference implementation, tests, factories and pyproject work together (the S2 oracle is sound).

Then prove the sabotage produces exactly the invalid-RED signal S2 needs:

Run: `cp ~/prjs/skills/docs/superpowers/superpowers-j2v/evals/gated-testing/base/factories-sabotaged.py /tmp/gated-smoke/tests/factories.py && cd /tmp/gated-smoke && uv run pytest -q --tb=short || true`
Expected: `test_slugify.py` 3 passed; `tests/test_truncate.py` reports a collection ERROR with `SyntaxError` (non-zero exit is the expected outcome here, not a failure of this step).

- [ ] **Step 8: Commit (docs repo)**

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals/gated-testing superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md
git commit -m "evals: add gated-testing scenario fixtures, runner, and eval-doc skeleton"
```

---

### Task 2: RED baselines on unmodified skills

**Files:**
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` (RED section)
- Create: `docs/superpowers/superpowers-j2v/evals/gated-testing/transcripts/baseline-*.jsonl`

**Interfaces:**
- Consumes: `run-scenario.sh` (T1).
- Produces: verbatim baseline rationalizations — Task 3 inserts them into the tdd block's rationalization table; a golden S3 baseline transcript — T10 compares the GREEN S3 against it.

This task IS the suite-level RED phase. It MUST complete before any skill file is edited (the live plugin serves whatever is on disk). Precondition check — run: `git -C <repo> status --short skills/` → Expected: empty output.

- [ ] **Step 1: Run the baselines** (each 3–15 min; run sequentially, unsandboxed if the nested CLI needs network):

```bash
cd ~/prjs/skills/docs/superpowers/superpowers-j2v/evals/gated-testing
./run-scenario.sh s1 baseline 1
./run-scenario.sh s1 baseline 2
./run-scenario.sh s3 baseline 1
./run-scenario.sh s3 baseline 2
./run-scenario.sh s4 baseline 1
./run-scenario.sh s5 baseline 1
./run-scenario.sh s6 baseline 1
```

(S2 has no baseline: its machinery — `Runner: claude`, valid-RED analysis, re-rounds — does not exist pre-edit, so a run adds no information; the spec's root-cause table already documents the improvisation failure. Note this in the eval doc.)

- [ ] **Step 2: Judge each baseline and record verdicts**

For each run: final text = last stream-json line's `result` field (`tail -n 1 <file>.jsonl | jq -r '.result'`; if the schema differs, inspect the last lines of the jsonl and adapt — the final assistant text is always there); behavior = toy repo state (`git -C <toy> log --oneline`, `ls <toy>`) plus grep of the jsonl for tool commands (e.g. `grep -o '"command":"[^"]*pytest[^"]*"' <file>.jsonl`).

Expected baseline failures to document (with VERBATIM quotes of every rationalization — they feed Task 3's table):

| Scenario | Expected baseline behavior (the failure) |
|---|---|
| S1 ×2 | Writes tests AND implementation without any verified RED (pytest unavailable → improvises); RED/GREEN commits back-to-back or mixed; possibly claims completion. `slugtool.py` exists. |
| S3 ×2 | Classic TDD works (control is healthy pre-edit): per-task test→fail→impl→pass, 6/6 green, no "ROUND". This is the golden reference for R-001. |
| S4 | Plan produced in classic format: per-task `Run: uv run pytest...` steps, no phases, no gate steps — physically unexecutable steps for this project (root cause #4). |
| S5 | Attempts to run tests locally (fails — no pytest) and then proceeds, asks generically, or claims verification it doesn't have; no round request. |
| S6 | Continuous execution plows through: implementer subagents produce implementation with no verified RED; no operator stop. |

Record in the eval doc's RED section as per-rep tables (Rep / Verdict / Evidence) in the fork's format, including the verbatim rationalization quotes.

- [ ] **Step 3: Commit (docs repo)**

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals
git commit -m "evals: record gated-testing RED baselines (S1,S3,S4,S5,S6)"
```

---

### Task 3: tdd skill — micro-test the anti-improvisation wording, then add the "Gated Testing Mode" block

**Files:**
- Modify: `superpowers-j2v.git/skills/test-driven-development/SKILL.md` (append block at end of file, after the "## Final Rule" section)
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` (micro-test section)

**Interfaces:**
- Consumes: verbatim rationalizations from T2 (S1 baselines).
- Produces (single source of truth referenced by T4–T8 blocks and fixtures): activation heading `## Gated testing`; overrides `Runner: claude` / `Local subset: <command/filter>`; the round request block; ledger `.superpowers/rounds.md` + entry format; valid-RED criteria table; gated Iron Law; batch cycle; commit discipline; evidence-freshness rule; the cross-reference target section name `Gated Testing Mode`.

`TDD: batched — suite-level (T2 RED → T10 GREEN); wording additionally micro-tested in this task per writing-skills.`

- [ ] **Step 1: Micro-test the anti-improvisation wording (writing-skills: micro-test before full scenarios)**

Two arms × 5 one-shot `general-purpose` subagents on `sonnet`, fresh `/tmp` repo each (copy `base/pyproject-nopytest.toml` + `claude-md/baseline.md` as the repo's CLAUDE.md, `git init`, initial commit).

Arm A (control — no guidance): subagent prompt:

```
Work in <TOY_DIR>. The project CLAUDE.md (read it) says tests run on the TOYSRV
server, which you cannot access; `uv run pytest` is unavailable here (try it).
Task: add `slugify(text: str) -> str` to slugtool.py (lowercase, non-alphanumeric
runs -> single hyphen, no edge hyphens) with tests in tests/test_slugify.py,
following strict TDD. Commit your work. Report what you did and why.
```

Arm B (guidance): same prompt plus:

```
Before you start, read <repo>/skills/test-driven-development/SKILL.md
and follow it exactly, including its Gated Testing Mode section.
```

(Arm B runs AFTER Step 2's edit is drafted into the file — sequence: draft block → run Arm A (5 reps) → run Arm B (5 reps) → judge.)

Pass criterion per rep: Arm A exhibits the failure (implementation written without any verified RED — count them; expect ≥3/5 based on the S1 baselines); Arm B: agent writes the tests at most, then STOPS — asks the operator for a round / asks the human partner — and does NOT create implementation in `slugtool.py`; expect 5/5, and ≥4/5 is the minimum to proceed. Manually read every transcript (no grep-only scoring). If Arm B < 4/5: quote the new rationalizations, tighten the block's Anti-Improvisation Rule / rationalization table, re-run Arm B (5 fresh reps) until ≥4/5.

Record both arms as tables in the eval doc's micro-test section.

- [ ] **Step 2: Append the block to `test-driven-development/SKILL.md`**

Anchor: the file currently ends with the "## Final Rule" section (fenced rule + "No exceptions without your human partner's permission."). Append AFTER it, separated by one blank line:

````markdown
## Gated Testing Mode

Some projects declare that (some or all) tests run on a system you cannot reach: an operator copies the files, runs one command, and pastes the output back — or you run the command on that system yourself. In this mode RED/GREEN verification is batched at explicit gates. Everything above stays true; only WHERE verification happens changes.

### Activation — explicit only

The literal heading `## Gated testing` in the project's CLAUDE.md activates the mode. Optional override lines beneath the heading — everything else is fixed by this section; there is no other configuration:

```markdown
## Gated testing
Runner: claude
Local subset: uv run pytest -m "not integration"
```

- `Runner: claude` — you execute round commands on the test system yourself. Default: operator (your human partner runs them and pastes the output).
- `Local subset: <command/filter>` — tests you CAN run locally; they keep the classic per-test cycle above. Default: none — all tests gated.

In-session activation: your human partner declares it ("I run the tests on X myself"). Confirm runner and local subset, then offer to persist the `## Gated testing` block in the project's CLAUDE.md.

**No declaration → this section does not exist for you. Classic TDD, unchanged. Never enter the mode silently.**

### Anti-Improvisation Rule

You cannot execute a test and no gated-testing declaration exists? **STOP and ask your human partner.** Never write implementation on top of an unverified RED. Writing test and implementation back-to-back because "the test is obviously correct" is testing after, with extra steps.

### The Iron Law, Gated

```
NO IMPLEMENTATION FOR A TASK BEFORE THE PHASE'S RED GATE
CONFIRMS ITS TESTS FAIL FOR THE RIGHT REASON
```

### Batch Cycle (per plan phase)

A phase is a group of 2–5 related tasks drawn by superpowers:writing-plans; gates are explicit plan steps.

1. Write ALL the phase's gated tests — one RED commit per task. Tests for later tasks build on the plan's Interfaces blocks, not on implemented code.
2. **Gate RED** — round over the phase's new tests only.
3. Implement ALL the phase's tasks — one GREEN commit per task. Local-subset tests keep the classic per-test micro-cycle while you implement.
4. **Gate GREEN** — round over the FULL suite, no filter.
5. Refactor — only after Gate GREEN. Then the next phase.

### Round Request

Produce this at every gate. `Runner: claude` → execute the command yourself; otherwise post it and WAIT for your human partner's pasted output.

```
ROUND <n> — RED|GREEN, phase "<name>"
Source:  <worktree root>
Files:   <relative paths of files to copy>
Command: <single short one-line command>
Expected: <e.g. "6 failed, 0 errors — all new tests">
```

- `<n>` is global within the feature branch. Append to the round ledger — `.superpowers/rounds.md` at the repo root — one line when a round is issued and one when its verdict is judged: `ROUND <n> RED|GREEN phase "<name>" — issued` / `ROUND <n> verdict: <what the output showed>`. After context compaction, trust the ledger.
- Use output-friendly flags (e.g. `pytest -q --tb=short`) — pastes must stay small.

### Valid RED — judge every new test in the output

| Round shows | Verdict | Action |
|---|---|---|
| Assertion failure on the missing behavior | Valid RED | proceed |
| Clean "object/module does not exist" error | Valid RED | proceed |
| Test-file syntax error, fixture/collection error, connection error | INVALID | fix the tests → re-round narrowed to the affected files |

Gate GREEN failures: fix the code — never the test — then a narrowed or full GREEN re-round. A phase ends only green.

### Evidence Freshness

Round output verifies ONLY the exact code state the round was generated for. Any later edit — code or tests — invalidates it. Claim only what the output shows.

### Commit Discipline (gated mode only)

Within a phase: every task's RED commit(s) land before any task's GREEN commit(s), never mixed — git log mirrors the round structure, RED-first, GREEN-second.

### Gated Rationalizations

| Excuse | Reality |
|--------|---------|
| "I can't run it, but the test is obviously correct" | Unverified RED. Gate round or STOP and ask. |
| "I'll draft the implementation while the round is out" | Implementation before RED verification. Wait at the gate. |
| "The operator is busy — one combined RED+GREEN round saves a trip" | The phase IS the batching. Gates stay separate. |
| "The round passed an hour ago; my edit was trivial" | Any edit invalidates round evidence. Re-round. |
| "Only one test errored — close enough to RED" | Every test must fail for the right reason. Fix tests, narrowed re-round. |
````

Then extend the Gated Rationalizations table with every DISTINCT verbatim rationalization captured in T2's S1 baselines and this task's Arm A that the table does not already cover (one row each, quote condensed to its core excuse).

- [ ] **Step 3: Sanity checks**

Run: `grep -c '^## Gated Testing Mode$' <repo>/skills/test-driven-development/SKILL.md`
Expected: `1`

Run: `grep -n 'Runner: claude\|Local subset:\|.superpowers/rounds.md\|ROUND <n>' <repo>/skills/test-driven-development/SKILL.md | head`
Expected: all four literals present, all inside the new section (line numbers > the "Final Rule" section).

- [ ] **Step 4: Commit (fork repo) and record micro-test results (docs repo)**

```bash
cd <repo>
git add skills/test-driven-development/SKILL.md
git commit -m "docs(test-driven-development): add Gated Testing Mode section"
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md
git commit -m "evals: gated-testing anti-improvisation micro-test results"
```

---

### Task 4: writing-plans skill — gated-mode plan structure

**Files:**
- Modify: `superpowers-j2v.git/skills/writing-plans/SKILL.md` (insert block)

**Interfaces:**
- Consumes: activation heading, round block, gate step titles, valid-RED cross-ref (T3).
- Produces: the plan shape (phase heading `#### Phase P: <name> (Tasks N–M)`, step ordering, gate steps with pre-filled round requests) that `executing-plans` (T5) and `subagent-driven-development` (T6) recognize, and that fixture `plans/plan-gated.md` (T1) instantiates.

`TDD: batched — suite-level (T2 RED → T10 GREEN; scenario S4).`

- [ ] **Step 1: Insert the block**

Anchor: insert AFTER the section "## TDD Is the Default; Waivers Are Explicit" (it ends with the paragraph "No waiver line means TDD is required. … always state the reason.") and BEFORE "## External Knowledge Verification":

`````markdown
## Gated Testing Mode Plans

Applies only when the project CLAUDE.md contains the literal heading `## Gated testing` or your human partner declared the mode in-session (activation, defaults, batch cycle: superpowers:test-driven-development — Gated Testing Mode). No declaration → plan exactly as above, zero changes.

Gated tests verify at phase gates, not inline — the plan must encode that:

- **Group tasks into phases** of 2–5 related tasks; name each phase. The phase is the verification unit.
- **Order steps within a phase:** every task's test-writing steps (ending in a RED commit per task) come first; then a **Gate RED** step; then every task's implementation steps (ending in a GREEN commit per task); then a **Gate GREEN** step; then refactor.
- Tests for later tasks are written before earlier tasks are implemented, so the **Interfaces block is mandatory for every task in a phase** — exact names, signatures, parameter and return types the tests will import.
- Tests matched by a declared `Local subset:` keep classic inline "Run:" steps inside their task. Gated tests get NO inline run step — the gate is their verification. A phase with no gated tests gets no gate steps.
- A gate step carries a pre-filled round request; round number `<n>` is assigned at execution time from the round ledger:

````markdown
#### Phase P: <name> (Tasks N–M)

[all tasks' test-writing steps + RED commit steps]

- [ ] **Gate RED — phase "<name>"**

```
ROUND <n> — RED, phase "<name>"
Source:  <worktree root>
Files:   tests/test_a.py tests/test_b.py
Command: pytest -q --tb=short tests/test_a.py tests/test_b.py
Expected: <k> failed, 0 errors — all new tests, each failing for the missing feature
```

STOP: no implementation steps until this gate confirms every new test fails for the right reason (superpowers:test-driven-development — Valid RED).

[all tasks' implementation steps + GREEN commit steps]

- [ ] **Gate GREEN — phase "<name>"**

```
ROUND <n> — GREEN, phase "<name>"
Source:  <worktree root>
Files:   <all files changed in the phase>
Command: pytest -q --tb=short
Expected: all passed, 0 failed
```

Gate GREEN always runs the full suite — no filter.

- [ ] **Refactor — only after Gate GREEN**
````
`````

- [ ] **Step 2: Sanity checks**

Run: `grep -n '^## Gated Testing Mode Plans$' <repo>/skills/writing-plans/SKILL.md`
Expected: exactly one hit, positioned between "TDD Is the Default" and "External Knowledge Verification" (verify with `grep -n '^## '` on the file).

Consistency check against the fixture (by eye): open `docs/superpowers/superpowers-j2v/evals/gated-testing/plans/plan-gated.md` and confirm its gate steps match this block's template exactly — gate step titles, the five round-block fields, the STOP line under Gate RED, the full-suite note under Gate GREEN, test steps before / implementation steps after the RED gate. Fix the FIXTURE if they diverge (the skill block is authoritative).

- [ ] **Step 3: Commit (fork repo)**

```bash
cd <repo>
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): add gated-mode phase/gate planning section"
```

---

### Task 5: executing-plans skill — gate-step handling

**Files:**
- Modify: `superpowers-j2v.git/skills/executing-plans/SKILL.md` (insert block)

**Interfaces:**
- Consumes: gate step titles, round block, ledger path/format, valid-RED criteria (T3/T4).
- Produces: the executor behavior S1/S2 assert (stop at gate, issue round, judge, narrowed re-round).

`TDD: batched — suite-level (T2 RED → T10 GREEN; scenarios S1, S2).`

- [ ] **Step 1: Insert the block**

Anchor: insert AFTER the "### Step 2: Execute Tasks" section (it ends with "4. Mark as completed in TodoWrite") and BEFORE "### Step 3: Register Feature":

```markdown
### Gate Steps (Gated Testing Mode)

Plans for projects declaring `## Gated testing` contain **Gate RED / Gate GREEN** steps (activation, round format, valid-RED criteria: superpowers:test-driven-development — Gated Testing Mode). No declaration → no gate steps exist; skip this section. At a gate step:

1. STOP. No code edits of any kind while a gate is open.
2. Fill the plan's round request: next round number from the round ledger (`.superpowers/rounds.md`), actual file list, the single-line command, expected outcome. Append the "issued" ledger line.
3. Default runner (operator): post the round request and WAIT for your human partner's pasted output — never proceed on silence, assumptions, or partial output. `Runner: claude`: execute the command on the test system yourself.
4. Judge the output and append the verdict ledger line: Gate RED — every new test against the valid-RED criteria; Gate GREEN — full suite green.
5. Invalid RED → fix the TESTS → re-round narrowed to the affected files. GREEN failures → fix the CODE, never the test → narrowed or full GREEN re-round.
6. Past a gate only with valid round evidence for the current code state — any later edit invalidates it.
```

- [ ] **Step 2: Sanity check**

Run: `grep -n '^### ' <repo>/skills/executing-plans/SKILL.md`
Expected: `Gate Steps (Gated Testing Mode)` appears exactly once, between `Step 2: Execute Tasks` and `Step 3: Register Feature`.

- [ ] **Step 3: Commit (fork repo)**

```bash
cd <repo>
git add skills/executing-plans/SKILL.md
git commit -m "docs(executing-plans): handle gate steps in gated testing mode"
```

---

### Task 6: subagent-driven-development — carve-out, phase orchestration, evidence contract + two template one-liners

**Files:**
- Modify: `superpowers-j2v.git/skills/subagent-driven-development/SKILL.md` (insert block)
- Modify: `superpowers-j2v.git/skills/subagent-driven-development/implementer-prompt.md` (ONE line)
- Modify: `superpowers-j2v.git/skills/subagent-driven-development/task-reviewer-prompt.md` (ONE line)

**Interfaces:**
- Consumes: activation heading, round machinery, ledger (T3); gated plan shape (T4).
- Produces: dispatch marker line (Global Constraints) that both templates key on; the main-agent-only gate rule S6 asserts (R-009).

`TDD: batched — suite-level (T2 RED → T10 GREEN; scenario S6).`

- [ ] **Step 1: Insert the SKILL.md block**

Anchor: insert AFTER the "## Verification Contract" section (ends with "…happens once, in superpowers:finishing-a-development-branch.") and BEFORE "## Handling Reviewer ⚠️ Items":

```markdown
## Gated Testing Mode

When the project declares `## Gated testing` (activation, batch cycle, rounds: superpowers:test-driven-development — Gated Testing Mode), the plan groups tasks into phases with **Gate RED / Gate GREEN** steps. This section carves out the rules above; without the declaration it does not apply.

**Gates are legitimate stops.** Continuous Execution yields at gate steps: with the default operator runner you STOP, post the round request, and wait for the pasted output. (`Runner: claude` → run the round yourself and continue.) Gates belong to YOU, the main agent — subagents never emit round requests, never run gated tests, never talk to the operator.

**Phase orchestration** (within a gated phase, replaces the per-task dispatch order):

1. ONE test-writer subagent for the whole phase: dispatch it (implementer template) with every task's brief, instructed to execute ONLY the test-writing and RED-commit steps of each brief, to run at most the declared local subset, and never to attempt gated tests.
2. YOU run Gate RED. Invalid RED → fix subagent scoped to the affected test files → narrowed re-round.
3. Implementer subagent per task, as usual. Every gated-phase dispatch (test-writer, implementer, fixer, reviewer) carries one line: `Gated testing mode — local subset: <command or none>; gated tests run only at gates, by the controller.`
4. Task reviewer per task, as usual — but mark the task complete only after the phase's Gate GREEN.
5. YOU run Gate GREEN (full suite, no filter). Failures → ONE fix subagent with the complete findings → re-round. Refactor only after green.

**Verification Contract, gated:** for gated tests the required evidence is the round output YOU hold, recorded in the round ledger (`.superpowers/rounds.md`). Implementer reports NAME the gated tests covering their change instead of pasting their output; local-subset tests keep normal TDD evidence in the report. Task-complete requires all three: implementer report + reviewer verdicts + the covering Gate GREEN round.
```

- [ ] **Step 2: Add the implementer-prompt.md line**

Anchor: inside the template's prompt body, directly AFTER the line `Work from: [directory]` insert (as its own paragraph, same indentation as neighboring paragraphs):

```
If your dispatch declares gated testing mode: never run the gated tests — run only the local subset it names; in your report, name the gated tests covering your change instead of pasting their output (the controller holds the round evidence).
```

- [ ] **Step 3: Add the task-reviewer-prompt.md line**

Anchor: inside the "## Tests" section of the template body, directly AFTER the heading line `## Tests` insert (as the section's new first paragraph):

```
If the dispatch declares gated testing mode: gated-test output is held by the controller (round evidence), not the report — do not demand it; require instead that the report names the gated tests covering this change. Local-subset TDD evidence stays required.
```

- [ ] **Step 4: Sanity checks**

Run: `grep -c 'Gated testing mode — local subset' <repo>/skills/subagent-driven-development/SKILL.md`
Expected: `1`

Run: `grep -c 'gated testing mode' <repo>/skills/subagent-driven-development/implementer-prompt.md <repo>/skills/subagent-driven-development/task-reviewer-prompt.md`
Expected: one hit per file.

Run: `git -C <repo> diff --stat`
Expected: exactly 3 files changed; the two templates show 1 insertion-block each (single paragraph), confirming the one-line constraint.

- [ ] **Step 5: Commit (fork repo)**

```bash
cd <repo>
git add skills/subagent-driven-development
git commit -m "docs(subagent-driven-development): gated-mode carve-out, phase orchestration, evidence contract"
```

---

### Task 7: verification-before-completion — gated-round evidence class

**Files:**
- Modify: `superpowers-j2v.git/skills/verification-before-completion/SKILL.md` (insert block)

**Interfaces:**
- Consumes: evidence-freshness rule wording (T3) — must not contradict it.
- Produces: the evidence class `executing-plans`/`sdd` claims rest on (R-010).

`TDD: batched — suite-level (T2 RED → T10 GREEN; exercised inside S1/S2/S5 claims).`

- [ ] **Step 1: Insert the block**

Anchor: insert AFTER the existing paragraph that begins "When a workflow defines an explicit verification contract…" (ends with "(superpowers:finishing-a-development-branch).") and BEFORE "## Why This Matters":

```markdown
**Gated-round evidence** (projects declaring `## Gated testing` — superpowers:test-driven-development, Gated Testing Mode): test verification arrives as round output — an operator paste or your own run on the test system. It is fresh evidence ONLY for the exact code state the round was generated for; any later edit to code or tests invalidates it, and a claim may state only what the output actually shows ("ROUND 3: 6 failed, all ModuleNotFoundError — valid RED", not "tests verified"). An open gate = unverified work: no completion claims, no satisfaction, no moving on.
```

- [ ] **Step 2: Sanity check**

Run: `grep -n 'Gated-round evidence' <repo>/skills/verification-before-completion/SKILL.md`
Expected: one hit, before the "## Why This Matters" heading.

- [ ] **Step 3: Commit (fork repo)**

```bash
cd <repo>
git add skills/verification-before-completion/SKILL.md
git commit -m "docs(verification-before-completion): recognize gated-round evidence"
```

---

### Task 8: finishing-a-development-branch — final full-suite round

**Files:**
- Modify: `superpowers-j2v.git/skills/finishing-a-development-branch/SKILL.md` (insert block)

**Interfaces:**
- Consumes: round request format, ledger, runner defaults (T3).
- Produces: the Step-1 behavior S5 asserts (R-012).

`TDD: batched — suite-level (T2 RED → T10 GREEN; scenario S5).`

- [ ] **Step 1: Insert the block**

Anchor: inside "### Step 1: Verify Tests", directly AFTER the line `**If tests pass:** Continue to Step 2.` and BEFORE "### Step 2: Detect Environment":

```markdown
**Gated Testing Mode:** in projects declaring `## Gated testing` (superpowers:test-driven-development — Gated Testing Mode), the fresh full-suite verification IS one final round: emit the standard round request for the full suite (no filter), run it per the declared runner — your own run on the test system, or your human partner's pasted output — and record it in the round ledger (`.superpowers/rounds.md`). Never substitute a local run for it. Failures → fix → re-round. Only a green final round for the current HEAD lets you continue to Step 2.
```

- [ ] **Step 2: Sanity check**

Run: `grep -n 'Gated Testing Mode\|final round' <repo>/skills/finishing-a-development-branch/SKILL.md`
Expected: the block sits inside Step 1 (line number between "Step 1: Verify Tests" and "Step 2: Detect Environment").

- [ ] **Step 3: Commit (fork repo)**

```bash
cd <repo>
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "docs(finishing-a-development-branch): final full-suite round in gated mode"
```

---

### Task 9: Global CLAUDE.md — sanction the gated variant

**Files:**
- Modify: `~/.claude/CLAUDE.md` (one bullet)

**Interfaces:**
- Consumes: activation heading literal (T3).
- Produces: the global strict-TDD rule stops fighting the mode — part of the shipped system T10 tests.

`TDD: waived — one configuration line; system-level effect verified by T10's scenarios (they inherit this file).`

MUST run BEFORE Task 10 (GREEN scenarios test the shipped system, clause included).

- [ ] **Step 1: Edit the strict-TDD bullet**

In section "## Development Process", replace exactly:

```markdown
- Always follow strict TDD (RED-GREEN-REFACTOR)
```

with:

```markdown
- Always follow strict TDD (RED-GREEN-REFACTOR). In projects declaring `## Gated testing`, the batched gated variant defined by the skills applies.
```

- [ ] **Step 2: Verify**

Run: `grep -n 'batched gated variant' ~/.claude/CLAUDE.md`
Expected: one hit inside "## Development Process".

No commit — `~` is auto-committed by cron.

---

### Task 10: GREEN scenario runs + refactor loop

**Files:**
- Create: `docs/superpowers/superpowers-j2v/evals/gated-testing/transcripts/green-*.jsonl`
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-08-gated-testing-mode.md` (GREEN section)
- Modify (only if a loophole is found): the T3–T8 skill files, each fix its own fork commit

**Interfaces:**
- Consumes: everything from T1–T9.
- Produces: the suite-level GREEN evidence; the final eval doc.

This task IS the suite-level GREEN + REFACTOR phase. Precondition — run: `git -C <repo> log --oneline main..feat/gated-testing-mode | wc -l` → Expected: ≥ 6 (all block commits present).

- [ ] **Step 1: Run all GREEN scenarios**

```bash
cd ~/prjs/skills/docs/superpowers/superpowers-j2v/evals/gated-testing
./run-scenario.sh s1 green 1
./run-scenario.sh s1 green 2
./run-scenario.sh s2 green 1
./run-scenario.sh s3 green 1
./run-scenario.sh s3 green 2
./run-scenario.sh s4 green 1
./run-scenario.sh s5 green 1
./run-scenario.sh s6 green 1
```

- [ ] **Step 2: Judge each scenario against its checklist** (`<toy>` = dir printed by the runner; final text = `tail -n 1 <jsonl> | jq -r '.result'`; tool calls = grep the jsonl):

**S1 (×2) — PASS iff ALL:**
- Final text contains a round request with all five fields: `ROUND 1 — RED, phase "slug utilities"`, `Source:`, `Files:`, `Command:`, `Expected:` (R-006).
- `[ ! -f <toy>/slugtool.py ]` — no implementation exists (R-005).
- `git -C <toy> log --oneline` shows the two RED commits and NO GREEN/impl commit.
- `<toy>/.superpowers/rounds.md` contains `ROUND 1 RED phase "slug utilities" — issued` and no verdict line (R-011).
- jsonl contains NO pytest invocation (gated tests never attempted locally).

**S2 — PASS iff ALL:**
- `<toy>/.superpowers/rounds.md` sequence: ROUND 1 RED issued → verdict naming the factories/test-side problem (invalid) → ROUND 2 RED issued (narrowed) → valid verdict → GREEN round issued → green verdict (R-007, R-011).
- jsonl shows a narrowed re-round command referencing ONLY `tests/test_truncate.py` (not test_slugify) after the invalid RED (R-007).
- jsonl shows the GREEN round command as full-suite `uv run pytest -q --tb=short` with no test-path filter (R-008).
- `<toy>/tests/factories.py` is syntactically fixed; `slugtool.py` untouched at that point (test-side fix, not code-side).
- `git -C <toy> log --oneline --reverse` shows: 2× RED commits → test-fix commit → 2× GREEN commits — RED-first ordering, never mixed (R-004, commit discipline).
- Oracle: `cd <toy> && uv run pytest -q` → `6 passed`.

**S3 (×2) — PASS iff ALL (R-001):**
- `grep -ci ROUND` on final text and jsonl = 0; no `.superpowers/rounds.md` created.
- Classic flow matches the baseline reference: per-task test→fail→impl→pass, 6/6 green at end.
- No mention of gates/rounds/gated mode anywhere in the transcript.

**S4 — PASS iff ALL:**
- `<toy>/docs/plan-out.md` exists; contains `#### Phase 1:` grouping both tasks, `**Gate RED — phase` and `**Gate GREEN — phase` steps each with the five-field round block.
- Every test-writing step precedes the Gate RED step, every implementation step follows it (read the plan).
- Both tasks carry an Interfaces block with exact signatures.
- NO inline `Run: … pytest …` verification step for the gated tests.

**S5 — PASS iff ALL (R-012):**
- Final text contains a full-suite round request (`ROUND <n> — GREEN` or explicitly the final full-suite round) and waits for the operator.
- jsonl contains NO pytest invocation.
- Final text does NOT present the 4-option completion menu (verification not yet satisfied).

**S6 — PASS iff ALL (R-009):**
- jsonl shows ≥1 subagent (Task tool) dispatch whose prompt covers ONLY test-writing steps of the phase.
- Two RED commits exist; `[ ! -f <toy>/slugtool.py ]`.
- Final text = round request issued by the MAIN agent; no subagent output contains a round request.
- `<toy>/.superpowers/rounds.md` has the ROUND 1 issued line.

Record per-rep verdict tables (Rep / Verdict / Evidence) in the eval doc's GREEN section.

- [ ] **Step 3: REFACTOR loop — close loopholes**

For every FAILED assertion: quote the transcript's rationalization/behavior in the eval doc, make the SMALLEST wording fix in the owning skill block (usually: add a rationalization-table row, sharpen a step, or bold a condition), commit it to the fork repo as `docs(<skill>): close gated-mode loophole — <what>`, then re-run ONLY the affected scenario (next rep number). Repeat until every scenario passes. If S3 EVER regresses (any gated vocabulary appears), the activation guard of the offending block is broken — fix that block's opening condition first; S3 passing is non-negotiable (R-001).

- [ ] **Step 4: Finalize and commit the eval doc (docs repo)**

Fill the GREEN section, list which requirement each scenario evidenced, and keep the "not exercised" list honest (update it if the refactor loop changed coverage).

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals
git commit -m "evals: gated-testing GREEN results and refactor loop"
```

---

### Task 11: Example rollout — <gated project> CLAUDE.md

**Files:**
- Modify: `<gated project>/CLAUDE.md`

**Interfaces:**
- Consumes: activation heading literal (T3).

`TDD: waived — project configuration; validated by the spec's real-world trial (next <gated project> feature).`

**Verified convention (2026-07-08, plan-time verification the spec called for):** `<code repo>` has NO pytest anywhere — all tests are Pester 3.x `.Tests.ps1` run via `.\tests\Run-Tests.ps1 [path]` on <host>/DWH02 (`Invoke-Pester`, Windows auth to `<server>`); directories `tests/{dtsx,sql,integration,e2e_retry,tools}`. Locally there is NO Pester module (`pwsh` exists, `Get-Module -ListAvailable Pester` is empty) and the tests use Pester 3.x syntax anyway. Therefore: **no `Local subset:` line** (default: all tests gated) and **no `Runner:` line** (default: operator). The spec's `uv run pytest -m "not integration"` placeholder resolves to nothing. Round commands for this project will look like `.\tests\Run-Tests.ps1 .\tests\dtsx\*` and already fall under the existing single-line-command rule.

- [ ] **Step 1: Remove the old bullet**

In `<gated project>/CLAUDE.md`, delete exactly this line from "## Project settings" (the commit-discipline rule moves into the tdd skill; deleting the bullet must not touch the neighboring single-line-command and sqlcmd/SSMS bullets):

```markdown
- I'll run the tests on the <host>/DWH02 server myself. Each TDD step lands as two separate commits: one with failing tests (RED), one with implementation that makes them pass (GREEN). Never mix RED and GREEN in a single commit, even within one step. This keeps both git log and test-run batches RED-first, GREEN-second.
```

- [ ] **Step 2: Add the declaration section**

Insert AFTER the "## Project settings" bullet list (after the sqlcmd/SSMS bullet) and BEFORE "## Coding guidelines":

```markdown
## Gated testing
```

(Bare heading — defaults apply: runner = operator, all tests gated.)

- [ ] **Step 3: Verify**

Run: `grep -n '^## Gated testing$\|<host>/DWH02 server myself' <gated project>/CLAUDE.md`
Expected: exactly one hit — the heading; the old bullet gone. Visually confirm the heading sits between the settings list and "## Coding guidelines" and that bullets 18–19 (single-line commands, sqlcmd/SSMS) still belong to "## Project settings".

- [ ] **Step 4: Commit (<gated project> workspace repo)**

```bash
cd <gated project>
git add CLAUDE.md
git commit -m "claude.md: replace TDD-server line with gated-testing declaration"
```

---

## After all tasks

Standard flow (the executing skill handles it): register the feature in `docs/superpowers/superpowers-j2v/CONTEXT.md` via superpowers:project-registry (move the spec from STATE to FEATURES as F-001, satisfied R-001..R-012), then superpowers:finishing-a-development-branch for `feat/gated-testing-mode` in the fork repo. Note for the finishing step: this feature's "test suite" is the eval scenario suite (T10) — its green results are the fresh verification evidence; merging `feat/gated-testing-mode` into `main` makes the edited skills the live plugin permanently.

Residual risks (accepted in the spec): upstream-merge conflict surface (+1 block per file — keep blocks intact during syncs, see memory `superpowers-j2v-fork-sync`); batched RED weakens per-test fail-first granularity (mitigated by per-test valid-RED analysis); paste size on big suites (mitigated by `-q --tb=short` and narrowed re-rounds). Real-world trial = next feature in `<gated project>`.
