# Deep Research Subagents

Parallel read-only research subagents that settle open design decisions before the design is presented. Read this file after your human partner accepts the deep research proposal — the proposal itself is made from the skill's step 5.

## What This Buys

A spec that carries decisions already made, each grounded in something you checked. Without it, the hard questions — which backend, which library, which architecture — reach the spec as open bullets and get settled later by whoever implements them, from memory, under time pressure.

## When To Propose It

Propose the deep tier when an open decision meets one of these:

- **Unfamiliar domain** — you would otherwise reason about established patterns from general knowledge
- **Architecture choice** — two or more structurally different designs are live and the choice is expensive to reverse
- **Library or service comparison** — the decision is what to depend on, and the candidates differ in maintenance, licence, or capability
- **Contested prior art** — the problem is common, and the published solutions disagree

Do NOT propose it for: a decision an active D-entry already settles (declare the assumption with its ID instead), a question your human partner answers in one sentence, or anything the quick tier already covered. Deep research buys a decision, not reassurance.

## Choosing The Mode

| Mode | Unit | Runs | Fits when |
|---|---|---|---|
| **Per-decision** | one open decision = one question = one subagent | before you propose approaches; the findings feed them | the open questions are independent and each has its own answer space |
| **Per-approach** | one sketched approach = one subagent (feasibility, prior art, risks) | after you sketch 2-3 approaches, before your recommendation | the questions are entangled — they only make sense inside a whole design |

Name the mode in the proposal. One mode per round: if a per-decision round leaves an approach-level question open, that is a new proposal, not a silent second dispatch.

## The Proposal

The only thing in its message your human partner has to answer: research questions, mode, subagent count, cost. In per-approach mode it also names the sketched approaches — that is the unit being researched. The research verdict may head it; nothing else may — no clarifying question, no recommendation, no design content. Then stop and wait.

```
Three decisions here need more than a quick check:

1. <question — phrased so that an answer settles the decision>
2. <question>
3. <question>

Mode: per-decision — one read-only research subagent per question, all
dispatched in parallel. They read the codebase, the web, and library docs,
and each comes back with options, trade-offs, and a recommendation. They
decide nothing; you and I settle each decision afterwards.

Cost: 3 subagents, token-intensive, a few minutes of wall clock.

Want me to run this? Trim or edit the question list first if any of these
are already settled for you.
```

Acceptance may come trimmed or edited — dispatch exactly the list your human partner approved, nothing added back, and count it first (see Dispatching). A decline ends the deep tier for this round: continue on the quick check and do not re-propose unless a new decision warrants it.

## Dispatching

**Count first. If the trim did not lower the count, you do not have approval yet.**

Compare the number you are about to dispatch with the number you proposed. A trim that names something you never listed — a question, when your list was approaches — narrows every subagent's brief and leaves the count exactly where it was. That is not the trade they asked for: a trim is a cost objection, and the cost is the number of subagents, not the length of their briefs. Say the number, say the trim did not lower it, and ask whether to run it anyway or drop one of the items you listed instead. Then stop and wait, exactly as the proposal stopped and waited.

This is a check on cost going *up* relative to what they approved. A list your human partner enlarged — they added a question or an approach — is approved as enlarged: dispatch it and do not re-ask.

| Thought | Reality |
|---------|---------|
| "They said run the rest — that is approval" | They approved a cheaper run. Same count with narrower briefs costs what they objected to. |
| "I'll mention the narrowed scope in the dispatch message" | By then the subagents are running. Reporting a spend is not asking for it. |
| "The trim obviously meant the third approach" | It named a question. Guessing which listed item they meant is the guess that costs them tokens — ask. |

Dispatch every research subagent as `general-purpose` with `model: sonnet`. Issue ALL of them in a single message — several dispatch calls in one response run concurrently, one per response runs them sequentially (superpowers:dispatching-parallel-agents).

Each subagent is read-only and stateless: it writes no file, edits no code, runs no git command, and makes no decision. It does not inherit your session's history — the prompt carries everything it needs.

### Subagent prompt template

```
You are a read-only research subagent. Investigate ONE question and report
findings. You are not deciding anything and you are not writing any file.

Question: <the research question, verbatim from the approved list>

Context you need:
- Project: <one paragraph — what it is, what it is built with>
- Where this decision bites: <the concrete thing being designed>
- Hard constraints: <e.g. "runtime dependencies: standard library only";
  "one local SQLite file, no external services"> — an option that violates
  one of these is still worth reporting, but report it as excluded and say
  which constraint excludes it.

Sources: this codebase (read only), the web, and official library or API
documentation. Prefer primary sources — project docs, release notes, issue
trackers — over blog summaries. Check that anything you recommend still
exists and is maintained.

Rules:
- Do NOT write, edit, or create any file. Do NOT run git. Do NOT install
  anything.
- Do NOT decide. Recommend, and say what would change your recommendation.
- Report what you could NOT establish rather than filling the gap with a
  plausible guess.

Return EXACTLY this structure:

## Question
<restate it>

## Options
For each option: name, one-line summary, how it works, maturity and
maintenance status, and what depending on it costs.

## Trade-offs
A comparison across the axes that actually decide this question — name the
axes.

## Recommendation
One option, the reason it wins on those axes, and the condition under which
the runner-up would win instead.

## Excluded by constraints
Options a hard constraint rules out, each with the constraint that rules it
out.

## Unknowns
What you could not establish, and what it would take to establish it.

## Sources
URLs and file paths, one per line, each with what it supports.
```

## Taking The Decisions

The subagents come back; the deciding work is yours and your human partner's:

1. Present ONE decision at a time: the options, the trade-off that actually decides it, your recommendation, and what it costs. Keep the raw findings out of the message — they go to the analysis file.
2. Ask for approval on that decision alone. A single bulk "approve all of this" defeats the tier — the point is that each decision gets looked at.
3. If a recommendation collides with an active D-entry, it is never presented as a plain option — run project-registry op 4 (the gate protocol) first. Findings are inputs; the direction is still gated before it is presented.
4. The moment your human partner condemns a direction, record it via project-registry op 3 immediately — negative decisions never wait for the end of the session.

A subagent's recommendation is evidence, not authority. If its sources are thin or its reasoning does not survive your reading, say so and take the decision without it.

## Persistence

Two files, committed together with the spec:

- **The spec** gets a decisions section: one line per decision with a short rationale and a pointer to the analysis file.
- **The analysis file** — `docs/superpowers/research/YYYY-MM-DD-<topic>-analysis.md` — carries what the spec deliberately leaves out: the rejected options, the comparisons, the sources.

### Analysis file template

```markdown
# Research: <topic>

Date: YYYY-MM-DD
Spec: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
Mode: per-decision | per-approach — <n> read-only research subagents
Question list approved by your human partner on YYYY-MM-DD

## Decision 1: <the decision, as decided>

**Approved:** <option> — <one-line rationale>

**Options considered**

| Option | Summary | Cost | Verdict |
|---|---|---|---|
| <name> | <summary> | <cost> | chosen / rejected: <why> |

**Excluded by constraints:** <option> — <constraint that excludes it>

**Unknowns carried into the spec:** <what remains unestablished>

**Sources**
- <url or path> — <what it supports>

## Decision 2: <…>
```

Approved decisions still go into the spec AND into CONTEXT.md as D-entries at the skill's step 12; a direction your human partner explicitly condemned goes in as a `✗` entry. The analysis file substitutes for neither.
