# Install Skills Library into your Cursor global config.
#
# Shared skill/agent content lives in the repo's .claude/ tree; this script
# copies the consumer allowlist into $env:USERPROFILE\.cursor\ (skills, agents,
# hooks) and merges active hook registration into ~/.cursor/hooks.json.
# Hook scripts ship from .cursor/hooks/ (Cursor JSON stdout contract); spike
# *-probe.sh fixtures are dev-only and excluded.
#
# Validation strategy (why bash detection + SHA pin coexist):
#   • Local clone  → require bash + scripts/validate.sh before copy (fail-closed).
#     Catches structural drift while you still have the full repo.
#   • Remote one-liner → SHA-256 pin on the release tarball is the integrity gate;
#     validate.sh is skipped when bash is absent (common on Windows without Git Bash).
#     The pinned asset is the same tree CI validated at release time.
#
# Usage — pipe from GitHub (no clone required):
#   irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.4.0/install-cursor.ps1 | iex
#
# Usage — from a local clone:
#   .\install-cursor.ps1
#
# Options:
#   -Force   Overwrite existing files without prompting
#   -Dest    Override the install destination (default: $env:USERPROFILE\.cursor)
#
# Session-state writer resolution (project-first — see findings-ledger/references/install-paths.md):
#   $proj = $env:CURSOR_PROJECT_DIR ?? $env:CLAUDE_PROJECT_DIR ?? "."
#   $SS = Join-Path $proj ".claude\skills\session-state\scripts\session-state.sh"
#   if (-not (Test-Path $SS)) { $SS = Join-Path $env:USERPROFILE ".cursor\skills\session-state\scripts\session-state.sh" }
#   if (-not (Test-Path $SS)) { $SS = Join-Path $env:USERPROFILE ".claude\skills\session-state\scripts\session-state.sh" }
#   bash $SS init
#
# Integrity: the remote install path downloads a PINNED release asset and
# verifies its SHA-256 against $ExpectedSha256 below before extracting anything.
# A mismatch aborts the install. To install a different state, install from a
# local clone (.\install-cursor.ps1) instead — there is intentionally no "track main"
# remote path. See RELEASING.md for how the pin is produced.

param(
  [switch]$Force,
  [string]$Dest = "$env:USERPROFILE\.cursor"
)

$ErrorActionPreference = "Stop"

if ($Dest -notmatch '^[/.a-zA-Z0-9._-]+$') {
  throw "Error: unsafe -Dest (shell metacharacters not allowed): $Dest"
}

$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "LazyIsEfficient" }
$RepoName  = if ($env:REPO_NAME)  { $env:REPO_NAME  } else { "agentic-os" }

$Version        = "v2.4.0"
$ExpectedSha256 = "4ba796045726c51a609f8d15f92e6171cdeb2917ad62449417022309414be2b8"

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
    Write-Error "tar is required to extract the release asset (ships with Windows 10 1803+). Install tar or use a local clone (.\install-cursor.ps1)."
    exit 1
  }

  $TmpDir   = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName()))
  $Asset    = "$RepoName-$Version.tar.gz"
  $AssetUrl = "https://github.com/$RepoOwner/$RepoName/releases/download/$Version/$Asset"
  $Archive  = Join-Path $TmpDir $Asset

  Write-Host "Downloading pinned release $Version from https://github.com/$RepoOwner/$RepoName ..."
  Invoke-WebRequest -Uri $AssetUrl -OutFile $Archive -UseBasicParsing

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
# Failure modes:
#   • Local clone + no bash → abort (structural validate.sh must run before copy).
#   • Pinned remote + no bash → continue (SHA-256 pin is the integrity gate).
#   • validate.sh nonzero → abort (do not ship a broken tree).
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
  } elseif ($LocalSrc) {
    Write-Error @"
bash is required to validate a local clone before install.
Install Git Bash (https://git-scm.com/download/win) or WSL, then re-run .\install-cursor.ps1.
Alternatively use the pinned remote install (irm …/install-cursor.ps1 | iex) which verifies SHA-256 without bash.
"@
    exit 1
  } else {
    Write-Warning "bash not found — skipping structural validation (pinned release was verified by SHA-256)."
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

function Install-CursorHooks {
  $SrcDir  = Join-Path $RepoRoot ".cursor\hooks"
  $DestDir = Join-Path $Dest "hooks"
  if (-not (Test-Path $SrcDir)) { return }
  New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

  Get-ChildItem -Path $SrcDir -Recurse -File | Where-Object { $_.Name -notlike '*-probe.sh' } | ForEach-Object {
    $rel    = $_.FullName.Substring($SrcDir.Length + 1)
    $target = Join-Path $DestDir $rel
    if ($Force -or -not (Test-Path $target)) {
      $targetParent = Split-Path $target
      New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
      Copy-Item -Path $_.FullName -Destination $target
    }
  }

  Write-Host "  OK hooks -> $DestDir"

  # Mark hook scripts executable (Cursor invokes paths directly). Positional arg avoids
  # shell-quoting bugs when $Dest contains apostrophes. Skipped when bash absent —
  # hooks may not run until the user installs Git Bash/WSL and re-runs install.
  $bash = Get-Command bash -ErrorAction SilentlyContinue
  if ($bash) {
    Get-ChildItem -Path $DestDir -Filter "*.sh" -Recurse -File | ForEach-Object {
      & $bash.Source -c 'chmod +x "$1"' -- $_.FullName
    }
  } elseif (Test-Path $DestDir) {
    Write-Warning "bash not found — hook scripts copied but not marked executable. Install Git Bash and re-run, or chmod +x manually under $DestDir"
  }
}

# ── Run ────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Installing to $Dest"

Install-Dir "skills"
Install-Dir "agents"
Install-CursorHooks

function Install-CursorHookSettings {
  $SrcFile = Join-Path $RepoRoot "assets\consumer\cursor-hooks.json"
  if (-not (Test-Path $SrcFile)) { return }
  $DestFile = Join-Path $Dest "hooks.json"
  $srcJson = Get-Content $SrcFile -Raw | ConvertFrom-Json
  if (Test-Path $DestFile) {
    $destJson = Get-Content $DestFile -Raw | ConvertFrom-Json
    $destJson.version = $srcJson.version
    $destJson | Add-Member -NotePropertyName hooks -NotePropertyValue $srcJson.hooks -Force
    $destJson | ConvertTo-Json -Depth 12 | Set-Content $DestFile -Encoding utf8
  } else {
    Copy-Item $SrcFile $DestFile
  }
  Write-Host "  OK hooks active -> $DestFile"
}

Install-CursorHookSettings

if ($TmpDir -and (Test-Path $TmpDir)) {
  Remove-Item $TmpDir -Recurse -Force
}

Write-Host ""
Write-Host "Done. Restart Cursor to load the new skills, agents, subagent types, and hooks."
Write-Host ""
Write-Host "Recommended — Cursor Settings → Rules → User Rules:"
Write-Host "  Paste the Skills + orchestration blocks from README § Configure Cursor rules"
Write-Host "  (https://github.com/LazyIsEfficient/agentic-os#configure-cursor-rules--skill-discipline)"
Write-Host "  so orchestrator dispatch persists across projects."
Write-Host ""
Write-Host "Project-local doctrine (this repo): AGENTS.md + .cursor/rules/*.mdc"
Write-Host ""
Write-Host "Session-state writer (after install — see findings-ledger/references/install-paths.md):"
Write-Host '  $SS = Join-Path $env:USERPROFILE ".cursor\skills\session-state\scripts\session-state.sh"'
Write-Host '  bash $SS init   # or project-first chain from install-paths.md'
Write-Host ""
Write-Host "To update later, re-run this script (-Force to overwrite customisations)."
