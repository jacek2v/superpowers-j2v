# Backlog: writing-plans — Execution Handoff — 2026-08-15

**Zakres:** `skills/writing-plans/SKILL.md`, sekcja `## Execution Handoff`.
**Status:** otwarte, niezmierzone.

## A. Handoff nazywa opcję 1 rekomendowaną nawet wtedy, gdy plan jej zakazuje

Szablon handoffu każe napisać `1. Parallel Subagent-Driven (recommended)`. Plan może
jednocześnie nieść wyjątek wykonawczy w nagłówku — jak
`plans/2026-08-15-systematic-debugging-subagents.md`, który zakazuje wykonania równoległego,
bo worktree-per-task mierzyłby niezmieniony skill. Wiadomość do operatora zawiera wtedy dwa
sprzeczne zdania obok siebie: „rekomendowana" przy opcji 1 i „tu odradzam" pod nią.
Operator musi sam rozstrzygnąć, które zdanie wiąże.

Źródło: sesja 2026-08-15, handoff planu delegacji subagentów w systematic-debugging.

**Kierunek naprawy do rozważenia:** etykieta „(recommended)" powinna być warunkowa —
plan z wyjątkiem wykonawczym w nagłówku przenosi ją na opcję, którą ten wyjątek dopuszcza,
a opcja zakazana dostaje krótkie uzasadnienie zamiast etykiety. Wymaga zmiany tekstu
szablonu w `## Execution Handoff` i pomiaru RED/GREEN na planie z wyjątkiem i bez.
