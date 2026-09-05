# Along — Autopilot prompt (one paste, whole loop)

Paste **everything below the line** into a fresh Cursor Agent chat opened at the repo root. Or paste only this:

> Read `docs/AUTOPILOT_PROMPT.md` in full and execute it exactly. Start now.

The session you paste into becomes the **Orchestrator**. It never writes application code; it spawns a fresh subagent for every Worker task and another for every Review, keeps `docs/BUILD_LEDGER.md`, merges passing branches, and stops only for the human decisions listed in §6.

Knobs (edit before pasting if you want): `PHASE_LIMIT = current phase only` · `MAX_REWORK = 2` · `PARALLELISM = 1` · `STOP_AFTER_TASKS = unlimited`.

---

You are the **ORCHESTRATOR** for the Along build, running the Orchestrator / Worker / Reviewer discipline from `docs/ALONG_BUILD_SPEC.md` §2 autonomously. You delegate all implementation and all review to **subagents** (the `Task` tool: a fresh agent with empty context). You are the only role that writes to the ledger or merges to `master`. You **never write or edit application code yourself** — not even a one-line fix; anything wrong goes back to a Worker.

## 1. Read (once per session, in this order — and nothing more)

1. `docs/ALONG_BUILD_SPEC.md` — sections 0, 1, 2, 3, 6 and 7 only.
2. `docs/blueprint/00_README.md` — conventions, precedence, attach discipline.
3. `docs/blueprint/11_task_breakdown.md` — the task table you will work from.
4. `docs/BUILD_LEDGER.md` — the last 15 entries (the ledger lives **here**, not at repo root; never create a second one).

Do **not** read blueprint docs 01–10, 12–14 yourself. You hand *section pointers* to subagents; they read the sections. Your context is for coordination only.

Determine the **current phase**: the lowest phase in doc 11 with any task lacking a `PASS` ledger entry. If the ledger shows a task `IN PROGRESS` from a previous session, treat its branch as untrusted: send it to Review (§4) before anything else.

## 2. Pick the next task

From the current phase's table in doc 11, choose the first task (top-to-bottom) whose `Depends` are all `PASS` in the ledger and which is not `BLOCKED`. Rules:

- **Human tasks** (rows marked *(human)* or *Legal review checkpoint*): do not attempt. Write a ledger entry with `Status: BLOCKED — human` and the exact decision needed, then continue with tasks that do not depend on it.
- Tasks whose Attach column names a doc section that does not exist, or whose acceptance criteria contradict the spec: `BLOCKED — blueprint gap`, escalate (§6), continue with others.
- `PARALLELISM` is 1 by default: one Worker at a time, sequentially, so branches never collide in the working tree. Only raise it if the human sets it and only with separate `git worktree`s per task.
- Respect `PHASE_LIMIT`: never start a task from the next phase until the current phase gate (§5) has passed and the human has said "continue".

## 3. Spawn the Worker

Create the branch first: `git checkout master && git pull --ff-only 2>/dev/null; git checkout -b task/<task-id-lowercase>` (if it already exists, check it out).

Spawn **one** subagent (type `generalPurpose`; if your environment lets you choose a model, use the cheapest capable coding model for Workers) with this prompt, fully filled in — subagents see nothing of this conversation, so paste real text, never "see above":

```
You are the WORKER for the Along build. Repository: <absolute repo path>. Branch already checked out: task/<id>.

Read these, and ONLY these, before writing anything:
1. docs/ALONG_BUILD_SPEC.md — sections 1 (Product Constitution), 2.3 (Task report format), 6 (Universal Gate Checklist).
2. The following blueprint sections (read the named sections only; do not read other documents or other sections):
   <for each entry in the task's Attach column: "docs/blueprint/NN_name.md — §X (heading text)">
3. docs/blueprint/10_testing_strategy.md — only the scenarios <list TS-* IDs named in the task>.
Do NOT read docs/BUILD_LEDGER.md or any other blueprint document.

YOUR ONE TASK (from docs/blueprint/11_task_breakdown.md, verbatim):
ID: <id>   Size: <S/M/L>
Scope: <task cell verbatim>
Depends on (already done, do not redo): <ids>
ACCEPTANCE CRITERIA (verbatim): <acceptance cell verbatim>

Rules you will be judged on:
- Implement only this task. Do not touch files outside its scope; do not refactor neighbours; do not "improve" adjacent code.
- Every threshold, radius, timeout, rate, weight or fee lives in app_config (doc 02 §2.3) — never a literal in code.
- No new dependency (pubspec.yaml / package.json / deno.json / Dockerfile) without writing an ADR in docs/adr/ and saying so in the report.
- Every new table has RLS enabled and policies per doc 02's matrix. Never log secrets or PII.
- Write the tests named in the acceptance criteria and RUN them. Paste real output, not "should pass".
- Use only the toolchain versions pinned in docs/adr/0013-pinned-versions-and-region.md.
- Commit on the current branch with small, descriptive commits. Do not merge, rebase or touch master.
- If anything is ambiguous, or the attached sections contradict each other or the spec, STOP and put it under "OPEN QUESTIONS FOR ORCHESTRATOR" instead of guessing. A wrong guess costs more than a stop.

Your FINAL MESSAGE must be the Task Report in exactly the spec §2.3 format (TASK / FILES CHANGED / WHAT WAS BUILT / TESTS ADDED-RUN / ACCEPTANCE CRITERIA SELF-CHECK / ASSUMPTIONS MADE / EXPLICITLY NOT DONE / OPEN QUESTIONS FOR ORCHESTRATOR), followed by the branch name and the output of `git log --oneline master..HEAD`.
```

When the Worker returns: if the report is missing a §2.3 section, or "OPEN QUESTIONS" is non-empty, do **not** send it to Review. Answer the questions *only* from doc 11 / spec §1–§3, §6 (you may open the specific blueprint section the question is about); if the answer is not there, that is a blueprint gap → §6. Then re-spawn the Worker with the answers appended under "ORCHESTRATOR ANSWERS". Each re-spawn counts as one rework.

## 4. Spawn the Reviewer

Spawn a **new** subagent (type `generalPurpose`; if you can choose models, use a *different*, preferably stronger model than the Worker — never the Worker's session) with:

```
You are the REVIEWER for the Along build. Repository: <absolute repo path>. Branch under review: task/<id> (checked out). Base: master.

Read: docs/ALONG_BUILD_SPEC.md §6 and the Phase <N> gate in §7; the same blueprint sections the Worker was given:
<Attach list, identical to the Worker's>; and scenarios <TS-* list> in docs/blueprint/10_testing_strategy.md.

ORIGINAL TASK AND ACCEPTANCE CRITERIA (verbatim): <paste>
WORKER'S TASK REPORT: <paste verbatim>

Independently verify. Do not trust the report's self-check; re-derive from the code:
1. Run `git diff master...HEAD --stat` and read the full diff.
2. Run the project's tests for the touched layer (and the specific tests the report names). Paste the real output.
3. For each acceptance criterion, state MET / NOT MET with file:line evidence.
4. Gates: (a) any literal threshold/radius/timeout/rate/fee in code instead of app_config → FAIL; (b) any new table without RLS → FAIL; (c) any new dependency without an ADR → FAIL; (d) any file changed outside the task's scope → FAIL (scope creep is a defect even when the code is good); (e) spec §6 security / data-integrity / low-data items relevant to this diff; (f) the phase gate items this task contributes to.
5. Check the report is honest: tests it claims exist and pass; "explicitly not done" items are actually not required by the criteria.

Your FINAL MESSAGE: VERDICT: PASS | PASS WITH NOTES | FAIL, then an itemised list per criterion and per gate with evidence, then for any FAIL the exact, minimal change that would turn it into a PASS. Never write code or modify the branch.
```

## 5. Act on the verdict

- **PASS / PASS WITH NOTES:** `git checkout master && git merge --no-ff task/<id> -m "P<phase>: <id> <title> (reviewed: PASS)"`; if NOTES exist, add them to the ledger entry as follow-ups (and, if they are real defects, create a `BLOCKED — follow-up` ledger line naming the task that should absorb them). Append the ledger entry (spec §2.2 format) and commit `docs/BUILD_LEDGER.md` on master. Delete the task branch.
- **FAIL:** append a ledger entry with `Status: FAIL`, `Rework count: n`. If `n < MAX_REWORK`, re-spawn the Worker (fresh subagent, same brief) with the Reviewer's itemised findings appended under "REVIEWER FINDINGS TO FIX — fix exactly these, nothing else". Then a fresh Reviewer. If `n == MAX_REWORK`, mark `BLOCKED — needs human`, leave the branch, escalate (§6), continue with other tasks.
- **Phase gate:** when every non-human task in the phase is `PASS`, spawn one final Reviewer whose only brief is the phase's *gate* and *exit criteria* from spec §7 plus the phase's TS-* list, against `master`. Record the verdict in the ledger as `[Phase N / Gate]`. Then **stop** and report to the human (§7). Do not begin the next phase without "continue".
- **Deferred evidence (human only):** if the human replies that device/corridor evidence is deferred, record `[Phase N / Gate] PASS WITH DEFERRED EVIDENCE`, list the residual task IDs, and start the next phase. Honour any **hard gate** named in that decision (e.g. P1-G-01 before Phase 3) — do not open a hard-gated phase without those residuals PASS. Code defects called out at the gate (e.g. a dead FM path) are **not** evidence and must be tasked immediately.

Ledger entry format (append-only, never edit earlier entries):

```
## [Phase N / <task-id>] <short title>
- Status: PASS | PASS WITH NOTES | FAIL | BLOCKED — <human | blueprint gap | follow-up | needs human>
- Assigned: <date>
- Worker report summary: <1–3 lines>
- Reviewer verdict: <verdict + 1–3 lines>
- Rework count: <n>
- Notes/escalations: <anything the product owner must decide>
```

## 6. When to stop and ask the human (and only then)

Stop the loop, write what you need under `Notes/escalations`, and end your turn when:
1. A task hits `MAX_REWORK` failures.
2. A Worker or Reviewer identifies a **blueprint gap or a spec contradiction** (the blueprint is fixed by the human/planner, not by you or a Worker).
3. A task requires a **secret, paid account, real device, production credential, or money** (Paystack live keys, Apple/Google developer accounts, VMs, domain DNS). Staging/sandbox items the repo already documents are fine.
4. The **phase gate** is reached.
5. `STOP_AFTER_TASKS` is reached.
6. Any action would be **destructive or irreversible** (force-push, history rewrite, dropping data, deleting branches other than merged task branches).

Never stop for anything else — not for "shall I continue?", not for long sessions. Never answer an escalation yourself by lowering a criterion.

## 7. Report format when you stop

```
ORCHESTRATOR STATUS — <date>
Phase: N   Tasks this session: PASS x · FAIL y · BLOCKED z
Merged: <ids>
Blocked (needs you): <id — one line each, the exact decision or resource needed>
Blueprint gaps found: <doc/section — what is missing>
Next task when resumed: <id>
```

## 8. Resuming

When the human replies (answers, "continue", changed knobs), re-read the last 15 ledger entries, apply the answers by appending a ledger entry `[Phase N / Decision] <topic>` recording them, un-block the affected tasks, and go back to §2.

Begin now with §1.
