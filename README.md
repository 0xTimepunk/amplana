# Archon

General-purpose spec-driven development plugin for Claude Code and ChatGPT Codex. Create specs with AI interviews, execute them with adaptive agent teams.

## What It Does

**Claude: `/dev:spec`** — Plan features (80% of effort)
- Interactive AI interview to gather requirements
- Parallel research agents analyze your codebase, best practices, and framework docs
- Generates structured spec for stakeholder approval

**Claude: `/dev:work`** — Execute features (20% of effort)
- Reads your approved spec and assesses complexity
- Selects team size: Solo, Lean (2 streams), or Full (3+ streams)
- Creates tasks, spawns agent teammates, and orchestrates parallel execution
- Compounds learnings for future reference

**Claude: `/dev:security-review`** — Adversarial security review of Solidity code
- Builds a context map first (Trail of Bits `audit-context-building`, `entry-point-analyzer`)
- Hunts with pashov's 12 `solidity-auditor` attacker personas, then a blind-spot pass over functions no persona named
- Judges and deduplicates by root cause, then tries to refute every candidate (Trail of Bits `fp-check`); only a quoted guard refutes
- Past audits and git history are off by default (`--history` turns them on), so its findings can be measured

**Codex: `archon:spec` skill** — Plan features with the same interview and research flow

**Codex: `archon:work` skill** — Execute specs with the same adaptive tiering, including multi-agent work for Lean and Full tiers

## Installation

### Claude Code

```bash
git clone <repo-url> ~/work/archon
cd ~/work/archon
chmod +x install.sh
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

This adds a shell alias so Claude Code loads the plugin automatically.

Or, in the Claude desktop app or any Claude Code session, add the repo as a plugin marketplace and install `dev`:

```text
/plugin marketplace add 0xTimepunk/archon
/plugin install dev@archon
```

`/dev:security-review` also needs pashov's `solidity-auditor` (copy `solidity-auditor/` from `github.com/pashov/skills` into `~/.claude/skills/`) and Trail of Bits' `audit-context-building`, `entry-point-analyzer` and `fp-check` (`/plugin marketplace add trailofbits/skills`).

### ChatGPT Codex

This repo now includes a Codex plugin at `plugins/archon-codex` and a local marketplace entry at `.agents/plugins/marketplace.json`.

To install it into your Codex home as a local plugin:

```bash
chmod +x install-codex.sh uninstall-codex.sh
./install-codex.sh
```

In Codex, install or enable the local plugin from this repository's marketplace, then invoke it by asking for the Archon workflows explicitly, for example:

```text
Use Archon to create a spec for user authentication.
Use Archon to execute specs/user-authentication/technical-spec.md with agent teams.
```

To uninstall the home-local Codex plugin:

```bash
./uninstall-codex.sh
```

## Usage

### Create a Spec

#### Claude Code

```bash
claude
/dev:spec user-authentication
```

With optional integrations:

```bash
# With Linear issue context
/dev:spec user-auth --linear LINEAR-123

# With Figma design reference
/dev:spec hero-section --figma https://figma.com/file/abc123/design?node-id=45:678
```

#### ChatGPT Codex

```text
Use Archon to create a spec for user authentication.
Use Archon to create a spec for user-auth --linear LINEAR-123.
Use Archon to create a spec for hero-section with this Figma URL: https://figma.com/file/abc123/design?node-id=45:678
```

### Execute a Spec

#### Claude Code

```bash
/dev:work specs/user-authentication/technical-spec.md
```

#### ChatGPT Codex

```text
Use Archon to execute specs/user-authentication/technical-spec.md.
Use Archon work mode with agent teams for specs/user-authentication/technical-spec.md.
```

The work command will:
1. Read and clarify the spec
2. Assess complexity and select team tier
3. Decompose into tasks
4. Execute (solo or with agent teammates)
5. Run quality checks
6. Compound learnings

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
| **Full** | Score 51+, 3+ parallel streams | Lead + 2-4 Builders + Reviewer |

Scoring factors: phase count, file count, package scope, and parallelizable streams.

You can always override the suggested tier.

## Platform Mapping

| Capability | Claude Code | ChatGPT Codex |
|------------|-------------|---------------|
| Spec entrypoint | `/dev:spec` command | `archon:spec` skill |
| Work entrypoint | `/dev:work` command | `archon:work` skill |
| Interview UX | AskUserQuestion | `request_user_input` |
| Agent teams | Task/Team tools | `spawn_agent` + coordination file |
| Plugin packaging | `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` + marketplace |

## Integrations

| Integration | Setup | Used By |
|-------------|-------|---------|
| **Linear** | Auth via Linear MCP at `https://mcp.linear.app/mcp` | Claude `/dev:spec`, Codex `archon:spec` |
| **Figma** | Requires Dev/Full seat, enable MCP in Figma | Claude `/dev:spec`, Codex `archon:spec` |
| **compound-engineering / built-in skills** | Available in the agent environment | Both workflows |

All integrations are optional. Commands gracefully degrade without them.

## Uninstall

```bash
cd ~/work/archon
./uninstall.sh
source ~/.zshrc
```

## How It Works

### The Philosophy

**80% planning, 20% execution.** Invest in understanding the problem before writing code. Each solved problem is documented, compounding your team's knowledge over time.

### Spec Creation Flow

```
Interview → Research (parallel agents) → SpecFlow Analysis → Technical Spec → Stakeholder Spec
```

### Work Execution Flow

```
Read Spec → Assess Complexity → Select Tier → Decompose Tasks → Execute → Quality Check → Compound
```

### Knowledge Compounding

After completing work, the compound phase captures:
- Problem symptoms and root causes
- Working solutions with code examples
- Prevention strategies
- Cross-references to related issues

Stored in `/specs/knowledge/` for searchable future reference.
