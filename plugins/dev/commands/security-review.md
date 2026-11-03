---
name: dev:security-review
description: Adversarial multi-agent security review of Solidity code — context map, 12 attacker personas, judge, refute-first verification
argument-hint: "[files or folder to review] [--history] [--passes N]"
---

# Adversarial Security Review Command

Run a security review in four stages: build a context map, hunt with twelve attacker personas, judge and deduplicate, then try to refute every candidate before it reaches the report. The hunting stage is pashov's `solidity-auditor`; the context and refutation stages are Trail of Bits' `audit-context-building`, `entry-point-analyzer` and `fp-check`. This command is the orchestration that joins them, plus the rules that keep the run honest.

## Input

<input_scope> #$ARGUMENTS </input_scope>

- **Files or folder** — the in-scope `.sol` files. A folder means every `.sol` file under it, minus `interfaces/`, `mocks/`, `test/`, `*.t.sol`. Everything else in the repo may be read for context; nothing else is reviewed.
- `--history` — **off by default.** See "History triage" below.
- `--passes N` — hunting passes (default 1). Each pass after the first is told what earlier passes found.

## Dependencies

Resolve these paths in one parallel message before anything else. Search, in order, `./.claude/skills/`, `~/.claude/skills/` and `~/.claude/plugins/cache/` (Glob with each as its root; take the first hit, and the highest version folder when a plugin cache holds several). If any is missing, print which one and how to install it, and stop:

- pashov: `git clone https://github.com/pashov/skills` and copy `solidity-auditor/` into `~/.claude/skills/`.
- Trail of Bits: `/plugin marketplace add trailofbits/skills`, then install `audit-context-building`, `entry-point-analyzer` and `fp-check`.

| Name | Glob | Source |
|---|---|---|
| `{pashov}` | `**/solidity-auditor/references/hacking-agents/shared-rules.md` → two levels up | `github.com/pashov/skills` |
| `{tob_context}` | `**/audit-context-building/skills/audit-context-building/SKILL.md` | Trail of Bits skills marketplace |
| `{tob_entry}` | `**/entry-point-analyzer/skills/entry-point-analyzer/references/solidity.md` | Trail of Bits skills marketplace |
| `{tob_fp}` | `**/fp-check/skills/fp-check/SKILL.md` → its folder | Trail of Bits skills marketplace |

Record the version of each (pashov `VERSION` file; ToB plugin folder version) in `{run_dir}/scope.md`. A result is only comparable to another run with the same versions.

## History triage — off by default

Prior audit reports, `audits/` folders, git history and blame, changelogs, issue trackers, and finding ledgers (`.solidity-auditor/memory.tsv`) are **not read** unless `--history` is passed.

Why off: a review that reads the last audit finds the last audit's bugs and reports them as its own. That inflates any measurement of what the review finds, and it points every agent at ground already walked. Turn it on for day-to-day work on a codebase you own, where re-confirming old fixes is useful. Leave it off for any run whose numbers you will quote.

When off, every agent prompt carries this line, verbatim:

```
Do not read audit reports, audits/ folders, git history, changelogs or finding ledgers. Review the code as it is.
```

## Stage 0 — Scope

1. `mkdir -p .security-review/{stamp}` → `{run_dir}`. One stamp per run (`date +%Y%m%d-%H%M%S`).
2. Write `{run_dir}/source.md`: every in-scope file as `### path` plus a fenced `solidity` block, in path order. Print its line count.
3. Write `{run_dir}/scope.md`: file list, line count, dependency versions, history on/off, passes, model.

## Stage 1 — Context map (1 agent)

One agent, foreground. It builds the map that every hunter reads. **It reports no findings.** Trail of Bits' context skill is explicit that context building and bug hunting are separate phases, and a context agent that starts hunting writes a worse map.

Prompt:

```
Build a security context map of the code in {run_dir}/source.md. Do not report vulnerabilities.

Method: read {tob_context} and follow its Phase 1 (orientation) and its cross-function flow rules.
Use {tob_entry} to classify entry points. Do the full per-function micro-analysis only for functions
that move value, change accounting, or change who may act; summarise the rest in one line each.

Write {run_dir}/context.md, at most 500 lines, with these sections:
1. Contracts — one line each: role in the system, who deploys it, what it holds.
2. Actors and trust — every role (governance, admins, strategists, managers, keepers, validators,
   relayers, users, any external contract). For each: what it can do, and whether it is trusted.
   Only governance-level roles are trusted. Every other role is an attacker against users and
   against governance, within the powers the code gives it.
3. Entry points — a table per contract: function, access (public / role / owner), state written,
   external calls.
4. State — each storage variable that holds value or accounting, and every function that writes it.
5. Flows — the main user flows end to end across contracts (for example request → fulfil → claim),
   and the order of state writes in each.
6. Invariants — the properties the code must keep for users not to lose funds or be blocked.
   At least 15. Each names the functions that must keep it.
7. Assumptions — what the code assumes about tokens, oracles, external contracts and callers.

Cite file:line for every claim. Say "unclear" rather than guess.
{history line}
```

## Stage 2 — Hunt (12 agents per pass)

Build the twelve bundles exactly as pashov's `solidity-auditor` does (its SKILL.md, Turn 2 step 3), with two changes:

1. `source.md` is `{run_dir}/source.md` from Stage 0.
2. `{run_dir}/context.md` is appended to every bundle, after `report-language.md`, under the heading `# Context map (from Stage 1 — a map, not a verdict)`.

Spawn the twelve agents in one message, in the background, using the two prompt templates in `{pashov}/agent-prompts.md` verbatim, plus these lines at the end of each:

```
Your bundle ends with a context map built by another agent. Use it to find your way. Where the code
disagrees with the map, the code wins — and a wrong line in the map is itself a lead.
Rate each FINDING's severity as Critical, High, Medium or Low (impact × likelihood) in a
`severity:` field.
{history line}
```

Write each agent's output to `{run_dir}/hunt/pass-{K}/agent-{N}.md`. Wait for all twelve; never respawn one that dies — record the loss in `scope.md`.

### Stage 2b — Blind-spot pass (1 agent, after the last pass)

Personas cover bug classes; nothing makes them cover every function. List every function in `context.md`'s entry-point tables that no hunt item names (match on contract and function, both `fn` and `_fn`). Write the list to `{run_dir}/hunt/uncovered.md`. If it is not empty, spawn one agent:

```
You are an attacker. Read {run_dir}/agent-7-bundle.md (source + SOP + first-principles specialty
+ shared rules + context map). Then hunt only in the functions listed in {run_dir}/hunt/uncovered.md,
and in the flows that pass through them. Twelve agents found nothing in these functions; assume
they missed something. Same output format and READ-ONLY rule as your bundle says.
{history line}
```

Write its output to `{run_dir}/hunt/blind-spot.md`. Stage 3 reads it with the rest.

### Multi-pass runs

On a multi-pass run, write `{run_dir}/hunt/known-after-pass-{K}.md` (one line per item: contract, function, bug class, title) and append it to the next pass's bundles with pashov's "Known findings — ground already walked" text. That text tells agents to report listed bugs again in full; keep it.

## Stage 3 — Judge and deduplicate (1 agent)

One agent reads every hunt file and `{pashov}/judging.md`, and writes `{run_dir}/candidates.md`.

```
Read {pashov}/judging.md and every file under {run_dir}/hunt/. Then:
1. Group items that share a root cause (the same code-level defect), whatever their titles.
   Same root cause in two functions that need two fixes = two items.
2. Run every FINDING through the four gates in judging.md. Apply its lead-promotion rules.
   Exception to Gate 3: strategists, managers, keepers, validators and other non-governance
   roles are attackers (see the context map). A harm they can cause to users or to governance
   clears Gate 3.
3. For each surviving item write: id, title, severity (Critical/High/Medium/Low), status
   (FINDING or LEAD), contract, function, root cause (one sentence), path, proof, fix,
   agents that raised it (count and numbers).
4. List rejected items at the end with the gate that rejected them.
{history line}
```

## Stage 4 — Refute (verifier agents)

Split the FINDINGs and the LEADs rated Medium or above in `candidates.md` into slices of at most 8, grouped by contract. Spawn one verifier per slice, in the background, in one message.

```
You are a skeptic. Your job is to prove each candidate below wrong.
Read {tob_fp}/SKILL.md and, in its folder, references/standard-verification.md,
references/gate-reviews.md, references/false-positive-patterns.md and
references/bug-class-verification.md. Apply standard verification to each candidate;
escalate to deep verification only where the skill says to.

Candidates: {slice from candidates.md}
Code: {run_dir}/source.md, plus any file in the repository for context.

For each candidate: restate the claim; trace the path from caller to harm; quote the guard
that stops it if one exists. Verdict: TRUE POSITIVE, FALSE POSITIVE, or UNCERTAIN, with the
evidence. FALSE POSITIVE needs a quoted file:line that stops the attack, or a quoted line that
shows the claim misreads the code. "Unlikely", "the admin would not" or "probably guarded"
is UNCERTAIN, never FALSE POSITIVE. If TRUE POSITIVE, re-rate severity from the impact you can prove, not the impact
claimed. Do not write or run code inside the repository.
End your output with one line per candidate in exactly this form:
VERDICT | <id> | TRUE POSITIVE or FALSE POSITIVE or UNCERTAIN | <severity> | <one-line reason>
{history line}
```

Write each verifier's output to `{run_dir}/verify/slice-{M}.md`. The `VERDICT` lines are what Stage 5 reads.

## Stage 5 — Report

Write `{run_dir}/report.md` yourself, from `candidates.md` and the verify files. No new judgment at this stage.

1. **Findings** — TRUE POSITIVE items, by severity, with the verifier's severity. Each: title, location, root cause, path, proof, fix, `raised by k/12 agents`.
2. **Leads** — UNCERTAIN items, and LEADs not sent to verification.
3. **Refuted** — FALSE POSITIVE items, one line each with the verifier's reason. Keep them: they are how the review's precision is measured.
4. **Run record** — the `scope.md` contents, agent count, and wall time per stage.

Print the findings table and the path to `report.md`.

## Rules

- **Read-only.** No agent creates, edits or deletes a file in the reviewed repository. Proof-of-concept code goes in the agent's own scratch space or in the finding as text.
- **No network for agents.** Agents do not use web search or web fetch during a review. The code is the evidence.
- **Nothing is dropped silently.** Every hunt item ends in the report as a finding, a lead, or a refuted line with a reason.
- **A new bug in live code is not published.** If the review finds a valid issue in code that is deployed, the report goes to the code's owner first.

## Why it is built this way

- **Skills are invoked by the orchestrator, by path.** Agents are told which skill file to read; nothing waits for a skill to auto-trigger. A September 2026 EVMbench study found Claude Code triggered installed audit skills 0 times in 40 runs when left to pick them itself (Gao et al., arXiv 2609.29454).
- **Context before hunting.** The best published pipeline-style recall on EVMbench anchors hunters on a per-function dossier (CHAINTRIX, arXiv 2605.09350, self-reported).
- **A blind-spot pass.** Persona coverage and function coverage are different things; the second decomposition is what CHAINTRIX credits for its extra recall.
- **Refute by quoted line.** A precision filter that rejects on doubt costs recall. Only a quoted guard rejects; doubt stays a lead.
- **Agreement ranks, never filters.** `raised by k/12` is printed, never used to drop an item.
- **Everything refuted is kept.** Precision cannot be measured on items that were thrown away.

## Credits

Stage 2 is pashov's `solidity-auditor` (MIT, `github.com/pashov/skills`). Stages 1 and 4 apply Trail of Bits' `audit-context-building`, `entry-point-analyzer` and `fp-check` skills (`github.com/trailofbits/skills`). Neither is copied here: the command reads them from where they are installed, so their authors' updates reach it.
