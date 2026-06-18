# Install Skills Library into your Claude Code global config.
#
# Usage — pipe from GitHub (no clone required):
#   irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.4.0/install.ps1 | iex
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

$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "LazyIsEfficient" }
$RepoName  = if ($env:REPO_NAME)  { $env:REPO_NAME  } else { "agentic-os" }

# Pinned release. Both values are produced together by scripts/release.sh and
# must be updated together — $ExpectedSha256 is the digest of the release asset
# built from tag $Version.
$Version        = "v1.4.0"
$ExpectedSha256 = "a999d63479e20431c6e30c8079f6d9764d080e0dea6981de43dc74dfbdbe16c9"

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
# consumer's global namespace. Author-facing scaffolds, the router, and the
# v2-collab command ship; maintainer-only commands (audit-library, review-gate,
# plan-clean, triage-findings) stay in-repo and are never installed, to avoid
# polluting the consumer's command namespace.
Install-Files "commands" @("skill-new.md", "agent-new.md", "route.md", "v2-collab.md")
# Workflows: ship-tagged allowlist ONLY. Only the v2-collab workflow ships (it
# backs the globally-installed /v2-collab command, which resolves its workflow
# from ~/.claude/workflows/). The other workflows (sharded library audit,
# routing-collision sweep) are maintainer-only and stay in-repo.
Install-Files "workflows" @("v2-collab.js")

$HooksSrc  = Join-Path $Src "hooks"
$HooksDest = Join-Path $Dest "hooks"
if (Test-Path $HooksSrc) {
  New-Item -ItemType Directory -Force -Path $HooksDest | Out-Null
  Copy-Item -Path "$HooksSrc\*" -Destination $HooksDest -Recurse -Force
  Write-Host "  OK hooks -> $HooksDest"
}

if ($TmpDir -and (Test-Path $TmpDir)) {
  Remove-Item $TmpDir -Recurse -Force
}

Write-Host ""
Write-Host "Done. Restart Claude Code to load the new skills, agents, and commands."
Write-Host ""
Write-Host "To update later, re-run this script (-Force to overwrite customisations)."
