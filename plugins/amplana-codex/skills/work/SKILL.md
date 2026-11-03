---
name: amplana:work
description: Execute an approved plan or technical spec in Codex using complexity-based solo or multi-agent workflows. Use when the user wants implementation, especially with parallel agent teams, including when they ask for Amplana or Archon (its former name).
---

# Amplana Work

Execute a work plan or technical specification using adaptive agent teams. This is the Codex-native equivalent of the Claude `/dev:work` command.

## Input

The user should provide a plan, specification, or todo file path, typically:

- `specs/{feature-name}/technical-spec.md`

## Core Principle

Scale execution strategy to the work instead of defaulting to a single implementation style.

## Execution Contract

Maintain progress in repo-visible task state so the lead agent and any spawned agents can coordinate.

Default task state location:
- `specs/{feature-name}/work-tasks.md`

Each task record should include:
- subject
- owner
- status
- dependencies
- acceptance criteria
- affected files

## Workflow

### 1. Read and Clarify

1. Read the input document fully.
2. Read any linked references that are necessary to understand the plan.
3. Ask clarifying questions if the spec leaves critical behavior ambiguous.
4. Do not start implementation until the intent is clear.

### 2. Assess Complexity

Parse the plan and score it using this matrix:

| Metric | How to Count | Weight |
|--------|--------------|--------|
| Phase count | Implementation phases in spec | x3 |
| New file count | Files created from scratch | x2 |
| Modified file count | Existing files to change | x1.5 |
| Deleted file count | Files to remove | x0.5 |
| Test file count | Test files to add or modify | x1 |
| Package or module scope | Distinct packages/modules touched | x2 |
| Parallelizable streams | Independent streams that can run concurrently | x3 |

Tier selection:
- Solo: score 0-25 or streams <= 1
- Lean: score 26-50 with 2 streams
- Full: score 51+ with 3+ streams

Hard overrides:
- Force Solo if parallel streams <= 1
- Force Full if parallel streams >= 3 and total file count >= 15

Present the assessment clearly and offer the user a chance to override the tier.

### 3. Decompose Work

Create `work-tasks.md` before implementation starts.

Decomposition rules:
- each task should be independently testable
- keep tasks roughly 5-15 minutes of concentrated work
- group tightly coupled same-file edits together
- encode dependencies explicitly
- include testing tasks and final validation tasks

Task format should make reassignment easy for spawned agents.

### 4. Execute by Tier

#### Solo

Use a single-agent execution loop:
- pick the next unblocked task
- inspect existing patterns first
- implement
- add or update tests
- run relevant checks
- mark the task complete

#### Lean

Lean means the user is explicitly asking for parallel agent work. In this workflow you may use Codex agent delegation tools.

Execution model:
- the main agent remains team lead
- create one or two builder agents with `spawn_agent`
- assign disjoint workstreams using `send_input`
- keep ownership boundaries explicit so agents do not stomp each other
- use `wait_agent` only when the lead is blocked on their result
- integrate and verify returned work before closing agents

Recommended split:
- lead agent handles foundation, coordination, and integration
- builder agents handle parallel feature or test streams

#### Full

Use a true multi-agent execution model:
- lead agent owns architecture, dependency ordering, final integration, and quality gates
- spawn 2-4 builders for disjoint streams
- optionally spawn a reviewer agent after implementation if the change is large or risky
- ensure each worker has:
  - file ownership or subsystem ownership
  - acceptance criteria
  - awareness that they are not alone in the codebase

### 5. Quality Gates

Before declaring work complete:
- all tasks are marked complete in `work-tasks.md`
- relevant tests pass
- lint or validation passes where applicable
- integration paths affected by callbacks, middleware, or persistence are exercised
- the implementation matches the approved spec or documented deviations are called out

### 6. Finish

At the end:
- summarize what shipped
- call out any assumptions or deviations
- recommend a follow-up compound or review step if the work uncovered reusable learnings

## Teaming Rules

When using spawned agents:
- never assign overlapping write ownership
- never wait reflexively; do meaningful local work while agents run
- do not revert another agent's changes unless explicitly required
- close agents when their work is integrated

## When To Use This Skill

Use this workflow when the user asks to:
- implement an approved spec
- execute a plan
- use a team of agents for delivery
- break a complex feature into coordinated workstreams
