# Codex compatibility

AgenticOS is authored in Claude Code's `.claude/` layout. `install.sh --codex` maps the portable parts onto Codex's supported user or project surfaces instead of copying Claude configuration wholesale.

The Codex shell path currently targets macOS/Linux (or another Bash environment). `install.ps1` remains Claude-only.

## Surface mapping

| AgenticOS source | Codex destination | Status |
|---|---|---|
| `.claude/skills/*` | `~/.agents/skills/*` or `.agents/skills/*` | Installed directly; each skill retains Codex's required `name` and `description` fields plus AgenticOS routing metadata |
| `.claude/agents/*.md` | `~/.codex/agents/*.toml` or `.codex/agents/*.toml` | Converted during install to `name`, `description`, `developer_instructions`, and a conservative sandbox mode |
| SessionStart session-state hook | `~/.codex/hooks.json` or `.codex/hooks.json` | Installed; plain stdout is documented as additional Codex developer context |
| PreCompact checkpoint hook | Same hook file | Installed; the event and matcher are supported by Codex |
| `.claude/commands/*.md` | None | Not installed; [Codex custom prompts are deprecated in favor of skills](https://learn.chatgpt.com/docs/custom-prompts) |
| `.claude/memory/` hooks | None | Not installed; [Codex provides a native local memory system](https://learn.chatgpt.com/docs/customization/memories) |
| `CLAUDE.md` / `.claude/rules/` | None | Not copied; durable Codex guidance belongs in [`AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md) |

Codex's documented skill locations are `.agents/skills` for repository scope and `~/.agents/skills` for user scope. Custom agents are standalone TOML files under `.codex/agents` or `~/.codex/agents`. Project hooks and config load only after the repository is trusted. See the official [skills](https://learn.chatgpt.com/docs/build-skills), [subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents), and [hooks](https://learn.chatgpt.com/docs/hooks) documentation.

## Intentional limits

- Claude agent `tools:` allowlists do not have a one-to-one Codex custom-agent field. The converter maps roles with `Edit` or `Write` to `workspace-write`; all others become `read-only`. Permission and approval behavior otherwise inherits from the parent Codex task.
- Agent bodies can still mention Claude capability names. The converter adds an instruction to use the equivalent Codex-native tool or skill discovery mechanism.
- The Codex hook set is deliberately smaller than Claude's awareness harness. It re-injects `SESSION-STATE.md` at startup, resume, clear, and post-compaction, and records a pre-compaction checkpoint. Per-turn digest, shell-policy, survey, and custom memory hooks remain Claude-only until they have Codex-specific live-fire evidence.
- Merging into an existing Codex `hooks.json` requires `jq`; without it, the installer preserves that file and warns instead of replacing user configuration.
- Codex native memory is separate from AgenticOS `.claude/memory/`; the installer neither enables it nor edits the user's Codex memory settings.

## Distribution note

OpenAI recommends plugins for distributing bundles of multiple skills. The shell installer remains useful for this repository because it also performs pinned-asset verification, converts role definitions, supports project-local installation, and merges hooks. A future Codex plugin could remove the conversion step and provide a marketplace-native install path.
