# Install Skills Library into your Claude Code global config.
#
# Usage — pipe from GitHub (no clone required):
#   irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.6.0/install.ps1 | iex
#
# Usage — from a local clone:
#   .\install.ps1
#
# Options:
#   -Force   Overwrite existing files without prompting
#   -Dest    Override the install destination (default: $env:USERPROFILE\.claude)
#
# Integrity: the remote install path downloads a PINNED release asset and
# verifies its SHA-256 against $ExpectedSha256 below before extracting anything.
# A mismatch aborts the install. To install a different state, install from a
# local clone (.\install.ps1) instead — there is intentionally no "track main"
# remote path. See RELEASING.md for how the pin is produced.

param(
  [switch]$Force,
  [string]$Dest = "$env:USERPROFILE\.claude"
)

$ErrorActionPreference = "Stop"

if ($Dest -notmatch '^[/\\:.a-zA-Z0-9._-]+$') {
  throw "Error: unsafe -Dest (shell metacharacters not allowed): $Dest"
}

$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "LazyIsEfficient" }
$RepoName  = if ($env:REPO_NAME)  { $env:REPO_NAME  } else { "agentic-os" }

# Pinned release. Both values are produced together by scripts/release.sh and
# must be updated together — $ExpectedSha256 is the digest of the release asset
# built from tag $Version.
$Version        = "v3.0.1"
$ExpectedSha256 = "7fca2eb60fe898b1eae17975a9d1bbecde21b4c813f42ef9e5ee94a87353eaea"

# ── Resolve source ─────────────────────────────────────────────────────────────

$ScriptDir  = $PSScriptRoot
$LocalSrc   = if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir ".claude\skills"))) {
                Join-Path $ScriptDir ".claude"
              } else { $null }

$TmpDir = $null

if ($LocalSrc) {
  $Src = $LocalSrc
  Write-Host "Installing from local clone at $ScriptDir"
} else {
  if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Write-Error "tar is required to extract the release asset (ships with Windows 10 1803+). Install tar or use a local clone (.\install.ps1)."
    exit 1
  }

  $TmpDir   = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName()))
  $Asset    = "$RepoName-$Version.tar.gz"
  $AssetUrl = "https://github.com/$RepoOwner/$RepoName/releases/download/$Version/$Asset"
  $Archive  = Join-Path $TmpDir $Asset

  Write-Host "Downloading pinned release $Version from https://github.com/$RepoOwner/$RepoName ..."
  Invoke-WebRequest -Uri $AssetUrl -OutFile $Archive -UseBasicParsing

  # Verify integrity BEFORE extracting. Fail closed on any mismatch.
  $ActualSha = (Get-FileHash -Algorithm SHA256 -Path $Archive).Hash.ToLower()
  if ($ActualSha -ne $ExpectedSha256.ToLower()) {
    Remove-Item $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error "Integrity check FAILED for $Asset — aborting install.`n  expected: $ExpectedSha256`n  actual:   $ActualSha`nDo not proceed. The download may be corrupt or tampered with."
    exit 1
  }
  Write-Host "  OK SHA-256 verified ($ActualSha)"

  & tar -xzf "$Archive" -C "$TmpDir"
  if ($LASTEXITCODE -ne 0) {
    Remove-Item $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error "Failed to extract $Asset — aborting install."
    exit 1
  }

  $Src = Join-Path $TmpDir "$RepoName-$Version\.claude"
}

# ── Validate before copying ────────────────────────────────────────────────────
# Repo root is the parent of $Src (which points at ...\<root>\.claude) for both
# the local clone and the downloaded archive. The validator is pure Bash; we run
# it via `bash` to keep the six structural checks in ONE place (scripts/validate.sh)
# rather than reimplementing them in PowerShell.
# NOTE: Windows hosts may not have bash on PATH (Git Bash / WSL provide it). If
# bash is unavailable we WARN and continue rather than block the install, since a
# Windows-only user cannot run the validator; CI and install.sh still enforce it
# as a hard gate on every PR and on the macOS/Linux install path.
$RepoRoot   = Split-Path $Src
$ValidateSh = Join-Path $RepoRoot "scripts\validate.sh"
if (Test-Path $ValidateSh) {
  $bash = Get-Command bash -ErrorAction SilentlyContinue
  if ($bash) {
    Write-Host ""
    Write-Host "Validating library structure ..."
    & $bash.Source (Join-Path $RepoRoot "scripts/validate.sh") $RepoRoot
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Library failed structural validation — aborting install."
      exit 1
    }
  } else {
    Write-Warning "bash not found — skipping structural validation (enforced by CI and the macOS/Linux installer)."
  }
} else {
  Write-Error "scripts/validate.sh not found at $RepoRoot — aborting install."
  exit 1
}

# ── Install helper ─────────────────────────────────────────────────────────────

function Install-Dir {
  param([string]$Name)
  $SrcDir  = Join-Path $Src $Name
  $DestDir = Join-Path $Dest $Name
  if (-not (Test-Path $SrcDir)) { return }
  New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

  if ($Force) {
    Copy-Item -Path "$SrcDir\*" -Destination $DestDir -Recurse -Force
  } else {
    Get-ChildItem -Path $SrcDir -Recurse -File | ForEach-Object {
      $rel    = $_.FullName.Substring($SrcDir.Length + 1)
      $target = Join-Path $DestDir $rel
      if (-not (Test-Path $target)) {
        $targetParent = Split-Path $target
        New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
        Copy-Item -Path $_.FullName -Destination $target
      }
    }
  }

  Write-Host "  OK $Name -> $DestDir"
}

# Ship-tagged allowlist: copy ONLY the named files from $Src\$Name, never the
# whole directory. Used for surfaces (commands) where some files are
# maintainer-only and must not pollute a consumer's global namespace.
function Install-Files {
  param([string]$Name, [string[]]$Files)
  $SrcDir  = Join-Path $Src $Name
  $DestDir = Join-Path $Dest $Name
  if (-not (Test-Path $SrcDir)) { return }

  $copied = 0
  foreach ($rel in $Files) {
    $src = Join-Path $SrcDir $rel
    if (-not (Test-Path $src)) { continue }
    $target = Join-Path $DestDir $rel
    if ($Force -or -not (Test-Path $target)) {
      $targetParent = Split-Path $target
      New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
      Copy-Item -Path $src -Destination $target
    }
    $copied++
  }

  if ($copied -gt 0) { Write-Host "  OK $Name ($copied ship-tagged) -> $DestDir" }
}

# ── Run ────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Installing to $Dest"

Install-Dir "skills"
Install-Dir "agents"
# Commands: ship-tagged allowlist ONLY — list each file that installs into a
# consumer's global namespace. The author-facing scaffolds plus /state (the
# awareness-harness writer command — its skill + hooks ship alongside) are the
# only consumer commands; maintainer-only commands (audit-library, review-gate,
# triage-findings, eval-harness) stay in-repo and are never installed, to avoid
# polluting the consumer's command namespace.
Install-Files "commands" @("skill-new.md", "agent-new.md", "state.md")
# Workflows: NOTHING ships. The only workflow (audit-skill-library) is a
# maintainer-only tool that stays in-repo and is never installed.

$HooksSrc  = Join-Path $Src "hooks"
$HooksDest = Join-Path $Dest "hooks"
if (Test-Path $HooksSrc) {
  New-Item -ItemType Directory -Force -Path $HooksDest | Out-Null
  Copy-Item -Path "$HooksSrc\*" -Destination $HooksDest -Recurse -Force
  Write-Host "  OK hooks -> $HooksDest"
}

function Install-ClaudeHookSettings {
  $SrcFile = Join-Path $RepoRoot "assets\consumer\claude-settings.json"
  if (-not (Test-Path $SrcFile)) { return }
  # $Dest exists by now (the hooks copy created $Dest\hooks). Convert-Path gives
  # a full filesystem path so [IO.File]::WriteAllText — which resolves relative
  # paths against .NET's CWD, not PowerShell's — always writes the right place.
  $DestFile = Join-Path (Convert-Path -LiteralPath $Dest) "settings.json"
  $HooksDir = Join-Path $Dest "hooks"

  # Rewrite the template's `$HOME/.claude/hooks` token to the actual install
  # hooks dir, then register. Done in NATIVE PowerShell (no bash/jq shell-out)
  # so registration never silently no-ops on a Windows box that lacks jq — the
  # previous version required bash+jq and, when either was missing, left hooks
  # copied-but-unregistered on any re-install or custom -Dest. (The hooks are
  # bash scripts and still need bash at RUNTIME, but that is not install-time's
  # concern.) Forward slashes: bash-on-Windows accepts them and, unlike the
  # backslash form, they need no JSON escaping. $Dest is validated at the top of
  # this script to exclude `$`, so the replacement string is injection-safe.
  $HooksDirFwd = ($HooksDir -replace '\\', '/')
  $raw = Get-Content $SrcFile -Raw
  $rewritten = $raw -replace [regex]::Escape('$HOME/.claude/hooks'), $HooksDirFwd

  # Own the entire hooks key (replace it), preserving all other top-level keys —
  # matches install.sh (`jq '.hooks = $h'`) and SECURITY.md.
  if (Test-Path $DestFile) {
    # Existing settings: merge. -Depth 100 so a consumer's deeply-nested keys
    # round-trip intact. NOTE: on Windows PowerShell 5.1 this JSON round-trip
    # can unwrap single-element arrays — the Windows smoke test (RELEASING.md
    # step 6) must confirm hooks.PreToolUse stays an array on an EXISTING
    # settings.json before tagging.
    $hooks    = ($rewritten | ConvertFrom-Json).hooks
    $destJson = Get-Content $DestFile -Raw | ConvertFrom-Json
    $destJson | Add-Member -NotePropertyName hooks -NotePropertyValue $hooks -Force
    $out = $destJson | ConvertTo-Json -Depth 100
  } else {
    # Fresh file (the common first install): the template is already exactly
    # `{"hooks":{...}}` with correct array shapes — write its rewritten text
    # VERBATIM, with no JSON round-trip, sidestepping the 5.1 array-unwrap
    # entirely for this path.
    $out = $rewritten
  }

  # WriteAllText emits UTF-8 WITHOUT a BOM on BOTH PS 5.1 and 7. (`Set-Content
  # -Encoding utf8` writes a BOM on 5.1, which a strict JSON parser — e.g. Node
  # JSON.parse — rejects, silently breaking hook loading.)
  [System.IO.File]::WriteAllText($DestFile, $out)
  Write-Host "  OK hooks active -> $DestFile"
}

Install-ClaudeHookSettings

if ($TmpDir -and (Test-Path $TmpDir)) {
  Remove-Item $TmpDir -Recurse -Force
}

Write-Host ""
Write-Host "Done. Restart Claude Code to load the new skills, agents, commands, and hooks."
Write-Host ""
Write-Host "To update later, re-run this script (-Force to overwrite customisations)."
