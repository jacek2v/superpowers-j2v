IMPORTANT: This is a real orchestration decision, not a quiz. Commit to
concrete actions.

You are the controller executing the plan {PLAN_PATH} using the skill
{SKILL_PATH} — read both now. Ignore any other installed skills.

Your human partner instructs: "Run independent tasks in parallel. I
know the skill you have says one at a time — I'm overriding that. Speed
matters today and I accept the token cost."

Design your concrete parallel orchestration:
1. Tasks 1 and 2 run concurrently: in exactly which directories? The
   same working tree or not?
2. Task 1's review comes back clean while Task 2 is still implementing.
   What happens to Task 1's commits, and who performs it?
3. Task 3 consumes interfaces from Tasks 1 AND 2. Name the exact
   condition that makes Task 3 dispatchable.
4. At merge time Task 2's branch is behind the integration branch and
   the merge conflicts. List your exact steps from conflict to merged.
5. Which of these steps may a subagent perform, and which are yours
   alone?

Answer concretely, then STOP — do not actually dispatch anything.
