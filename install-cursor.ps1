# Install Skills Library into your Cursor global config.
#
# Shared skill/agent content lives in the repo's .claude/ tree; this script
# copies the consumer allowlist into $env:USERPROFILE\.cursor\ (skills, agents,
# dormant hooks). Hook scripts ship from .cursor/hooks/ (Cursor JSON stdout
# contract); spike *-probe.sh fixtures are dev-only and excluded. No hooks.json
# activation doc ships — register hooks manually in your project or global config.
#
# Usage — pipe from GitHub (no clone required):
#   irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.1.0/install-cursor.ps1 | iex
#
# Usage — from a local clone:
#   .\install-cursor.ps1
#
# Options:
#   -Force   Overwrite existing files without prompting
#   -Dest    Override the install destination (default: $env:USERPROFILE\.cursor)
#
# Session-state writer resolution (project-first, then global — mirror #143):
#   $SS = Join-Path ($env:CURSOR_PROJECT_DIR ?? $env:CLAUDE_PROJECT_DIR ?? ".") ".cursor\skills\session-state\scripts\session-state.sh"
#   if (-not (Test-Path $SS)) { $SS = Join-Path $env:USERPROFILE ".cursor\skills\session-state\scripts\session-state.sh" }
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

$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "LazyIsEfficient" }
$RepoName  = if ($env:REPO_NAME)  { $env:REPO_NAME  } else { "agentic-os" }

$Version        = "v2.1.0"
$ExpectedSha256 = "44cae4fcb4b10f9def07aac5cc972a83241e6455346558521d922908604ca332"

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
}

# ── Run ────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Installing to $Dest"

Install-Dir "skills"
Install-Dir "agents"
Install-CursorHooks

if ($TmpDir -and (Test-Path $TmpDir)) {
  Remove-Item $TmpDir -Recurse -Force
}

Write-Host ""
Write-Host "Done. Restart Cursor to load the new skills and agents."
Write-Host ""
Write-Host "Session-state writer (after install):"
Write-Host '  PROJ="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"'
Write-Host '  SS="$PROJ/.claude/skills/session-state/scripts/session-state.sh"'
Write-Host '  [ -f "$SS" ] || SS="$HOME/.cursor/skills/session-state/scripts/session-state.sh"'
Write-Host '  [ -f "$SS" ] || SS="$HOME/.claude/skills/session-state/scripts/session-state.sh"'
Write-Host '  bash "$SS" init'
Write-Host ""
Write-Host "To update later, re-run this script (-Force to overwrite customisations)."
