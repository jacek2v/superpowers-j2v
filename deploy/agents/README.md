# SDD predefined subagents

Definitions the `subagent-driven-development` skill dispatches by name. They
exist to carry a **per-role reasoning effort**: the Agent/Task dispatch tool
honors `model` per call but has **no inline effort parameter** — an inline
`effort:` field is silently ignored. The only channel for per-role effort is a
predefined agent whose frontmatter sets `effort`, which is what these two files
are.

| File | Dispatch name | Model / effort | Used for |
|---|---|---|---|
| `sdd-high.md` | `sdd-high` | sonnet / high | task reviewer, final whole-branch reviewer, fix subagents |
| `sdd-escalate.md` | `sdd-escalate` | opus / high | BLOCKED "needs more reasoning" escalation only |

The normal implementer is NOT here — it dispatches as `general-purpose` with
`model: sonnet` and inherits the session effort (see SKILL.md "Model Selection").

## Install

These files are stored here for versioning; they are **not** auto-registered
from the repo. To make the `sdd-high` / `sdd-escalate` dispatch names resolve,
copy them into an agents directory Claude Code loads:

```bash
cp sdd-high.md sdd-escalate.md ~/.claude/agents/        # user-level (all projects)
# or, project-scoped:
cp sdd-high.md sdd-escalate.md <project>/.claude/agents/
```

Keep them in sync with this copy after edits. The controller/session `model`
and `effort` are set by the operator (`/model sonnet`, `/effort medium`), not by
these files.
