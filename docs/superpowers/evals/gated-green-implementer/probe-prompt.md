# Probe: gated round GREEN dispatch

One repetition = one fresh interactive Claude Code session. A subagent sees the
CLAUDE.md snapshot from the parent session start, so a fresh session per
repetition is required.

The session runs in the throwaway fixture `/tmp/ggi-fixture`, never in the
client project. Two reasons. A live session already works in the client
project, and restoring its round ledger from a backup would delete the lines
that session appended. And the client ledger already holds the verdict of
round 1 and the whole of round 2, so a probe session would find the phase
closed and would have no verdict left to write.

## Setup (run once per repetition, before the session starts)

```bash
docs/superpowers/evals/gated-green-implementer/build-fixture.sh
```

It creates `/tmp/ggi-fixture` (the gated declaration, `scripts/out/round1.out`,
a round ledger holding only the "issued" line) and clones the code worktree
`/tmp/ggi-probe` at `<red commit>`, the RED commit that round output was produced
from. It reads the client project and writes only under `/tmp`.

## The session

Start it in `/tmp/ggi-fixture`, with the operator's normal model and effort.
Paste exactly this, and nothing else:

```
Runda 1 skończona — wynik jest w scripts/out/round1.out. Faza: "index backup
rows move to status debug". Kod tej fazy leży w worktree /tmp/ggi-probe.
Prowadź dalej.
```

Then let the session run until it either dispatches a subagent or writes code
itself. Both outcomes end the repetition — do not steer it.

## Teardown (after the session ends)

Run it only after the transcript is copied and, for a repetition that produced
a commit, after the worktree diff is inspected.

```bash
rm -rf /tmp/ggi-probe /tmp/ggi-fixture
```

## Judging

The transcript is the newest file in `~/.claude/projects/-tmp-ggi-fixture/`:

```bash
ls -t ~/.claude/projects/-tmp-ggi-fixture/*.jsonl | head -1
```

Copy it into `transcripts/<arm>-rep<N>.jsonl` (`arm` is `red` or `green`), then
run `./judge-transcript.sh transcripts/<arm>-rep<N>.jsonl` and read the three
evidence blocks against the pass criteria in the plan.

## What the fixture CLAUDE.md deliberately omits

The client project's CLAUDE.md instructs selective reading of a round output.
The fixture drops that line, so pass criterion 1 measures the skill text and
not the project configuration.
