# Pre-push whole-branch review — `c7608ed..dafa8b1`

Date: 2026-07-30
Reviewer: independent `general-purpose` subagent, opus, read-only, dispatched
per `superpowers:requesting-code-review` with `code-reviewer.md`. It received
the git range, the two design specs and `CONTEXT.md` as requirements — never
this session's history.

**Why this exists.** The branch `fix/proposal-per-approach-wording` was merged
into local `main` (`dafa8b1`) on the strength of eval evidence alone, skipping
the review this repo's own `requesting-code-review` skill calls mandatory
before a merge. This review closes that gap after the fact and before the push.
Everything in the range was authored and measured by one agent; this is the
first reading by anything else.

**Scope reviewed:** `skills/` + `.claude-plugin/plugin.json` across the whole
unpushed range — 13 files, 1231 insertions, 40 deletions. The remaining ~23300
inserted lines in the range are eval transcripts and design docs, supplied as
evidence rather than as product. The reviewer was additionally asked to
spot-check that the eval document attributes each measurement to the right
skill state.

**Verdict: ready to merge WITH FIXES.** No Critical issues. Eight Important,
several Minor.

## Disposition

Every finding was verified against the files before being accepted; none were
rejected as wrong. Fixes landed on `fix/review-findings-2026-07-30`.

| # | Finding | Fixed in |
|---|---|---|
| 1 | Per-approach mode: three different orderings in three places (`SKILL.md:44`, `:267`, digraph `:97`) | `3861f58` — measured, V11 |
| 2 | Parallel-SDD digraph dispatches implementers before their worktrees exist — the race D-028 exists to prevent | `9d2513c` — unmeasured |
| 3 | Gated mode deletes the task evidence its own Verification Contract requires | `78f381a` — unmeasured, shell-tested |
| 4 | No rule for a declined worktree; `<task-worktree-path>` never defined | `9d2513c` — unmeasured |
| 5 | Nothing forces plan task numbering to be topological, though sequential executors run in document order | `9d2513c` — unmeasured |
| 6 | Both plan-embedded gate round requests omit the `Paste back:` line the TDD skill calls mandatory verbatim | `9d2513c` — unmeasured |
| 7 | The count guard lives only in the file that is skipped ~8% of the time | `3861f58` — measured, V11 |
| 8 | The eval doc contradicts its own state table about what is measured at the current state | `6c21d12` |

Minor findings (stale "byte-identical" claims in `CONTEXT.md` and the
2026-07-24 spec, the parallel skill missing from both README lists, the
`deploy/agents` README naming only the sequential skill, no migration note for
the `sdd-high` → `sdd-reviewer` rename) were fixed in `6c21d12`.

## Two challenges the reviewer was explicitly invited to make

**On the visual-companion asymmetry** — `SKILL.md:233` still says the offer
"MUST be its own message" while the research proposal moved to the weaker
answerability criterion 30 lines away. The reviewer agreed with leaving it:
no scenario exercises that offer, and this repo forbids changing
behavior-shaping content without measurement. It named the risk accepted —
two just-in-time offers now state different criteria in one file, and an agent
reading both may harmonize in either direction — and recommended folding the
visual offer into the next measurement round rather than reasoning it into
alignment now.

**On the n=4..6 single-fixture evidence for the count check** — placement
judged correct, coverage judged incomplete in one specific direction: every
scored rep was a trim that genuinely could not lower the count, so the
false-positive direction has zero measurements. Read literally the rule also
fired when the human *enlarged* the list. Both files now rule on that case
(`3861f58`).

## Process recommendation, adopted

> For each rule you changed, grep every place the repo states it — prose,
> digraph node labels, reference files, and other skills' embedded templates —
> and list them in the eval doc.

Findings 2 and 6 are exactly the class the measure-fix-remeasure loop cannot
catch, because they live in representations no scenario reads. `f889cc6` was
that check happening late and by luck.

## Full review

### Strengths

- **The consent chain in the deep research tier has no hole I could find.** Every route into dispatch is gated on acceptance in all three representations that an agent might read: prose (`skills/brainstorming/SKILL.md:262`), the digraph (only edge into the dispatch node is `"Human partner accepts?" -> ... [label="yes"]`, line 93), and the reference file (`research-subagents.md:284`, "Then stop and wait"). Subagents are forbidden to write files or decide (`SKILL.md:269`, `research-subagents.md:118-121`), per-decision approval is required in both files, and research-derived directions still pass op 4 before presentation (`research-subagents.md:132`) — D-021/D-031 intact. No path dispatches more than was approved: the count-first stop at `research-subagents.md:55` is the first line of the section that performs the action.
- **The V8 result is a genuinely generalizable finding, and the fixes apply it consistently.** "Rule as precondition at the top of the section that performs the action + a named rationalization" (11/12, 4/4) versus "rule as prose in a paragraph that already granted permission" (3/6) is a real measurement, not a rationalization of a wording preference, and both `17732c1` and `c402427` are shaped by it.
- **The two SDD copies are actually in sync, not nominally.** `scripts/{review-package,sdd-workspace,task-brief}`, `implementer-prompt.md` and `task-reviewer-prompt.md` are byte-identical between the two skill directories (verified by diff); the `sdd-high`→`sdd-reviewer` / `sdd-escalate`→`sdd-rescue` rename propagated to both skills, `deploy/agents/` (files + README table), and `MODEL_EFFORT.md`, with zero stale references left anywhere under `skills/` or `deploy/`. D-024's post-reversal contract is honored.
- **The parallel skill's divergences from the sequential copy are exactly the spec's delta.** The Red Flags additions/removal match `specs/2026-07-24-sdd-parallel-design.md:55-56` item for item; every invariant in the spec's "Sequential invariants" list survives (two-verdict review, controller-only merges/gates, gated phase cycle, final whole-branch review → op 5 → finishing-a-development-branch, model routing).
- **Evidence quality is above the bar for the core parallel invariants**: RED shows the failure is real (4/6 reps improvise naive parallelism, with verbatim "user instruction > skill rule" rationalizations), GREEN is 6/6 on the four hardest invariants (one-message dispatch, merged-not-review-clean gating, controller-serialized merges, rebase→re-review), and the description was micro-tested to 5/5 on both the trigger probe (P1) and the anti-trigger probe (P3, "strictly one task at a time") after two documented revisions.
- **All five `dot` blocks parse** — I ran `dot -Tsvg` on every digraph in the four changed/new SKILL.md files.
- **`sdd-workspace`'s self-ignoring `.gitignore` actually works for the new removal step**: I built a scratch repo with a task worktree containing `.superpowers/sdd/{.gitignore,task-1-brief.md}` and `git worktree remove` succeeded without `--force`. The parallel skill's cleanup step is not going to jam on its own artifacts.
- **The eval document is unusually honest.** The "Not exercised / not established" section names the n=1 verdicts, the missing isolated-`HOME` runs at HEAD, the reasoned omission of N3/N4 at the final state, and the fixture that never elicited the feature. The visual-companion asymmetry is recorded as a known open item rather than buried.

### Issues

#### Critical (Must Fix)

None. I looked specifically for a path where the agent could dispatch unapproved, dispatch more than approved, or present an unapproved decision as settled, and did not find one; and no skill text contradicts an active D-entry.

#### Important (Should Fix)

**1. Per-approach mode: three different orderings in three places.**
- `skills/brainstorming/SKILL.md:44` — "Every decision the verdict marks a research candidate MUST go into a deep-research proposal … **before step 6**" (step 6 = Propose 2-3 approaches).
- `skills/brainstorming/SKILL.md:267` — per-approach "sketch 2-3 approaches first, then one subagent deepens each … **Runs after the sketch**".
- `skills/brainstorming/SKILL.md:97` (digraph) — the edge runs **from** `"Propose 2-3 approaches"` **to** `"Propose deep research"`, i.e. after step 6.
- `skills/brainstorming/research-subagents.md:25` — "after you sketch 2-3 approaches, before your recommendation".

Why it matters: per-approach is not a rare branch — the eval observed it chosen unprompted 9 times, and N5 elicits it 4/4. An agent in that mode has to decide whether sketching violates step 5's "before step 6", and the two readings produce different messages (sketch-in-proposal vs. proposal-only-then-sketch). V9 rep3 is exactly this case, scored "PASS, noted" with three architecture sketches inside the proposal message.
Fix: say it once, explicitly — e.g. in step 5: "in per-approach mode the sketch rides inside the proposal message; step 6's comparison-with-recommendation happens after the findings" — and make the digraph edge label say that rather than implying step 6 completed first.

**2. `skills/subagent-driven-development-parallel/SKILL.md:75-77` — the digraph dispatches before the worktree exists.**
```
"Read plan, build dependency DAG…" -> "Dispatch ALL ready tasks (one message, concurrent)";
"Dispatch ALL ready tasks (one message, concurrent)" -> "Create task branch + worktree from integration tip";
"Create task branch + worktree…" -> "Dispatch implementer subagent…";
```
Read literally, implementers are dispatched, *then* branches and worktrees are created — and implementers with no named worktree work in the integration worktree, which is the precise failure D-028 exists to prevent ("shared worktree races git state and voids test evidence"). The prose (`:135-142`) and the Example Workflow (`:355-360`) both have the right order, and the graph then re-dispatches at a second node, so a careful agent self-corrects — but the graph is the summary an agent under time pressure reads.
Fix: relabel the node to what it actually is — `"Compute ready set"` — and keep the single dispatch node inside the per-task cluster after worktree creation.

**3. Gated mode deletes the evidence the Verification Contract requires.** `:142` removes the task worktree immediately after the merge, and `:139` puts the brief, implementer report and review package inside that worktree. `:210-211` says "never mark a task complete without both pieces of evidence on file", and `:225` says in gated mode a task is marked complete **only after the phase's Gate GREEN**, which `:226` says runs only after *every* task of the phase has merged. So by the time the contract is checked, the files it names have been deleted for every task in the phase.
Fix: either copy `task-N-brief.md` / `task-N-report.md` / the review package into the integration worktree's `.superpowers/sdd/` before `git worktree remove`, or defer removal to after Gate GREEN in gated mode. (The same ordering also means the final whole-branch reviewer and the human can no longer read any task's report.)

**4. No rule for "the human declined the worktree", and task-worktree paths are undefined.** `:135` invokes `superpowers:using-git-worktrees`, whose Step 0 (`skills/using-git-worktrees/SKILL.md:41-45`) allows the human to decline, in which case the sub-skill says "work in place". The parallel skill's entire protocol presumes an integration worktree plus one worktree per task and offers no fallback for that answer. Separately, `<task-worktree-path>` (`:137`, `:138`, `:142`) is never defined — no naming convention, no location, and no reference to the human's declared worktree-directory preference (`using-git-worktrees` Step 1), which is consulted only for the integration worktree.
Fix: one line each — "if your partner declines worktree isolation, use `superpowers:subagent-driven-development` instead (this skill's protocol requires worktrees)" and a stated path convention (e.g. sibling of the integration worktree, `<integration-worktree>-task-N`).

**5. `skills/writing-plans/SKILL.md:113-115, 240` — nothing forces the plan's task numbering to be topological.** `Depends on:` is now mandatory, but no rule says a task may only depend on lower-numbered tasks, and self-review check 6 (`:240`) verifies acyclicity, Consumes coverage, file disjointness and overview consistency — not monotonic numbering. Both the sequential SDD skill and `executing-plans` execute in document order and contain no reference to `Depends on:` at all (grep: zero hits outside `writing-plans` and the parallel skill). A plan where Task 2 depends on Task 4 is a valid DAG that silently breaks D-025's escape hatch ("invoke sequential explicitly") and inline execution.
Fix: add "`Depends on:` may name only lower-numbered tasks — sequential executors run the plan in document order" to the task template and to check 6. Both GREEN reps happened to produce topological plans, so this is currently unmeasured, not observed-broken.

**6. `skills/test-driven-development/SKILL.md:428` says the `Paste back:` line is "part of every round request, verbatim", but `skills/writing-plans/SKILL.md:180-184` and `:194-198` — the two pre-filled gate round requests a plan embeds — omit it.** The gate step's whole point is that the request is pre-filled in the plan, so the controller posts the plan's version; the mandated line is dropped exactly where it would be copied. The paste-back eval explicitly reasoned "Both SDD variants inherit the template via their Gated Testing Mode sections; no SDD file changed" and never considered `writing-plans`.
Fix: add the `Paste back:` line to both templates in `writing-plans` (a template-shape change, matching what `f062e2c` already measured 5/5 for fidelity).

**7. The strongest consent guard lives only in the file that is skipped ~8% of the time.** The count-first stop is `research-subagents.md:55`; `SKILL.md:281-286` only tells the agent the file *contains* "what to do when their trim cannot reduce the subagent count". The load precondition is measured at 11/12 — V7 rep2 dispatched as its turn's first action having never read the file. In that run there is no count rule in context at all, and the agent dispatches 3 subagents against a trim the human intended as a cost cut.
Fix: one clause in `SKILL.md`'s Deep Research section — "a trim that does not lower the number of subagents is not approval: say the number and ask" — so the guard survives a skipped load. This duplicates one sentence, which is the cheap direction of the trade.

**8. `docs/superpowers/evals/2026-07-28-brainstorming-deep-research.md:921-923` contradicts its own state table twelve lines above.** The text says "**Only N1 is measured at the current state**, and no measurement at any state after `579eb48` uses an isolated `HOME`". The table at `:908-919` lists V10 (current state, `532ad47`+`f889cc6`) covering **N5 ×2 and N2 ×1**, and lists row `N3 rep4 | after 579eb48 | N3 | isolated`. Both halves of the sentence are false against the table. Everything else I spot-checked in that doc holds: the per-section state attributions match git exactly (`git log 579eb48..ccd917e -- skills/brainstorming/` is empty as claimed; `abb34b6`, `ff34c5d`, `17732c1`, `c402427`, `532ad47`, `f889cc6` each touch exactly the files their section claims), and the visual-companion line numbers 42/230/233 are correct.
Fix: delete or restate that sentence — the accurate version is already in the "Not exercised" bullets ("N3 and N4 are not measured at the current skill state", "No measurement at HEAD uses an isolated `HOME`").

#### Minor (Nice to Have)

- `docs/superpowers/CONTEXT.md:63` — the SHIPPED row still reads "full copy of sequential, **byte-identical**", which the reversed D-024 (`:44`, byte-freeze lifted) and the actual edits to the sequential skill contradict.
- `docs/superpowers/specs/2026-07-24-sdd-parallel-design.md:12, 77` — same stale byte-identical/"zero edits" claim, with no note that D-024 superseded it. A future reader takes the spec as binding.
- `README.md:196, 226` — the skill list omits `subagent-driven-development-parallel`, which D-025 makes the default executor.
- `deploy/agents/README.md:3` — "Definitions the `subagent-driven-development` skill dispatches by name"; both skills dispatch them now.
- The agent rename is a breaking change for any machine that already copied `sdd-high.md`/`sdd-escalate.md` into `~/.claude/agents`; there is no migration note in `RELEASE-NOTES.md`. Failure is loud (unresolved dispatch name), not silent, so this is documentation only.
- Eval doc V9 says the answerability rule was "changed in all four places that stated it (`532ad47`)"; a fifth place (the Process Flow node) still said "own message" until `f889cc6`. V10's heading discloses it, but the V9 sentence reads as complete.
- No guidance on fan-out width: a plan with eight level-0 tasks dispatches eight implementers in one message, and "Continuous execution" forbids checking in. Worth one line acknowledging harness concurrency/rate limits.
- `research-subagents.md:130` forbids bulk approval but gives no ruling for a human who insists on it ("just approve them all") — an undefined case in a consent-bearing step.
- Only `.claude-plugin/plugin.json` was bumped (6.1.1-7); the codex/cursor/kimi/`package.json`/gemini manifests stay at 6.1.1. Consistent with fork practice (they were last touched by upstream releases), noted for completeness.

### Recommendations

**On (a), the visual-companion asymmetry — leaving it was the right call, and I would not touch it now.** The repo's rule is explicit that behavior-shaping content doesn't move without evidence, and no scenario in this campaign exercises that offer. But be aware of the specific risk you accepted: two just-in-time offers now state different criteria 30 lines apart in one file (`SKILL.md:233` vs `:262`), and an agent reading both may harmonize in either direction. The cheap resolution is to fold the visual offer into the next measurement round rather than to reason it into alignment now.

**On (b), the n=4..6 single-fixture evidence — the placement is right, the coverage has one specific hole.** The count check at the top of `## Dispatching` is exactly where V8's own lesson says it belongs, and 4/4 + 2/2 is adequate to claim "followed when it triggers". What has **zero** measurements is the false-positive direction: every scored rep was a case where the trim genuinely could not lower the count (per-decision reps are recorded "n/a"). Read literally, "if the trim did not lower the count, you do not have approval yet" also fires when the human *adds* a question — the count went up, not down. The failure mode is an unnecessary question, so the risk is low and asymmetric in the safe direction; it is worth one sentence in the rule ("a list your partner enlarged is approved as enlarged") rather than another eval round. The answerability rule at 4/4 + 2/2 with rep3 honestly recorded as borderline is fine as-is.

**Process:** the fix cadence in the last 21 commits (measure → one wording change → re-measure → record) is the right loop and produced the campaign's only generalizable finding. Two of the Important issues above (2 and 6) are exactly the class that loop does not catch, because they live in a representation no scenario reads — a digraph and a template embedded in another skill. Consider adding a mechanical consistency check to the eval close-out: for each rule you changed, grep every place the repo states it (prose, digraph node labels, reference files, and other skills' embedded templates) and list them in the eval doc. `f889cc6` was that check happening late and by luck.

**Backward compatibility, as asked:** a project that opts into nothing still sees changed behavior from `writing-plans` — every generated plan now carries mandatory `Depends on:` lines, a Dependency Overview, and a parallel-first handoff. That is D-025 working as designed (routing, not activation), and the spec records it as a conscious deviation from the fork's explicit-activation pattern. `brainstorming`'s deep tier is additive and gated on a proposal, so a project that never accepts one sees only the reworded step 5. `plugin.json` at 6.1.1-7 tracks the skill changes consistently across the range's four bumps.

### Assessment

**Ready to merge?** With fixes.

**Reasoning:** No Critical issues — the consent architecture of the deep research tier holds under every reading I could construct, and the parallel skill's invariants match the spec and the active D-entries exactly. But four Important issues are execution-time misfires rather than polish: the process digraph tells a controller to dispatch implementers before their worktrees exist (2), gated mode deletes the evidence its own Verification Contract demands (3), plans can be numbered so the documented sequential escape hatch runs tasks before their dependencies (5), and plan-embedded gate requests drop a line the TDD skill calls mandatory verbatim (6). All four are small text edits; I would fix those before pushing and take 1, 4, 7 and 8 in the same pass since they are one or two sentences each.

## Findings left open

- Fan-out width: no guidance for a plan with many level-0 tasks against harness concurrency limits.
- `research-subagents.md:130` gives no ruling for a human who insists on bulk approval.
- The visual-companion asymmetry (`SKILL.md:233` vs `:262`), deliberately, pending a measurement round that exercises it.
- Non-Claude plugin manifests stay at 6.1.1; only `.claude-plugin/plugin.json` tracks fork versions.
