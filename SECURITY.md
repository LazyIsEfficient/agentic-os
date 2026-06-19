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
- **No `settings.json` ships.** The repo's own `.claude/settings.json` (dev permissions + autoMode config) is **not** shipped, and S5-C deliberately did not add a shipped one. So every shipped hook script is **dormant** on a consumer until they register it in their own `settings.json` — the executable code is on disk but nothing runs it automatically. This is the opt-in posture: the library never auto-executes a hook on a consumer.
- Shipped hooks:
  - `.claude/hooks/block-bad-bash.sh` — a `jq`-gated ergonomics nudge, explicitly self-labeled *not a security control*. Benign and minimal.
  - The awareness-harness hooks — `session-state-inject.sh`, `session-state-digest.sh`, `session-state-checkpoint.sh`, `survey-before-act.sh` — ship **dormant** (S5-C). The `session-state` skill documents the opt-in registration; `SESSION-STATE.md` is governed by rule 7 below.

## Policy for shipped hooks

Every hook that ships to consumers MUST:

1. **Live as a vendored `*.sh` shell script** under `.claude/hooks/` (other interpreters evade the shell-idiom denylist and are rejected on file type). Hook `command` entries in any shipped `settings.json` must *invoke* such a script — never carry inline shell.
2. **Make no runtime network call** — no `curl`/`wget`/`nc`/`scp`/`sftp`, no `/dev/tcp`, no pipe-to-shell (`… | bash`). Nothing is fetched or executed from the network at runtime.
3. **Contain no dynamic/obfuscated execution** — no `eval`, no `base64 -d | sh`, no `source <(…)`, no inline `python -c` / `node -e`.
4. **Touch no credentials, persistence, or privilege** — no `~/.ssh`/`~/.aws`/`~/.gnupg`/`id_rsa`/`.npmrc` access, no `crontab`/`launchctl`/`systemctl`/LaunchAgents, no `sudo`, no `chmod 777`, no recursive deletes of `$HOME`/`/`.
5. **Be minimal and auditable** — small enough to read in full in one sitting. Do not chase completeness pattern-by-pattern (see the note in `block-bad-bash.sh`).
6. **Pass human security review before merge** — a maintainer or `security-reviewer` pass is required for any new or changed shipped hook (the V2_ROADMAP "ship + ratchet" gate).
7. **Treat any file a hook injects into context as untrusted, user-local, never-committed data.** Hooks that read a file and emit it into the model's context (e.g. the `session-state-*` hooks emitting `SESSION-STATE.md`) create a standing prompt-injection channel: whoever can write that file controls text injected every session/turn with no tool call. So such files MUST stay gitignored and per-developer (never committed, never in a shared/multi-writer checkout), and the injected block MUST be framed as DATA, not instructions. `SESSION-STATE.md` is gitignored for exactly this reason.

## Enforcement — and its limits

`scripts/validate.sh` **Invariant 8 (`hook-safety`)** enforces rules 1–4 deterministically (Tier 0) and runs in CI on every PR and push (`.github/workflows/validate.yml`). `scripts/validate-test.sh` proves the invariant trips on a malicious hook and stays clean on the legitimate one.

**This is a tripwire, not a sandbox.** A static scan denies the *obvious* exfil / destructive / obfuscation patterns; it cannot *prove* a hook is safe, and a determined attacker can evade a regex. It is one layer. The real defenses are layered: minimal auditable scripts (rule 5) + the no-runtime-fetch policy (rule 2) + human review (rule 6) + the workspace-trust gate. Do not treat a green Invariant 8 as proof of safety.

## Shipping the awareness harness (V2_ROADMAP S5-C — opt-in shipped)

The awareness harness (the `session-state-*` and `survey-before-act` hooks, the
`/state` command, the `session-state` skill, and the writer) ships to consumers
**opt-in / dormant** as of S5-C. The tooling is self-contained and installs; the
hooks are on disk but **inert** until a consumer registers them. No active
`settings.json` ships — that (auto-firing the hooks on every consumer session) is
a separate, still-gated step.

**Shipped in S5-C (opt-in mode) — done:**
1. **Writer + template are skill-local.** The writer lives at
   `.claude/skills/session-state/scripts/session-state.sh` and the schema template
   at `.claude/skills/session-state/assets/SESSION-STATE.template.md`; both ship via
   `install_dir "skills"` recursion. The writer resolves the template relative to
   itself and the live `SESSION-STATE.md` at the project root (`CLAUDE_PROJECT_DIR`),
   so `init` works on a consumer with no repo-root dependency. Both call sites
   (`.claude/commands/state.md`, `.claude/skills/session-state/SKILL.md`) point at
   the shipped path.
2. **`/state` is in the command ship allowlist** in `install.sh` AND `install.ps1`
   (parity), with `EXPECTED_CMDS` in `validate.sh` and the `validate-test.sh`
   manifest fixture updated in lockstep.
3. **The opt-in registration is documented, not shipped.** `session-state/SKILL.md`
   carries the `settings.json` snippet a consumer pastes to activate; the command
   entries invoke vendored `.claude/hooks/` scripts (no inline shell).
4. **Untrusted-data framing (rule 7)** is carried in the skill and the template;
   `SESSION-STATE.md` stays gitignored / per-developer on the consumer side.

**Still gated — shipping the hooks *active* (a registered `settings.json`):**
- Register hooks through a shipped, **Invariant-8(b)**-checked settings file and
  re-run `security-reviewer` on that install diff before merge. Until then the
  consumer opts in by hand, which keeps auto-execution off the supply chain.

**Note for review:** the writer ships as a **skill-local script**, which is *not*
covered by Invariant 8 (that gate scans `.claude/hooks/*.sh` only). It is benign by
construction (pure bash/awk/coreutils; no network, exec, persistence, or credential
access), but its safety rests on review + minimality, not the static gate.

## Reporting a vulnerability

Report privately via a **GitHub Security Advisory** on the repository (`LazyIsEfficient/agentic-os`) rather than a public issue. Please include the affected file(s), the execution path, and a proof-of-concept if you have one. Do not open a public issue for an unfixed vulnerability.
