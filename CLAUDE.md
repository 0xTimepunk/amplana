# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Repository Overview

**Archon** is a general-purpose spec-driven development plugin repository for Claude Code and ChatGPT Codex. It provides:

1. **`/dev:spec`** — AI interview + parallel research agents to create feature specifications
2. **`/dev:work`** — Adaptive agent teams that execute specs (team size scales with complexity)
3. **`dev:specifier`** — Auto-triggered Claude skill for spec creation
4. **`archon:spec` / `archon:work`** — Codex-native skills for the same planning and execution workflows

This is a **plugin repository**, not application code. It defines commands, skills, and workflows that Claude Code and ChatGPT Codex use to help engineers plan and build features.

---

## Repository Structure

```
archon/
├── plugins/dev/                     # Claude Code plugin
│   ├── .claude-plugin/
│   │   └── plugin.json              # Plugin metadata (name: dev, v1.1.0)
│   ├── commands/                    # User-invocable slash commands
│   │   ├── spec.md                  # /dev:spec command
│   │   ├── work.md                  # /dev:work command
│   │   └── security-review.md       # /dev:security-review command
│   └── skills/                      # Auto-triggered skills
│       └── specifier/
│           └── SKILL.md             # Specifier skill
├── plugins/archon-codex/            # Codex plugin
│   ├── .codex-plugin/
│   │   └── plugin.json              # Codex plugin manifest
│   ├── .mcp.json                    # Optional MCP server config
│   └── skills/
│       ├── spec/
│       │   └── SKILL.md             # Codex spec workflow
│       └── work/
│           └── SKILL.md             # Codex adaptive work workflow
├── .agents/plugins/marketplace.json # Repo-local Codex marketplace entry
├── .claude-plugin/marketplace.json  # Claude Code marketplace entry (dev@archon)
│
├── CLAUDE.md                        # This file
├── README.md                        # User-facing docs
├── install.sh                       # Plugin installation
├── uninstall.sh                     # Plugin removal
└── .gitignore
```

---

## The Four-Step Workflow

All significant work follows this pattern:

```
Plan (80%) → Work (20%) → Assess → Compound
```

### 1. Plan (80% of effort)
- Use `/dev:spec {feature-name}` command
- Complete AI interview with AskUserQuestion
- Get stakeholder approval before implementation

### 2. Work (20% of effort)
- `/dev:work` executes the approved plan
- Team size adapts to complexity (Solo / Lean / Full)
- Tasks tracked via TaskCreate/TaskList

### 3. Assess
- Reviewer agents run for complex changes
- Human reviews findings and signs off

### 4. Compound
- Capture learnings in `/specs/knowledge/`
- Each documented solution compounds team knowledge

---

## Working with This Repository

### For Plugin Development

Claude commands and skills live in `/plugins/dev/`. Codex plugin assets live in `/plugins/archon-codex/`. When creating or updating:

1. **Claude Commands**: `/plugins/dev/commands/{name}.md` with YAML frontmatter
2. **Skills**: `/plugins/dev/skills/{name}/SKILL.md` or `/plugins/archon-codex/skills/{name}/SKILL.md`
3. Keep workflow files focused and single-responsibility
4. Test the relevant host workflow before committing
5. Update the relevant manifest version when behavior changes materially

### Command Frontmatter Format

```yaml
---
name: dev:{command-name}
description: Short description of the command
argument-hint: "[arguments description]"
---
```

### Skill Frontmatter Format

```yaml
---
name: dev:{skill-name}
description: When this skill should auto-trigger
---
```

---

## Compound Engineering Agents

The following agents are available via Claude Code's Task tool (no bundling required):

**Research agents** (used by `/dev:spec`):
- `compound-engineering:research:repo-research-analyst`
- `compound-engineering:research:best-practices-researcher`
- `compound-engineering:research:framework-docs-researcher`
- `compound-engineering:workflow:spec-flow-analyzer`

**Review agents** (used by `/dev:work`):
- `compound-engineering:review:code-simplicity-reviewer`
- `compound-engineering:review:security-sentinel`
- `compound-engineering:review:performance-oracle`
- `compound-engineering:review:kieran-rails-reviewer`
- `compound-engineering:review:kieran-python-reviewer`
- `compound-engineering:review:kieran-typescript-reviewer`

**Design agents** (used by both):
- `compound-engineering:design:figma-design-sync`
- `compound-engineering:design:design-implementation-reviewer`

---

## MCP Servers

The plugin configures two optional MCP servers:

| Server | Purpose | Required? |
|--------|---------|-----------|
| Linear | Read/write Linear issues for `--linear` flag | Optional |
| Figma | Extract design specs for `--figma` flag | Optional |

Both gracefully degrade — commands work without them, just skip the relevant features.
