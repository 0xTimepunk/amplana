---
name: dev:brief
description: Turn requirements you have already decided into an agent-ready spec: pressure-test them, research the codebase, write the build plan
argument-hint: <feature-name> [requirements...] [--no-interview] [--linear LINEAR-XXX] [--figma <figma-url>]
---

# /dev:brief Command

Brief the builders on what you have already decided. You decide what to build (whiteboard, peers, stakeholders); this command takes those requirements, pressure-tests them with focused questions, researches the codebase with parallel agents, and writes an agent-ready technical spec and build plan for `/dev:work`, plus a concise spec for stakeholder approval (80% planning, 20% execution).

It does not decide what to build. Where the requirements leave a product decision open, ask (or record it as an open question); do not invent scope.

(`/dev:brief` was called `/dev:spec` before v1.2.0. `/dev:spec` still works for now and runs this command.)

## Input

<feature_name>$ARGUMENTS</feature_name>

The first word is the feature name (kebab-case it if needed). Any other text that is not a flag is the **requirements** you have decided, for example:

```
/dev:brief dodge-game "Single-file HTML canvas game: arrow keys move a square, red blocks fall, score is survival time, R restarts"
```

## Before You Start

### Paths

All `specs/...` paths in this command are **relative to the repository root** (`git rev-parse --show-toplevel`), or to the current directory when it is not a git repository. Never write to an absolute `/specs/` path.

### Interview mode

Pick one, and say which in your first message:

- **Interactive** (default): AskUserQuestion is available and no `--no-interview` flag was passed.
- **No interview**: AskUserQuestion is not available (for example a headless `claude -p` run), or `--no-interview` was passed. Do not ask questions. Build the interview notes from the requirements, the Linear issue (if any) and the codebase. Where the requirements are silent on an implementation detail, choose the simplest reasonable option and record it under **Assumptions** in `interview-notes.md`. Where they are silent on a product decision (who it is for, what is in or out of scope, behaviour a user would notice), do not decide: record it under **Open Questions** and carry it into the spec's Open Questions table. If there are no requirements at all and no way to ask, stop and print the usage example above.

In no-interview mode, every place below that says "use AskUserQuestion" means: take the recommended or first option and record the choice.

### Agent resolution

Nothing here requires another plugin. Research runs as `general-purpose` subagents with the role prompts below. If the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin's 2.x agent types are installed, they are used instead. Check the agent types available to the subagent tool (`Task`; called `Agent` in newer Claude Code) once, before Phase 3:

- If `compound-engineering:research:repo-research-analyst` is listed (compound-engineering 2.x), use the **compound-engineering agent** for each role below.
- Otherwise (compound-engineering not installed, or 3.x, which no longer registers agent types) use `subagent_type="general-purpose"` and start its prompt with the **role prompt**, followed by the same task prompt.
- If no subagent tool is available, do the research yourself, in sequence, and write the same files.

| Role | compound-engineering 2.x agent | Role prompt (prefix for a `general-purpose` agent) |
|------|---------------------------|------------------------------------------------------|
| Repo research | `compound-engineering:research:repo-research-analyst` | "You are a repository research analyst. Map the structure, conventions, similar code and test setup relevant to this feature. Cite file paths with line numbers." |
| Best practices | `compound-engineering:research:best-practices-researcher` | "You are a best-practices researcher. Summarise current, widely accepted practice for this kind of feature, with sources." |
| Framework docs | `compound-engineering:research:framework-docs-researcher` | "You are a framework documentation researcher. Find the exact APIs, versions and constraints of the libraries or platform this feature uses, with links." |
| Spec flow | `compound-engineering:workflow:spec-flow-analyzer` | "You are a spec flow analyst. Walk every user flow in this feature description and list missing states, edge cases, error paths and unclear requirements." |
| Figma design | `compound-engineering:design:figma-design-sync` | "You are a design spec extractor. Use the Figma MCP tools to read the given URL and write a design spec." (needs a Figma MCP server either way) |

Tell the user once which set is in use, for example: "Using general-purpose research agents (no compound-engineering 2.x agent types found)."

compound-engineering **skills** are used where they exist, by whichever name is installed: spec review is `compound-engineering:ce-doc-review` (3.x) or `compound-engineering:document-review` (2.x). Check the available skills list before calling one.

## Workflow

### Phase 1: Setup

1. Parse the feature name, the requirements and the flags from the input
   - If `--linear LINEAR-XXX` is provided, extract the Linear issue ID
2. Determine spec paths:
   - Spec directory: `specs/{feature-name}/`
   - Concise spec: `specs/{feature-name}/spec.md`
   - Technical spec: `specs/{feature-name}/technical-spec.md`
   - Interview notes: `specs/{feature-name}/interview-notes.md`
   - Research folder: `specs/{feature-name}/research/`
3. Check if spec directory already exists:
   - If exists, use AskUserQuestion: "Spec already exists. Continue editing or start fresh?" (no-interview mode: continue editing)
4. **Check if interview-notes.md already exists:**
   - If `specs/{feature-name}/interview-notes.md` exists, **skip Phase 2 entirely**
   - Inform user: "Found existing interview notes. Skipping interview and proceeding to Phase 3."
5. Create `specs/{feature-name}/` and `specs/{feature-name}/research/` directories if needed
6. If Linear issue provided:
   - Check if a Linear MCP server is connected: look for tools ending in `get_issue` and `update_issue` whose name contains `linear` (for example `mcp__linear__get_issue`, or `mcp__plugin_dev_linear__get_issue` for older installs)
   - If available: Read the issue for context, extract acceptance criteria, note Figma/Postman links
   - If not available: Show warning "Linear MCP not connected (see the Amplana README, Optional integrations). Continuing without Linear." and skip Phase 2.5
7. If `--figma` is provided:
   - Extract the Figma URL from arguments
   - Store for use in Phase 3.1.1
   - Note: needs a connected Figma MCP server (Figma account with a Dev or Full seat). If none is connected, keep the URL in the technical spec's References and skip Phase 3.1.1

---

### Phase 2: Interview

**SKIP THIS PHASE if interview-notes.md already exists (checked in Phase 1 step 4)**

**No-interview mode:** do not interview. Write `specs/{feature-name}/interview-notes.md` with these sections, filled from the requirements, the Linear issue and the codebase: Summary, Requirements (functional, non-functional), Acceptance Criteria (checkbox list), Technical Decisions, Assumptions (each implementation choice you made where the requirements were silent), Open Questions (each product decision left to the user), Testing Strategy. Then go to Phase 2.5.

**Interactive mode:** conduct a thorough interview using the **AskUserQuestion** tool. If requirements were given, start from them and ask only about what they leave open or what looks contradictory or risky. If none were given, first ask one open question: what have you decided to build, for whom, and what must be true when it is done? Then continue from the answer. Ask 2-4 focused questions at a time covering:

**Technical Implementation**
- Architecture approach
- Data models and schemas
- API contracts
- Integration points
- Technology choices

**Requirements**
- Functional requirements (user stories)
- Non-functional requirements (performance, security, scalability)
- Acceptance criteria (seed from Linear if available)

**Design & UX** (if applicable)
- User flows
- Edge cases
- Error states

**Tradeoffs & Risks**
- Alternative approaches considered
- Technical debt implications
- Security concerns
- Performance implications
- Dependencies and blockers

**Testing Strategy**
- Unit test scope
- Integration test scenarios
- E2E test coverage

#### Interview Guidelines

- Use AskUserQuestion with 2-4 focused questions per round
- Ask non-obvious questions and probe deeply on tradeoffs
- Challenge assumptions constructively
- Reference Linear context if loaded
- **Reference codebase research findings** to ask informed questions
- Continue until all sections have sufficient content

**After interview:** Write the interview transcript to `specs/{feature-name}/interview-notes.md`

---

### Phase 2.5: Sync to Linear (if --linear provided)

**SKIP THIS PHASE if no Linear issue was provided in Phase 1**

After interview completes and interview-notes.md is written, sync the gathered requirements back to the Linear issue:

1. **Extract from interview transcript:**
   - Parse the Acceptance Criteria section (full checkbox list with nesting)
   - Extract Technical Decisions and condense to 3-5 key bullets

2. **Format Technical Notes:**
   Condense technical decisions into 3-5 bullets covering:
   - Authentication/authorization approach
   - Data architecture decisions
   - Key technical constraints
   - Integration points
   - Any TBD items

3. **Read current Linear issue** with the Linear `get_issue` tool found in Phase 1 (the tool name depends on how the server was added):
   ```
   mcp__linear__get_issue(id="{LINEAR-XXX}")
   ```

4. **Update issue description:**
   - Find `## Acceptance Criteria` heading in the existing description
   - If found: Replace entire section content up to next heading
   - If not found: Append new `## Acceptance Criteria` section at end
   - Find `## Technical Notes` heading
   - If found: Replace entire section content up to next heading
   - If not found: Append new `## Technical Notes` section after Acceptance Criteria

5. **Write updated description** (this writes to Linear; in interactive mode, show the new sections and confirm with AskUserQuestion first):
   ```
   mcp__linear__update_issue(
     id="{LINEAR-XXX}",
     description="{updated_description_markdown}"
   )
   ```

6. **Confirm success:**
   > "Synced to Linear {LINEAR-XXX}: Acceptance Criteria and Technical Notes updated."

**Section Templates:**

**Acceptance Criteria:**
```markdown
## Acceptance Criteria

- [ ] {requirement 1}
- [ ] {requirement 2}
  - [ ] {sub-requirement}
  - [ ] {sub-requirement}
- [ ] {requirement 3}
```

**Technical Notes:**
```markdown
## Technical Notes

- **{Topic 1}:** {Brief description of technical decision/constraint}
- **{Topic 2}:** {Brief description}
- **{Topic 3}:** {Brief description}
- **{Topic 4}:** {Brief description} (if applicable)
- **{Topic 5}:** {Brief description} (if applicable)
```

---

### Phase 3: Research & Technical Planning

**First, read the interview notes:**
1. Read `specs/{feature-name}/interview-notes.md` to extract all gathered requirements
2. Parse the interview transcript to identify:
   - Feature summary and goals
   - Functional and non-functional requirements
   - Technical decisions and constraints
   - Risks and tradeoffs discussed
   - Testing strategy

#### 3.1 Repository Research & Context Gathering

Run these three agents **in parallel** using the subagent tool (agent types from **Agent resolution** above). Every research prompt must also say: the repository root path, and "Return your findings in your reply; do not write or edit files." You write the research files from their replies:

```
# compound-engineering 2.x agent types present
Task(subagent_type="compound-engineering:research:repo-research-analyst", prompt="{feature_description_from_interview}")
Task(subagent_type="compound-engineering:research:best-practices-researcher", prompt="{feature_description_from_interview}")
Task(subagent_type="compound-engineering:research:framework-docs-researcher", prompt="{feature_description_from_interview}")

# Otherwise (default)
Task(subagent_type="general-purpose", prompt="{repo research role prompt}\n\nRepository: {repo root}. Return findings in your reply; do not write files.\n\n{feature_description_from_interview}")
Task(subagent_type="general-purpose", prompt="{best practices role prompt}\n\nRepository: {repo root}. Return findings in your reply; do not write files.\n\n{feature_description_from_interview}")
Task(subagent_type="general-purpose", prompt="{framework docs role prompt}\n\nRepository: {repo root}. Return findings in your reply; do not write files.\n\n{feature_description_from_interview}")
```

If the feature touches at most two files and uses no external library, run only the repo research agent, and write a one-line `best-practices.md` and `framework-docs.md` saying why they were skipped. Always run the spec flow analysis.

**Save Research Outputs:**
After each agent completes, write its findings to the research folder:
- `specs/{feature-name}/research/repo-analysis.md` - Repository patterns, similar code, conventions
- `specs/{feature-name}/research/best-practices.md` - External best practices and recommendations
- `specs/{feature-name}/research/framework-docs.md` - Framework documentation and examples

**Reference Collection:**
- [ ] Document all research findings with specific file paths (e.g., `app/services/example_service.rb:42`)
- [ ] Include URLs to external documentation and best practices guides
- [ ] Create a reference list of similar issues or PRs (e.g., `#123`, `#456`)
- [ ] Note any team conventions discovered in `CLAUDE.md` or team documentation

#### 3.1.1 Figma Design Specification (if --figma provided)

**ONLY run if `--figma` flag was used in Phase 1 and a Figma MCP server is connected**

1. Create design directory: `specs/{feature-name}/design/`

2. Run the Figma design agent (`general-purpose` with the Figma role prompt unless the compound-engineering 2.x agent is listed):
   ```
   Task(subagent_type="compound-engineering:design:figma-design-sync", prompt="
   Extract design specifications from Figma URL: {figma_url}

   Output comprehensive design spec including:
   - Layout structure and component hierarchy
   - Typography (font family, sizes, weights, line heights)
   - Colors (backgrounds, text, borders, accents)
   - Spacing (padding, margins, gaps)
   - Responsive breakpoints
   - Interactive states (hover, focus, active)
   - Shadows, borders, decorative elements
   - Component variants and states
   ")
   ```

3. Save output to `specs/{feature-name}/design/specification.md`

4. Take screenshot of design and save to `specs/{feature-name}/design/reference.png`

5. Update technical-spec.md template to include design reference section:
   ```markdown
   ## Design Reference
   See: [design/specification.md](./design/specification.md)
   ![Design Reference](./design/reference.png)
   ```

#### 3.2 SpecFlow Analysis

After research completes, run the spec flow analysis:

```
# compound-engineering 2.x agent types present
Task(subagent_type="compound-engineering:workflow:spec-flow-analyzer", prompt="{repo root}\n\n{feature_description_with_research_findings}")

# Otherwise (default)
Task(subagent_type="general-purpose", prompt="{spec flow role prompt}\n\nRepository: {repo root}. Return findings in your reply; do not write files.\n\n{feature_description_with_research_findings}")
```

**Save SpecFlow Output:**
Write the analysis to `specs/{feature-name}/research/specflow-analysis.md`

**SpecFlow Analyzer Output:**
- [ ] Review SpecFlow analysis results
- [ ] Incorporate any identified gaps or edge cases
- [ ] Update acceptance criteria based on SpecFlow findings

#### 3.3 Technical Spec Generation

Based on all gathered research, write the technical specification to `specs/{feature-name}/technical-spec.md`.

**Choose detail level based on complexity:**

---

##### MINIMAL (Simple features)

```markdown
# {Feature Name} Technical Specification

## Overview
[Brief problem/feature description from interview]

## Acceptance Criteria
- [ ] Core requirement 1
- [ ] Core requirement 2

## Context
[Critical information from research]

## Implementation
### {filename}.{ext}
```{language}
// Pseudo-code or skeleton
```

## References
- Related issue: #[issue_number]
- Documentation: [relevant_docs_url]
```

---

##### STANDARD (Recommended for most features)

```markdown
# {Feature Name} Technical Specification

## Overview
[Comprehensive description from interview]

## Problem Statement / Motivation
[Why this matters - from interview]

## Proposed Solution
[High-level approach]

## Technical Considerations
- Architecture impacts
- Performance implications
- Security considerations

## Acceptance Criteria
- [ ] Detailed requirement 1
- [ ] Detailed requirement 2
- [ ] Testing requirements

## Success Metrics
[How we measure success]

## Dependencies & Risks
[What could block or complicate this]

## Implementation

### {filename}.{ext}
```{language}
// Implementation skeleton with key methods
```

## References & Research
- Similar implementations: [file_path:line_number]
- Best practices: [documentation_url]
- Related PRs: #[pr_number]
```

---

##### COMPREHENSIVE (Major features, architectural changes)

```markdown
# {Feature Name} Technical Specification

## Overview
[Executive summary]

## Problem Statement
[Detailed problem analysis from interview]

## Proposed Solution
[Comprehensive solution design]

## Technical Approach

### Architecture
[Detailed technical design]

### Implementation Phases

#### Phase 1: [Foundation]
- Tasks and deliverables
- Success criteria

#### Phase 2: [Core Implementation]
- Tasks and deliverables
- Success criteria

#### Phase 3: [Polish & Optimization]
- Tasks and deliverables
- Success criteria

## Alternative Approaches Considered
[Other solutions evaluated and why rejected - from interview]

## Acceptance Criteria

### Functional Requirements
- [ ] Detailed functional criteria

### Non-Functional Requirements
- [ ] Performance targets
- [ ] Security requirements
- [ ] Accessibility standards

### Quality Gates
- [ ] Test coverage requirements
- [ ] Documentation completeness
- [ ] Code review approval

## Success Metrics
[Detailed KPIs and measurement methods]

## Dependencies & Prerequisites
[Detailed dependency analysis]

## Risk Analysis & Mitigation
[Comprehensive risk assessment from interview]

## Implementation

### {filename}.{ext}
```{language}
// Detailed implementation with all key components
```

## Future Considerations
[Extensibility and long-term vision]

## Documentation Plan
[What docs need updating]

## References & Research

### Internal References
- Architecture decisions: [file_path:line_number]
- Similar features: [file_path:line_number]
- Configuration: [file_path:line_number]

### External References
- Framework documentation: [url]
- Best practices guide: [url]
- Industry standards: [url]

### Related Work
- Previous PRs: #[pr_numbers]
- Related issues: #[issue_numbers]
- Design documents: [links]
```

---

### Phase 4: Distill Stakeholder Summary

**IMPORTANT: No additional questions in this phase. Pure distillation.**

Read the technical spec from Phase 3 (`specs/{feature-name}/technical-spec.md`) and distill into a concise spec for stakeholder approval.

Write to `specs/{feature-name}/spec.md` using this **strict template** (enforced). Always write Status as Draft and leave the Approval box unticked: only a human approves a spec.

```markdown
# {Feature Name} Spec

## Metadata
- Project: {project-name}
- Milestone: {milestone-name}
- Linear Issue: {LINEAR-XXX} or N/A
- Interview Date: {date}
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary
{1-2 paragraph executive summary}

## Requirements

### Functional
1. {requirement}
2. {requirement}

### Non-Functional
- {requirement}

## Technical Design

### Architecture
{Diagrams, component descriptions}

### Data Model
{Schema changes, new models}

### API Changes
{Endpoints, contracts}

## Implementation Plan

### Phase 1: {Name}
- [ ] Task 1
- [ ] Task 2

## Test Plan
- [ ] Unit tests for: {components}
- [ ] Integration tests for: {flows}
- [ ] E2E tests for: {scenarios}

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

## Open Questions

### Unresolved
Product decisions the requirements leave open. The user must answer these before approving.

| Question | Why it matters | Options |
|----------|----------------|---------|

### Resolved
| Question | Answer | Decided By |
|----------|--------|------------|

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)

---

## Approval
- [ ] Stakeholder Approved
- Approved date: ___

## Next Steps
After approval, run: `/dev:work specs/{feature-name}/technical-spec.md`
```

---

### Phase 5: Post-Generation Options

Present the completion summary. In interactive mode, follow it with the options below using **AskUserQuestion**. In no-interview mode, print the summary and the next-step line (`/dev:work specs/{feature-name}/technical-spec.md`) and stop.

```
Spec created at: specs/{feature-name}/

Files:
- spec.md              - Stakeholder spec (strict template)
- technical-spec.md    - Detailed technical specification
- interview-notes.md   - Interview transcript
- research/            - Research agent outputs
  |- repo-analysis.md
  |- best-practices.md
  |- framework-docs.md
  \- specflow-analysis.md
```

**Question:** "Spec ready. What would you like to do next?"

**Options:**
1. **Open in editor** - Open the spec files for review
2. **Deepen research** - Enhance each section with parallel research agents (best practices, performance, UI)
3. **Get feedback** - Review the technical spec for gaps, contradictions and scope
4. **Start `/dev:work`** - Begin implementing this spec locally
5. **Create Linear issue** - Create issue in Linear with spec content (only offer when a Linear MCP server is connected)
6. **Simplify** - Reduce detail level of technical spec

AskUserQuestion takes at most 4 options per question: show the first four that apply and let **Other** cover the rest.

**Based on selection:**

- **Open in editor** -> Run `open specs/{feature-name}/spec.md` (macOS) or `xdg-open` (Linux)
- **Deepen research** -> Run additional targeted research agents (same roles as Phase 3.1) on the weak sections and fold the findings into the technical spec
- **Get feedback** -> If a compound-engineering doc review skill is installed: `Skill(skill="compound-engineering:ce-doc-review", args="specs/{feature-name}/technical-spec.md")` (2.x: `compound-engineering:document-review`). Otherwise: one `general-purpose` agent prompted "You are a spec reviewer. Find gaps, contradictions, untestable criteria and scope creep in this spec. Report, do not edit." with the spec path
- **`/dev:work`** -> `Skill(skill="dev:work", args="specs/{feature-name}/technical-spec.md")`
- **Create Linear issue** -> Create Linear issue with spec.md content
- **Simplify** -> Ask "What should I simplify?" then regenerate simpler version
- **Other** (automatically provided) -> Accept free text for rework or specific changes

**Loop** back to options after Simplify, Get feedback or Other changes until the user selects `/dev:work` or ends the session.

---

## Output Structure

```
specs/{feature-name}/
|- spec.md              # Stakeholder spec (strict template - for approval)
|- technical-spec.md    # Detailed technical spec with implementation guidance
|- interview-notes.md   # Interview transcript
|- design/              # Design specification (if --figma used)
|  |- specification.md  # Figma design spec from design-sync agent
|  \- reference.png     # Design screenshot
\- research/            # Research agent outputs (for reference)
   |- repo-analysis.md
   |- best-practices.md
   |- framework-docs.md
   \- specflow-analysis.md
```

## Usage Examples

```bash
# Basic usage
/dev:brief user-authentication

# Requirements up front (the interview only asks about gaps)
/dev:brief dodge-game "Single-file HTML canvas game: arrow keys move, blocks fall, survival-time score"

# No interview at all (also the automatic mode in headless `claude -p` runs)
/dev:brief dodge-game --no-interview "Single-file HTML canvas game: arrow keys move, blocks fall, survival-time score"

# With Linear issue reference
/dev:brief user-authentication --linear LINEAR-123

# With Figma design reference
/dev:brief hero-section --figma https://figma.com/file/abc123/design?node-id=45:678

# With both Linear and Figma
/dev:brief user-dashboard --linear LINEAR-123 --figma https://figma.com/file/xyz789/app?node-id=12:34
```

## Key Principles

- **NEVER CODE** - This command produces specs, not implementation
- **You decide what, it plans how** - Requirements come from the user; the command sharpens and plans them, it does not choose the product
- **80/20 Rule** - 80% planning effort here, 20% execution later
- **Research First** - Parallel agents gather context before planning
- **Interview Notes as Source of Truth** - All specs derive from interview-notes.md
- **Stakeholder Approval Required** - spec.md is the approval artifact
