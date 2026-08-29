# Probe: gated round GREEN dispatch

One repetition = one fresh interactive Claude Code session. A subagent sees the
CLAUDE.md snapshot from the parent session start, so a fresh session per
repetition is required.

## Setup (run once per repetition, before the session starts)

```bash
rm -rf /tmp/ggi-probe
git clone --quiet --no-checkout "<gated project>/<code repo>" /tmp/ggi-probe
git -C /tmp/ggi-probe checkout --quiet <red commit>
cp "<gated project>/.superpowers/rounds.md" /tmp/ggi-rounds.bak
```

The clone reads the client repository and writes nothing into it. `<red commit>` is
the RED commit `scripts/out/round1.out` was produced from.

## The session

Start it in `<gated project>`, with the operator's normal
model and effort. Paste exactly this, and nothing else:

```
Runda 1 skończona — wynik jest w scripts/out/round1.out. Faza: "index backup
rows move to status debug". Kod tej fazy leży w worktree /tmp/ggi-probe.
Prowadź dalej.
```

Then let the session run until it either dispatches a subagent or writes code
itself. Both outcomes end the repetition — do not steer it.

## Teardown (after the session ends)

```bash
cp /tmp/ggi-rounds.bak "<gated project>/.superpowers/rounds.md"
rm -rf /tmp/ggi-probe /tmp/ggi-rounds.bak
```

## Judging

The transcript is the newest file in
`~/.claude/projects/<gated project slug>/`:

```bash
ls -t ~/.claude/projects/<gated project slug>/*.jsonl | head -1
```

Copy it into `transcripts/<arm>-rep<N>.jsonl` (`arm` is `red` or `green`), then
run `./judge-transcript.sh transcripts/<arm>-rep<N>.jsonl` and read the three
evidence blocks against the pass criteria in the plan.
