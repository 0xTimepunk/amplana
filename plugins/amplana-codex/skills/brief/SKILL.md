---
name: amplana:brief
description: Turn requirements the user has already decided into an agent-ready spec in Codex, using focused questions, targeted research, and spec validation. Use when the user wants to brief or spec a feature before implementation, including when they ask for Amplana or Archon (its former name).
---

# Amplana Brief

Brief the builders on what the user has already decided. Take their requirements, pressure-test them with focused questions, research the codebase, and write an agent-ready technical spec and build plan. This is the Codex-native equivalent of the Claude `/dev:brief` command (formerly `amplana:spec`).

Do not decide what to build: where the requirements leave a product decision open, ask or record it as an open question.

## Input

The user may provide:
- A feature name
- Optional Linear issue reference
- Optional Figma URL

If the feature name is not explicit, derive a short kebab-case slug from the request before creating files.

## Core Principle

Spend most of the effort on understanding and specification before any implementation starts.

## Output Contract

Write outputs under:

- `specs/{feature-name}/spec.md`
- `specs/{feature-name}/technical-spec.md`
- `specs/{feature-name}/interview-notes.md`
- `specs/{feature-name}/research/`

If design context is provided, also use:

- `specs/{feature-name}/design/specification.md`

## Workflow

### 1. Setup

1. Parse the feature name and optional flags from the user request.
2. Determine:
   - spec directory: `specs/{feature-name}/`
   - concise spec: `specs/{feature-name}/spec.md`
   - technical spec: `specs/{feature-name}/technical-spec.md`
   - interview notes: `specs/{feature-name}/interview-notes.md`
   - research directory: `specs/{feature-name}/research/`
3. If the spec directory already exists, inspect its contents before asking the user anything.
4. If `interview-notes.md` already exists, skip the interview and continue from the existing notes.
5. If the user referenced Linear or Figma, treat them as optional enrichments. If those MCP servers are unavailable, continue without blocking.

### 2. Interview

If `interview-notes.md` does not exist, run an interview using `request_user_input`.

Interview requirements:
- Ask 1-3 focused questions per round.
- Prefer multiple-choice prompts when a real tradeoff exists.
- Cover:
  - architecture and integration points
  - data model or schema implications
  - user-facing requirements and acceptance criteria
  - non-functional constraints
  - risks, tradeoffs, and edge cases
  - testing expectations
- Continue until you can produce a decision-complete technical spec.
- Challenge vague requirements instead of papering over them.

After the interview, write a concise transcript and extracted decisions to `interview-notes.md`.

### 3. Optional Linear Sync

If a Linear issue is present and the integration is available:
- read the issue for context before finalizing the spec
- extract or refresh acceptance criteria and technical notes from the interview
- update the issue description without removing unrelated user-written content

If the integration is unavailable, note that in the output and continue.

### 4. Research

Ground the spec in the repo before generating it.

Do all of the following:
- inspect the codebase directly for similar implementations and conventions
- summarize relevant repository findings into `research/repo-analysis.md`
- gather external best practices when the topic is high-risk, unfamiliar, or framework-specific
- gather framework documentation when exact APIs or patterns matter
- run a spec-flow style review for missing flows, states, and edge cases

Use Codex-native tools and available skills where appropriate:
- `repo-research-analyst`
- `best-practices-researcher`
- `framework-docs-researcher`
- `spec-flow-analyzer`

Save research artifacts to:
- `research/repo-analysis.md`
- `research/best-practices.md`
- `research/framework-docs.md`
- `research/specflow-analysis.md`

### 5. Design Context

If a Figma URL is provided and the integration is available:
- extract a design specification covering structure, typography, colors, spacing, responsive behavior, and states
- write it to `design/specification.md`
- reference it from the technical spec

If design extraction is unavailable, preserve the URL and document the missing integration instead of blocking the workflow.

### 6. Technical Spec Generation

Generate `technical-spec.md` using the interview and research outputs.

The spec should include:
- overview
- goals and non-goals
- acceptance criteria
- architecture and data flow
- data model or API changes
- implementation phases or workstreams
- testing strategy
- risks and mitigations
- references to relevant code paths, docs, or design material

Keep the level of detail proportional to complexity, but make it actionable enough for execution.

### 7. Concise Stakeholder Spec

Generate `spec.md` as the short stakeholder-facing summary of the technical spec.

It should capture:
- problem
- proposed approach
- acceptance criteria
- open questions: unresolved product decisions for the user to answer before approval, and decisions already made

### 8. Final Guidance

Before ending:
- remind the user the spec is ready for approval
- point them to the work workflow for implementation
- call out any unresolved assumptions explicitly
