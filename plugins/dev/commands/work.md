---
name: dev:work
description: Execute specs using adaptive agent teams with knowledge compounding
argument-hint: "[spec file path, e.g., specs/feature-name/technical-spec.md]"
---

# Adaptive Work Execution Command

Execute a work plan using adaptive agent teams. Team size scales with spec complexity — from solo execution for simple tasks to full teams for complex multi-stream work.

## Introduction

This command takes a work document (plan, specification, or todo file) and executes it systematically using Claude Code's agent teams. The focus is on **shipping complete features** by understanding requirements quickly, following existing patterns, and adapting team size to the work's complexity.

## Input Document

<input_document> #$ARGUMENTS </input_document>

## Before You Start

### Paths

All `specs/...` paths are **relative to the repository root** (`git rev-parse --show-toplevel`), or to the current directory when it is not a git repository.

### Tool check

Check once which of these tools you have, and say in one line which execution features are available:

| Tool | Used for | When missing |
|------|----------|--------------|
| AskUserQuestion | Clarifying questions, tier confirmation, compound prompt | **Non-interactive mode** (for example a headless `claude -p` run): ask nothing, take the recommended option at every decision point, and list each decision in the final summary |
| TaskCreate / TaskUpdate / TaskList | Task tracking | Track tasks in `specs/{feature-name}/work-tasks.md` (one checklist line per task: subject, owner, status, blocked-by) |
| TeamCreate / SendMessage | Lean and Full agent teams | Agent teams are an experimental Claude Code feature, on only when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set. Without them, Lean and Full run as **parallel subagents** (see Phase 4) |
| Task (called Agent in newer Claude Code) | Subagents (builders, reviewers) | Everything runs Solo |

### Agent resolution

Nothing in this command requires another plugin. Reviewers run as `subagent_type="general-purpose"` with the role prompts given below. If the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin's 2.x agent types are installed (`compound-engineering:review:*` is in the agent type list), use those instead; compound-engineering 3.x no longer registers agent types. compound-engineering **skills** are used where they exist, by whichever name is installed (check the available skills list first): worktrees are `ce-worktree` (3.x) or `git-worktree` (2.x), branch review is `ce-code-review` (3.x) or `ce:review` (2.x).

## Execution Workflow

### Phase 1: Quick Start

1. **Read Plan and Clarify**

   - Read the work document completely
   - Review any references or links provided in the plan
   - If anything is unclear or ambiguous, ask clarifying questions now
   - Check the sibling `spec.md` (if any): if its Approval box is not ticked, say so. Interactive: ask "The spec is not marked approved. Proceed anyway?" Non-interactive: proceed and list "spec not approved" in the final summary
   - Get user approval to proceed
   - **Do not skip this** - better to ask questions now than build the wrong thing
   - Non-interactive mode: do not stop. Resolve each ambiguity with the simplest reading of the spec and note it as an assumption

2. **Setup Environment**

   Never commit to the default branch. First find where you are:

   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null || echo "not a git repo"
   git status --porcelain            # uncommitted changes?
   git remote                        # any remotes?
   # Default branch: the remote's HEAD if there is a remote, else the current branch
   DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
   [ -z "$DEFAULT" ] && DEFAULT=$(git rev-parse --abbrev-ref HEAD)
   ```

   - **Not a git repo:** ask whether to run `git init` (non-interactive: work in place without git and say so). Skip the rest of this step.
   - **Uncommitted changes** (ignore untracked files under `specs/{feature-name}/`: they are this spec, they carry over to the new branch, and they are committed with the work): do not switch branches. Ask whether to branch from the current state (non-interactive: create the feature branch from the current HEAD with `git checkout -b feat/{feature-name}`, keeping the changes), then skip the options below.

   With a clean working tree, choose a work style (ask the user; non-interactive: Option A):

   **Option A: Feature branch in this checkout**
   ```bash
   git checkout "$DEFAULT"
   git remote | grep -q . && git pull --ff-only origin "$DEFAULT"   # only when a remote exists
   git checkout -b feat/{feature-name}
   ```
   If you are already on a non-default feature branch the user created for this work, stay on it.

   **Option B: Isolated worktree (for parallel development)**
   - With compound-engineering: `Skill(skill="compound-engineering:ce-worktree")` (2.x: `compound-engineering:git-worktree`)
   - Otherwise:
     ```bash
     git worktree add -b feat/{feature-name} "../$(basename "$PWD")-{feature-name}" "$DEFAULT"
     ```
     then work inside that directory.

   **Recommendation**: Use a worktree if you want to work on several features at once or keep the main checkout untouched. Use a feature branch for a single feature.

---

### Phase 2: Complexity Assessment

Analyze the technical spec to determine team size. Parse the spec and extract these metrics:

#### Scoring Matrix

| Metric | How to Count | Weight |
|--------|-------------|--------|
| Phase count | Number of implementation phases in spec (count 1 if the spec has no phases section) | x3 |
| New file count | Files to create from scratch (not counting test files) | x2 |
| Modified file count | Existing files to change (not counting test files) | x1.5 |
| Deleted file count | Files to remove | x0.5 |
| Test file count | Test files to create or modify | x1 |
| Package/module scope | Distinct packages/modules touched | x2 |
| Parallelizable streams | Independent work streams that can run concurrently | x3 |

**Calculate:** `score = sum(metric * weight)`

#### Tier Selection

| Tier | Score Range | Parallel Streams | Team Composition |
|------|------------|-----------------|-----------------|
| **Solo** | 0-25 OR streams <= 1 | 0-1 | Single agent with TaskCreate tracking |
| **Lean** | 26-50, 2 streams | 2 | Lead + 1-2 Builder teammates |
| **Full** | 51+, 3+ streams | 3+ | Lead + 2-4 Builders + optional Reviewer |

#### Hard Overrides

- **Force Solo** if `parallelizable_streams <= 1` regardless of score (no benefit from team when work is sequential)
- **Force Full** if `parallelizable_streams >= 3 AND total_file_count >= 15` (complex enough to justify full team)

#### Announce Decision

Present the assessment to the user before proceeding:

```
Complexity Assessment:
- Phases: {n} (x3 = {score})
- New files: {n} (x2 = {score})
- Modified files: {n} (x1.5 = {score})
- Test files: {n} (x1 = {score})
- Packages: {n} (x2 = {score})
- Parallel streams: {n} (x3 = {score})
- Total score: {total}

Selected tier: {Solo|Lean|Full}
Rationale: {why this tier was chosen}

Parallel streams identified:
1. {stream description}
2. {stream description}
...
```

Use AskUserQuestion to confirm tier or let user override (non-interactive mode: proceed with the selected tier):
- "Proceed with {tier} execution (Recommended)"
- "Override to Solo"
- "Override to Lean"
- "Override to Full"

If the tier is Lean or Full and TeamCreate is not available, say so in the announcement: "Agent teams are off (set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to enable them); running {tier} as parallel subagents."

---

### Phase 3: Task Decomposition

Break the spec into tasks using TaskCreate. Every task gets created regardless of tier — the tier only determines how they're executed.

Without TaskCreate, write the same tasks to `specs/{feature-name}/work-tasks.md` and keep that file current instead (`- [ ] T1 Create game loop in index.html | owner: lead | blocked-by: none`). Read "TaskCreate", "TaskUpdate" and "TaskList" below as edits to and reads of that file.

#### Task Structure

Each task must have:
- **subject**: `"<verb> <what> in <where>"` — imperative form, specific
- **description**: Full context including:
  - Which spec section this implements
  - Files to create or modify (with paths)
  - Implementation notes and approach
  - Acceptance criteria for this task
  - Dependencies on other tasks
- **activeForm**: Present participle for spinner display (e.g., "Creating user model")

#### Task Granularity Rules

- **Single responsibility**: One file or tightly coupled group of files
- **Testable independently**: Each task produces verifiable output
- **5-15 minute scope**: Not too small (overhead), not too big (hard to track)
- **Same-file affinity**: Multiple changes to the same file belong in the same task

#### Dependencies

Use `addBlockedBy` to establish task ordering:
- Foundation tasks (models, schemas, types) block implementation tasks
- Implementation tasks block test tasks
- All tasks block the final integration test task

#### Example Task Decomposition

```
TaskCreate: "Create User model and migration"
  description: "Phase 1 foundation. Create app/models/user.rb with..."
  activeForm: "Creating User model"

TaskCreate: "Add authentication endpoints"
  description: "Phase 2 core. Create app/controllers/auth_controller.rb..."
  activeForm: "Adding auth endpoints"
  addBlockedBy: [task-1-id]

TaskCreate: "Write unit tests for User model"
  description: "Test coverage for User model validations..."
  activeForm: "Writing User model tests"
  addBlockedBy: [task-1-id]

TaskCreate: "Write integration tests for auth flow"
  description: "E2E auth flow tests..."
  activeForm: "Writing auth integration tests"
  addBlockedBy: [task-1-id, task-2-id]
```

---

### Phase 4: Execute

Execution strategy depends on the tier selected in Phase 2.

#### Solo Execution

For simple, sequential work. No team creation needed.

```
For each task (respecting dependency order):
  1. TaskUpdate(taskId, status="in_progress")
  2. Read any referenced files from the spec
  3. Look for similar patterns in codebase
  4. Implement following existing conventions
  5. Write tests for new functionality
  6. Run tests after changes
  7. TaskUpdate(taskId, status="completed")
  8. Check TaskList for next unblocked task
```

Run tests after completing each phase's worth of tasks (not after every single task). If the project has no test setup, use the checks the spec's Test Plan names (for example a small Node script for pure logic, or loading the page in a browser) rather than adding a test framework the spec did not ask for.

#### Lean Team Execution

Needs agent teams (TeamCreate). Without them, use **Lean/Full without agent teams** below.

For work with 2 parallel streams.

```
1. TeamCreate(team_name="dev-{feature-name}")

2. Spawn teammates:
   Task(
     subagent_type="general-purpose",
     team_name="dev-{feature-name}",
     name="builder-1",
     prompt="You are a builder on the dev-{feature-name} team.
       Read the team config at ~/.claude/teams/dev-{feature-name}/config.json.
       Check TaskList for tasks assigned to you.
       Execute each task: read the description, implement it, write tests, mark completed.
       After completing a task, check TaskList for your next assigned task.
       When all your tasks are done, notify the team lead.
       Follow existing codebase patterns. Run tests after each task."
   )

3. Lead takes Stream 1 tasks (foundational + sequential work)
   - Execute foundational tasks first (models, schemas, types)
   - These unblock builder tasks

4. Assign Stream 2 tasks to builder-1:
   TaskUpdate(taskId, owner="builder-1")

5. Lead monitors progress:
   - Check TaskList periodically
   - Unblock dependent tasks as prerequisites complete
   - Handle any blockers builders report

6. When all tasks complete, proceed to Phase 5
```

#### Full Team Execution

For complex work with 3+ parallel streams. Needs agent teams (TeamCreate); without them, use **Lean/Full without agent teams** below.

```
1. TeamCreate(team_name="dev-{feature-name}")

2. Spawn teammates:
   # Builders for parallel streams
   Task(
     subagent_type="general-purpose",
     team_name="dev-{feature-name}",
     name="builder-1",
     prompt="You are builder-1 on the dev-{feature-name} team.
       Read the team config at ~/.claude/teams/dev-{feature-name}/config.json.
       Check TaskList for tasks assigned to you.
       Execute each task: read the description, implement it, write tests, mark completed.
       After completing a task, check TaskList for your next assigned task.
       When all your tasks are done, notify the team lead.
       Follow existing codebase patterns. Run tests after each task."
   )

   Task(
     subagent_type="general-purpose",
     team_name="dev-{feature-name}",
     name="builder-2",
     prompt="You are builder-2 on the dev-{feature-name} team.
       Read the team config at ~/.claude/teams/dev-{feature-name}/config.json.
       Check TaskList for tasks assigned to you.
       Execute each task: read the description, implement it, write tests, mark completed.
       After completing a task, check TaskList for your next assigned task.
       When all your tasks are done, notify the team lead.
       Follow existing codebase patterns. Run tests after each task."
   )

   # Optional: Reviewer for complex/risky changes
   Task(
     subagent_type="general-purpose",
     team_name="dev-{feature-name}",
     name="reviewer",
     prompt="You are the reviewer on the dev-{feature-name} team.
       Read the team config at ~/.claude/teams/dev-{feature-name}/config.json.
       Your job is to review completed work streams for quality issues.
       Check TaskList for review tasks assigned to you.
       For each review: read the changed files, check for bugs, verify tests pass,
       ensure patterns are followed. Report findings to the team lead.
       Do NOT make changes yourself — only report issues."
   )

3. Lead takes foundational tasks:
   - Execute Phase 1 foundation work (models, schemas, shared types)
   - These unblock all builder tasks

4. Assign parallel stream tasks:
   - Stream 2 tasks -> builder-1
   - Stream 3 tasks -> builder-2
   - Additional streams distributed round-robin

5. Lead orchestrates:
   - Check TaskList periodically for progress
   - Unblock dependent tasks as prerequisites complete
   - Assign review tasks to reviewer as streams complete
   - Handle blockers reported by builders
   - Re-assign tasks if a builder is stuck

6. When all implementation tasks complete:
   - Assign final integration review to reviewer (if present)
   - Address any reviewer findings
   - Proceed to Phase 5
```

#### Lean/Full without agent teams

When TeamCreate is not available (agent teams off, or a host that does not offer them), keep the tier's parallelism with plain subagents:

```
1. Lead does the foundation tasks first, alone.
2. For each remaining stream, in ONE message (so they run in parallel):
   Task(
     subagent_type="general-purpose",
     prompt="You are a builder for {feature-name}. Your tasks: {task list with descriptions}.
       You own only these files: {paths}. Do not edit any other file; other builders are working beside you.
       Follow existing codebase patterns. Run the relevant checks after each task.
       Reply with: files changed, checks run and their results, anything left undone."
   )
3. Lead marks each builder's tasks completed from its reply, then integrates and runs the full checks.
4. For Full tier, optionally run one reviewer subagent on the integrated result (see Phase 5).
```

Streams must have disjoint file ownership. If two streams need the same file, merge them into one stream or run them in sequence. If no subagent tool (`Task`, or `Agent` in newer Claude Code) is available either, run the tasks Solo.

#### Communication Discipline (All Tiers)

- **No ack messages** — don't send "got it" or "working on it"
- **No status broadcasts** — use TaskList to check progress
- **Messages only for**: blockers, decisions needed, questions, completion summaries
- **Lead checks TaskList** for progress, not message polling

#### Figma Design Sync (if applicable)

For UI work with Figma designs (any tier):

- Implement components following design specs
- With the compound-engineering 2.x `compound-engineering:design:figma-design-sync` agent and a connected Figma MCP server, compare iteratively; otherwise compare against `specs/{feature-name}/design/specification.md` (and the Figma MCP tools, if connected) yourself
- Fix visual differences identified
- Repeat until implementation matches design

---

### Phase 5: Quality Check

1. **Run Full Test Suite**

   Run the project's test command (detect from package.json, Makefile, or CLAUDE.md):
   ```bash
   # Examples - use whatever the project uses
   bun test
   npm test
   bin/rails test
   pytest
   cargo test
   go test ./...
   ```

2. **Run Linting** (if configured)

   ```bash
   # Use whatever the project uses
   npm run lint
   bundle exec rubocop
   ruff check .
   ```

3. **Consider Reviewer Agents** (Optional)

   Use for complex, risky, or large changes. Run in parallel with the subagent tool. The names below are compound-engineering 2.x agent types; without them, treat each name as a role and give a `general-purpose` agent a one-line role prompt like the examples further down:

   - **code-simplicity-reviewer**: Check for unnecessary complexity
   - **performance-oracle**: Check for performance issues
   - **security-sentinel**: Scan for security vulnerabilities

   Language/framework-specific reviewers:
   - **kieran-rails-reviewer**: Rails conventions (Ruby projects)
   - **kieran-python-reviewer**: Python conventions
   - **kieran-typescript-reviewer**: TypeScript conventions
   - **dhh-rails-reviewer**: DHH-style Rails review

   ```
   # compound-engineering 2.x agent types present
   Task(subagent_type="compound-engineering:review:code-simplicity-reviewer", prompt="Review changes for simplicity")
   Task(subagent_type="compound-engineering:review:security-sentinel", prompt="Scan for security vulnerabilities")

   # Otherwise (default): the same roles as general-purpose agents
   Task(subagent_type="general-purpose", prompt="You are a code simplicity reviewer. Review the diff against {default branch} for unnecessary complexity, dead code and YAGNI. Report findings with file:line; do not edit.")
   Task(subagent_type="general-purpose", prompt="You are a security reviewer. Review the diff against {default branch} for injection, unsafe input handling, secrets and auth flaws. Report findings with file:line; do not edit.")
   ```

   For a whole-branch review with compound-engineering you can also run `Skill(skill="compound-engineering:ce-code-review")` (2.x: `compound-engineering:ce:review`).

   Present findings to user and address critical issues.

4. **Commit**

   Commit the work on the feature branch with a conventional commit message (for example `feat(dodge-game): add canvas dodge game`). Include the `specs/{feature-name}/` files. Do not push; tell the user the branch name.

5. **Final Validation Checklist**
   - [ ] All tasks marked completed (verify via TaskList)
   - [ ] All tests pass
   - [ ] Linting passes (if configured)
   - [ ] Code follows existing patterns
   - [ ] Figma designs match implementation (if applicable)
   - [ ] No console errors or warnings

---

### Phase 6: Shutdown & Compound

#### Team Shutdown (Lean/Full tiers with agent teams only)

```
1. Verify all tasks completed via TaskList
2. Run full test suite one final time
3. Send shutdown_request to each teammate:
   SendMessage(type="shutdown_request", recipient="builder-1", content="All tasks complete, shutting down")
   SendMessage(type="shutdown_request", recipient="builder-2", content="All tasks complete, shutting down")
   SendMessage(type="shutdown_request", recipient="reviewer", content="All tasks complete, shutting down")
4. Wait for shutdown_response (approve: true) from each
5. TeamDelete to clean up team resources
```

#### Compound Learnings

This step is **opt-in**: nothing is written to `specs/knowledge/` unless the user says yes. In non-interactive mode, skip it and end with the summary (what shipped, checks run, assumptions and decisions taken).

**Prompt the user:**

```
AskUserQuestion:
  question: "Quality checks complete. Document learnings for the team? (Strongly recommended - each documented solution compounds your team's knowledge)"
  options:
    1. "Yes, compound now (Recommended)" - Document learnings inline
    2. "No, skip for now" - Can run compound later
```

##### If "Yes" — Run Compound Inline

**Purpose:** Captures problem solutions while context is fresh, creating structured documentation for searchability and future reference. Uses parallel subagents for maximum efficiency.

**Why "compound"?** Each documented solution compounds your team's knowledge. The first time you solve a problem takes research. Document it, and the next occurrence takes minutes. Knowledge compounds.

**Execution: Parallel Subagents**

Launch these as `general-purpose` subagents IN PARALLEL (they are roles, not installed agent types). For a small change, one agent doing all six roles in order is enough:

**1. Context Analyzer**
   - Extracts conversation history
   - Identifies problem type, component, symptoms
   - Returns: YAML frontmatter skeleton

**2. Solution Extractor**
   - Analyzes all investigation steps
   - Identifies root cause
   - Extracts working solution with code examples
   - Returns: Solution content block

**3. Related Docs Finder**
   - Searches `specs/knowledge/` for related documentation
   - Identifies cross-references and links
   - Finds related GitHub issues
   - Returns: Links and relationships

**4. Prevention Strategist**
   - Develops prevention strategies
   - Creates best practices guidance
   - Generates test cases if applicable
   - Returns: Prevention/testing content

**5. Category Classifier**
   - Determines optimal `specs/knowledge/` category
   - Validates category against schema
   - Suggests filename based on slug
   - Returns: Final path and filename

**6. Documentation Writer**
   - Assembles complete markdown file
   - Validates YAML frontmatter
   - Formats content for readability
   - Creates the file in correct location

**7. Optional: Specialized Agent Invocation** (Post-Documentation)
   Based on problem type detected, invoke applicable reviewers (compound-engineering 2.x agent types if listed, otherwise `general-purpose` agents with the matching role):
   - **performance_issue** -> `performance-oracle`
   - **security_issue** -> `security-sentinel`
   - **database_issue** -> `data-integrity-guardian`
   - Any code-heavy issue -> `code-simplicity-reviewer`

**What It Captures**

- **Problem symptom**: Exact error messages, observable behavior
- **Investigation steps tried**: What didn't work and why
- **Root cause analysis**: Technical explanation
- **Working solution**: Step-by-step fix with code examples
- **Prevention strategies**: How to avoid in future
- **Cross-references**: Links to related issues and docs

**What It Creates**

Organized documentation at `specs/knowledge/[category]/[filename].md`

Categories auto-detected from problem:
- build-errors/
- test-failures/
- runtime-errors/
- performance-issues/
- database-issues/
- security-issues/
- ui-bugs/
- integration-issues/
- logic-errors/

**Success Output**

```
Parallel documentation generation complete

Primary Subagent Results:
  Context Analyzer: Identified {type} in {component}
  Solution Extractor: Extracted {n} code fixes
  Related Docs Finder: Found {n} related issues
  Prevention Strategist: Generated test cases
  Category Classifier: specs/knowledge/{category}/
  Documentation Writer: Created complete markdown

File created:
- specs/knowledge/{category}/{filename}.md

This documentation will be searchable for future reference when similar
issues occur.

What's next?
1. Continue workflow (recommended)
2. Link related documentation
3. Update other references
4. View documentation
5. Other
```

##### If "No" — Skip for Now

Inform user:
> "No problem. You can document learnings later when you have more context."

---

## Key Principles

### Start Fast, Execute Faster

- Get clarification once at the start, then execute
- Don't wait for perfect understanding — ask questions and move
- The goal is to **finish the feature**, not create perfect process

### Adapt Team Size to Work

- Solo for simple sequential work — teams add overhead with no benefit
- Lean for two parallel streams — just enough coordination
- Full for complex multi-stream work — maximize parallelism
- **Never force a team when the work is sequential**

### The Plan is Your Guide

- Work documents should reference similar code and patterns
- Load those references and follow them
- Don't reinvent — match what exists

### Test As You Go

- Run tests after each phase, not at the end
- Fix failures immediately
- Continuous testing prevents big surprises

### Quality is Built In

- Follow existing patterns
- Write tests for new code
- Run linting before pushing
- Use reviewer agents for complex/risky changes only

### Ship Complete Features

- Mark all tasks completed before moving on
- Don't leave features 80% done
- A finished feature that ships beats a perfect feature that doesn't

## Quality Checklist

Before completing, verify:

- [ ] All clarifying questions asked and answered
- [ ] All tasks marked completed (TaskList shows all completed)
- [ ] Tests pass
- [ ] Linting passes (if configured)
- [ ] Code follows existing patterns
- [ ] Figma designs match implementation (if applicable)
- [ ] Commit messages follow conventional format
- [ ] Team shut down cleanly (if used)

## When to Use Reviewer Agents

**Don't use by default.** Use reviewer agents only when:

- Large refactor affecting many files (10+)
- Security-sensitive changes (authentication, permissions, data access)
- Performance-critical code paths
- Complex algorithms or business logic
- User explicitly requests thorough review

For most features: tests + linting + following patterns is sufficient.

## Common Pitfalls to Avoid

- **Over-teaming simple work** — Solo is fine for sequential tasks
- **Analysis paralysis** — Don't overthink, read the plan and execute
- **Skipping clarifying questions** — Ask now, not after building wrong thing
- **Ignoring plan references** — The plan has links for a reason
- **Testing at the end** — Test continuously or suffer later
- **80% done syndrome** — Finish the feature, don't move on early
- **Over-reviewing simple changes** — Save reviewer agents for complex work
- **Chatty team comms** — No ack messages, use TaskList for status
- **Skipping compound** — Document learnings to make future work easier

## The Compounding Philosophy

This creates a compounding knowledge system:

1. First time you solve a problem -> Research (30 min)
2. Document the solution -> specs/knowledge/{category}/{name}.md (5 min)
3. Next time similar issue occurs -> Quick lookup (2 min)
4. Knowledge compounds -> Team gets smarter

**Each unit of engineering work should make subsequent units of work easier — not harder.**
