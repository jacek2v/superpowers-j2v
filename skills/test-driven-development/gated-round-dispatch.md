# Gated Round Dispatch

Use this at a gate in Gated Testing Mode, after you judged the round and wrote
the verdict into the round ledger. One template serves all three dispatch
targets — only the verdict line and the wanted-behavior block change.

| Verdict | Dispatch target | Model / effort |
|---|---|---|
| Valid RED | `gated-green-implementer` | sonnet / high |
| INVALID RED — the tests are wrong | `sdd-rescue` | opus / high |
| Gate GREEN failure — the code is wrong | `sdd-rescue` | opus / high |

Pass no path to the plan and no path to the spec. When a plan exists, paste the
one relevant task block into "Wanted behavior". The subagent gets exactly what
it needs and nothing else.

```
Subagent (gated-green-implementer | sdd-rescue):
  description: "Round <n> <verdict> — <short subject>"
  prompt: |
    You write code for a project whose tests run behind a gate. You never run
    the tests. The main session owns the gate and holds the round evidence.

    ## Work from

    [WORKTREE_PATH]

    ## Round verdict

    Round <n> — <Valid RED | INVALID RED | Gate GREEN failure>, phase "<name>".
    The main session judged this verdict and recorded it in the round ledger.

    ## What the round showed

    [The summary counts and every failure block, verbatim from the round
    output. Nothing else from that file.]

    ## Wanted behavior

    [What the code must do, written by the main session. When a plan exists,
    the relevant task block goes here verbatim.]

    ## Rules

    - Do NOT edit any test file. The tests state the required behavior.
      This rule is lifted for an INVALID RED repair, and then it inverts: you
      fix the tests and you touch no production code.
    - Do NOT run the test suite. It is gated — you cannot reach the test system.
    - Write the smallest change that produces the wanted behavior.
    - Follow the patterns already in the files you touch.

    ## Commit

    Commit in [WORKTREE_PATH]. Within a phase every RED commit lands before
    every GREEN commit, so your commit is a GREEN commit — unless this dispatch
    is an INVALID RED repair, which is a RED commit.

    ## Report back, under 15 lines

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED
    - Files changed
    - Diff summary — one line per file, what changed
    - Commit subject and short SHA
    - Your concerns, if any

    Use BLOCKED when the wanted behavior needs a decision you cannot make from
    the material above. Put the specifics in your final message; the main
    session acts on it directly.
```

**After the report comes back:** inspect `git log -1` and the diff yourself. A
subagent report never closes a task.

**The commit invalidates the round output that produced it.** Request a new
round; do not reuse the old one.

**BLOCKED from `gated-green-implementer`** escalates to `sdd-rescue` — one jump,
not an effort ladder.

**A missing agent name** — `gated-green-implementer` or `sdd-rescue` not in your
registry — falls back to `general-purpose` with your session model. The agent
definitions live under [deploy/agents/](../../deploy/agents/); install them per
that directory's README so the names resolve.
