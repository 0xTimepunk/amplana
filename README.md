# Archon

Spec-driven development plugin for Claude Code and ChatGPT Codex. You decide what to build; Archon turns those decisions into an agent-ready spec, then executes it with adaptive agent teams.

> **Renamed in 1.2.0:** `/dev:spec` is now `/dev:brief` (Codex: `archon:spec` is now `archon:brief`). The old names still work for one release and run the new command. Output files are unchanged.

## What It Does

**Claude: `/dev:brief`** — Brief the builders (80% of effort)
- Starts after the thinking: you bring requirements you have already decided (on the whiteboard, with your peers)
- Pressure-tests them with focused questions about gaps, contradictions and risks (or skips the questions with `--no-interview`)
- Parallel research agents analyze your codebase, best practices, and framework docs
- Writes an agent-ready technical spec and build plan, plus a short spec for stakeholder approval

It does not decide what to build. Open product questions come back to you, or are recorded as open questions in the spec.

**Claude: `/dev:work`** — Execute features (20% of effort)
- Reads your approved spec and assesses complexity
- Selects team size: Solo, Lean (2 streams), or Full (3+ streams)
- Creates tasks, spawns agent teammates, and orchestrates parallel execution
- Optionally documents learnings in `specs/knowledge/` for future reference

**Claude: `/dev:security-review`** — Adversarial security review of Solidity code
- Builds a context map first (Trail of Bits `audit-context-building`, `entry-point-analyzer`)
- Hunts with pashov's 12 `solidity-auditor` attacker personas, then a blind-spot pass over functions no persona named
- Judges and deduplicates by root cause, then tries to refute every candidate (Trail of Bits `fp-check`); only a quoted guard refutes
- Past audits and git history are off by default (`--history` turns them on), so its findings can be measured

**Codex: `archon:brief` skill** — The same brief flow: questions, research, agent-ready spec

**Codex: `archon:work` skill** — Execute specs with the same adaptive tiering, including multi-agent work for Lean and Full tiers

## Installation

### Claude Code

In Claude Code (2.1.275 or later):

```text
/plugin install dev --marketplace 0xTimepunk/archon
```

On older versions, add the marketplace first, then install:

```text
/plugin marketplace add 0xTimepunk/archon
/plugin install dev@archon
```

Then run `/reload-plugins` or restart Claude Code. `/dev:brief`, `/dev:work` and `/dev:security-review` are now available in every project.

**Recommended:** the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin. Archon uses its review, worktree and doc review skills when they are installed:

```text
/plugin install compound-engineering --marketplace EveryInc/compound-engineering-plugin
```

Archon does not need it. Without it, every step still runs, using `general-purpose` agents with role prompts and plain `git worktree`.

#### From a clone

```bash
git clone https://github.com/0xTimepunk/archon.git ~/work/archon
cd ~/work/archon
./install.sh                               # or: ./install.sh --with-compound-engineering
```

`install.sh` registers the clone as a local marketplace and installs `dev@archon` with the `claude plugin` CLI. It does not edit your shell rc files. Edits to the clone take effect on the next Claude Code start.

For a one-off session without installing anything:

```bash
claude --plugin-dir ~/work/archon/plugins/dev
```

**For `/dev:security-review` only:** it also needs pashov's `solidity-auditor` (copy `solidity-auditor/` from `github.com/pashov/skills` into `~/.claude/skills/`) and Trail of Bits' `audit-context-building`, `entry-point-analyzer` and `fp-check` (`/plugin marketplace add trailofbits/skills`).

### ChatGPT Codex

This repo includes a Codex plugin at `plugins/archon-codex` and a local marketplace entry at `.agents/plugins/marketplace.json`.

To install it into your Codex home as a local plugin:

```bash
./install-codex.sh
```

In Codex, install or enable the local plugin from this repository's marketplace, then invoke it by asking for the Archon workflows explicitly, for example:

```text
Use Archon to brief user authentication: email + password, sessions in Postgres, no social login yet.
Use Archon to execute specs/user-authentication/technical-spec.md with agent teams.
```

To uninstall the home-local Codex plugin:

```bash
./uninstall-codex.sh
```

## Usage

### Brief a Feature

#### Claude Code

Pass the feature name and what you have decided. The questions then cover only the gaps and risks:

```text
/dev:brief dodge-game "Single-file HTML canvas game: arrow keys move a square, red blocks fall, score is survival time, R restarts"
```

Skip the questions entirely with `--no-interview`. Archon records the choices it made under Assumptions in `interview-notes.md`. Headless runs (`claude -p`), which cannot ask questions, use this mode automatically:

```bash
claude -p '/dev:brief dodge-game --no-interview "Single-file HTML canvas game: arrow keys move, blocks fall, survival-time score"'
```

With optional integrations (see [Optional integrations](#optional-integrations)):

```text
/dev:brief user-auth --linear LINEAR-123
/dev:brief hero-section --figma https://figma.com/file/abc123/design?node-id=45:678
```

With just a name (`/dev:brief user-authentication`), it asks you for the requirements first.

Specs are written to `specs/{feature-name}/` at the root of the repository you run Claude Code in. The stakeholder spec starts as Draft; approving it is your call.

#### ChatGPT Codex

```text
Use Archon to brief user authentication: email + password, sessions in Postgres, no social login yet.
Use Archon to brief user-auth --linear LINEAR-123.
Use Archon to brief hero-section with this Figma URL: https://figma.com/file/abc123/design?node-id=45:678
```

### Execute a Spec

#### Claude Code

```text
/dev:work specs/user-authentication/technical-spec.md
```

#### ChatGPT Codex

```text
Use Archon to execute specs/user-authentication/technical-spec.md.
Use Archon work mode with agent teams for specs/user-authentication/technical-spec.md.
```

The work command will:
1. Read and clarify the spec
2. Create a feature branch from your default branch (it pulls only when the repo has a remote, and never switches branches over uncommitted changes)
3. Assess complexity and select team tier
4. Decompose into tasks
5. Execute (solo or with agent teammates)
6. Run quality checks
7. Offer to document learnings (Claude only, and only if you say yes)

In a headless run, `/dev:work` asks nothing: it takes the recommended option at each decision point and lists those decisions in its final summary.

### Review Solidity Code

#### Claude Code

```bash
/dev:security-review src/vaults
/dev:security-review src/Vault.sol src/Strategy.sol --passes 3
```

Writes everything to `.security-review/<stamp>/`: the context map, every agent's raw output, the judged candidates, the verifier verdicts and `report.md` (findings, leads, and refuted items with reasons).

## Adaptive Team Strategy

`/dev:work` scores your spec's complexity and picks the right team size:

| Tier | When | Team |
|------|------|------|
| **Solo** | Score 0-25 or 1 parallel stream | Single agent |
| **Lean** | Score 26-50, 2 parallel streams | Lead + 1-2 Builders |
| **Full** | Score 51+, 3+ parallel streams | Lead + 2-4 Builders, plus an optional Reviewer for large or risky changes |

Scoring factors: phase count, file count, package scope, and parallelizable streams.

You can always override the suggested tier.

### Agent teams (Lean and Full)

In Claude Code, Lean and Full use agent teams (TeamCreate, shared task list, teammate messages), an experimental feature that is off by default. To turn it on, add this to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

or start Claude Code with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude`.

Without it, Lean and Full still run in parallel, as plain subagents that each own a separate set of files, and the lead integrates their work. Where subagents are not available either, the work runs Solo. When the task tools are missing (as in some headless runs), tasks are tracked in `specs/{feature-name}/work-tasks.md`.

## Platform Mapping

| Capability | Claude Code | ChatGPT Codex |
|------------|-------------|---------------|
| Brief entrypoint | `/dev:brief` command (`/dev:spec`: deprecated alias) | `archon:brief` skill (`archon:spec`: deprecated alias) |
| Work entrypoint | `/dev:work` command | `archon:work` skill |
| Question UX | AskUserQuestion (skipped with `--no-interview`) | `request_user_input` |
| Agent teams | Team tools with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, else parallel subagents | `spawn_agent` + coordination file |
| Task tracking | TaskCreate/TaskList, else `work-tasks.md` | `specs/{feature-name}/work-tasks.md` |
| Knowledge capture | Optional, writes `specs/knowledge/` | Not included; recommends a follow-up step |
| Plugin packaging | `.claude-plugin/marketplace.json` + `plugins/dev/.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` + marketplace |

## Optional integrations

| Integration | What it adds | Setup |
|-------------|--------------|-------|
| **compound-engineering** | Doc review, code review and worktree skills; 2.x agent types for research and review | `/plugin install compound-engineering --marketplace EveryInc/compound-engineering-plugin` |
| **Linear** | `--linear`: reads the issue, and after the interview **updates** its Acceptance Criteria and Technical Notes sections (with your confirmation) | `claude mcp add --transport http linear https://mcp.linear.app/mcp`, then authenticate with `/mcp` |
| **Figma** | `--figma`: extracts a design spec from a Figma frame | Figma Dev or Full seat; `claude mcp add --transport http figma https://mcp.figma.com/mcp`, then `/mcp` |

Neither plugin configures the Linear or Figma servers for you, so sessions don't show them as needing authentication unless you add them. Without an integration, its flag is skipped with a warning.

**In Codex**, add them to `~/.codex/config.toml`:

```toml
[mcp_servers.linear]
url = "https://mcp.linear.app/mcp"

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
```

then sign in with `codex mcp login linear` (and `codex mcp login figma`). `codex mcp list` shows what is connected.

## Uninstall

In Claude Code:

```text
/plugin uninstall dev@archon
/plugin marketplace remove archon
```

Or from a clone:

```bash
./uninstall.sh
```

`uninstall.sh` also removes the `claude` shell alias that older versions of `install.sh` added.

## How It Works

### The Philosophy

**80% planning, 20% execution.** Invest in understanding the problem before writing code. Each solved problem can be documented, compounding your team's knowledge over time.

### Brief Flow

```
Your requirements → Questions (optional) → Research (parallel agents) → SpecFlow Analysis → Technical Spec → Stakeholder Spec
```

### Work Execution Flow

```
Read Spec → Assess Complexity → Select Tier → Decompose Tasks → Execute → Quality Check → Compound (optional)
```

### Knowledge Compounding

After quality checks, `/dev:work` asks whether to document learnings. If you say yes, it captures:
- Problem symptoms and root causes
- Working solutions with code examples
- Prevention strategies
- Cross-references to related issues

Stored in `specs/knowledge/` at the repository root, for future reference. The Codex `archon:work` skill does not write this folder.

## License

[MIT](LICENSE)
