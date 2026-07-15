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

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — change by editing in place, abandon by striking.

- **D-001** ✓ <decision, ≤1 line> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-002** ✗ DO NOT <direction> — <why, one clause> [YYYY-MM-DD](specs/…)
- **D-003** ✓ <changed decision> — <why> [YYYY-MM-DD](specs/…) (prev: <compressed prior state — why>)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| YYYY-MM-DD | <feature, 1 line> | D-001, D-002 |
```
