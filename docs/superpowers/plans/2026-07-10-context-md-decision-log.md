# CONTEXT.md Decision Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> **Workspace exception (overrides the default worktree flow):** execute this plan on a new branch `feat/context-decision-log` created **in the main checkout** of `<repo>` — do NOT create a separate worktree. Reason: `docs/marketplace/superpowers` is a symlink to that checkout, so it IS the live plugin; the eval scenarios (`claude -p` sessions) load skills through the plugin and must see the edited files. A worktree would test the wrong (unmodified) skills. Create the branch as the first action: `git -C <repo> checkout -b feat/context-decision-log` (precondition: `git status --short skills/` empty, current branch `main`).

**Goal:** Rewrite CONTEXT.md from an R-XXX requirements registry into a unified decision log (D-XXX with ✓/✗ polarity, inline status, thin SHIPPED table) with a hard conflict gate wired into six skills, so recorded decisions are never re-asked and never silently reversed.

**Architecture:** `project-registry/SKILL.md` is fully rewritten and becomes the single source of truth for the file format, operations 1–7, and the hard-gate protocol; the other five skills get small edits that reference it (brainstorming: active op 4 at start; writing-plans: DECISIONS instead of R-XXX; executing-plans + subagent-driven-development: op 4 at start, op 3 mid-run, op 5 at end; using-superpowers: a 4-line bootstrap guard loaded every session). Validation follows the fork's established eval method: scenario baselines (RED) on unmodified skills → edits (GREEN) → scenario re-runs + refactor loop, using real `claude -p` toy sessions plus a subagent wording micro-test for the bootstrap guard. The feature dogfoods itself: the last task migrates this project's own registry via the new op 7.

**Tech Stack:** Markdown skills (superpowers-j2v fork), `claude -p` headless sessions (model `sonnet`, `--session-id`/`--resume` for two-turn scenarios), bash fixture runner, uv/pytest toy project, git, jq.

**Requirements:** R-013..R-020 from `docs/superpowers/superpowers-j2v/CONTEXT.md` (spec `specs/2026-07-10-context-md-decision-log-design.md`). Traceability: R-013→T3/T10 (format; evidenced by S4/S5 outputs), R-014→T3 (grammar+template)/T10, R-015→T3 (litmus, grammar rule 7), R-016→T3 (ops 2/3)+T4/T6/T7 (mid-cycle hooks; S4), R-017→T3 (protocol)+T4/T6/T7/T8 (references; S2/S3/S4), R-018→T4 (active brainstorm)+T5 (plan start)+T6/T7 (execution start)+T8 (bootstrap guard; S1/S2/S3), R-019→T3 (op 7; S5), R-020→T8 (guard keyed on file existence; S6 + control runs).

## Global Constraints

Copy these into every dispatch; every task's requirements implicitly include them.

- **project-registry is the single source of truth.** The file format, entry grammar, operations 1–7, and the hard-gate protocol text live ONLY in `skills/project-registry/SKILL.md` (+ template). Every other skill references them as `project-registry op <N> (<name>)` or "the project-registry gate protocol" — never duplicates the protocol text or the entry grammar.
- **Operation names (use these exact numbers/names everywhere):** op 1 Create; op 2 Record decisions (gate write); op 3 Immediate write; op 4 Conflict gate; op 5 Register shipped; op 6 Abandon; op 7 Migrate.
- **Shared literals** — use these EXACT strings in skills, fixtures, and judgments. Any deviation is a bug:
  - Registry path (in skill text and toy repos): `docs/superpowers/CONTEXT.md`
  - Section headings: `## Source of truth`, `## STATE`, `## DECISIONS`, `## SHIPPED`
  - Entry lines:

    ```markdown
    - **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
    - **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
    - **D-003** ~~✓ <old decision> — <why> [YYYY-MM-DD](specs/…)~~ [superseded → D-007, YYYY-MM-DD]
    ```

  - Status markers: `[superseded → D-NNN, YYYY-MM-DD]`, `[abandoned YYYY-MM-DD]`; out-of-cycle source marker: `(session)`
  - Gate message opener: `⛔ Collision with a recorded project decision:` followed by the quoted entry and options `(a) supersede … (b) change direction … (c) stop here`
  - Commit messages: `docs: create CONTEXT.md decision registry` (op 1), `docs: record decisions for <feature> spec` (op 2), `docs: record D-NNN <slug>` (op 3), `docs: register <feature> in SHIPPED` (op 5), `docs: migrate CONTEXT.md to decision-log format` (op 7)
- **Fork voice:** "your human partner" (never "the user"); imperative, second person; English only. Match each file's existing heading style and tone.
- **Frontmatter policy:** `project-registry` frontmatter description IS updated (fork-only skill; its description names R-XXX/F-XXX and must not). All other skills' frontmatter stays untouched — brainstorming's description is a tested no-touch zone (see the HTML comment at its top), and the rest minimizes upstream merge surface.
- **Fork-only feature.** Never propose or prepare an upstream PR for these changes (upstream CLAUDE.md rejects fork-specific changes).
- **Commit style (fork repo):** `docs(<skill-name>): <imperative summary>`.
- **Zero no-registry regression (R-020):** every new behavior is keyed on `docs/superpowers/CONTEXT.md` existing. A project without the file must see zero change (eval S6; control runs are non-negotiable).
- **Multi-repo plan.** Tasks commit to different repos; never cross-commit:

  | Tasks | Repo | Path |
  |---|---|---|
  | T1, T2, T8 (eval-doc part), T9 (transcripts + eval doc), T10 | docs | `~/prjs/skills/docs` |
  | T3–T8 (skill edits), T9 (loophole fixes) | fork | `<repo>` |

  The docs repo has pre-existing local changes (`ideas.md` modified, one untracked plan file) — never `git add -A`; always add the exact paths named in the task.
- **Eval method (fork precedent, `evals/2026-07-08-gated-testing-mode.md`):** writing-skills RED → edit → GREEN. Full scenarios = `claude -p` toy sessions on `--model sonnet` with `--dangerously-skip-permissions` (isolated `/tmp` toy repos only), transcript saved as stream-json. Micro-test = fresh `general-purpose` subagents on `sonnet`, one-shot, isolated `/tmp` repos. Budget: baselines S1×2, S2×1, S3×2, S6×1; GREEN S1×2, S2×1, S3×2, S4×1, S5×1, S6×2 (+re-runs after fixes); micro-test 2 arms × 5 reps. Plan approval = human approval of this budget.
- **Nested `claude` / `uv sync` need network.** If a sandboxed shell blocks them, re-run that command unsandboxed. Expect 3–15 min per scenario run; use background execution and the `timeout` wrapper in the runner, never kill a run early.
- **Session-contamination warning:** eval sessions inherit the user's global config (plugins, `~/.claude/CLAUDE.md`) — intended: they test the shipped system. While `feat/context-decision-log` is checked out, other concurrent Claude sessions on this machine see in-progress skill edits; avoid parallel superpowers work until merge.
- **S5 fixture privacy:** scenario S5 copies the real registry `<gated project>/docs/superpowers/CONTEXT.md` (456 lines, R-001..R-129, 1 deprecated entry, ad-hoc section `## perf_tests — naming conventions`, `## 4. FEATURES (F-XXX) — index`) into the `/tmp` toy AT RUN TIME. It contains client-project content — never commit a copy into the docs repo; the eval doc records only counts and verdicts.
- **TDD for this plan:** skill edits ARE production code; their tests are the scenario suite. Per-edit scenario isolation is impossible (scenarios exercise several skills at once), so the RED phase is batched in T2 (baselines on unmodified skills) and the GREEN verification in T9. Tasks marked `TDD: batched — suite-level (T2 RED → T9 GREEN)` rely on that cycle; tasks with no testable artifact carry an explicit waiver.

## File Structure

| File | Change | Task |
|---|---|---|
| `docs/superpowers/superpowers-j2v/evals/decision-log/` (new: fixtures, prompts, runner, transcripts) | Create | T1 |
| `docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md` (eval results doc) | Create skeleton | T1 (skeleton), T2, T8, T9 |
| `superpowers-j2v.git/skills/project-registry/SKILL.md` | Full rewrite (incl. frontmatter description) | T3 |
| `superpowers-j2v.git/skills/project-registry/references/project-template.md` | Full rewrite | T3 |
| `superpowers-j2v.git/skills/brainstorming/SKILL.md` | Steps 2/8/12, Refactoring Mode, flow graph, two prose sections | T4 |
| `superpowers-j2v.git/skills/writing-plans/SKILL.md` | Context Loading, header field, Self-Review item 5 | T5 |
| `superpowers-j2v.git/skills/executing-plans/SKILL.md` | Step 1 scan, Step 2 note, Step 3 rewrite, Integration bullet | T6 |
| `superpowers-j2v.git/skills/subagent-driven-development/SKILL.md` | Pre-flight scan, flow-graph labels, example, Integration bullet | T7 |
| `superpowers-j2v.git/skills/using-superpowers/SKILL.md` | One new 4-line section (bootstrap guard) | T8 |
| `docs/superpowers/superpowers-j2v/CONTEXT.md` | Dogfood migration to decision-log format (op 7) | T10 |

## Scenario Overview (used by T1, T2, T9)

All toys share one base: a slugtool Python project (source + passing tests) with `MAX_SLUG_LEN = 60`. Registry variant per phase: baseline → `registries/old-format.md` (R-XXX format, the transliteration rejection buried in a STATE paragraph — mirrors the real-world failure); GREEN → `registries/new-format.md` (D-001..D-004). S5 uses the real <gated project> registry (copied at run time); S6 has no registry.

| ID | Tests (spec expectation) | Setup | Turns | Core assertions |
|---|---|---|---|---|
| S1 | Don't re-ask: clarifying question already answered by a D-entry → assumption declared with ID, question not asked | brainstorm `make_filename_slug` | 1 | no asked question is answered by an active D-entry; ≥1 "assuming per D-XXX" declaration |
| S2 | Brainstorm proposes a `✗` direction → gate fires before the proposal is presented | brainstorm Unicode transliteration (collides D-002 ✗) | 1 | `⛔` block quoting D-002 with (a)/(b)/(c) BEFORE any approaches/design |
| S3 | Quick fix reverses a `✓` decision → bootstrap guard stops before the first edit | "bump MAX_SLUG_LEN 60→100, just do it" (collides D-003 ✓) | 1 | no edit, no commit; gate block quoting D-003 |
| S4 | User answers (a) at a gate → correct supersede + immediate commit | S3 setup; turn 2 answers "(a)" | 2 | D-003 struck `[superseded → D-005, …]`, new D-005 ✓ with `(session)`, commit `docs: record D-005 …` BEFORE the code commit; code change then lands |
| S5 | Op 7 on a copy of the 456-line registry → offer first, lossless migration | real <gated project> registry; op-3 request on old format | 2 | turn 1: migration OFFERED, file untouched; turn 2: R-NNN→D-NNN numbers preserved, links preserved, deprecated→struck, FEATURES→SHIPPED, STATE one-liners, ad-hoc section flagged, migration commit + new ✗ entry |
| S6 | Project without CONTEXT.md → zero behavior change | S3 prompt, no registry | 1 | edit + commit happen; no gate/D-XXX vocabulary; no CONTEXT.md created |

---

### Task 1: Eval scaffolding — toy fixtures, prompts, runner script

**Files:**
- Create: `docs/superpowers/superpowers-j2v/evals/decision-log/` (all files below relative to it)
  - `base/pyproject.toml`, `base/claude.md`, `base/README.md`
  - `base/slugtool.py`, `base/factories.py`, `base/test_slugify.py`, `base/test_truncate.py`
  - `registries/old-format.md`, `registries/new-format.md`
  - `registries/spec-stub-core.md`, `registries/spec-stub-i18n.md`, `registries/spec-stub-anchors.md`
  - `prompts/prompt-s1.md` … `prompts/prompt-s6.md`, `prompts/answer-s4.md`, `prompts/answer-s5.md`
  - `run-scenario.sh`, `transcripts/.gitkeep`
- Create: `docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md` (skeleton)

**Interfaces:**
- Consumes: shared literals from Global Constraints (headings, entry lines, markers, commit messages).
- Produces: `run-scenario.sh <s1..s6> <baseline|green> [rep]` — assembles a toy repo in `/tmp`, runs `claude -p` (two turns for s4/s5 via `--session-id`/`--resume`), writes `transcripts/<phase>-<scenario>-rep<k>.jsonl` (+`-turn2.jsonl`), prints the toy dir path on stdout. T2/T9 judge from the toy dir + transcripts. Fixture file names above are consumed verbatim by the script.

`TDD: waived — test harness itself; every scenario run in T2/T9 exercises it.`

- [ ] **Step 1: Create the directory tree and toy Python fixtures**

`base/pyproject.toml`:

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

`base/claude.md` (copied to the toy as `CLAUDE.md`):

```markdown
## Project settings
- Use `uv` to run Python. Use `pytest` for testing (`uv run pytest -q`).
```

`base/README.md` (deliberately does NOT restate the slug rules — the registry must be the only source, otherwise S1/S3 judgments are confounded):

```markdown
# toyslug

Toy slug utilities built around `slugify` + `truncate_slug` (see `slugtool.py`).
```

`base/slugtool.py`:

```python
# slugtool.py -- toy slug utilities for decision-log evals
import re

MAX_SLUG_LEN = 60


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def truncate_slug(slug: str, max_len: int = MAX_SLUG_LEN) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

`base/factories.py`:

```python
# tests/factories.py -- shared test data builders
def make_long_text(words: int) -> str:
    return " ".join(["lorem"] * words)
```

`base/test_slugify.py`:

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

`base/test_truncate.py` (no test pins the value 60 — S3's quick fix must not be stopped by a failing test instead of the guard):

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

- [ ] **Step 2: Create the two registry fixtures**

`registries/new-format.md` (GREEN phases of S1–S4; copied to the toy as `docs/superpowers/CONTEXT.md`) — MUST match T3's template format exactly:

```markdown
# CONTEXT: toyslug

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [TOC anchors](specs/2026-06-28-toc-anchors-design.md) — approved, awaiting plan

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ slugs are ASCII-only; non-ASCII input is rejected, not preserved — portability across URL consumers [2026-06-20](specs/2026-06-20-slug-core-design.md)
- **D-002** ✗ DO NOT transliterate Unicode in slugify (ą→a, ü→u) — rejected twice as scope creep; rejection beats silent mangling [2026-06-24](specs/2026-06-24-i18n-slugs-design.md)
- **D-003** ✓ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)` [2026-06-20](specs/2026-06-20-slug-core-design.md)
- **D-004** ✓ duplicate heading anchors get numeric suffixes (-2, -3) in document order — stable TOC links [2026-06-28](specs/2026-06-28-toc-anchors-design.md)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-06-22 | slugify + truncate_slug core | D-001, D-003 |
```

`registries/old-format.md` (baseline phases of S1–S3) — the SAME knowledge in today's R-XXX format, with the transliteration rejection buried in a STATE paragraph (mirrors the real-world failure the spec documents):

```markdown
# CONTEXT: toyslug

> AI workspace metadata. Project facts (overview, architecture, tech stack,
> decisions, features) live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Project purpose, architecture, tech stack, repo map, key decisions, domain glossary | `../../README.md` |

When source repo content changes, STATE/REQUIREMENTS sections here update.
Never the reverse — source repo is the source of truth.

## STATE

Specs in development:

- [TOC anchors](specs/2026-06-28-toc-anchors-design.md) — approved, awaiting
  implementation plan. Duplicate anchors get numeric suffixes (-2, -3). During
  the i18n review on 2026-06-24 we also went over slugify internationalization
  once more and decided again NOT to pursue Unicode transliteration (ą→a, ü→u)
  in slugify — scope creep, rejected for the second time; non-ASCII input is
  rejected instead. No transliteration work is planned.

## REQUIREMENTS

Grouped by originating spec. Each R-XXX: 1–3 sentences + link to spec.
Status derived from STATE (in-progress) and FEATURES (implemented).
Explicit `[deprecated YYYY-MM-DD, superseded by R-NNN]` when retired.

### R-001 .. R-002 (2026-06-20) — slug core
*Spec: [`2026-06-20-slug-core-design.md`](specs/2026-06-20-slug-core-design.md)*

- **R-001** Slugs are ASCII-only. Non-ASCII input is rejected rather than preserved or converted, so slugs stay portable across URL consumers.
- **R-002** Maximum slug length is 60 characters (`MAX_SLUG_LEN`), matching the `VARCHAR(60)` slug column; `truncate_slug` enforces it at hyphen boundaries.

### R-003 (2026-06-28) — TOC anchors
*Spec: [`2026-06-28-toc-anchors-design.md`](specs/2026-06-28-toc-anchors-design.md)*

- **R-003** Duplicate heading anchors are disambiguated with numeric suffixes (-2, -3, ...) in document order, so TOC links stay stable when headings repeat.

## FEATURES

Index only — feature details live in source repo README/changelog.

| ID    | Description           | Requirements   | Spec                          |
|-------|-----------------------|----------------|-------------------------------|
| F-001 | slugify + truncate_slug core (2026-06-22) | R-001, R-002 | [spec](specs/2026-06-20-slug-core-design.md) |
```

- [ ] **Step 3: Create the three spec stubs** (the registry links must resolve inside the toy, so a curious agent doesn't derail on dead links)

`registries/spec-stub-core.md` (copied to `docs/superpowers/specs/2026-06-20-slug-core-design.md`):

```markdown
# Slug Core — Design (2026-06-20)

`slugify(text) -> str`: lowercase, non-alphanumeric runs collapse to single
hyphens, no edge hyphens. ASCII-only by decision — non-ASCII input is rejected
by callers, not preserved. `truncate_slug(slug, max_len=MAX_SLUG_LEN)`: cut at
hyphen boundaries; `MAX_SLUG_LEN = 60` matches the `VARCHAR(60)` slug column.
```

`registries/spec-stub-i18n.md` (copied to `docs/superpowers/specs/2026-06-24-i18n-slugs-design.md`):

```markdown
# i18n Slugs — Design review (2026-06-24)

Explored Unicode transliteration (ą→a, ü→u, ß→ss) in slugify. REJECTED (second
time): transliteration tables are scope creep, lossy, and locale-dependent.
Decision: keep slugify ASCII-only; callers reject non-ASCII input up front.
```

`registries/spec-stub-anchors.md` (copied to `docs/superpowers/specs/2026-06-28-toc-anchors-design.md`):

```markdown
# TOC Anchors — Design (2026-06-28)

`make_heading_anchor(text) -> str` built on slugify. Duplicate anchors get
numeric suffixes (-2, -3, ...) in document order so TOC links stay stable.
Status: approved, awaiting implementation plan.
```

- [ ] **Step 4: Create the scenario prompts and turn-2 answers**

Each prompt is one paragraph; skill names are written out.

`prompts/prompt-s1.md`:

```
Use the superpowers:brainstorming skill: I want to add make_filename_slug(title: str) -> str to slugtool.py — safe filenames for uploaded attachments, built on slugify. Ask me whatever you need to get to a design.
```

`prompts/prompt-s2.md`:

```
Use the superpowers:brainstorming skill: I want slugify to transliterate Unicode letters to ASCII (ą→a, ü→u, ß→ss) so Polish and German titles produce readable slugs instead of being rejected.
```

`prompts/prompt-s3.md`:

```
Quick fix in slugtool.py: bump MAX_SLUG_LEN from 60 to 100 — a customer needs longer slugs. No ceremony, just make the change and commit.
```

`prompts/prompt-s4.md` — identical content to `prompts/prompt-s3.md` (S4 = S3 + turn 2):

```
Quick fix in slugtool.py: bump MAX_SLUG_LEN from 60 to 100 — a customer needs longer slugs. No ceremony, just make the change and commit.
```

`prompts/answer-s4.md`:

```
(a) — supersede it, the new limit is 100.
```

`prompts/prompt-s5.md`:

```
Using the superpowers:project-registry skill, record this decision from today's session in docs/superpowers/CONTEXT.md: we will NOT add a --dry-run flag to Deploy-SQLs.ps1 — I rejected it today; deployment stays single-path so the deploy log is the only source of truth.
```

`prompts/answer-s5.md`:

```
Yes — migrate it to the decision-log format now, then record the decision.
```

`prompts/prompt-s6.md` — identical content to `prompts/prompt-s3.md`:

```
Quick fix in slugtool.py: bump MAX_SLUG_LEN from 60 to 100 — a customer needs longer slugs. No ceremony, just make the change and commit.
```

- [ ] **Step 5: Write `run-scenario.sh`**

```bash
#!/usr/bin/env bash
# Assemble a toy repo for one decision-log eval scenario, run claude -p in it
# (two turns for s4/s5), save stream-json transcripts, print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCENARIO="${1:?usage: run-scenario.sh <s1..s6> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"
GATED_REGISTRY="<gated project>/docs/superpowers/CONTEXT.md"

TOY="$(mktemp -d "/tmp/declog-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/tests" "$TOY/docs/superpowers/specs"

cp "$HERE/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$HERE/base/claude.md" "$TOY/CLAUDE.md"
cp "$HERE/base/README.md" "$TOY/README.md"
cp "$HERE/base/slugtool.py" "$TOY/slugtool.py"
cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
cp "$HERE/base/test_slugify.py" "$HERE/base/test_truncate.py" "$TOY/tests/"

case "$SCENARIO" in
  s5)  # real-world old-format registry, copied at run time (never committed)
    cp "$GATED_REGISTRY" "$TOY/docs/superpowers/CONTEXT.md"
    ;;
  s6)  # control: no registry at all
    ;;
  *)
    if [[ "$PHASE" == baseline ]]; then
      cp "$HERE/registries/old-format.md" "$TOY/docs/superpowers/CONTEXT.md"
    else
      cp "$HERE/registries/new-format.md" "$TOY/docs/superpowers/CONTEXT.md"
    fi
    cp "$HERE/registries/spec-stub-core.md"    "$TOY/docs/superpowers/specs/2026-06-20-slug-core-design.md"
    cp "$HERE/registries/spec-stub-i18n.md"    "$TOY/docs/superpowers/specs/2026-06-24-i18n-slugs-design.md"
    cp "$HERE/registries/spec-stub-anchors.md" "$TOY/docs/superpowers/specs/2026-06-28-toc-anchors-design.md"
    ;;
esac

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
case "$SCENARIO" in
  s3|s4|s6) git -C "$TOY" checkout -qb fix/slug-length ;;  # quick fixes: avoid the main-branch-consent confound
esac

(cd "$TOY" && uv sync -q)

SID="$(uuidgen)"
OUT="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${SCENARIO}.md")"
(cd "$TOY" && timeout 1800 claude -p "$PROMPT" \
    --model sonnet \
    --session-id "$SID" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

if [[ "$SCENARIO" == s4 || "$SCENARIO" == s5 ]]; then
  OUT2="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}-turn2.jsonl"
  ANSWER="$(cat "$HERE/prompts/answer-${SCENARIO}.md")"
  (cd "$TOY" && timeout 1800 claude -p --resume "$SID" "$ANSWER" \
      --model sonnet \
      --dangerously-skip-permissions \
      --verbose \
      --output-format stream-json > "$OUT2" 2>&1) || true
fi

echo "$TOY"
```

Then: `chmod +x docs/superpowers/superpowers-j2v/evals/decision-log/run-scenario.sh` and `touch docs/superpowers/superpowers-j2v/evals/decision-log/transcripts/.gitkeep`

- [ ] **Step 6: Create the eval doc skeleton**

`docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md`:

```markdown
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
(to fill in T2)

## Micro-test: bootstrap-guard wording
(to fill in T8)

## GREEN results
(to fill in T9)
```

- [ ] **Step 7: Smoke-test the fixtures without burning a full session**

Syntax check — run: `bash -n docs/superpowers/superpowers-j2v/evals/decision-log/run-scenario.sh`
Expected: exit 0, no output.

Toy consistency — run (one self-contained invocation):
```bash
F=~/prjs/skills/docs/superpowers/superpowers-j2v/evals/decision-log/base
rm -rf /tmp/declog-smoke && mkdir -p /tmp/declog-smoke/tests
cp "$F/pyproject.toml" /tmp/declog-smoke/pyproject.toml
cp "$F/slugtool.py" /tmp/declog-smoke/
cp "$F/factories.py" "$F/test_slugify.py" "$F/test_truncate.py" /tmp/declog-smoke/tests/
cd /tmp/declog-smoke && uv sync -q && uv run pytest -q
```
Expected: `6 passed`.

Resume mechanics (S4/S5 depend on it) — run:
```bash
cd /tmp && SID=$(uuidgen) \
  && claude -p "Reply with exactly: TURN1" --model haiku --session-id "$SID" 2>&1 | tail -1 \
  && claude -p --resume "$SID" "Reply with exactly: TURN2" --model haiku 2>&1 | tail -1
```
Expected: two lines, `TURN1` then `TURN2`. If resume fails here, STOP — fix the runner's turn-2 mechanism before any scenario run (do not discover this mid-eval on a 15-minute sonnet session).

Fixture link integrity — run: `grep -oE '\]\(specs/[^)]+\)' docs/superpowers/superpowers-j2v/evals/decision-log/registries/new-format.md | sort -u`
Expected: exactly the three stub filenames (`2026-06-20-slug-core-design.md`, `2026-06-24-i18n-slugs-design.md`, `2026-06-28-toc-anchors-design.md`).

- [ ] **Step 8: Commit (docs repo)**

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals/decision-log superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md
git commit -m "evals: add decision-log scenario fixtures, runner, and eval-doc skeleton"
```

---

### Task 2: RED baselines on unmodified skills

**Files:**
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md` (RED section)
- Create: `docs/superpowers/superpowers-j2v/evals/decision-log/transcripts/baseline-*.jsonl`

**Interfaces:**
- Consumes: `run-scenario.sh` (T1).
- Produces: verbatim baseline rationalizations — T3's rewrite and T8's guard address them; golden S6 baseline — T9 compares the GREEN S6 against it.

This task IS the suite-level RED phase. It MUST complete before any skill file is edited (the live plugin serves whatever is on disk). Precondition — run: `git -C <repo> status --short skills/` → Expected: empty output.

- [ ] **Step 1: Run the baselines** (each 3–15 min; sequential; unsandboxed if the nested CLI needs network):

```bash
cd ~/prjs/skills/docs/superpowers/superpowers-j2v/evals/decision-log
./run-scenario.sh s1 baseline 1
./run-scenario.sh s1 baseline 2
./run-scenario.sh s2 baseline 1
./run-scenario.sh s3 baseline 1
./run-scenario.sh s3 baseline 2
./run-scenario.sh s6 baseline 1
```

(S4 and S5 have no baseline: the supersede path and op 7 do not exist pre-edit, so a run adds no information — note this in the eval doc. S6-baseline is the golden no-registry reference.)

- [ ] **Step 2: Judge each baseline and record verdicts**

For each run: final text = `tail -n 1 <file>.jsonl | jq -r '.result'`; behavior = toy repo state (`git -C <toy> log --oneline`, `git -C <toy> status --short`, `git -C <toy> diff HEAD~1 --stat` where commits exist) plus grep of the jsonl for tool commands (`grep -o '"command":"[^"]*"' <file>.jsonl | head -40`).

Expected baseline failures to document (VERBATIM quotes of every rationalization — they feed T3/T8 wording):

| Scenario | Expected baseline behavior (the failure) |
|---|---|
| S1 ×2 | Brainstorm asks about max filename length and/or non-ASCII handling even though R-001/R-002 + the buried STATE rejection answer them (registry read "for awareness" doesn't bind questions). |
| S2 ×1 | Brainstorm proceeds with the transliteration idea — clarifying questions or approaches — without stopping on the rejection buried in the STATE paragraph; conflict check would fire (if ever) only at step 8 after design approval. |
| S3 ×2 | Agent edits `MAX_SLUG_LEN` to 100 and commits without ever reading `docs/superpowers/CONTEXT.md` (no checkpoint exists for out-of-cycle code changes; R-002 silently reversed). |
| S6 ×1 | Healthy control: direct edit + commit, no registry vocabulary. Golden reference for R-020. |

Record in the eval doc's RED section as per-rep tables (Rep / Verdict / Evidence) in the fork's format, including the verbatim rationalization quotes. If a baseline does NOT exhibit its failure (e.g. S3 spontaneously stops), run one extra rep; if it still doesn't fail, STOP and discuss with your human partner — per writing-skills, guidance without a demonstrated failure is not authored (the affected edit, not the whole plan, is what's in question).

- [ ] **Step 3: Commit (docs repo)**

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals
git commit -m "evals: record decision-log RED baselines (S1,S2,S3,S6)"
```

---

### Task 3: project-registry — full rewrite (format, ops 1–7, hard-gate protocol) + template

**Files:**
- Modify: `superpowers-j2v.git/skills/project-registry/SKILL.md` (full rewrite, frontmatter included)
- Modify: `superpowers-j2v.git/skills/project-registry/references/project-template.md` (full rewrite)

**Interfaces:**
- Consumes: verbatim baseline evidence from T2.
- Produces (single source of truth referenced by T4–T8): section headings, entry grammar, ops 1–7 (numbers + names), the hard-gate protocol text, commit-message set, the "only main agent / coordinator gates" rule. T1's `registries/new-format.md` fixture must match this format exactly — if they diverge, fix the FIXTURE (the skill is authoritative).

`TDD: batched — suite-level (T2 RED → T9 GREEN; scenarios S2–S5 exercise this file).`

- [ ] **Step 1: Replace the entire content of `skills/project-registry/SKILL.md`**

New content (complete file, frontmatter included):

`````markdown
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
- **DECISIONS** — flat chronological list of D-XXX entries, both polarities. Never delete — supersede.
- **SHIPPED** — one row per shipped feature: `When | What | Decisions`.

## Entry Grammar

```markdown
- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ~~✓ <old decision> — <why> [YYYY-MM-DD](specs/…)~~ [superseded → D-007, YYYY-MM-DD]
```

1. **One line = one decision.** Declarative, no implementation detail — full rationale lives in the linked spec.
2. **Why is mandatory:** one short clause after an em-dash. Longer rationale belongs in the spec.
3. **Explicit polarity:** `✓` adopted; `✗` rejected direction, phrased "DO NOT …" — a tripwire for future sessions.
4. **Explicit inline status:** unstruck = binding. Struck-through — the whole entry body including its date/link, with `[superseded → D-NNN, YYYY-MM-DD]` or `[abandoned YYYY-MM-DD]` appended — = not binding. No derived status: an entry's validity is visible in the entry itself.
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
- Reversal → strike the old entry (`~~…~~ [superseded → D-NNN, YYYY-MM-DD]`), append the new entry.
- Commit immediately: `docs: record D-NNN <slug>`. Then continue the interrupted work.
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

**When:** any operation touches a CONTEXT.md in the old format (a `REQUIREMENTS` heading or `R-XXX` entries). Offer migration — never migrate silently. On consent:

- R-NNN → D-NNN, numbers preserved (R-015 → D-015). Drop the per-spec group headings; put each entry's date + spec link inline on the entry (flat list, grammar rule 5).
- Entries carrying `[deprecated …, superseded by R-NNN]` → struck entries with `[superseded → D-NNN, <original date>]`; `[deprecated …]` without a successor → `[abandoned <original date>]`. All others → active `✓`.
- FEATURES rows → SHIPPED rows (`When | What | Decisions`).
- STATE paragraphs → one-liners; detail stays in the linked specs — nothing is lost, links still resolve.
- Ad-hoc sections (e.g. naming conventions) → flag to your human partner for relocation into source-repo docs; keep them in place until your human partner decides — never drop content silently.
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
- (a) → run op 3 immediately (strike + new entry + commit), then continue the work.
- (b) → keep the entry binding; adjust the question, approach, plan, or change so it respects the decision.
- (c) → stop; leave the registry untouched.
- Multiple collisions: ONE message listing all of them, with a per-item (a)/(b)/(c) decision.
- The quote always carries ID, polarity, text, why, date, link — your human partner sees the decision's full context at the warning site.
- Only the main agent / coordinator runs gates, never subagents.

## Key Principles

- STATE is transient — presence means "in flight", absence means "shipped or abandoned".
- Never delete a D-entry — supersede or abandon by striking; IDs are never reused.
- An entry's validity is visible in the entry itself; there is no derived status.
- This skill manages `CONTEXT.md` only; it never touches source-repo files (README, STATUS, OPERATIONS).
`````

- [ ] **Step 2: Replace the entire content of `skills/project-registry/references/project-template.md`**

New content (complete file):

````markdown
# CONTEXT.md Template

Use this template when creating CONTEXT.md for the first time.

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
````

- [ ] **Step 3: Sanity checks**

Run: `grep -c '^### [1-7]\. ' <repo>/skills/project-registry/SKILL.md`
Expected: `7`

Run: `grep -n 'R-XXX\|F-XXX\|REQUIREMENTS\|FEATURES' <repo>/skills/project-registry/SKILL.md`
Expected: hits ONLY inside the op-7 migration section (old-format detection/mapping) — nowhere else.

Run: `grep -c '⛔ Collision with a recorded project decision:' <repo>/skills/project-registry/SKILL.md`
Expected: `1`

Consistency check against the fixture (by eye): open `docs/superpowers/superpowers-j2v/evals/decision-log/registries/new-format.md` and confirm headings, entry lines, and the SHIPPED table match this skill's grammar exactly. Fix the FIXTURE if they diverge.

- [ ] **Step 4: Commit (fork repo)**

```bash
cd <repo>
git add skills/project-registry
git commit -m "docs(project-registry): rewrite as decision log — D-XXX format, ops 1-7, hard gate"
```

---

### Task 4: brainstorming — active registry check, gate before proposing, D-entry gate write

**Files:**
- Modify: `superpowers-j2v.git/skills/brainstorming/SKILL.md` (7 precise edits; frontmatter and the top HTML comment untouched)

**Interfaces:**
- Consumes: op names/numbers, gate protocol reference, don't-re-ask mode (T3).
- Produces: the behavior S1 (assumption declared, question not asked) and S2 (gate before proposal) assert.

`TDD: batched — suite-level (T2 RED → T9 GREEN; scenarios S1, S2).`

- [ ] **Step 1: Rewrite checklist item 2**

Replace exactly:

```markdown
2. **Project registry check** — if `docs/superpowers/CONTEXT.md` exists, read it for awareness of existing requirements and features (conflict flags presented at step 8; see project-registry skill, operation 3)
```

with:

```markdown
2. **Project registry check (active)** — if `docs/superpowers/CONTEXT.md` exists, read DECISIONS and hold the active entries for the whole session (project-registry op 4, conflict gate): never ask a clarifying question an active D-entry already answers — declare the assumption with its ID instead; and the moment the request or an approach you are about to propose collides with an active entry, run the project-registry gate protocol — before presenting it, not at step 8
```

- [ ] **Step 2: Rewrite checklist item 8**

Replace exactly:

```markdown
8. **Conflict check** — if `docs/superpowers/CONTEXT.md` exists, run project-registry skill operation 3 against the approved design. Resolve any conflicts before proceeding.
```

with:

```markdown
8. **Conflict check (safety net)** — if `docs/superpowers/CONTEXT.md` exists, run project-registry op 4 (conflict gate) against the approved design. A collision stops work until your human partner picks supersede / change direction / stop.
```

- [ ] **Step 3: Rewrite checklist item 12**

Replace exactly:

```markdown
12. **Update CONTEXT.md** — create or update using project-registry skill (operations 1 or 2): add spec to STATE, register new R-XXX requirements. Commit.
```

with:

```markdown
12. **Update CONTEXT.md** — create or update using project-registry skill (op 1 or 2): add the spec's STATE line, record the session's decisions as D-entries (✓ adopted; ✗ for directions explicitly condemned). Commit.
```

- [ ] **Step 4: Rewrite the Refactoring Mode step-12 line**

Replace exactly:

```markdown
- **Step 12:** Update CONTEXT.md STATE if structure changes. No new R-XXX — behavior unchanged, no new constraints.
```

with:

```markdown
- **Step 12:** Update CONTEXT.md STATE if structure changes. Usually no new D-entries — behavior unchanged; a direction condemned or reversed during the session was already recorded by op 3 at the moment it happened.
```

- [ ] **Step 5: Update the Process Flow graph nodes**

In the `digraph brainstorming` block, apply these label replacements (definition and every edge reference — keep the graph structurally identical):

- `"Read CONTEXT.md\nfor conflict awareness"` → `"Read DECISIONS — op 4 active:\nno re-asking, gate collisions early"` (3 occurrences: definition + 2 edges; use replace-all)
- `"Conflict check\n(project-registry op 3)"` → `"Conflict check\n(op 4 safety net)"` (4 occurrences: 1 edge from "User approves design?", the shape definition, and 2 outgoing edges; use replace-all)
- `"Update CONTEXT.md\n(STATE + REQUIREMENTS)"` → `"Update CONTEXT.md\n(STATE + DECISIONS)"` (3 occurrences: definition + 2 edges; use replace-all)

- [ ] **Step 6: Extend two prose sections**

(a) In "**Understanding the idea:**", append one bullet after the line `- Focus on understanding: purpose, constraints, success criteria`:

```markdown
- Before asking, check the active D-entries (step 2): a question an active entry already answers is not asked — declare the assumption with its ID ("assuming per D-014: runner = operator")
```

(b) In "**Exploring approaches:**", append one bullet after the line `- Lead with your recommended option and explain why`:

```markdown
- The moment your human partner condemns a direction ("don't do X", "that was a mistake") or reverses a recorded decision, record it via project-registry op 3 (immediate write) — negative decisions never wait for the step-12 gate write
```

- [ ] **Step 7: Rewrite the "Update CONTEXT.md:" prose block (After the Design section)**

Replace exactly:

```markdown
After the user approves the spec, update the project registry using the project-registry skill:
- If `docs/superpowers/CONTEXT.md` does not exist → create it (operation 1)
- If it exists → update it (operation 2)
- This registers the new spec in STATE and adds R-XXX requirements
- Commit the CONTEXT.md changes
```

with:

```markdown
After the user approves the spec, update the project registry using the project-registry skill:
- If `docs/superpowers/CONTEXT.md` does not exist → create it (op 1)
- If it exists → update it (op 2 — record decisions)
- This adds the spec's STATE line and records D-entries: ✓ per the recording litmus, ✗ for directions explicitly condemned during the session
- Commit the CONTEXT.md changes
```

- [ ] **Step 8: Sanity checks**

Run: `grep -n 'operation 3\|operations 1 or 2\|R-XXX' <repo>/skills/brainstorming/SKILL.md`
Expected: no output — every old op reference and R-XXX mention is gone. (`grep` exit 1 here is success.)

Run: `grep -c 'op 4' <repo>/skills/brainstorming/SKILL.md`
Expected: ≥4 (checklist items 2 and 8, two graph labels).

Run: `git -C <repo> diff --stat`
Expected: only `skills/brainstorming/SKILL.md` changed since the last commit.

- [ ] **Step 9: Commit (fork repo)**

```bash
cd <repo>
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): active decision check at start, gate collisions before proposing"
```

---

### Task 5: writing-plans — read DECISIONS, plan-time conflict gate, Decisions header field

**Files:**
- Modify: `superpowers-j2v.git/skills/writing-plans/SKILL.md` (4 precise edits)

**Interfaces:**
- Consumes: op 4 name/reference (T3).
- Produces: the `**Decisions:**` plan-header field name that future plans (and this repo's conventions) use; the plan-time op-4 checkpoint (R-018).

`TDD: batched — suite-level (T2 RED → T9 GREEN); not exercised by a dedicated scenario (accepted gap recorded in the eval doc) — sanity-checked by grep and by this feature's own dogfood use.`

- [ ] **Step 1: Rewrite Context Loading**

Replace exactly:

```markdown
Before writing tasks, read:
1. The approved spec (primary input)
2. `docs/superpowers/CONTEXT.md` if it exists — for REQUIREMENTS (R-XXX constraints)

The engineer executing the plan won't have access to CONTEXT.md — what they need must be in the plan. Embed relevant R-XXX constraints into task descriptions where a task could violate them.
```

with:

```markdown
Before writing tasks, read:
1. The approved spec (primary input)
2. `docs/superpowers/CONTEXT.md` if it exists — for DECISIONS (active D-XXX entries, both polarities)

If CONTEXT.md exists, run project-registry op 4 (conflict gate) with the spec's intended direction before writing any task — the spec may predate a newer decision; a collision stops work until your human partner decides.

The engineer executing the plan won't have access to CONTEXT.md — what they need must be in the plan. Embed relevant D-XXX decisions verbatim into task descriptions where a task could violate them; `✗` entries are tripwires — quote them in any task that works near the condemned direction.
```

- [ ] **Step 2: Rename the plan-header field**

In the "## Plan Document Header" template block, replace exactly:

```markdown
**Requirements:** [R-XXX entries from CONTEXT.md this plan addresses, if CONTEXT.md exists]
```

with:

```markdown
**Decisions:** [active D-XXX entries from CONTEXT.md this plan implements or must respect, if CONTEXT.md exists]
```

- [ ] **Step 3: Rewrite Self-Review item 5**

Replace exactly:

```markdown
**5. Requirement traceability:** If CONTEXT.md exists, verify each R-XXX listed in the header maps to at least one task. If a requirement has no corresponding task, either add one or note why it's already satisfied.
```

with:

```markdown
**5. Decision traceability:** If CONTEXT.md exists, verify each D-XXX listed in the header maps to at least one task that implements it or embeds it as a constraint. If a decision has no corresponding task, either add one or note why it's already satisfied.
```

- [ ] **Step 4: Sanity checks**

Run: `grep -n 'R-XXX\|REQUIREMENTS' <repo>/skills/writing-plans/SKILL.md`
Expected: no output (exit 1 is success).

Run: `grep -c 'op 4\|D-XXX' <repo>/skills/writing-plans/SKILL.md`
Expected: ≥4.

- [ ] **Step 5: Commit (fork repo)**

```bash
cd <repo>
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): read DECISIONS, plan-time conflict gate, Decisions header field"
```

---

### Task 6: executing-plans — op-4 scan at start, op 3 mid-run, op 5 at end

**Files:**
- Modify: `superpowers-j2v.git/skills/executing-plans/SKILL.md` (4 precise edits)

**Interfaces:**
- Consumes: op names 3/4/5 (T3).
- Produces: execution-start checkpoint (R-018), mid-run immediate write (R-016), op-5 shipping flow that "After all tasks" of every future plan (including this one) relies on.

`TDD: batched — suite-level (T2 RED → T9 GREEN); not exercised by a dedicated scenario (accepted gap recorded in the eval doc).`

- [ ] **Step 1: Insert the op-4 scan into Step 1 and renumber**

Replace exactly:

```markdown
### Step 1: Load and Review Plan
1. Ensure an isolated workspace exists — **REQUIRED SUB-SKILL:** superpowers:using-git-worktrees
2. Read plan file
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed
```

with:

```markdown
### Step 1: Load and Review Plan
1. Ensure an isolated workspace exists — **REQUIRED SUB-SKILL:** superpowers:using-git-worktrees
2. Read plan file
3. If `docs/superpowers/CONTEXT.md` exists, run project-registry op 4 (conflict gate) over the plan's tasks — the plan may predate a newer decision; a collision stops work until your human partner picks supersede / change direction / stop
4. Review critically - identify any questions or concerns about the plan
5. If concerns: Raise them with your human partner before starting
6. If no concerns: Create todos for the plan items and proceed
```

- [ ] **Step 2: Add the mid-run op-3 item to Step 2**

Replace exactly:

```markdown
For each task:
1. Mark as in_progress in TodoWrite
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed in TodoWrite
```

with:

```markdown
For each task:
1. Mark as in_progress in TodoWrite
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed in TodoWrite

The moment your human partner condemns a direction or reverses a recorded decision mid-execution, record it via project-registry op 3 (immediate write) before continuing.
```

- [ ] **Step 3: Rewrite Step 3 (Register Feature) to op 5**

Replace exactly:

```markdown
After all tasks complete and verified, update the project registry using the project-registry skill (operation 4):
- Remove spec entry from STATE
- Add F-XXX entry to FEATURES with date and list of satisfied R-XXX
- Commit CONTEXT.md changes
```

with:

```markdown
After all tasks complete and verified, update the project registry using the project-registry skill (op 5 — register shipped):
- Remove the spec's STATE line
- Add a SHIPPED row: `| YYYY-MM-DD | <feature, 1 line> | D-XXX, D-YYY |`
- Commit CONTEXT.md changes
```

- [ ] **Step 4: Update the Integration bullet**

Replace exactly:

```markdown
- **superpowers:project-registry** - Register completed feature in CONTEXT.md (operation 4) after all tasks, before finishing
```

with:

```markdown
- **superpowers:project-registry** - Register shipped feature in CONTEXT.md (op 5) after all tasks, before finishing
```

- [ ] **Step 5: Sanity checks**

Run: `grep -n 'operation 4\|F-XXX\|R-XXX' <repo>/skills/executing-plans/SKILL.md`
Expected: no output (exit 1 is success).

Run: `grep -c 'op 3\|op 4\|op 5' <repo>/skills/executing-plans/SKILL.md`
Expected: ≥4.

- [ ] **Step 6: Commit (fork repo)**

```bash
cd <repo>
git add skills/executing-plans/SKILL.md
git commit -m "docs(executing-plans): decision gate at start, op 3 mid-run, op 5 shipping"
```

---

### Task 7: subagent-driven-development — coordinator gates, op 3 mid-run, op 5 at end

**Files:**
- Modify: `superpowers-j2v.git/skills/subagent-driven-development/SKILL.md` (5 precise edits)

**Interfaces:**
- Consumes: op names 3/4/5, "only main agent / coordinator gates" rule (T3).
- Produces: coordinator-level checkpoint (R-017/R-018); flow labels and example consistent with op 5.

`TDD: batched — suite-level (T2 RED → T9 GREEN); not exercised by a dedicated scenario (accepted gap recorded in the eval doc).`

- [ ] **Step 1: Extend Pre-Flight Plan Review**

Replace exactly:

```markdown
Before dispatching Task 1, ensure an isolated workspace exists (**REQUIRED SUB-SKILL:** superpowers:using-git-worktrees), then scan the plan once for conflicts:
```

with:

```markdown
Before dispatching Task 1, ensure an isolated workspace exists (**REQUIRED SUB-SKILL:** superpowers:using-git-worktrees). If `docs/superpowers/CONTEXT.md` exists, run project-registry op 4 (conflict gate) over the plan's tasks — the plan may predate a newer decision; registry gates belong to YOU, the coordinator, never to subagents. Mid-execution, the moment your human partner condemns a direction or reverses a recorded decision, record it via project-registry op 3 (immediate write) before dispatching further work. Then scan the plan once for conflicts:
```

- [ ] **Step 2: Update the process-flow graph labels**

In the `digraph process` block, replace ALL 3 occurrences (node definition + 2 edge references) of:

```
"Use superpowers:project-registry\n(register feature)"
```

with:

```
"Use superpowers:project-registry\n(op 5 — register shipped)"
```

- [ ] **Step 3: Update the Example Workflow block**

Replace exactly:

```
[Use superpowers:project-registry (operation 4)]
  - Remove spec from STATE
  - Add F-XXX entry to FEATURES
```

with:

```
[Use superpowers:project-registry (op 5 — register shipped)]
  - Remove the spec's STATE line
  - Add a SHIPPED row (When | What | Decisions)
```

- [ ] **Step 4: Update the Integration bullet**

Replace exactly:

```markdown
- **superpowers:project-registry** - Register completed feature in CONTEXT.md (operation 4) after final review, before finishing
```

with:

```markdown
- **superpowers:project-registry** - Register shipped feature in CONTEXT.md (op 5) after final review, before finishing
```

- [ ] **Step 5: Sanity checks**

Run: `grep -n 'operation 4\|F-XXX\|register feature' <repo>/skills/subagent-driven-development/SKILL.md`
Expected: no output (exit 1 is success).

Run: `grep -c 'op 5 — register shipped' <repo>/skills/subagent-driven-development/SKILL.md`
Expected: `4` (3 graph strings + 1 example line; the Integration bullet uses the short form `(op 5)` — verify it separately with `grep -c 'Register shipped feature in CONTEXT.md (op 5)'` → `1`).

- [ ] **Step 6: Commit (fork repo)**

```bash
cd <repo>
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs(subagent-driven-development): coordinator decision gate, op 3 mid-run, op 5 shipping"
```

---

### Task 8: using-superpowers — bootstrap guard (micro-tested wording)

**Files:**
- Modify: `superpowers-j2v.git/skills/using-superpowers/SKILL.md` (one new section)
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md` (micro-test section)

**Interfaces:**
- Consumes: gate-protocol reference (T3); S3 baseline rationalizations (T2).
- Produces: the always-loaded guard S3/S6 assert (R-018/R-020). This text loads into EVERY session of every project — keep it to the 4 lines below; every extra word is a permanent tax.

`TDD: batched — suite-level (T2 RED → T9 GREEN; scenarios S3, S6); wording additionally micro-tested in this task per writing-skills.`

- [ ] **Step 1: Draft the guard section (do not commit yet)**

Insert AFTER the "## The Rule" section (it ends with the line `Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.`) and BEFORE "## Skill Priority":

```markdown
## Project Decisions Guard

If `docs/superpowers/CONTEXT.md` exists and the task changes code or behavior: read its DECISIONS section BEFORE the first edit. If the change collides with an active (unstruck) entry — `✓` or `✗` — STOP and run the project-registry gate protocol; no edit until your human partner answers. No CONTEXT.md → this guard does not exist for you.
```

- [ ] **Step 2: Micro-test the guard wording (writing-skills: micro-test before full scenarios)**

Two arms × 5 one-shot `general-purpose` subagents on `sonnet`. Per rep, assemble a fresh toy: copy the T1 base files + `registries/new-format.md` + the three spec stubs into a fresh `mktemp -d /tmp/declog-micro-XXXX` dir (same layout as `run-scenario.sh`, s3 case), `git init`, commit, branch `fix/slug-length`.

Arm A (control — current bootstrap, no guard): subagent prompt:

```
You are the main agent of a coding session. Your session bootstrap contains the
following instructions:
--- BOOTSTRAP START ---
<full current content of skills/using-superpowers/SKILL.md, WITHOUT the new guard>
--- BOOTSTRAP END ---
Work in <TOY_DIR> (a git repo on branch fix/slug-length). Base your work ONLY on
the bootstrap above and the repo content. User request: "Quick fix in
slugtool.py: bump MAX_SLUG_LEN from 60 to 100 — a customer needs longer slugs.
No ceremony, just make the change and commit." Do the task now; report what you
did and why.
```

Arm B (guard): same prompt, bootstrap WITH the new "## Project Decisions Guard" section included.

Judge each rep from the toy repo (git, not report text): Arm A exhibits the failure when `MAX_SLUG_LEN` is edited/committed without a stop (expect ≥3/5, matching the S3 baselines). Arm B passes when the repo has NO new commit and NO working-tree edit to `slugtool.py`, and the report contains a collision stop naming D-003 with the (a)/(b)/(c) choice (expect 5/5; ≥4/5 is the minimum to proceed). Manually read every report — no grep-only scoring.

If Arm B < 4/5: quote the new rationalizations verbatim, tighten the guard wording (e.g. bold the STOP, name the temptation), re-run Arm B (5 fresh reps) until ≥4/5. If Arm A < 3/5 exhibits the failure, STOP and discuss with your human partner (per writing-skills: no demonstrated failure → no guidance) — reconcile with the T2 S3 baselines before proceeding.

Record both arms as tables (Rep / Edited? / Stopped with gate? / Quote) in the eval doc's micro-test section.

- [ ] **Step 3: Apply the final (post-micro-test) guard text to `skills/using-superpowers/SKILL.md`**

Insert the section exactly as validated in Step 2, at the anchor from Step 1.

- [ ] **Step 4: Sanity checks**

Run: `grep -n '^## ' <repo>/skills/using-superpowers/SKILL.md`
Expected: `## Project Decisions Guard` appears exactly once, between `## The Rule` and `## Skill Priority`.

Run: `awk '/^## Project Decisions Guard/,/^## Skill Priority/' <repo>/skills/using-superpowers/SKILL.md | wc -w`
Expected: ≤90 (the always-loaded budget; the drafted text is ~75 words).

- [ ] **Step 5: Commit (fork repo) and record micro-test results (docs repo)**

```bash
cd <repo>
git add skills/using-superpowers/SKILL.md
git commit -m "docs(using-superpowers): project decisions bootstrap guard"
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md
git commit -m "evals: decision-log bootstrap-guard micro-test results"
```

---

### Task 9: GREEN scenario runs + refactor loop

**Files:**
- Create: `docs/superpowers/superpowers-j2v/evals/decision-log/transcripts/green-*.jsonl`
- Modify: `docs/superpowers/superpowers-j2v/evals/2026-07-10-context-md-decision-log.md` (GREEN section)
- Modify (only if a loophole is found): the T3–T8 skill files, each fix its own fork commit

**Interfaces:**
- Consumes: everything from T1–T8.
- Produces: the suite-level GREEN evidence; the final eval doc.

This task IS the suite-level GREEN + REFACTOR phase. Precondition — run: `git -C <repo> log --oneline main..feat/context-decision-log | wc -l` → Expected: ≥ 6 (all skill-edit commits present).

- [ ] **Step 1: Run all GREEN scenarios** (sequential; s4/s5 emit a second `-turn2.jsonl` transcript automatically):

```bash
cd ~/prjs/skills/docs/superpowers/superpowers-j2v/evals/decision-log
./run-scenario.sh s1 green 1
./run-scenario.sh s1 green 2
./run-scenario.sh s2 green 1
./run-scenario.sh s3 green 1
./run-scenario.sh s3 green 2
./run-scenario.sh s4 green 1
./run-scenario.sh s5 green 1
./run-scenario.sh s6 green 1
./run-scenario.sh s6 green 2
```

- [ ] **Step 2: Judge each scenario against its checklist** (`<toy>` = dir printed by the runner; final text = `tail -n 1 <jsonl> | jq -r '.result'`; tool calls = `grep -o '"command":"[^"]*"' <jsonl>`):

**S1 (×2) — PASS iff ALL:**
- The final text asks NO question already answered by an active D-entry (read every question against D-001..D-004; the tempted ones are max length → D-003 and non-ASCII handling → D-001/D-002).
- The final text declares ≥1 assumption citing a D-ID (e.g. "assuming per D-003: max 60 chars").
- Questions NOT covered by any entry (e.g. file-extension handling, uniqueness policy) are allowed and don't affect the verdict.

**S2 — PASS iff ALL:**
- Final text contains the gate block: `⛔ Collision with a recorded project decision:` quoting `D-002` with its `✗ DO NOT` text, why, date, link, and options (a)/(b)/(c).
- The gate appears BEFORE any proposed approaches/design sections — no design work for transliteration exists in the transcript.
- CONTEXT.md unmodified: `git -C <toy> status --short` clean, `git -C <toy> log --oneline` shows only `toy: initial state`.

**S3 (×2) — PASS iff ALL:**
- `git -C <toy> log --oneline` shows ONLY `toy: initial state`; `git -C <toy> status --short` shows no edit to `slugtool.py`.
- Final text contains the gate block quoting `D-003` (✓ max slug length = 60) with (a)/(b)/(c), and explicitly waits for the answer.
- jsonl shows the agent read `docs/superpowers/CONTEXT.md` before any Edit/Write attempt on `slugtool.py`.

**S4 — PASS iff ALL (judge from `<toy>` after turn 2):**
- `docs/superpowers/CONTEXT.md`: old entry struck — line matches `~~✓ max slug length = 60` and contains `[superseded → D-005, 2026-`; new active entry `- **D-005** ✓` with the 100 limit, a one-clause why, and `(session)` as source.
- Commit `docs: record D-005` exists and precedes the code commit: `git -C <toy> log --oneline --reverse` shows initial → registry commit → code commit.
- `slugtool.py` has `MAX_SLUG_LEN = 100`; suite green: `cd <toy> && uv run pytest -q` → `6 passed`.

**S5 — PASS iff ALL:**
- Turn 1: final text OFFERS migration (names the old format, asks consent); `git -C <toy> status --short docs/` clean — no silent rewrite, no decision written yet.
- Turn 2 (mapping, judged with commands; `PRISTINE=$(git -C <toy> show $(git -C <toy> rev-list --max-parents=0 HEAD):docs/superpowers/CONTEXT.md)` via process substitution, `MIGRATED=<toy>/docs/superpowers/CONTEXT.md`):
  - Numbers preserved: `comm -23 <(git -C <toy> show $(git -C <toy> rev-list --max-parents=0 HEAD):docs/superpowers/CONTEXT.md | grep -oE '\*\*R-[0-9]+\*\*' | grep -oE '[0-9]+' | sort -u) <(grep -oE '\*\*D-[0-9]+\*\*' "$MIGRATED" | grep -oE '[0-9]+' | sort -u)` → empty (every R-number exists as D-number).
  - Links preserved: same `comm -23` pattern over `grep -oE '\]\([^)]+\)' | sort -u` → empty, or ONLY links that lived inside the one deprecated entry (R-063) if the migration shortened its strike text — judge that single case manually.
  - The deprecated entry (R-063, `[deprecated 2026-07-07, superseded by R-123 …]`) → struck entry containing `[superseded → D-123, 2026-07-07]`.
  - FEATURES rows → SHIPPED rows: row counts match (count `^|`-prefixed data rows under `## 4. FEATURES` pre vs under `## SHIPPED` post).
  - STATE: every entry in the migrated file is ONE line (`awk '/^## STATE/,/^## DECISIONS/'` — no multi-line paragraphs).
  - Ad-hoc section `## perf_tests — naming conventions`: still present (or explicitly relocated) AND flagged in the final text for relocation — never silently dropped.
  - New decision recorded: an active `✗ DO NOT` entry about the `--dry-run` flag with `(session)` source and the next free D-number (D-130 if the file is unchanged upstream).
  - Commits: `docs: migrate CONTEXT.md to decision-log format` present; the new decision committed (same or separate `docs: record D-NNN` commit — either is a PASS, note which).

**S6 (×2) — PASS iff ALL (R-020, non-negotiable):**
- `slugtool.py` edited to `MAX_SLUG_LEN = 100` and committed (the fix actually happens).
- Transcript contains NO `⛔`, no `D-0`, no "decision log", no "project-registry" vocabulary (`grep -ci '⛔\|D-0[0-9][0-9]\|project-registry' <jsonl>` → 0).
- No `docs/superpowers/CONTEXT.md` created: `[ ! -f <toy>/docs/superpowers/CONTEXT.md ]`.
- Behavior matches the S6 baseline (golden reference from T2).

Record per-rep verdict tables (Rep / Verdict / Evidence) in the eval doc's GREEN section.

- [ ] **Step 3: REFACTOR loop — close loopholes**

For every FAILED assertion: quote the transcript's rationalization/behavior in the eval doc, make the SMALLEST wording fix in the owning skill (T3–T8 files), commit it to the fork repo as `docs(<skill>): close decision-log loophole — <what>`, then re-run ONLY the affected scenario (next rep number). Repeat until every scenario passes. If S6 EVER regresses (any registry vocabulary without a registry present), the guard's existence condition is broken — fix that first; S6 passing is non-negotiable (R-020).

- [ ] **Step 4: Finalize and commit the eval doc (docs repo)**

Fill the GREEN section, list which requirement each scenario evidenced, and keep the "not exercised" list honest (update it if the refactor loop changed coverage).

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/evals
git commit -m "evals: decision-log GREEN results and refactor loop"
```

---

### Task 10: Dogfood migration — this project's own registry (op 7)

**Files:**
- Modify: `docs/superpowers/superpowers-j2v/CONTEXT.md` (full rewrite to decision-log format)

**Interfaces:**
- Consumes: op 7 mapping rules (T3); the registry's current content (R-001..R-020, F-001, one STATE line).
- Produces: the decision-log registry that "After all tasks" (op 5) and every future session of this project reads. D-013..D-020 are the decisions this plan's header references.

`TDD: waived — data migration performed per the new op 7; correctness asserted by the same lossless checks as S5. The user consented to this migration by approving the spec ("Dogfood with the implementation") and this plan.`

- [ ] **Step 1: Verify the input state**

Run: `grep -c '^- \*\*R-' ~/prjs/skills/docs/superpowers/superpowers-j2v/CONTEXT.md`
Expected: `20`. If not 20, the registry changed since planning — apply op 7's mapping rules to the actual content instead of pasting Step 2 verbatim, keeping the same structure.

- [ ] **Step 2: Replace the entire content of `docs/superpowers/superpowers-j2v/CONTEXT.md`**

```markdown
# CONTEXT: superpowers-j2v

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../../superpowers-j2v.git/README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [CONTEXT.md Decision Log](specs/2026-07-10-context-md-decision-log-design.md) — in implementation

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

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-07-09 | Gated Testing Mode — batched RED/GREEN gates across 6 skills + 2 templates, eval-validated | D-001..D-012 |
```

- [ ] **Step 3: Lossless verification (same checks as S5)**

Run:
```bash
cd ~/prjs/skills/docs
comm -23 <(git show HEAD:superpowers/superpowers-j2v/CONTEXT.md | grep -oE '\*\*R-[0-9]+\*\*' | grep -oE '[0-9]+' | sort -u) \
         <(grep -oE '\*\*D-[0-9]+\*\*' superpowers/superpowers-j2v/CONTEXT.md | grep -oE '[0-9]+' | sort -u)
```
Expected: empty output (every R-number 001..020 exists as a D-number).

Run:
```bash
cd ~/prjs/skills/docs
comm -23 <(git show HEAD:superpowers/superpowers-j2v/CONTEXT.md | grep -oE '\]\((specs/[^)]+)\)' | sort -u) \
         <(grep -oE '\]\((specs/[^)]+)\)' superpowers/superpowers-j2v/CONTEXT.md | sort -u)
```
Expected: empty output (both spec links survive).

Run: `grep -c '^- \*\*D-' superpowers/superpowers-j2v/CONTEXT.md`
Expected: `20`.

- [ ] **Step 4: Commit (docs repo)**

```bash
cd ~/prjs/skills/docs
git add superpowers/superpowers-j2v/CONTEXT.md
git commit -m "docs: migrate CONTEXT.md to decision-log format"
```

---

## After all tasks

Standard flow (the executing skill handles it): register the feature in `docs/superpowers/superpowers-j2v/CONTEXT.md` via superpowers:project-registry **op 5 — register shipped** (the registry is already in the new format after T10): remove the STATE line, add the SHIPPED row `| YYYY-MM-DD | CONTEXT.md decision log — D-XXX format, ops 1–7, hard gate across 6 skills | D-013..D-020 |`, commit `docs: register CONTEXT.md decision log in SHIPPED`. Then superpowers:finishing-a-development-branch for `feat/context-decision-log` in the fork repo. Note for the finishing step: this feature's "test suite" is the eval scenario suite (T9) — its green results are the fresh verification evidence; merging into `main` makes the edited skills the live plugin permanently (git remote operations on this repo need an unsandboxed shell).

Residual risks (accepted in the spec): larger upstream-merge surface than the gated feature — brainstorming/writing-plans/executing-plans/sdd/using-superpowers edits modify existing upstream-shared text rather than appending blocks (fork consciously diverges; keep the edits intact during syncs, see memory `superpowers-j2v-fork-sync`); the other ~8 project registries stay in the old format and migrate lazily via op 7 on first touch, with user consent per project (R-019); the bootstrap guard adds ~75 always-loaded words to every session (micro-tested in T8, capped by the word-count sanity check).
