# Install, update, or uninstall AgenticOS in your Claude Code global config.
#
# Usage — pipe from GitHub (no clone required):
#   irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v3.0.1/install.ps1 | iex
#
# Usage — from a local clone:
#   .\install.ps1
#
# Options:
#   -Force        Also overwrite AgenticOS files you modified locally
#   -PruneLegacy  Remove retired skill directories left by pre-manifest installs
#   -Uninstall    Remove AgenticOS-owned files and hook registrations
#   -DryRun       Print what would change; change nothing
#   -Dest         Override the install destination (default: $env:USERPROFILE\.claude)
#
# Lifecycle (same rules as install.sh): $Dest\.agentic-os-manifest.json records
# every installed file and its SHA-256. Re-running updates files you have not
# modified, keeps (and names) files you have, always refreshes shipped hooks
# (backing up a modified one to <file>.bak.<timestamp>), prunes files a release
# dropped, and never touches files that are not in the manifest.
#
# Integrity: the remote install path downloads a PINNED release asset and
# verifies its SHA-256 against $ExpectedSha256 below before extracting anything.
# A mismatch aborts the install. To install a different state, install from a
# local clone (.\install.ps1) instead — there is intentionally no "track main"
# remote path. See RELEASING.md for how the pin is produced.

param(
  [switch]$Force,
  [switch]$PruneLegacy,
  [switch]$Uninstall,
  [switch]$DryRun,
  [string]$Dest = "$env:USERPROFILE\.claude"
)

$ErrorActionPreference = "Stop"

if ($Dest -notmatch '^[/\\:.a-zA-Z0-9._-]+$') {
  throw "Error: unsafe -Dest (shell metacharacters not allowed): $Dest"
}
if ($Uninstall -and ($Force -or $PruneLegacy)) {
  throw "Error: -Force and -PruneLegacy do not apply to -Uninstall (modified files are always kept)."
}

$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "LazyIsEfficient" }
$RepoName  = if ($env:REPO_NAME)  { $env:REPO_NAME  } else { "agentic-os" }

# Pinned release. Both values are produced together by scripts/release.sh and
# must be updated together — $ExpectedSha256 is the digest of the release asset
# built from tag $Version.
$Version        = "v3.0.1"
$ExpectedSha256 = "7fca2eb60fe898b1eae17975a9d1bbecde21b4c813f42ef9e5ee94a87353eaea"

# Hook scripts removed from assets/consumer/claude-settings.json in a past
# release (basenames). Install and uninstall unregister them from settings.json;
# their files are pruned through the manifest. Keep in sync with RETIRED_HOOKS
# in install.sh (validate.sh checks).
$RetiredHooks = @()

$ManifestName = ".agentic-os-manifest.json"

# ── Resolve source ─────────────────────────────────────────────────────────────

$ScriptDir  = $PSScriptRoot
$LocalSrc   = if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir ".claude\skills"))) {
                Join-Path $ScriptDir ".claude"
              } else { $null }

$TmpDir = $null

if ($LocalSrc) {
  $Src = $LocalSrc
  $SourceKind = "local-clone"
  Write-Host "Using local clone at $ScriptDir"
} else {
  $SourceKind = "release"
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
# as a hard gate on every PR and on the macOS/Linux install path. Uninstall
# copies nothing, so it skips validation.
$RepoRoot   = Split-Path $Src
$ValidateSh = Join-Path $RepoRoot "scripts\validate.sh"
if (-not (Test-Path $ValidateSh)) {
  Write-Error "scripts/validate.sh not found at $RepoRoot — aborting."
  exit 1
}
if (-not $Uninstall) {
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
}

# Retired skill slugs: the validator's TOMBSTONES list is the single source.
$Tombstones = @()
$tombLine = Select-String -LiteralPath $ValidateSh -Pattern '^TOMBSTONES="(.*)"$' | Select-Object -First 1
if ($tombLine) { $Tombstones = @($tombLine.Matches[0].Groups[1].Value -split ' ' | Where-Object { $_ }) }

# Absolute install root (relative -Dest resolves against PowerShell's CWD).
$Root  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Dest).TrimEnd('\', '/')
$Work  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $Work | Out-Null
$Stage = Join-Path $Work "stage"
$Stamp = Get-Date -Format "yyyyMMddHHmmss"
$Pfx   = if ($DryRun) { "[dry-run] " } else { "" }
$script:Warnings = 0

function Note([string]$Msg) { Write-Host "  $Pfx$Msg" }
function Warn([string]$Msg) { Write-Host "  ! $Pfx$Msg"; $script:Warnings++ }

# ── Manifest ───────────────────────────────────────────────────────────────────

$SafeRel = '^[A-Za-z0-9._@+/-]+$'

function Get-Sha([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLower() }

function Join-Rel([string]$Base, [string]$Rel) { Join-Path $Base ($Rel -replace '/', [System.IO.Path]::DirectorySeparatorChar) }

function Test-SafeRel([string]$Rel) {
  ($Rel -match $SafeRel) -and -not $Rel.StartsWith('/') -and -not ($Rel -match '(^|/)\.\.(/|$)')
}

# rel -> sha for every file under $Dir (paths use '/').
function Get-TreeHashes([string]$Dir) {
  $map = @{}
  if (-not (Test-Path -LiteralPath $Dir)) { return $map }
  $full = (Convert-Path -LiteralPath $Dir).TrimEnd('\', '/')
  foreach ($f in Get-ChildItem -LiteralPath $full -Recurse -File -Force) {
    $rel = $f.FullName.Substring($full.Length + 1) -replace '\\', '/'
    $map[$rel] = Get-Sha $f.FullName
  }
  return $map
}

# rel -> sha from a manifest; absolute or `..` paths are ignored so a tampered
# manifest can never aim removal outside the install root.
function Read-Manifest([string]$RootDir) {
  $map = @{}
  $mf = Join-Path $RootDir $ManifestName
  if (-not (Test-Path -LiteralPath $mf)) { return $map }
  $json = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
  foreach ($e in @($json.files)) {
    if (($e.path -is [string]) -and ($e.sha256 -is [string]) -and ($e.sha256 -cmatch '^[0-9a-f]{64}$') -and (Test-SafeRel $e.path)) {
      $map[$e.path] = $e.sha256
    }
  }
  return $map
}

function Get-SortedKeys($Map) {
  $keys = [string[]]@($Map.Keys)
  [Array]::Sort($keys, [StringComparer]::Ordinal)
  return ,$keys
}

# Same line format as install.sh so both installers read each other's manifest.
function Write-Manifest([string]$RootDir, $Entries) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append("{`n  `"schema`": 1,`n  `"name`": `"agentic-os`",`n  `"version`": `"$Version`",`n")
  [void]$sb.Append("  `"source`": `"$SourceKind`",`n  `"platform`": `"claude`",`n  `"files`": [`n")
  $keys = Get-SortedKeys $Entries
  for ($i = 0; $i -lt $keys.Count; $i++) {
    $sep = if ($i -lt $keys.Count - 1) { "," } else { "" }
    [void]$sb.Append("    {`"path`": `"$($keys[$i])`", `"sha256`": `"$($Entries[$keys[$i]])`"}$sep`n")
  }
  [void]$sb.Append("  ]`n}`n")
  $mf = Join-Path $RootDir $ManifestName
  [System.IO.File]::WriteAllText("$mf.tmp", $sb.ToString())
  Move-Item -LiteralPath "$mf.tmp" -Destination $mf -Force
}

function Copy-Placed([string]$From, [string]$To) {
  if ($DryRun) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $To) | Out-Null
  Copy-Item -LiteralPath $From -Destination $To -Force
}

# Remove now-empty directories from each listed rel dir up to (never including) root.
function Remove-EmptyDirs([string]$RootDir, $RelDirs) {
  if ($DryRun) { return }
  foreach ($d in @($RelDirs | Sort-Object -Unique -Descending)) {
    $cur = $d
    while ($cur -and $cur -ne '.') {
      $p = Join-Rel $RootDir $cur
      if (Test-Path -LiteralPath $p) {
        if (@(Get-ChildItem -LiteralPath $p -Force).Count -gt 0) { break }
        Remove-Item -LiteralPath $p -Force
      }
      $cur = Get-RelDir $cur
    }
  }
}

function Get-RelDir([string]$Rel) { if ($Rel -match '/') { $Rel -replace '/[^/]*$', '' } else { '.' } }

# ── Hook registration (settings.json) ──────────────────────────────────────────
# Same semantics as scripts/lib/install-hook-settings.sh and SECURITY.md. A
# handler is AgenticOS-owned only when its whole command (trimmed, runs of `/`
# collapsed) EQUALS a template command or `bash <hooks dir>/<name>` for a
# retired hook — in the literal `$HOME/.claude/hooks/...` form or with the hooks
# dir substituted (canonical or as-given). Compound/piped commands that merely
# contain our path stay the consumer's. Only groups/events emptied by stripping
# are dropped.

$SettingsTemplate = Join-Path $RepoRoot "assets\consumer\claude-settings.json"
$HooksDirFwd      = (Join-Path $Root "hooks") -replace '\\', '/'
$HooksDirGivenFwd = ((Join-Path $Dest "hooks") -replace '\\', '/').TrimEnd('/')
$normCmd = { param([string]$c) ($c.Trim() -replace '/+', '/') }

function New-OwnedSet([string[]]$Cmds) {
  $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
  foreach ($c in $Cmds) {
    foreach ($form in @($c,
        ($c -replace [regex]::Escape('$HOME/.claude/hooks'), $HooksDirFwd),
        ($c -replace [regex]::Escape('$HOME/.claude/hooks'), $HooksDirGivenFwd))) {
      [void]$set.Add((& $normCmd $form))
    }
  }
  return ,$set
}

function Test-OwnedHandler($H, $Set) {
  ($H -is [System.Management.Automation.PSCustomObject]) -and $H.PSObject.Properties['command'] -and
    ($H.command -is [string]) -and $Set.Contains((& $normCmd $H.command))
}

# Strip owned handlers from an event's groups; drop groups emptied by that.
function Remove-OwnedGroups($Groups, $Set) {
  $kept = @()
  foreach ($g in @($Groups)) {
    if ($g -is [System.Management.Automation.PSCustomObject] -and $g.PSObject.Properties['hooks'] -and $g.hooks -is [System.Array] -and
        @($g.hooks | Where-Object { Test-OwnedHandler $_ $Set }).Count -gt 0) {
      $handlers = @($g.hooks | Where-Object { -not (Test-OwnedHandler $_ $Set) })
      if ($handlers.Count -eq 0) { continue }
      $g.hooks = $handlers
    }
    $kept += ,$g
  }
  return ,$kept
}

function Get-HookCommands($Json) {
  $out = @()
  if ($Json.PSObject.Properties['hooks'] -and $Json.hooks -is [System.Management.Automation.PSCustomObject]) {
    foreach ($ev in $Json.hooks.PSObject.Properties) {
      foreach ($g in @($ev.Value)) {
        if ($g -is [System.Management.Automation.PSCustomObject] -and $g.PSObject.Properties['hooks']) {
          foreach ($h in @($g.hooks)) { if ($h -is [System.Management.Automation.PSCustomObject] -and $h.command -is [string]) { $out += $h.command } }
        }
      }
    }
  }
  return ,$out
}

# Mode "merge": strip retired handlers everywhere, strip template handlers in
# shipped events, append our groups. Mode "uninstall": strip template + retired
# handlers everywhere. A non-object `hooks` (or, merging, a non-array shipped
# event) throws before anything is written.
function Update-ClaudeHookSettings([string]$Mode) {
  if (-not (Test-Path $SettingsTemplate)) { return }
  $DestFile = Join-Path $Root "settings.json"
  $raw = Get-Content $SettingsTemplate -Raw
  # Forward slashes: bash-on-Windows accepts them and, unlike the backslash form,
  # they need no JSON escaping. $Dest is validated at the top of this script to
  # exclude `$`, so the replacement string is injection-safe.
  $rewritten = $raw -replace [regex]::Escape('$HOME/.claude/hooks'), $HooksDirFwd
  $tplCmds = @(foreach ($tev in ($raw | ConvertFrom-Json).hooks.PSObject.Properties) {
    foreach ($tg in @($tev.Value)) { foreach ($th in @($tg.hooks)) { $th.command } } })
  $tplSet = New-OwnedSet $tplCmds
  $retSet = New-OwnedSet @($RetiredHooks | ForEach-Object { "bash `$HOME/.claude/hooks/$_" })
  $allSet = New-OwnedSet (@($tplCmds) + @($RetiredHooks | ForEach-Object { "bash `$HOME/.claude/hooks/$_" }))

  if (-not (Test-Path $DestFile)) {
    if ($Mode -eq "uninstall") { Write-Host "  . no $DestFile — no hook entries to unregister"; return }
    # Fresh file: write the rewritten template VERBATIM (no JSON round-trip, so
    # the Windows PowerShell 5.1 single-element-array unwrap cannot happen).
    if ($DryRun) { Note "merge AgenticOS hook registration into $DestFile"; return }
    [System.IO.File]::WriteAllText($DestFile, $rewritten)
    Write-Host "  OK hooks active -> $DestFile"
    return
  }

  # -Depth 100 so a consumer's deeply-nested keys round-trip intact. NOTE: on
  # Windows PowerShell 5.1 this JSON round-trip can unwrap single-element
  # arrays — the Windows smoke test (RELEASING.md) must confirm
  # hooks.PreToolUse stays an array on an EXISTING settings.json before tagging.
  $destJson = Get-Content $DestFile -Raw | ConvertFrom-Json
  $before = Get-HookCommands $destJson
  $existing = if ($destJson.PSObject.Properties['hooks']) { $destJson.hooks } else { $null }
  if ($null -ne $existing -and $existing -isnot [System.Management.Automation.PSCustomObject]) {
    throw "Error: failed to update AgenticOS hooks in ${DestFile}: hooks is not an object."
  }
  $stripSet = if ($Mode -eq "merge") { $retSet } else { $allSet }
  $merged = [ordered]@{}
  if ($null -ne $existing) {
    foreach ($ev in $existing.PSObject.Properties) {
      if ($ev.Value -is [System.Array] -and $ev.Value.Count -gt 0) {
        $kept = Remove-OwnedGroups $ev.Value $stripSet
        if ($kept.Count -eq 0) { continue }
        $merged[$ev.Name] = $kept
      } else {
        $merged[$ev.Name] = $ev.Value
      }
    }
  }
  if ($Mode -eq "merge") {
    $incoming = ($rewritten | ConvertFrom-Json).hooks
    foreach ($ev in $incoming.PSObject.Properties) {
      $groups = if ($merged.Contains($ev.Name)) { $merged[$ev.Name] } else { @() }
      if ($null -eq $groups) { $groups = @() }
      if ($groups -isnot [System.Array]) {
        throw "Error: failed to merge AgenticOS hooks into ${DestFile}: hooks.$($ev.Name) is not an array."
      }
      $keptGroups = Remove-OwnedGroups $groups $tplSet
      $merged[$ev.Name] = $keptGroups + @($ev.Value)
    }
  }
  if ($Mode -eq "uninstall" -and $merged.Count -eq 0 -and $null -ne $existing -and @($existing.PSObject.Properties).Count -gt 0) {
    $destJson.PSObject.Properties.Remove('hooks')
  } elseif ($null -ne $existing -or $Mode -eq "merge") {
    $destJson | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]$merged) -Force
  }
  $after = Get-HookCommands $destJson
  if ($Mode -eq "uninstall") {
    foreach ($c in @($before | Where-Object { $after -notcontains $_ } | Sort-Object -Unique)) {
      Write-Host "  $(if ($DryRun) { '[dry-run] ' } else { '- ' })unregister hook: $c"
    }
  }
  if ($DryRun) {
    if ($Mode -eq "merge") { Note "merge AgenticOS hook registration into $DestFile" }
    return
  }
  # WriteAllText emits UTF-8 WITHOUT a BOM on BOTH PS 5.1 and 7. (`Set-Content
  # -Encoding utf8` writes a BOM on 5.1, which a strict JSON parser — e.g. Node
  # JSON.parse — rejects, silently breaking hook loading.)
  [System.IO.File]::WriteAllText($DestFile, ($destJson | ConvertTo-Json -Depth 100))
  if ($Mode -eq "merge") { Write-Host "  OK hooks active -> $DestFile" }
}

# ── Uninstall ──────────────────────────────────────────────────────────────────

if ($Uninstall) {
  Write-Host ""
  Write-Host "${Pfx}Uninstalling AgenticOS from $Root"
  # Unregister hooks BEFORE deleting files: if the settings rewrite fails, the
  # hook scripts it still points at are left in place.
  Write-Host ""
  Write-Host "Hook registration: $(Join-Path $Root 'settings.json')"
  if (Test-Path -LiteralPath $Root) { Update-ClaudeHookSettings "uninstall" }
  Write-Host ""
  $mf = Join-Path $Root $ManifestName
  if (-not (Test-Path -LiteralPath $mf)) {
    Write-Host "  . no $ManifestName — nothing tracked to remove (a pre-manifest install: run the installer once to adopt it, then uninstall)"
  } else {
    $old = Read-Manifest $Root
    $dirs = @(); $removed = 0; $kept = 0
    foreach ($rel in (Get-SortedKeys $old)) {
      $target = Join-Rel $Root $rel
      if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
      if ((Get-Sha $target) -eq $old[$rel]) {
        Note "remove $rel"
        if (-not $DryRun) { Remove-Item -LiteralPath $target -Force }
        $dirs += (Get-RelDir $rel); $removed++
      } else {
        Warn "keep $rel — modified locally"; $kept++
      }
    }
    Remove-EmptyDirs $Root $dirs
    Note "remove $ManifestName"
    if (-not $DryRun) { Remove-Item -LiteralPath $mf -Force }
    Write-Host "  $Pfx$removed removed, $kept kept (modified)"
  }
  Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
  if ($TmpDir -and (Test-Path $TmpDir)) { Remove-Item $TmpDir -Recurse -Force }
  Write-Host ""
  Write-Host "${Pfx}Uninstall complete: $($script:Warnings) file(s) kept with a warning. Hook backups (*.bak.*) and files you created were not touched."
  exit 0
}

# ── Stage the release ──────────────────────────────────────────────────────────

function Install-Dir {
  param([string]$Name)
  $SrcDir = Join-Path $Src $Name
  if (-not (Test-Path $SrcDir)) { return }
  $To = Join-Path $Stage $Name
  New-Item -ItemType Directory -Force -Path $To | Out-Null
  Copy-Item -Path (Join-Path $SrcDir "*") -Destination $To -Recurse -Force
}

# Ship-tagged allowlist: stage ONLY the named files from $Src\$Name, never the
# whole directory. Used for surfaces (commands) where some files are
# maintainer-only and must not pollute a consumer's global namespace.
function Install-Files {
  param([string]$Name, [string[]]$Files)
  $SrcDir = Join-Path $Src $Name
  if (-not (Test-Path $SrcDir)) { return }
  foreach ($rel in $Files) {
    $from = Join-Path $SrcDir $rel
    if (-not (Test-Path $from)) { continue }
    New-Item -ItemType Directory -Force -Path (Join-Path $Stage $Name) | Out-Null
    Copy-Item -LiteralPath $from -Destination (Join-Path (Join-Path $Stage $Name) $rel)
  }
}

Write-Host ""
Write-Host "${Pfx}Installing to $Root"

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
Install-Dir "hooks"

# ── Sync $Root against the staged release ─────────────────────────────────────
# Phase 1 adds/updates and plans removals; hook registration is merged next;
# phase 2 removes, prunes empty dirs and writes the manifest — so settings.json
# never points at a hook file that is not on disk, even if the merge throws.

$new = Get-TreeHashes $Stage
foreach ($rel in $new.Keys) {
  if (-not ($rel -match '^[A-Za-z0-9._@+/-]+$')) { throw "Error: release contains a path outside [A-Za-z0-9._@+-] — refusing to install: $rel" }
}
$old = Read-Manifest $Root
$all = @{}
foreach ($k in $new.Keys) { $all[$k] = 1 }
foreach ($k in $old.Keys) { $all[$k] = 1 }

$manifest = @{}
$removals = New-Object System.Collections.ArrayList
$added = 0; $updated = 0; $same = 0; $legacyKept = 0

foreach ($rel in (Get-SortedKeys $all)) {
  $target = Join-Rel $Root $rel
  $csha = if (Test-Path -LiteralPath $target -PathType Leaf) { Get-Sha $target } else { $null }
  $osha = if ($old.ContainsKey($rel)) { $old[$rel] } else { $null }
  if (-not $new.ContainsKey($rel)) {
    # Tracked by the old manifest, dropped by this release.
    if ($null -eq $csha) { continue }
    if ($csha -eq $osha) { [void]$removals.Add(@($rel, "no longer shipped")) }
    else { Warn "keep $rel — no longer shipped, but modified locally (now yours)" }
    continue
  }
  $nsha = $new[$rel]
  $manifest[$rel] = $nsha
  $from = Join-Rel $Stage $rel
  if ($null -eq $csha) {
    Copy-Placed $from $target; $added++
  } elseif ($csha -eq $nsha) {
    $same++
  } elseif ($null -ne $osha -and $csha -eq $osha) {
    Copy-Placed $from $target; Note "update $rel"; $updated++
  } elseif ($rel.StartsWith("hooks/")) {
    # Shipped hooks are security-relevant: always take the release copy.
    if (-not $DryRun) { Copy-Item -LiteralPath $target -Destination "$target.bak.$Stamp" }
    Copy-Placed $from $target
    Warn "refresh hook $rel — it differed from the release copy; yours is saved as $rel.bak.$Stamp"
    $updated++
  } elseif ($Force) {
    Copy-Placed $from $target; Note "overwrite $rel (-Force)"; $updated++
  } elseif ($null -eq $osha) {
    Warn "keep $rel — differs from the release copy and predates the manifest (-Force overwrites)"; $legacyKept++
  } else {
    Warn "keep $rel — modified locally (-Force overwrites)"
  }
}

# Retired skills from pre-manifest installs: files the old manifest does not
# track are removed only with -PruneLegacy, listed one by one first.
foreach ($t in $Tombstones) {
  $d = Join-Path (Join-Path $Root "skills") $t
  if (-not (Test-Path -LiteralPath $d -PathType Container) -or (Test-Path -LiteralPath (Join-Path (Join-Path $Stage "skills") $t))) { continue }
  $legacy = @(foreach ($f in Get-ChildItem -LiteralPath $d -Recurse -File -Force) {
    $rel = "skills/$t/" + ($f.FullName.Substring((Convert-Path -LiteralPath $d).TrimEnd('\', '/').Length + 1) -replace '\\', '/')
    if (-not $old.ContainsKey($rel)) { $rel }
  })
  if ($legacy.Count -eq 0) { continue }
  if ($PruneLegacy) {
    foreach ($rel in $legacy) { [void]$removals.Add(@($rel, "retired skill $t (-PruneLegacy)")) }
  } else {
    Warn "retired skill directory skills/$t is still installed (predates the manifest) — re-run with -PruneLegacy to remove it"
  }
}

Update-ClaudeHookSettings "merge"

$dirs = @()
foreach ($r in $removals) {
  Note "remove $($r[0]) ($($r[1]))"
  if (-not $DryRun) { Remove-Item -LiteralPath (Join-Rel $Root $r[0]) -Force }
  $dirs += (Get-RelDir $r[0])
}
Remove-EmptyDirs $Root $dirs
if (-not $DryRun) { Write-Manifest $Root $manifest }
Write-Host "  OK ${Pfx}skills, agents, commands, hooks -> $Root ($added added, $updated updated, $same unchanged)"
if ($legacyKept -gt 0) {
  Write-Host "    $legacyKept file(s) predate the manifest and differ from this release; kept. Re-run with -Force to take the release copies."
}

Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
if ($TmpDir -and (Test-Path $TmpDir)) {
  Remove-Item $TmpDir -Recurse -Force
}

Write-Host ""
Write-Host "${Pfx}Done. Restart Claude Code to load the new skills, agents, commands, and hooks."
Write-Host ""
if ($script:Warnings -gt 0) { Write-Host "$($script:Warnings) warning(s) above. Files you modified were kept; -Force overwrites them." }
Write-Host "To update later, re-run this script. To remove AgenticOS, re-run it with -Uninstall."
