# Security Policy

## Why this file exists

Most of this library is **inert**: skills, agents, commands, and rules are Markdown — instructions a *model* reads. The worst case for a bad instruction is bad advice, with a human and the model in the loop.

**Hooks are different. They are executable code that the library distributes and that runs automatically on consumer machines.** On **Claude Code**, `install.sh` runs `install_dir "hooks"` and `chmod +x` on `.claude/hooks/*.sh`; `install.ps1` does the same. On **Cursor**, `install-cursor.sh` / `install-cursor.ps1` copy production hook scripts from `.cursor/hooks/` (JSON stdout contract; spike `*-probe.sh` excluded) into `~/.cursor/hooks/` and mark them executable — skills and agents come from the shared `.claude/` tree under `~/.cursor/`. Once registered in a platform hook config (Claude `settings.json` or Cursor `hooks.json`), a hook fires on routine events (e.g. `PreToolUse` / `beforeShellExecution` on tool or shell activity, `SessionStart` / `sessionStart` on session open), runs with the user's full shell and permissions, and has **no sandbox**. This is the library's distributed executable surface on **both platforms**, so it is the primary security concern regardless of which IDE you use.

## Threat model — the supply chain

The risk travels through the **distribution channel**. People install this library on trust; they do not audit every line of every shipped hook. That means:

- A **bug** in a shipped hook runs on everyone who installed it — not just the author.
- An **upstream compromise** (a malicious PR merged, or a maintainer account/CI compromised) propagates arbitrary code to every downstream installer automatically. One poisoned commit → code execution on N machines. This is the classic supply-chain attack shape (`event-stream`, `xz`).

The only barrier in front of a freshly pulled hook is each platform's **workspace-trust gate** (the repo or project must be trusted before hooks run). That is a single one-time gate on each platform, **not** a sandbox.

### What ships today

**Claude Code (`install.sh` / `install.ps1`)**
- Ships `.claude/hooks/*.sh` and marks them executable.
- **No `settings.json` ships.** The repo's own `.claude/settings.json` (dev permissions + autoMode config) is **not** shipped, and S5-C deliberately did not add a shipped one. Every shipped hook script is **dormant** on a consumer until they register it in their own `settings.json` — the executable code is on disk but nothing runs it automatically.

**Cursor (`install-cursor.sh` / `install-cursor.ps1`)**
- Ships production hook scripts from `.cursor/hooks/` into `~/.cursor/hooks/` (spike `*-probe.sh` excluded) and marks them executable. Skills and agents ship from `.claude/` into `~/.cursor/`; commands do **not** ship on Cursor.
- **No `hooks.json` ships.** The repo's own `.cursor/hooks.json` (dev/spike registration for live-fire probes) is **not** shipped. Hook scripts are **dormant** on a consumer until they register them in their own `hooks.json` — same opt-in posture as Claude.

**Shared shipped hook scripts (dormant until registered):**
  - **Claude only:** `.claude/hooks/block-bad-bash.sh` — a `jq`-gated ergonomics nudge, explicitly self-labeled *not a security control*. Benign and minimal.
  - **Both platforms (awareness harness):** `session-state-inject.sh`, `session-state-digest.sh`, `session-state-checkpoint.sh`, `survey-before-act.sh` — Claude copies from `.claude/hooks/` (plain stdout); Cursor copies from `.cursor/hooks/` (JSON stdout; requires `jq` at runtime for inject/digest). Ship **dormant** (S5-C). The `session-state` skill documents the opt-in registration; `SESSION-STATE.md` is governed by rule 7 below.

## Policy for shipped hooks

Every hook that ships to consumers MUST:

1. **Live as a vendored `*.sh` shell script** under `.claude/hooks/` (and, for Cursor-native ports, under `.cursor/hooks/` when present). Other interpreters evade the shell-idiom denylist and are rejected on file type. Hook `command` entries in any shipped hook config must *invoke* such a script — never carry inline shell:
   - **Claude Code:** `settings.json` — `<interpreter> .claude/hooks/<name>.sh [simple args]`
   - **Cursor:** `hooks.json` v1 — `.cursor/hooks/<name>.sh [simple args]` (no interpreter prefix; Cursor invokes the path directly)
2. **Make no runtime network call** — no `curl`/`wget`/`nc`/`scp`/`sftp`, no `/dev/tcp`, no pipe-to-shell (`… | bash`). Nothing is fetched or executed from the network at runtime.
3. **Contain no dynamic/obfuscated execution** — no `eval`, no `base64 -d | sh`, no `source <(…)`, no inline `python -c` / `node -e`.
4. **Touch no credentials, persistence, or privilege** — no `~/.ssh`/`~/.aws`/`~/.gnupg`/`id_rsa`/`.npmrc` access, no `crontab`/`launchctl`/`systemctl`/LaunchAgents, no `sudo`, no `chmod 777`, no recursive deletes of `$HOME`/`/`.
5. **Be minimal and auditable** — small enough to read in full in one sitting. Do not chase completeness pattern-by-pattern (see the note in `block-bad-bash.sh`).
6. **Pass human security review before merge** — a maintainer or `security-reviewer` pass is required for any new or changed shipped hook (the V2_ROADMAP "ship + ratchet" gate).
7. **Treat any file a hook injects into context as untrusted, user-local, never-committed data.** Hooks that read a file and emit it into the model's context (e.g. the `session-state-*` hooks emitting `SESSION-STATE.md`) create a standing prompt-injection channel: whoever can write that file controls text injected every session/turn with no tool call. So such files MUST stay gitignored and per-developer (never committed, never in a shared/multi-writer checkout), and the injected block MUST be framed as DATA, not instructions. `SESSION-STATE.md` is gitignored for exactly this reason.

## Enforcement — and its limits

`scripts/validate.sh` **Invariant 8 (`hook-safety`)** is a **defense-in-depth tripwire** for rules 1–4 on **both platforms** — it is **NOT the safety boundary**, and nothing here should be read as "Invariant 8 makes shipping a hook safe." It runs in CI on every PR and push (`.github/workflows/validate.yml`); `scripts/validate-test.sh` pins each covered idiom as a Tier-0 regression. It has two halves applied to each platform's hook surface:

- **(a) Denylist scan** of shipped hook *scripts* (`.claude/hooks/*.sh` always; `.cursor/hooks/*.sh` for production names — spike `*-probe.sh` live-fire fixtures are dev-only throwaways excluded until the full Cursor port lands).
- **(b) Strict-shape allowlist** for hook *command* entries in config JSON:
  - Claude `settings.json`: exactly `<interpreter> .claude/hooks/<name>.sh [simple args]`
  - Cursor `hooks.json`: exactly `.cursor/hooks/<name>.sh [simple args]`

Anything else — a chained `; curl…|bash`, a literal-newline statement, an `env` prefix, a `../` path traversal, a `$(…)` subshell — fails the shape and is rejected. This is an allowlist of *shape*, not a denylist of metacharacters (which is incompletable — an early denylist version missed the newline separator), so a single vendored call cannot become a chain.

**This is a tripwire, not a sandbox — on both Claude Code and Cursor, and the denylist half is fundamentally incompletable.** A static denylist of egress idioms cannot be finished by enumeration (resolver-based DNS exfil, variable-indirection, string-rebuild, and the next idiom nobody listed all evade it). So **the denylist catches the obvious and the accidental; it does not stop a determined attacker.** What actually makes a hook safe is the *layered* controls, of which the regex is the weakest: **(rule 5) minimal scripts a human reads in full + (rule 6) human security review of every shipped hook + (rule 2) the no-runtime-fetch policy + each platform's workspace-trust gate.** The strict-shape half (b), by contrast, IS completable — it is an allowlist of command *shape*, not a denylist of idioms — and is the load-bearing deterministic check on **both** platforms. **Any future active install (S5-C active registration on Claude, or a shipped `hooks.json` on Cursor) is gated on human review + strict-shape, never on the egress denylist being "complete."**

**Accepted, by-design limits of the regex denylist (NOT bugs — defended by the other layers):** the scan matches *literal* command idioms, so it cannot catch a payload assembled to defeat pattern-matching — most notably **variable indirection** (`A=cu; B=rl; "$A$B" http://…` reconstructs `curl` from fragments no single token matches), and equally string-reversal, `printf`-built command names, or an `IFS`/brace-expansion trick. Chasing these pattern-by-pattern is a losing game against a regex; they are out of scope for the tripwire and are caught instead by **rule 5 (minimal, auditable scripts a human reads in full)** and **rule 6 (human security review of every shipped hook)**. What the denylist *does* cover is the high-signal direct idioms — network tools (incl. `ssh`/`rsync`), version-suffixed and space-or-no-space `-m` interpreter invocations (python/node/perl/ruby), `openssl s_client`/`enc`, here-strings/heredocs and pipes fed to a shell, `eval`/`base64`/process-substitution — so an *accidental* or low-effort-malicious direct use trips the gate. `validate-test.sh` cases 11–26 pin Claude idioms; cases 30–31 pin Cursor config shape and a benign probe hook as Tier-0 regressions. The covered set is "the idioms we've seen tried," not a closed enumeration — new direct idioms get added as they're found (the ratchet), but the layered defenses above, not the regex, are what make a hook safe on either platform.

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

**Still gated — shipping the hooks *active* (registered config on either platform):**
- **Claude:** a shipped active `settings.json`
- **Cursor:** a shipped active `hooks.json`
- The gate is **human security review + the strict-shape command check (Invariant
  8(b))**, **not** the egress denylist being "complete" (it never is — see
  Enforcement). A shipped active config must register only single vendored-hook-script
  commands with no shell metacharacter, and a `security-reviewer` pass on the actual
  install diff is required before merge.
- Until then the consumer opts in by hand, which keeps auto-execution off the
  supply chain. **Recommendation (review #2): keep the harness dogfood-only / opt-in;
  do not flip to active** — an active install would rest on the tripwire that has
  already been stepped over, so the dormant posture is the one to ship.

**Note for review:** the writer ships as a **skill-local script**, which is *not*
covered by Invariant 8 (that gate scans `.claude/hooks/*.sh` and production
`.cursor/hooks/*.sh` only). It is benign by construction (pure bash/awk/coreutils;
no network, exec, persistence, or credential access), but its safety rests on
review + minimality, not the static gate.

## Reporting a vulnerability

Report privately via a **GitHub Security Advisory** on the repository (`LazyIsEfficient/agentic-os`) rather than a public issue. Please include the affected file(s), the execution path, and a proof-of-concept if you have one. Do not open a public issue for an unfixed vulnerability.
