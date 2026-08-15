# Debugging Subagents

Every phase of systematic debugging is dispatched: subagents read the evidence and return short syntheses, so the main session keeps its context for the hypothesis, the ledger, and the conversation with your human partner. Read this file before you dispatch anything — not after, not from memory.

## Roles And Models

| Role | Phase | Agent | Model | Character |
|---|---|---|---|---|
| Investigator — errors, reproduction, recent changes | 1 | `Explore` | `sonnet` | relay: read and report with evidence |
| Investigator — component-boundary evidence | 1 | `Explore` | `sonnet` | relay |
| Investigator — data-flow tracing | 1 | `Explore` | session model (omit `model`) | reasoning across the call stack |
| Pattern analyst | 2 | `Explore` | session model (omit `model`) | reasoning: find the difference that matters |
| Experimenter | 3 | `general-purpose` | `sonnet` | run one prescribed experiment, report verbatim output |
| Fixer | 4 | `general-purpose` | session model (omit `model`) | reasoning: failing test first, then the fix |
| Rescue — second fixer failure | 4 | `sdd-rescue` | opus/high, from the agent definition | one decisive jump, not an effort ladder |

Model follows the character of the work, not its price. Sonnet is faster and hallucinates less on relay work. The reasoning paths take the session model from round one, because a miss there returns as "nothing suspicious" and you cannot see what it missed.

**Name the dispatch target explicitly on every call.** An omitted `model` inherits your session model — deliberate for the reasoning roles, wrong for the relay ones. Effort is not a dispatch parameter: an inline `effort:` field is ignored, so per-role effort exists only inside predefined agents such as `sdd-rescue`. When `Explore` or `sdd-rescue` is missing from your agent registry, dispatch `general-purpose` instead and keep the model column above.

Subagents do not inherit your session history. Every prompt carries what it needs.

## Phase 1 — Investigators

Send 2-4 investigators in ONE message. Several dispatch calls in one response run concurrently; one call per response runs them one after another (superpowers:dispatching-parallel-agents). Each gets exactly one path, and no two get the same path.

### Investigator prompt template

```
You are a read-only debugging investigator. Investigate ONE path and report
what the evidence shows. You are not fixing anything and you are not deciding
anything.

Symptom: <the failure as observed — the exact command, its exit status, the
first error line>
Project: <one paragraph — what it is, what it is built with, how tests run>
Your path: <exactly one of: read the error output and the stack trace end to
end | reproduce it and establish whether it is deterministic | find what
changed recently, through git log, git diff, dependency and config changes |
instrument the component boundaries and show which boundary breaks | trace the
bad value backward to where it originates>
Out of scope: every other path — other investigators have them.

Rules:
- Do NOT edit source files. Do NOT commit. Do NOT propose a fix.
- Temporary instrumentation is allowed only on the boundary path. Remove it
  before you finish and say that you removed it.
- Quote evidence. Never paraphrase an error message.
- Report what you could NOT establish instead of filling the gap with a
  plausible guess. "Nothing suspicious on this path" is a valid result.

Return EXACTLY this structure:

## Synthesis
15 lines maximum. What this path shows about where the failure comes from.

## Evidence
For each claim above: the exact command you ran and the verbatim lines it
produced, or the file path with line numbers and the verbatim lines.

## Not established
What your path could not settle, and what would settle it.
```

You merge the reports. A path that returns "nothing suspicious" is a result, not a gap — decide whether the trace is genuinely absent or the investigator missed it, and re-dispatch that path with a sharper prompt when you cannot tell.

## Phase 2 — Pattern Analyst

Dispatch one analyst, and only when a working counterpart exists — similar code in the same codebase that works. With no counterpart there is nothing to compare and the phase is skipped, never faked.

### Pattern analyst prompt template

```
You are a read-only pattern analyst. Compare a broken implementation with a
working counterpart and report the differences. You are not fixing anything.

Symptom: <the failure as observed>
Broken: <file:line range>
Working counterpart: <file:line range — code that does the same kind of thing
and works>
Reference implementation, if any: <path or URL — read it completely, do not
skim>

Rules:
- List EVERY difference you find, including the ones that look irrelevant.
- Then name the single difference you can tie to the symptom, and show how.
- Answer "none of these explains the symptom" when that is what you found. Do
  not promote the most interesting difference to a cause.
- Do NOT edit any file.

Return EXACTLY this structure:

## Differences
One line each: what differs, and where — file:line on both sides.

## Tied to the symptom
The one difference you can connect to the failure, with the lines that show
the connection — or "none".

## Dependencies and assumptions
What the working counterpart has that the broken code does not: config,
environment, initialization order, callers.
```

## Phase 3 — Experimenter

The hypothesis is yours. The experimenter runs it and reports; it never forms one and never judges one.

### Experimenter prompt template

```
You are a debugging experimenter. Run ONE prescribed experiment and report
what happened. You are not diagnosing and you are not fixing.

Hypothesis under test (context only — judging it is not your job):
<the hypothesis>
Experiment: <the exact command, or the exact minimal change plus the command
that exercises it>
Expected if the hypothesis holds: <what the output would show>
Expected if it does not: <what the output would show instead>

Rules:
- Run exactly this experiment. Do not extend it. Do not fix anything you find.
- If you changed a file to run it, revert the change before you finish and say
  that you reverted it. `git diff` must come back empty.
- Return the output verbatim, including the parts that look irrelevant.

Return EXACTLY this structure:

## Command
<what you ran, verbatim>

## Output
<verbatim; trim only the head or the tail, and mark where you trimmed>

## Verdict
confirmed | refuted — one sentence tying the output to the two expectations
above.

## Instrumentation
reverted, `git diff` empty | none added
```

A refuted hypothesis goes into the ledger and the next hypothesis is yours to form. Never send a second experiment on the same guess.

## Phase 4 — Fixer

### Fixer prompt template

```
You are a debugging fixer. Fix ONE root cause, test first.

Root cause (established — do not re-investigate): <the synthesis from the
ledger, including the file and line where the bad value originates>
Already ruled out: <the refuted hypotheses, one line each>
Scope: the root cause only. No "while I'm here" improvements, no bundled
refactoring.

Required order (superpowers:test-driven-development):
1. Write the failing test: <the behavior it must pin down>
2. Run `<exact test command>` and confirm it fails for the right reason.
3. Write the minimal fix.
4. Run `<exact test command>`, then `<exact full-suite command>`.
5. Commit the test and the fix together.

Return EXACTLY this structure:

## Status
DONE | BLOCKED

## Test
The test you wrote, and its verbatim output from step 2.

## Fix
The diff, and what it changes about the root cause.

## Verification
The verbatim output of `<exact test command>` and `<exact full-suite command>`
after the fix.

## If BLOCKED
What you tried, the verbatim evidence of what happened, and what you would
need. Do not attempt a second approach — return instead.
```

The fixer's "tests pass" is the claim under test, not the evidence for it. You run the full suite yourself, once, in the main session, before you claim anything is fixed (superpowers:verification-before-completion).

## The Attempt Ledger

The ledger lives in your own messages. Not in a subagent, not only in a file: it must survive context compaction and it must be in front of you when you write the next dispatch.

```
Attempt 3 — hypothesis: <what you think the root cause is, and why>
            experiment: <the exact command or minimal change dispatched>
            result: confirmed | refuted — <what the raw evidence showed>
            conclusion: <what this rules in or rules out>
```

Every dispatch after the first carries the ledger's conclusions. That is what stops a fresh subagent from re-running an experiment you already refuted — it has none of your history otherwise.

## The Failure Ladder

| Fixer failure | Your move |
|---|---|
| 1st | Re-dispatch a fresh fixer with the ledger conclusions added to its brief |
| 2nd | Dispatch the `sdd-rescue` agent (opus/high); `general-purpose` with the session model only when that agent is missing from your registry |
| 3rd | STOP. Question the architecture and talk to your human partner |

One attempt per subagent. The counter, the ladder and the architecture conversation stay in this session: a subagent that has failed twice cannot see that it has, and will finish a bad fix rather than escalate.

## Gated Testing Projects

In a project that declares `## Gated testing` (superpowers:test-driven-development — Gated Testing Mode), no debugging subagent runs a test command.

**Ask for the RED round before Phase 1.** At the start you hold no failure output. Request the round first. Paste the round output into every investigator brief. That paste is where an investigator gets the failure evidence. Never gather that evidence yourself to fill the gap.

**Paste this line into every dispatch prompt — investigator, analyst, experimenter and fixer — before you send it. No phase earns an exception, and Phase 1 earns none either. The rule binds at the dispatch site, not in this file:**

```
Gated testing mode — do NOT run any test command. Do NOT run the suite and do
NOT run a single test. The operator runs every test at a gate.
```

- **Investigators and the analyst** read files. They run no test command. Running the existing suite IS running a test command. "It is read-only", "it is non-mutating" and "I am just observing the current state" are rationalizations, not exceptions.
- **The failure output reaches an investigator through its brief.** You hold the operator's pasted round output in this session. Copy the relevant part into the brief. An investigator under gating receives that output. It never goes and gets it.
- **The experimenter** gets a non-test experiment: a read, a git command, a script run. An experiment that needs the test suite is not dispatched — it becomes a round request you hand to the operator.
- **The fixer** loses steps 2 and 4 of its template: it writes the failing test, writes the fix, commits, and returns without running anything. Say so in its brief.
- **The rounds are yours.** You request the RED round and the GREEN round from the operator in this session, and you read their pasted output. A subagent never handles a gate.

Post each round request in exactly this format, then STOP and wait for the pasted output:

```
ROUND <n> — RED|GREEN, phase "<name>"
Source:  <worktree root>
Files:   <relative paths of files to copy>
Command: <single short one-line command>
Expected: <what the output must show — "1 failed, 1 passed — the new regression test">
Paste back: the run's summary counts + every failure/error with its message; passing tests stay out of the paste
```

The `Paste back:` line goes into every round request, verbatim — it tells the operator what to return.
