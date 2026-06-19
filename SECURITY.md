# Security Policy

## Why this file exists

Most of this library is **inert**: skills, agents, commands, and rules are Markdown — instructions a *model* reads. The worst case for a bad instruction is bad advice, with a human and the model in the loop.

**Hooks are different. They are executable code that the library distributes and that runs automatically on consumer machines.** `install.sh` runs `install_dir "hooks"` and `chmod +x` on `.claude/hooks/*.sh`; `install.ps1` does the same. Once registered in a `settings.json`, a hook fires on routine events (e.g. `PreToolUse` on *every* tool call, `SessionStart` on *every* session), runs with the user's full shell and permissions, and has **no sandbox**. This is the library's one piece of distributed executable code, so it is its primary security surface.

## Threat model — the supply chain

The risk travels through the **distribution channel**. People install this library on trust; they do not audit every line of every shipped hook. That means:

- A **bug** in a shipped hook runs on everyone who installed it — not just the author.
- An **upstream compromise** (a malicious PR merged, or a maintainer account/CI compromised) propagates arbitrary code to every downstream installer automatically. One poisoned commit → code execution on N machines. This is the classic supply-chain attack shape (`event-stream`, `xz`).

The only barrier in front of a freshly pulled hook is Claude Code's **workspace-trust gate** (the repo must be trusted before hooks run). That is a single one-time gate, **not** a sandbox.

### What ships today
- `install.sh` / `install.ps1` ship `.claude/hooks/*.sh` and mark them executable.
- The repo's own `.claude/settings.json` (dev permissions + autoMode config) is **not** shipped. So a shipped hook script is dormant on a consumer until it is registered in a `settings.json` — but the executable code is already on disk.
- Current shipped hook: `.claude/hooks/block-bad-bash.sh` — a `jq`-gated ergonomics nudge, explicitly self-labeled *not a security control*. It is benign and minimal by design.

## Policy for shipped hooks

Every hook that ships to consumers MUST:

1. **Live as a vendored `*.sh` shell script** under `.claude/hooks/` (other interpreters evade the shell-idiom denylist and are rejected on file type). Hook `command` entries in any shipped `settings.json` must *invoke* such a script — never carry inline shell.
2. **Make no runtime network call** — no `curl`/`wget`/`nc`/`scp`/`sftp`, no `/dev/tcp`, no pipe-to-shell (`… | bash`). Nothing is fetched or executed from the network at runtime.
3. **Contain no dynamic/obfuscated execution** — no `eval`, no `base64 -d | sh`, no `source <(…)`, no inline `python -c` / `node -e`.
4. **Touch no credentials, persistence, or privilege** — no `~/.ssh`/`~/.aws`/`~/.gnupg`/`id_rsa`/`.npmrc` access, no `crontab`/`launchctl`/`systemctl`/LaunchAgents, no `sudo`, no `chmod 777`, no recursive deletes of `$HOME`/`/`.
5. **Be minimal and auditable** — small enough to read in full in one sitting. Do not chase completeness pattern-by-pattern (see the note in `block-bad-bash.sh`).
6. **Pass human security review before merge** — a maintainer or `security-reviewer` pass is required for any new or changed shipped hook (the V2_ROADMAP "ship + ratchet" gate).

## Enforcement — and its limits

`scripts/validate.sh` **Invariant 8 (`hook-safety`)** enforces rules 1–4 deterministically (Tier 0) and runs in CI on every PR and push (`.github/workflows/validate.yml`). `scripts/validate-test.sh` proves the invariant trips on a malicious hook and stays clean on the legitimate one.

**This is a tripwire, not a sandbox.** A static scan denies the *obvious* exfil / destructive / obfuscation patterns; it cannot *prove* a hook is safe, and a determined attacker can evade a regex. It is one layer. The real defenses are layered: minimal auditable scripts (rule 5) + the no-runtime-fetch policy (rule 2) + human review (rule 6) + the workspace-trust gate. Do not treat a green Invariant 8 as proof of safety.

## Reporting a vulnerability

Report privately via a **GitHub Security Advisory** on the repository (`LazyIsEfficient/agentic-os`) rather than a public issue. Please include the affected file(s), the execution path, and a proof-of-concept if you have one. Do not open a public issue for an unfixed vulnerability.
