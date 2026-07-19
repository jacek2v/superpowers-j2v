# Model / effort

Kolumny „stare" zostawione jako referencja — poprzedni układ przed korektą wg
[stet.sh: Sonnet 5 vs Opus 4.8](https://www.stet.sh/blog/sonnet-5-vs-opus-4-8-reasoning-dial).
Kryterium doboru: najpierw jakość, potem koszty.

## Skille uruchamiane ręcznie (operator ustawia sesję)

| Skill | `/model` | `/effort` |
|---|---|---|
| brainstorming | opus (sonnet/xhigh przy bardzo rozmytym temacie) | high |
| writing-plans | opus | high (xhigh dla wielkich/wielosystemowych planów) |
| subagent-driven-development | opus (było: sonnet) | high (było: medium) |

## Role wewnątrz subagent-driven-development

Skill dobiera sam, operator nic nie robi.

| Rola | Model / effort | Skąd | Model / effort (stare) | Skąd (stare) |
|---|---|---|---|---|
| orkiestrator | opus / high | sesja operatora | sonnet / medium | sesja operatora |
| implementer (normalny) | sonnet / high | `general-purpose` + jawny `model: sonnet`; effort dziedziczy z sesji | sonnet / medium | dziedziczy z sesji |
| recenzent zadaniowy | sonnet / xhigh | agent `sdd-high` | sonnet / high | agent `sdd-high` |
| recenzent całej gałęzi | sonnet / xhigh | agent `sdd-high` | sonnet / high | agent `sdd-high` |
| fix-subagent (Critical/Important) | opus / high | agent `sdd-escalate` | sonnet / high | agent `sdd-high` |
| implementer BLOCKED → eskalacja | opus / high | agent `sdd-escalate` | opus / high | agent `sdd-escalate` |

Uzasadnienia:

- **Sesja opus/high:** effort sesji konsumuje implementer (sonnet rośnie z effortem),
  a orkiestrator-opus jest po efforcie płaski (3.00–3.17) — high nic nie psuje u
  orkiestratora, a podnosi implementera. Model opus daje orkiestratorowi osąd tam,
  gdzie decyzji nie da się oddelegować (registry gate, triage BLOCKED, „plan jest
  zły", ocena werdyktu recenzenta).
- **Recenzenci sonnet/xhigh:** szczyt sonneta — jedyny punkt, gdzie wygrywa 7/8
  wymiarów (clarity, weryfikacja); koszt vs opus na tym poziomie ~1.01x.
- **Fixer opus/high:** metryki to remis w szumie z sonnet/xhigh, ale profil roli
  sprzyja opusowi (diff minimality, robustness = anty-paliwo pętli re-review);
  poprawkę i tak re-recenzuje sonnet/xhigh. Routing przez `sdd-escalate` —
  wspólny „poziom naprawczy" z eskalacją.
- **Eskalacja opus/high:** skok modelu (inne tryby błędów), nie drabinka effortu;
  benchmark tu milczy — uzasadnienie strukturalne, z projektu skilla.
- **Wyżej niż high dla opusa (xhigh/max) — nigdzie:** equivalence płaskie, na xhigh
  aktywność skacze w zakres edycji (ryzyko dla chirurgicznego diffa), max
  nieopłacalny; sonnet na max wręcz spada.

Migracja w kodzie: **wykonana 2026-07-19**, zero nowych agentów. Zmienione pliki:
`deploy/agents/sdd-high.md` (effort→xhigh, opis bez fixera),
`deploy/agents/sdd-escalate.md` (opis + fixer), `deploy/agents/README.md`
(tabela + sesja opus/high), `skills/subagent-driven-development/SKILL.md`
(sesja, fixer→`sdd-escalate`, nawiasy xhigh, reguła routingu),
`task-reviewer-prompt.md` (nawias xhigh). Kopie w `~/.claude/agents/`
zsynchronizowane — rejestr agentów przeładowuje się w nowej sesji.

Zastrzeżenia: benchmark = 24 zadania, 2 repo (Go/Rust), pojedyncze przebiegi,
jeden sędzia; bez podziału na trudność zadań. Koszt tej wersji: dłuższe traile
implementera na high (więcej tur, większy kontekst orkiestratora).
