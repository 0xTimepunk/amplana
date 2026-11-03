# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Repository Overview

**Amplana** is a general-purpose spec-driven development plugin repository for Claude Code and ChatGPT Codex. It provides:

1. **`/dev:brief`** — turns requirements the user has already decided into an agent-ready spec: focused questions, parallel research agents, build plan (`/dev:spec` stays as a deprecated alias for one release)
2. **`/dev:work`** — Adaptive agent teams that execute specs (team size scales with complexity)
3. **`dev:specifier`** — Auto-triggered Claude skill for spec creation
4. **`amplana:brief` / `amplana:work`** — Codex-native skills for the same planning and execution workflows (`amplana:spec` is a deprecated alias)

This is a **plugin repository**, not application code. It defines commands, skills, and workflows that Claude Code and ChatGPT Codex use to help engineers plan and build features.

---

## Repository Structure

```
amplana/
├── .claude-plugin/marketplace.json  # Claude Code marketplace (name: amplana) listing plugins/dev
├── plugins/dev/                     # Claude Code plugin
│   ├── .claude-plugin/
│   │   └── plugin.json              # Plugin metadata (name: dev, v2.0.0)
│   ├── commands/                    # User-invocable slash commands
│   │   ├── brief.md                 # /dev:brief command
│   │   ├── spec.md                  # /dev:spec, deprecated alias of /dev:brief
│   │   ├── work.md                  # /dev:work command
│   │   └── security-review.md       # /dev:security-review command
│   └── skills/                      # Auto-triggered skills
│       └── specifier/
│           └── SKILL.md             # Specifier skill
├── plugins/amplana-codex/            # Codex plugin
│   ├── .codex-plugin/
│   │   └── plugin.json              # Codex plugin manifest
│   └── skills/
│       ├── brief/
│       │   └── SKILL.md             # Codex brief workflow (amplana:brief)
│       ├── spec/
│       │   └── SKILL.md             # amplana:spec, deprecated alias
│       └── work/
│           └── SKILL.md             # Codex adaptive work workflow
├── .agents/plugins/marketplace.json # Repo-local Codex marketplace entry
├── .claude-plugin/marketplace.json  # Claude Code marketplace entry (dev@amplana)
│
├── CLAUDE.md                        # This file
├── README.md                        # User-facing docs
├── install.sh                       # Claude install via `claude plugin` (no shell rc edits)
├── uninstall.sh                     # Claude plugin removal
├── install-codex.sh                 # Codex home-local install
├── uninstall-codex.sh               # Codex removal
├── LICENSE
└── .gitignore
```

---

## The Four-Step Workflow

All significant work follows this pattern:

```
Plan (80%) → Work (20%) → Assess → Compound
```

### 1. Plan (80% of effort)
- Use `/dev:brief {feature-name} "{decided requirements}"` command
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
- Optionally capture learnings in `specs/knowledge/` (only when the user says yes)
- Each documented solution compounds team knowledge

---

## Working with This Repository

### For Plugin Development

Claude commands and skills live in `plugins/dev/`. Codex plugin assets live in `plugins/amplana-codex/`. When creating or updating:

1. **Claude Commands**: `plugins/dev/commands/{name}.md` with YAML frontmatter
2. **Skills**: `plugins/dev/skills/{name}/SKILL.md` or `plugins/amplana-codex/skills/{name}/SKILL.md`
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

## Compound Engineering (optional)

Amplana must work without any other plugin. Every place that uses compound-engineering has a `general-purpose` fallback with a role prompt, written next to it in the command. Keep it that way when editing.

- **compound-engineering 2.x** registers agent types such as `compound-engineering:research:repo-research-analyst` and `compound-engineering:review:security-sentinel`. The commands use them when they appear in the agent type list.
- **compound-engineering 3.x** (current) registers no agent types, only skills. The commands use these skills when installed, by name: `ce-doc-review` (2.x `document-review`), `ce-code-review` (2.x `ce:review`), `ce-worktree` (2.x `git-worktree`).

Before referencing a new compound-engineering name, check that it exists in the current release.

---

## MCP Servers

Neither plugin configures MCP servers: users add Linear and Figma themselves (see README, Optional integrations: `claude mcp add` for Claude, `~/.codex/config.toml` plus `codex mcp login` for Codex), so sessions don't show them as needing auth. Don't add `mcpServers` back to either manifest.

| Server | Purpose | Required? |
|--------|---------|-----------|
| Linear | Read the issue for `--linear`, then update its Acceptance Criteria and Technical Notes | Optional |
| Figma | Extract design specs for `--figma` flag | Optional |

Commands detect the tools by name (`*linear*get_issue`, and so on) and skip the feature with a warning when they are missing.

---

## Testing a change

```bash
claude plugin validate .            # marketplace manifest
claude plugin validate plugins/dev  # plugin manifest, commands, skills
claude --plugin-dir plugins/dev     # one-off session with the working copy
```

Then run `/dev:brief` and `/dev:work` on a tiny project (for example a single-file HTML game), with and without compound-engineering installed, and headless with `claude -p` to exercise the no-interview path.
