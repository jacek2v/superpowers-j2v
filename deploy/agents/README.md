# SDD predefined subagents

Definitions the `subagent-driven-development` and
`subagent-driven-development-parallel` skills dispatch by name. They
exist to carry a **per-role reasoning effort**: the Agent/Task dispatch tool
honors `model` per call but has **no inline effort parameter** — an inline
`effort:` field is silently ignored. The only channel for per-role effort is a
predefined agent whose frontmatter sets `effort`, which is what these two files
are.

| File | Dispatch name | Model / effort | Used for |
|---|---|---|---|
| `sdd-reviewer.md` | `sdd-reviewer` | sonnet / xhigh | task reviewer, final whole-branch reviewer |
| `sdd-rescue.md` | `sdd-rescue` | opus / high | fix subagents, BLOCKED "needs more reasoning" escalation |

The normal implementer is NOT here — it dispatches as `general-purpose` with
`model: sonnet` and inherits the session effort (see SKILL.md "Model Selection").

## Install

These files are stored here for versioning; they are **not** auto-registered
from the repo. To make the `sdd-reviewer` / `sdd-rescue` dispatch names resolve,
copy them into an agents directory Claude Code loads:

```bash
cp sdd-reviewer.md sdd-rescue.md ~/.claude/agents/        # user-level (all projects)
# or, project-scoped:
cp sdd-reviewer.md sdd-rescue.md <project>/.claude/agents/
```

**Renamed from `sdd-high` / `sdd-escalate`.** If you copied the old files
earlier, delete them from your agents directory — a stale `sdd-high.md` is
never dispatched again, and leaving it there hides the fact that the new names
were never installed. A missing new name fails loudly (the dispatch does not
resolve), so nothing silently degrades.

Keep them in sync with this copy after edits. The controller/session `model`
and `effort` are set by the operator (`/model opus`, `/effort high`), not by
these files.
