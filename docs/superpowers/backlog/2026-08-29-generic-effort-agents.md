# Backlog: agenci ogólnego przeznaczenia niosący sam wysiłek — 2026-08-29

**Zakres:** `deploy/agents/`, `subagent-driven-development/SKILL.md`, jego kopia równoległa,
`systematic-debugging/debugging-subagents.md`, `requesting-code-review/`, oba szablony promptów.
**Status:** otwarte, odłożone przy specyfikacji
[`2026-08-29-gated-green-implementer-design.md`](../specs/2026-08-29-gated-green-implementer-design.md).

## Propozycja operatora

Zastąpić agentów nazwanych rolą (`sdd-reviewer`, `sdd-rescue`) agentami nazwanymi wysiłkiem
(`subagent-high`, `subagent-medium`, `subagent-xhigh`). Model podaje się wtedy przy każdym
wywołaniu, a plik agenta niesie wyłącznie `effort`.

## Dlaczego to działa

Narzędzie `Agent` opisuje parametr `model` tak: „Takes precedence over the agent definition's
model frontmatter and the configured default subagent model". Pole `effort` w wywołaniu jest
ignorowane i bierze się wyłącznie z frontmattera (`subagent-driven-development/SKILL.md:105-111`).
Podział „wysiłek w pliku, model z zewnątrz" leży dokładnie wzdłuż tej granicy. Obecne pliki
przybijają na stałe także model, choć nic tego nie wymaga.

## Co to daje i czego nie daje

Nie zmniejsza liczby plików: dziś są dwa, wariant ogólny potrzebuje dwóch albo trzech.
Zysk polega na tym, że każda para model plus wysiłek staje się osiągalna bez nowego pliku.
Dziś używane pary to sonnet/xhigh (recenzent), opus/high (naprawa), sonnet/wysiłek sesji
(implementer). Każda nowa para wymaga kolejnego pliku — na to trafiliśmy przy
`gated-green-implementer`.

## Koszt

Nazwy `sdd-reviewer` i `sdd-rescue` występują w kilkunastu miejscach treści kształtującej
zachowanie modelu: oba skille SDD, `systematic-debugging/debugging-subagents.md`,
`requesting-code-review`, dwa szablony promptów, `deploy/agents/README.md`.

Kolizja z zapisaną decyzją:

```
D-035 ✓ requesting-code-review dispatches the sdd-reviewer agent (sonnet/xhigh)
      in SDD and standalone alike — the old wording sent standalone reviews to
      opus (RED 5/5) [2026-08-05](../evals/2026-08-05-reviewer-dispatch-consistency.md)
```

Zmiana nazw celów wysyłki unieważnia ten pomiar. Przebudowa wymaga operacji 3 rejestru na D-035
i powtórzenia ewaluacji dyspozycji recenzenta.

Zastrzeżenie niekrytyczne: nazwa `subagent-high` mówi o wysiłku, ale nie o roli. Dziś nazwa celu
wysyłki niesie informację, po co ten subagent istnieje, i jest to część zabezpieczenia z D-035.
Po zmianie rolę musi nieść sam prompt.

## Kierunek pracy, gdy wróci

Osobna specyfikacja. Najpierw zmiana D-035 operacją 3 rejestru, potem zamiana nazw w tych
kilkunastu miejscach, na końcu powtórzenie ewaluacji
`evals/2026-08-05-reviewer-dispatch-consistency.md`.
