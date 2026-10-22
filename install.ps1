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
#   -WithDoctrine Also install the grounding/verification/review-tier doctrine
#                 as one marked block in CLAUDE.md that imports
#                 agentic-os\doctrine.md. Opt-in. Later runs without the flag
#                 keep it current while the block is still there; deleting the
#                 block opts out.
#   -WithMarketing / -WithGames
#                 Also install that opt-in pack (kept on later runs)
#   -WithoutMarketing / -WithoutGames
#                 Remove that pack: unmodified files go, edited ones are kept
#   -Dest         Override the install destination (default: $env:USERPROFILE\.claude)
#
# Packs (same rules as install.sh): a default install ships only the core
# library. assets\packs\<pack>.txt lists each opt-in pack's skills and agents.
# Once installed, a pack stays installed on later runs (the manifest records
# it) until -Without<Pack>. An install made before packs existed keeps the
# packs whose AgenticOS files it has.
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
  [switch]$WithDoctrine,
  [switch]$WithMarketing,
  [switch]$WithGames,
  [switch]$WithoutMarketing,
  [switch]$WithoutGames,
  [string]$Dest = "$env:USERPROFILE\.claude"
)

$ErrorActionPreference = "Stop"

if ($Dest -notmatch '^[/\\:.a-zA-Z0-9._-]+$') {
  throw "Error: unsafe -Dest (shell metacharacters not allowed): $Dest"
}
if ($Uninstall -and ($Force -or $PruneLegacy)) {
  throw "Error: -Force and -PruneLegacy do not apply to -Uninstall (modified files are always kept)."
}
if ($Uninstall -and $WithDoctrine) {
  throw "Error: -WithDoctrine does not apply to -Uninstall (uninstall always removes the doctrine block)."
}

# Opt-in packs, one assets\packs\<pack>.txt each (validate.sh ship-manifest
# checks this list against those files). Keep in sync with PACKS in install.sh.
$Packs = @('games', 'marketing')
$PackSwitch = @{ 'games' = 'Games'; 'marketing' = 'Marketing' }
$WithPacks = @(); $WithoutPacks = @()
if ($WithGames) { $WithPacks += 'games' }
if ($WithMarketing) { $WithPacks += 'marketing' }
if ($WithoutGames) { $WithoutPacks += 'games' }
if ($WithoutMarketing) { $WithoutPacks += 'marketing' }
if ($Uninstall -and ($WithPacks.Count + $WithoutPacks.Count) -gt 0) {
  throw "Error: -With<Pack> and -Without<Pack> do not apply to -Uninstall (uninstall removes every AgenticOS file, pack files included)."
}
foreach ($p in $Packs) {
  if (($WithPacks -ccontains $p) -and ($WithoutPacks -ccontains $p)) {
    throw "Error: -With$($PackSwitch[$p]) and -Without$($PackSwitch[$p]) contradict each other; give one of them."
  }
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
# Hook basenames a manifest tracked that this release no longer ships, so they
# are unregistered even if $RetiredHooks forgot them.
$script:DerivedRetired = @()

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
# A relative -Dest resolves against the current dir, which may hold spaces;
# hook commands are registered unquoted, so the resolved path must not.
if (-not $Uninstall -and $Root -notmatch '^[/\\:.a-zA-Z0-9._-]+$') { throw "Error: -Dest resolves to a path with whitespace or shell metacharacters ($Root); it would be pasted into hook commands. Use a plain path (to move an existing install: -Uninstall with the same -Dest, then reinstall)." }
$Work  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $Work | Out-Null
$Stage = Join-Path $Work "stage"
$Stamp = "$(Get-Date -Format "yyyyMMddHHmmss").$PID"
$Pfx   = if ($DryRun) { "[dry-run] " } else { "" }
$script:Warnings = 0
$script:Kept = 0
$script:Unsafe = 0
$script:Foreign = 0
$script:UnsafeRels = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)

function Note([string]$Msg) { Write-Host "  $Pfx$Msg" }
function Warn([string]$Msg) { Write-Host "  ! $Pfx$Msg"; $script:Warnings++ }
function Kept([string]$Msg) { Warn $Msg; $script:Kept++ }

# ── Manifest ───────────────────────────────────────────────────────────────────

function Get-Sha([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLower() }

function Join-Rel([string]$Base, [string]$Rel) { Join-Path $Base ($Rel -replace '/', [System.IO.Path]::DirectorySeparatorChar) }

# First path components this root ships. Nothing outside them is ever written
# or removed.
$ShippedPrefixes = @('skills', 'agents', 'commands', 'hooks', 'agentic-os')

# FileInfo.Attributes reads the entry itself, so a dangling symlink/junction is
# still seen; -1 means nothing exists at $Path.
function Test-ReparsePoint([string]$Path) {
  $attr = [int](New-Object System.IO.FileInfo $Path).Attributes
  return ($attr -ne -1) -and (($attr -band [int][System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

# Write $Text to a fresh, uniquely named file beside $Target (CreateNew = fails
# if anything, link included, already has that name), then move it over
# $Target, which replaces the entry instead of writing through it.
function Write-Beside([string]$Target, [string]$Text) {
  $tmp = Join-Path (Split-Path $Target) (".agentic-os." + [System.IO.Path]::GetRandomFileName())
  $fs = [System.IO.File]::Open($tmp, [System.IO.FileMode]::CreateNew)
  try {
    $bytes = (New-Object System.Text.UTF8Encoding $false).GetBytes($Text)
    $fs.Write($bytes, 0, $bytes.Length)
  } finally { $fs.Close() }
  Move-Item -LiteralPath $tmp -Destination $Target -Force
}

# The single gate in front of every write, backup, and delete (same rules as
# install.sh safe_rel): every component is [A-Za-z0-9._@+-] and none is `.`/`..`;
# at least two components (never the manifest, settings.json, CLAUDE.md, or
# anything else at the root); the first is a shipped prefix; and no component
# from $Root down to the file is a symlink/junction (reparse point), so nothing
# is ever reached outside $Root or through a link.
function Test-SafeRel([string]$Rel) {
  # \A..\z: .NET `$` also matches before a final newline.
  if ($Rel -cnotmatch '\A[A-Za-z0-9._@+-]+(/[A-Za-z0-9._@+-]+)+\z') { return $false }
  if ("/$Rel/" -match '/\.\.?/') { return $false }
  $parts = $Rel.Split('/')
  if ($ShippedPrefixes -cnotcontains $parts[0]) { return $false }
  # agentic-os/ holds exactly one AgenticOS file.
  if ($parts[0] -ceq 'agentic-os' -and $Rel -cne 'agentic-os/doctrine.md') { return $false }
  # A skills path must name a skill AgenticOS ships or has shipped.
  if ($parts[0] -ceq 'skills' -and -not $script:SkillNames.Contains($parts[1])) { return $false }
  # Every component, the leaf included and even when it does not exist yet: a
  # dangling link at the leaf is still a link.
  $p = $Root
  foreach ($c in $parts) {
    $p = Join-Path $p $c
    if (Test-ReparsePoint $p) { return $false }
  }
  # Normalised full path must stay under the normalised root.
  $full = [System.IO.Path]::GetFullPath($p)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  return $full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)
}

function Skip-Unsafe([string]$Rel) {
  $shown = $Rel -replace "`r", '\r' -replace "`n", '\n'
  Warn "skip $shown — unsafe path (outside the shipped dirs, unusual characters, or through a symlink); not touched"
  $script:Unsafe++
  [void]$script:UnsafeRels.Add($Rel)
}

# A shipped top-level dir that is itself a symlink/junction (stow-style
# dotfiles) would turn every file in it into an unsafe-path skip. Refuse it
# once, up front (same rule as install.sh refuse_linked_dirs).
function Assert-NoLinkedDirs([string[]]$Dirs = @('skills', 'agents', 'commands', 'hooks')) {
  foreach ($d in $Dirs) {
    $p = Join-Path $Root $d
    if (Test-ReparsePoint $p) {
      throw "Error: $p is a symlink. AgenticOS never writes or deletes through a symlink, so it cannot manage that directory. Replace it with a real directory (copy the link target's contents into it), then re-run. Nothing was changed."
    }
  }
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

# rel -> sha for each well-formed manifest entry (path charset, 64 lowercase
# hex). A parse filter only; Test-SafeRel guards every action.
function Read-Manifest([string]$RootDir) {
  $map = @{}
  $mf = Join-Path $RootDir $ManifestName
  if (Test-ReparsePoint $mf) { throw "Error: $mf is a symlink — refusing to use it. Remove it and re-run." }; if (-not (Test-Path -LiteralPath $mf)) { return $map }
  $json = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
  foreach ($e in @($json.files)) {
    if (($e.path -is [string]) -and ($e.sha256 -is [string]) -and ($e.sha256 -cmatch '\A[0-9a-f]{64}\z') -and ($e.path -cmatch '\A[A-Za-z0-9._@+/-]+\z')) {
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
  [void]$sb.Append("  `"source`": `"$SourceKind`",`n  `"platform`": `"claude`",`n")
  # Every run records the packs it installed (see Set-PackPlan); [] = core only.
  $pj = (@($script:PacksOn) | ForEach-Object { "`"$_`"" }) -join ', '
  [void]$sb.Append("  `"packs`": [$pj],`n")
  if ($script:DocCreated) {
    [void]$sb.Append("  `"doctrine`": {`"created`": $($script:DocCreated), `"block_sha256`": `"$($script:DocBlockSha)`"},`n")
  }
  [void]$sb.Append("  `"files`": [`n")
  $keys = Get-SortedKeys $Entries
  for ($i = 0; $i -lt $keys.Count; $i++) {
    $sep = if ($i -lt $keys.Count - 1) { "," } else { "" }
    [void]$sb.Append("    {`"path`": `"$($keys[$i])`", `"sha256`": `"$($Entries[$keys[$i]])`"}$sep`n")
  }
  [void]$sb.Append("  ]`n}`n")
  $mf = Join-Path $RootDir $ManifestName
  if (Test-ReparsePoint $mf) { throw "Error: $mf is a symlink — refusing to write the manifest through it. Remove it and re-run." }
  Write-Beside $mf $sb.ToString()
}

# Copy to a uniquely named temp file beside $To, then move it over $To, so the
# write never goes through an existing hard link or symlink at the target.
function Copy-Placed([string]$From, [string]$To) {
  if ($DryRun) { return }
  $dir = Split-Path $To
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $tmp = Join-Path $dir (".agentic-os." + [System.IO.Path]::GetRandomFileName())
  Copy-Item -LiteralPath $From -Destination $tmp
  Move-Item -LiteralPath $tmp -Destination $To -Force
}

# rel`tsha of every file in every earlier release (assets/release-hashes.txt,
# generated by scripts/gen-release-hashes.sh): lets adoption of a pre-manifest
# install tell an untouched old-release file from a user edit.
$script:KnownHashes = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
$script:SkillNames  = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
$ReleaseHashes = Join-Path $RepoRoot "assets\release-hashes.txt"
if (Test-Path -LiteralPath $ReleaseHashes) {
  foreach ($line in Get-Content -LiteralPath $ReleaseHashes) {
    if ($line -cmatch '^([0-9a-f]{64})  ([A-Za-z0-9._@+/-]+)$') {
      [void]$script:KnownHashes.Add("$($Matches[2])`t$($Matches[1])")
      if ($Matches[2] -cmatch '^skills/([^/]+)/') { [void]$script:SkillNames.Add($Matches[1]) }
    }
  }
}
foreach ($t in $Tombstones) { [void]$script:SkillNames.Add($t) }
foreach ($d in Get-ChildItem -LiteralPath (Join-Path $Src "skills") -Directory -ErrorAction SilentlyContinue) { [void]$script:SkillNames.Add($d.Name) }

# On-disk sha $Csha of $Rel is an AgenticOS copy: the manifest's, or any
# earlier release's copy of that path.
function Test-Unmodified([string]$Rel, $Csha, $Osha) {
  if ($null -eq $Csha) { return $false }
  if ($null -ne $Osha -and $Csha -eq $Osha) { return $true }
  return $script:KnownHashes.Contains("$Rel`t$Csha")
}

# Remove now-empty directories from each listed rel dir up to (never including) root.
function Remove-EmptyDirs([string]$RootDir, $RelDirs) {
  if ($DryRun) { return }
  foreach ($d in @($RelDirs | Sort-Object -Unique -Descending)) {
    $cur = $d
    while ($cur -and $cur -ne '.') {
      $p = Join-Rel $RootDir $cur
      if (Test-ReparsePoint $p) { break }
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
# handlers everywhere. Mode "check": run the merge without writing, so an
# unmergeable settings.json fails before anything is copied. A non-object `hooks` (or, merging, a non-array shipped
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
  $retCmds = @(@($RetiredHooks) + @($script:DerivedRetired) | Where-Object { $_ } | ForEach-Object { "bash `$HOME/.claude/hooks/$_" })
  $retSet = New-OwnedSet $retCmds
  $allSet = New-OwnedSet (@($tplCmds) + $retCmds)

  if (Test-ReparsePoint $DestFile) {
    throw "Error: $DestFile is a symlink — AgenticOS will not rewrite it. Merge the hooks by hand, or replace it with a regular file. Nothing was changed."
  }
  if (-not (Test-Path $DestFile)) {
    if ($Mode -eq "check") { return }
    if ($Mode -eq "uninstall") { Write-Host "  . no $DestFile — no hook entries to unregister"; return }
    # Fresh file: write the rewritten template VERBATIM (no JSON round-trip, so
    # the Windows PowerShell 5.1 single-element-array unwrap cannot happen).
    if ($DryRun) { Note "merge AgenticOS hook registration into $DestFile"; return }
    Write-Beside $DestFile $rewritten
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
  $stripSet = if ($Mode -eq "uninstall") { $allSet } else { $retSet }
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
  if ($Mode -ne "uninstall") {
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
  # "check" only proves the merge would succeed (it throws otherwise).
  if ($Mode -eq "check") { return }
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
  # Write-Beside emits UTF-8 WITHOUT a BOM on BOTH PS 5.1 and 7. (`Set-Content
  # -Encoding utf8` writes a BOM on 5.1, which a strict JSON parser — e.g. Node
  # JSON.parse — rejects, silently breaking hook loading.)
  Write-Beside $DestFile ($destJson | ConvertTo-Json -Depth 100)
  if ($Mode -eq "merge") { Write-Host "  OK hooks active -> $DestFile" }
}

# ── Doctrine block (-WithDoctrine) ─────────────────────────────────────────────
# Same rules as install.sh (see its doctrine_plan): one marked block at the top
# of CLAUDE.md that imports agentic-os/doctrine.md, followed by one blank line
# when the file already had content. Lines outside the block never change
# except that separator, which uninstall takes out again (not for a file the
# installer created, which never got one). Markers match with an optional
# trailing CR, and the block is written in the file's own line ending. Text is
# handled as ISO-8859-1 so every byte round-trips unchanged. The manifest
# records whether the installer created the file and the LF-normalised sha of
# the block. Modes: write / handsoff / optout / off, decided before any write;
# an explicit -WithDoctrine turns every handsoff case into a refusal.
# Single-quoted file names: validate.sh reads double-quoted names ending in .md
# as shipped commands.

$DocBegin = '<!-- agentic-os:doctrine:begin -->'
$DocEnd   = '<!-- agentic-os:doctrine:end -->'
$DocTarget = Join-Path $Root 'CLAUDE.md'
$DoctrineSrc = Join-Path $RepoRoot (Join-Path 'assets' (Join-Path 'consumer' 'doctrine.md'))
$DoctrineRel = 'agentic-os/doctrine.md'
$Latin1 = [System.Text.Encoding]::GetEncoding(28591)
$DocBlockLf = "$DocBegin`n@$DoctrineRel`n$DocEnd`n"
$script:DocMode = 'off'
$script:DocWhy = ''
$script:DocCreated = $null
$script:DocWritten = $null   # sha of what Install-DoctrineBlock wrote (rollback guard)
$script:DocPre = $null       # the target's bytes before that write ($null: it did not exist)
$script:DocBlockSha = $null

function Get-TextSha([string]$Text) {
  $h = [System.Security.Cryptography.SHA256]::Create()
  try { return (($h.ComputeHash($Latin1.GetBytes($Text)) | ForEach-Object { $_.ToString('x2') }) -join '') } finally { $h.Dispose() }
}

function Read-DoctrineRecord {
  $mf = Join-Path $Root $ManifestName
  if ((Test-ReparsePoint $mf) -or -not (Test-Path -LiteralPath $mf -PathType Leaf)) { return $null }
  $json = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
  $d = $json.PSObject.Properties['doctrine']
  if ($d -and ($d.Value.created -is [bool]) -and ($d.Value.block_sha256 -is [string]) -and ($d.Value.block_sha256 -cmatch '^[0-9a-f]{64}$')) {
    return $d.Value
  }
  return $null
}

function Test-Marker([string]$Line, [string]$Marker) { return ($Line -ceq $Marker) -or ($Line -ceq "$Marker`r") }

# @{ Lines; NB; NE; B; E; Crlf } (B/E = -1 when absent, 0-based).
function Get-DocLines([string]$Text) {
  $lines = $Text -split "`n"
  $nb = 0; $ne = 0; $b = -1; $e = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if (Test-Marker $lines[$i] $DocBegin) { $nb++; if ($b -lt 0) { $b = $i } }
    if (Test-Marker $lines[$i] $DocEnd) { $ne++; if ($e -lt 0) { $e = $i } }
  }
  return @{ Lines = $lines; NB = $nb; NE = $ne; B = $b; E = $e; Crlf = ($lines.Count -gt 1 -and $lines[0].EndsWith("`r")) }
}

function Join-Lines($Lines, [int]$From, [int]$To) {
  if ($To -lt $From) { return '' }
  return ($Lines[$From..$To] -join "`n")
}

function Get-CurBlockSha($D) { return Get-TextSha (((Join-Lines $D.Lines $D.B $D.E) -replace "`r(?=`n|$)", '') + "`n") }

function Read-Latin1([string]$Path) { return $Latin1.GetString([System.IO.File]::ReadAllBytes($Path)) }

# Why $DocTarget may not be rewritten ('' when it may).
function Get-DocUnsafeReason {
  if (Test-ReparsePoint $DocTarget) { return 'is a symlink' }
  if (-not (Test-Path -LiteralPath $DocTarget)) { return '' }
  if (-not (Test-Path -LiteralPath $DocTarget -PathType Leaf)) { return 'is not a regular file' }
  if ((Get-Item -LiteralPath $DocTarget -Force).LinkType -eq 'HardLink') { return 'is hard-linked elsewhere' }
  return ''
}

function Assert-DocUnchanged {
  $why = Get-DocUnsafeReason
  if ($why) { throw "Error: $DocTarget $why (it changed during the install) — not written. Re-run to finish." }
}

# Write via a fresh temp file beside the target, then move it over. The
# target's attributes and (on Windows) ACL are copied to the temp file first.
function Write-BesideBytes([string]$Target, [string]$Text) {
  $dir = Split-Path $Target
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Assert-DocUnchanged
  $tmp = Join-Path $dir (".agentic-os." + [System.IO.Path]::GetRandomFileName())
  $fs = [System.IO.File]::Open($tmp, [System.IO.FileMode]::CreateNew)
  try { $bytes = $Latin1.GetBytes($Text); $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Close() }
  if (Test-Path -LiteralPath $Target -PathType Leaf) {
    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
      Set-Acl -LiteralPath $tmp -AclObject (Get-Acl -LiteralPath $Target)
    }
    $attrs = [System.IO.File]::GetAttributes($Target) -band (-bnot [System.IO.FileAttributes]::ReadOnly)
    [System.IO.File]::SetAttributes($tmp, $attrs)
  }
  Assert-DocUnchanged
  Move-Item -LiteralPath $tmp -Destination $Target -Force
}

function Backup-DocTarget {
  $bak = "$DocTarget.bak.$Stamp"; $n = 1
  while ((Test-Path -LiteralPath $bak) -or (Test-ReparsePoint $bak)) { $bak = "$DocTarget.bak.$Stamp.$n"; $n++ }
  if (-not $DryRun) { Copy-Item -LiteralPath $DocTarget -Destination $bak }
  return $bak
}

function Write-DocHandsOff {
  Warn "$DocTarget $($script:DocWhy) — AgenticOS leaves it untouched. If it holds the AgenticOS doctrine block, delete the lines from '$DocBegin' to '$DocEnd' by hand."
}

# Decide $script:DocMode before anything is written.
function Set-DoctrinePlan($Record) {
  if (-not ($WithDoctrine -or $Uninstall -or $Record)) { return }
  if (-not $Uninstall -and -not (Test-Path -LiteralPath $DoctrineSrc -PathType Leaf)) {
    throw "Error: $DoctrineSrc is missing from this release — cannot install the doctrine. Nothing was changed."
  }
  $script:DocBlockSha = Get-TextSha $DocBlockLf
  $why = Get-DocUnsafeReason
  if ($why) { $state = 'unsafe' }
  elseif (-not (Test-Path -LiteralPath $DocTarget)) { $state = 'absent' }
  else {
    $d = Get-DocLines (Read-Latin1 $DocTarget)
    if ($d.NB -ne $d.NE -or $d.NB -gt 1 -or ($d.NB -eq 1 -and $d.B -ge $d.E)) {
      $state = 'malformed'; $why = "has malformed AgenticOS doctrine markers ($($d.NB) begin, $($d.NE) end)"
    } elseif ($d.NB -eq 0) { $state = 'none' }
    else {
      $state = 'block'
      # Ours only if it is the block AgenticOS writes (the Claude block never
      # changes); a manifest record is no proof.
      if ((Get-CurBlockSha $d) -ne $script:DocBlockSha) {
        $state = 'foreign'; $why = 'holds an AgenticOS doctrine block that matches no block AgenticOS has shipped (edited by hand, or not written by AgenticOS)'
      }
    }
  }
  if ($WithDoctrine) {
    if ($state -eq 'unsafe') { throw "Error: $DocTarget $why — AgenticOS will not rewrite it. Replace it with a regular file, or install without -WithDoctrine. Nothing was changed." }
    if ($state -eq 'malformed') { throw "Error: $DocTarget $why. Fix or remove the $DocBegin ... $DocEnd lines by hand. Nothing was changed." }
    # An edited block of a recorded install is refreshed (after a .bak).
    # With no record, even a shipped block may be quoted text: never adopt it.
    if ($state -eq 'foreign' -and -not $Record) { throw "Error: $DocTarget has an AgenticOS-format doctrine block that is not a block AgenticOS shipped, and no install record. Remove the $DocBegin ... $DocEnd lines by hand, then re-run. Nothing was changed." }
    if ($state -eq 'block' -and -not $Record) { throw "Error: $DocTarget holds a shipped AgenticOS doctrine block, but no install record says AgenticOS wrote it (it may be quoted, e.g. in a code fence). Remove the $DocBegin ... $DocEnd lines by hand, then re-run. Nothing was changed." }
    $script:DocMode = 'write'
  } elseif ($Uninstall) {
    # Unsafe with no record: nothing says AgenticOS wrote there, so 'off'.
    if (($state -eq 'unsafe' -and $Record) -or $state -eq 'malformed' -or $state -eq 'foreign') { $script:DocMode = 'handsoff'; $script:DocWhy = $why }
    # A shipped block with no record may be quoted text: only a record makes it ours.
    elseif ($state -eq 'block' -and $Record) { $script:DocMode = 'write' }
    elseif ($state -eq 'block') { $script:DocMode = 'handsoff'; $script:DocWhy = 'holds an AgenticOS doctrine block, but no install record says AgenticOS put it there (it may be quoted text)' }
  } else {
    if ($state -eq 'unsafe' -or $state -eq 'malformed' -or $state -eq 'foreign') { $script:DocMode = 'handsoff'; $script:DocWhy = $why }
    elseif ($state -eq 'block') { $script:DocMode = 'write' }
    else { $script:DocMode = 'optout' }
  }
}

function Install-DoctrineBlock($Record) {
  if ($script:DocMode -eq 'handsoff') {
    Write-DocHandsOff
    $script:DocCreated = if ($Record.created) { 'true' } else { 'false' }
    $script:DocBlockSha = $Record.block_sha256
    return
  }
  if ($script:DocMode -eq 'optout') {
    Note "no AgenticOS doctrine block in $DocTarget — treating that as an opt-out: the doctrine is no longer installed or kept current. Re-run with -WithDoctrine to add it back."
    return
  }
  if ($script:DocMode -ne 'write') { return }
  if (-not (Test-Path -LiteralPath $DocTarget)) {
    $script:DocCreated = 'true'
    Note "create $DocTarget with the AgenticOS doctrine block"
    if (-not $DryRun) { $script:DocPre = $null; $script:DocWritten = Get-TextSha $DocBlockLf; Write-BesideBytes $DocTarget $DocBlockLf }
    return
  }
  $text = Read-Latin1 $DocTarget
  $d = Get-DocLines $text
  # The file existed: "created" survives only for a block already in a file
  # this install created.
  $script:DocCreated = if ($d.B -ge 0 -and $Record -and $Record.created) { 'true' } else { 'false' }
  $eol = if ($d.Crlf) { "`r`n" } else { "`n" }
  $blk = $DocBlockLf.Replace("`n", $eol)
  if ($d.B -lt 0) {
    $new = if ($text.Length -gt 0) { $blk + $eol + $text } else { $blk }
    Note "add the AgenticOS doctrine block to the top of $DocTarget"
  } else {
    $cur = (Join-Lines $d.Lines $d.B $d.E) + "`n"
    if ($cur -ceq $blk) { return }
    $curSha = Get-CurBlockSha $d
    $prefix = if ($d.B -gt 0) { (Join-Lines $d.Lines 0 ($d.B - 1)) + "`n" } else { '' }
    $new = $prefix + $blk + (Join-Lines $d.Lines ($d.E + 1) ($d.Lines.Count - 1))
    if ($curSha -eq $script:DocBlockSha) {
      Note "update the AgenticOS doctrine block in $DocTarget"
    } else {
      $bak = Backup-DocTarget
      Warn "refresh the doctrine block in $DocTarget — it differed from what AgenticOS wrote; the whole file is saved as $bak"
    }
  }
  if (-not $DryRun) { $script:DocPre = $text; $script:DocWritten = Get-TextSha $new; Write-BesideBytes $DocTarget $new }
}

function Remove-DoctrineBlock($Record) {
  if ($script:DocMode -eq 'handsoff') { Write-DocHandsOff; return }
  if ($script:DocMode -ne 'write') { return }
  # Re-check right before writing: the block may have changed since the plan.
  $d = Get-DocLines (Read-Latin1 $DocTarget)
  if ($d.NB -ne 1 -or $d.NE -ne 1 -or $d.B -ge $d.E -or (Get-CurBlockSha $d) -ne $script:DocBlockSha) {
    $script:DocWhy = 'changed during the uninstall and no longer holds a block AgenticOS shipped'
    $script:DocMode = 'handsoff'   # so the uninstall loop keeps the doctrine file it may import
    Write-DocHandsOff
    return
  }
  $created = [bool]($Record -and $Record.created)
  $rest = Join-Lines $d.Lines ($d.E + 1) ($d.Lines.Count - 1)
  if ($d.B -eq 0) {
    if (-not $created) {
      if ($rest.StartsWith("`r`n")) { $rest = $rest.Substring(2) } elseif ($rest.StartsWith("`n")) { $rest = $rest.Substring(1) }
    }
    $new = $rest
  } else {
    $new = (Join-Lines $d.Lines 0 ($d.B - 1)) + "`n" + $rest
  }
  if ($new.Length -eq 0 -and $created) {
    Note "remove $DocTarget (created by AgenticOS, now empty)"
    if (-not $DryRun) { Assert-DocUnchanged; Remove-Item -LiteralPath $DocTarget -Force }
  } else {
    Note "remove the AgenticOS doctrine block from $DocTarget"
    if (-not $DryRun) { Write-BesideBytes $DocTarget $new }
  }
}

$DocRecord = Read-DoctrineRecord
Set-DoctrinePlan $DocRecord
# Stage and record the doctrine while it is managed or left hands-off.
$Doctrine = $script:DocMode -eq 'write' -or $script:DocMode -eq 'handsoff'

# ── Uninstall ──────────────────────────────────────────────────────────────────

if ($Uninstall) {
  Write-Host ""
  Write-Host "${Pfx}Uninstalling AgenticOS from $Root"
  # Unregister hooks BEFORE deleting files: if the settings rewrite fails, the
  # hook scripts it still points at are left in place.
  Write-Host ""
  Assert-NoLinkedDirs
  Write-Host "Hook registration: $(Join-Path $Root 'settings.json')"
  $script:DerivedRetired = @((Read-Manifest $Root).Keys | Where-Object { $_ -cmatch '^hooks/[A-Za-z0-9._-]+\.sh$' } | ForEach-Object { $_.Substring(6) })
  if (Test-Path -LiteralPath $Root) { Update-ClaudeHookSettings "uninstall" }
  # The block goes before the doctrine file it imports.
  if ($script:DocMode -ne 'off') { Write-Host ""; Write-Host "Doctrine: $DocTarget"; Remove-DoctrineBlock $DocRecord }
  Write-Host ""
  $mf = Join-Path $Root $ManifestName
  if (-not (Test-Path -LiteralPath $mf)) {
    Write-Host "  . no $ManifestName — nothing tracked to remove (a pre-manifest install: run the installer once to adopt it, then uninstall)"
  } else {
    $old = Read-Manifest $Root
    $dirs = @(); $removed = 0; $kept = 0
    foreach ($rel in (Get-SortedKeys $old)) {
      if (-not (Test-SafeRel $rel)) { Skip-Unsafe $rel; continue }
      $target = Join-Rel $Root $rel
      if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
      if ($script:DocMode -eq 'handsoff' -and $rel -ceq $DoctrineRel) {
        # The CLAUDE.md block left in place may still import it.
        Warn "keep $rel — the CLAUDE.md block AgenticOS could not remove may still import it; delete it after removing that block"
        continue
      }
      if (Test-Unmodified $rel (Get-Sha $target) $old[$rel]) {
        Note "remove $rel"
        if (-not $DryRun) { Remove-Item -LiteralPath $target -Force }
        $dirs += (Get-RelDir $rel); $removed++
      } else {
        Kept "keep $rel — modified locally"; $kept++
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
  Write-Host "${Pfx}Uninstall complete: $($script:Kept) modified file(s) kept, $($script:Unsafe) unsafe path(s) skipped. Hook backups (*.bak.*) and files you created were not touched."
  exit 0
}

# ── Opt-in packs (-With<Pack>) ─────────────────────────────────────────────────
# Same rules as install.sh pack_plan. A pack is installed when its -With<Pack>
# switch is given, or the previous manifest lists it under "packs", or the
# manifest has no "packs" key (an install made before packs existed) and
# tracks any of its files, or there is no manifest at all (a pre-manifest
# release) and an AgenticOS copy (hash-matched) of one of its files is on
# disk. -Without<Pack> overrides all
# three. An unselected pack is simply not staged, so its files go through the
# normal prune below: unmodified ones are removed, edited ones kept.

$PackEntryRe = '^(skills/[a-z0-9-]+|agents/[a-z0-9-]+[.]md)$'
$script:PacksOn = @()
$script:PacksOff = @()   # entries of every unselected pack
$script:PackAdopt = @{}   # rel -> sha of pre-manifest files of a -Without pack

# Validated entries of pack $Pack (validate.sh checks them too; the installer
# re-checks because it deletes staged paths by them).
function Read-PackList([string]$Pack) {
  $f = Join-Path (Join-Path (Join-Path $RepoRoot "assets") "packs") "$Pack.txt"
  if ((Test-ReparsePoint $f) -or -not (Test-Path -LiteralPath $f -PathType Leaf)) {
    throw "Error: $f is missing (or a symlink): this payload predates opt-in packs or is incomplete. Use the install.ps1 from the same release as the payload (the pinned one-liner URL), or install from a local clone. Nothing was changed."
  }
  $out = @()
  foreach ($line in Get-Content -LiteralPath $f) {
    $l = $line.TrimEnd("`r")
    if ($l -match '^\s*(#|$)') { continue }
    if ($l -cnotmatch $PackEntryRe) { throw "Error: $f lists '$l', which is not skills/<name> or agents/<name>.md. Nothing was changed." }
    $out += $l
  }
  return ,$out
}

# Pack names in the previous manifest's "packs" array; $null when there is no
# manifest or it has no "packs" key (written before packs existed).
function Read-PacksRecord {
  $mf = Join-Path $Root $ManifestName
  if ((Test-ReparsePoint $mf) -or -not (Test-Path -LiteralPath $mf -PathType Leaf)) { return $null }
  $json = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
  $prop = $json.PSObject.Properties['packs']
  if (-not $prop) { return $null }
  return ,@(@($prop.Value) | Where-Object { ($_ -is [string]) -and ($_ -cmatch '^[a-z0-9-]+$') })
}

# Why $Root holds pack list $Entries (same rules as install.sh pack_tracked /
# pack_shipped_file): 'tracked' when a manifest written before packs existed
# tracks one of its files; with no manifest, "disk:<rel>" for the first file
# that is an AgenticOS copy (a regular file reached through no link whose sha
# is that path's copy in an earlier release or in this release's source), so
# an empty dir, a link, or the user's own skill of the same name counts for
# nothing. '' when none.
function Get-PackEvidence($Entries) {
  $mf = Join-Path $Root $ManifestName
  if (Test-ReparsePoint $mf) { return '' }   # the sync below refuses it
  if (Test-Path -LiteralPath $mf) {
    $paths = @((Read-Manifest $Root).Keys)
    foreach ($e in $Entries) {
      if ($e.StartsWith('skills/')) {
        if (@($paths | Where-Object { $_.StartsWith("$e/", [StringComparison]::Ordinal) }).Count -gt 0) { return 'tracked' }
      } elseif ($paths -ccontains $e) { return 'tracked' }
    }
    return ''
  }
  $first = @(Get-PackShippedFiles $Entries -First)
  if ($first.Count -gt 0) { return "disk:$($first[0].Rel)" }
  return ''
}

# A {Rel, Sha} object for each file of pack list $Entries under $Root that is an
# AgenticOS copy (same rules as install.sh pack_shipped_files): a regular file
# reached through no link whose sha is that path's copy in an earlier release
# or in this release's source. -First stops at the first. -All also returns
# every other regular file reached through no link, with Sha = $null (an
# edit, or the user's own).
function Get-PackShippedFiles($Entries, [switch]$First, [switch]$All) {
  $found = @()
  foreach ($e in $Entries) {
    $p = $Root; $linked = $false
    foreach ($c in $e.Split('/')) { $p = Join-Path $p $c; if (Test-ReparsePoint $p) { $linked = $true } }
    if ($linked -or -not (Test-Path -LiteralPath $p)) { continue }
    # Walk by hand: Get-ChildItem -Recurse follows junctions and directory
    # symlinks in Windows PowerShell 5.1, so never enter a reparse-point dir.
    $files = @()
    if (Test-Path -LiteralPath $p -PathType Container) {
      $dirs = New-Object System.Collections.Stack
      $dirs.Push($p)
      while ($dirs.Count -gt 0) {
        foreach ($ch in @(Get-ChildItem -LiteralPath $dirs.Pop() -Force)) {
          if (Test-ReparsePoint $ch.FullName) { continue }
          if ($ch.PSIsContainer) { $dirs.Push($ch.FullName) } else { $files += $ch }
        }
      }
    } else {
      $files = @(Get-Item -LiteralPath $p -Force)
    }
    $rootFull = (Convert-Path -LiteralPath $Root).TrimEnd('\', '/')
    foreach ($f in $files) {
      if (Test-ReparsePoint $f.FullName) { continue }
      $rel = $f.FullName.Substring($rootFull.Length + 1) -replace '\\', '/'
      # Same charset as Test-SafeRel; \A..\z because .NET `$` also matches
      # before a final newline. A name with a tab, CR or LF never becomes a key.
      if ($rel -cnotmatch '\A[A-Za-z0-9._@+-]+(/[A-Za-z0-9._@+-]+)+\z') {
        Warn "skip $($rel -replace '[\x00-\x1f\x7f]', '?') — unusual characters in the name; not an AgenticOS file, not touched"
        continue
      }
      $sha = Get-Sha $f.FullName
      $srcf = Join-Rel $Src $rel
      if ($script:KnownHashes.Contains("$rel`t$sha") -or ((Test-Path -LiteralPath $srcf -PathType Leaf) -and -not (Test-ReparsePoint $srcf) -and (Get-Sha $srcf) -eq $sha)) {
        $found += [pscustomobject]@{ Rel = $rel; Sha = $sha }
        if ($First) { return $found }
      } elseif ($All) {
        $found += [pscustomobject]@{ Rel = $rel; Sha = $null }
      }
    }
  }
  return $found
}

function Set-PackPlan {
  $rec = Read-PacksRecord
  Write-Host ""
  Write-Host "${Pfx}Opt-in packs:"
  foreach ($p in $Packs) {
    $entries = Read-PackList $p
    $sw = $PackSwitch[$p]
    $why = ''
    if ($WithoutPacks -ccontains $p) { $why = '' }
    elseif ($WithPacks -ccontains $p) { $why = 'flag' }
    elseif (($null -ne $rec) -and ($rec -ccontains $p)) { $why = 'recorded' }
    elseif ($null -eq $rec) {
      $ev = Get-PackEvidence $entries
      if ($ev -ceq 'tracked') { $why = 'tracked' } elseif ($ev) { $why = 'ondisk'; $evRel = $ev.Substring(5) }
    }
    switch ($why) {
      'flag' { Note "${p}: installed (-With$sw)" }
      'recorded' { Note "${p}: kept, as recorded in the install manifest; re-run with -Without$sw to remove it" }
      'tracked' { Note "${p}: kept, because the install manifest (written before packs existed) tracks its files; re-run with -Without$sw to remove it" }
      'ondisk' { Note "${p}: kept, because AgenticOS copies of its files are installed here with no manifest (e.g. $evRel); re-run with -Without$sw to remove it" }
      default {
        $script:PacksOff += $entries
        if ($WithoutPacks -ccontains $p) {
          Note "${p}: not installed (-Without$sw); unmodified files from it are removed, edited ones kept"
          # No manifest (a pre-manifest install): hand the pack's AgenticOS
          # copies to the sync below as if an old manifest tracked them, so the
          # normal "no longer shipped" prune removes them (install.sh pack_adopt).
          $mf = Join-Path $Root $ManifestName
          if (-not (Test-Path -LiteralPath $mf) -and -not (Test-ReparsePoint $mf)) {
            foreach ($hit in @(Get-PackShippedFiles $entries -All)) {
              if ($null -ne $hit.Sha) { $script:PackAdopt[$hit.Rel] = $hit.Sha }
              else { Warn "keep $($hit.Rel) — in the $p pack's dirs but not an AgenticOS release copy (edited, or yours), and no manifest tracks it; left in place, remove it by hand if you no longer want it" }
            }
          }
        }
        else { Note "${p}: not installed (add it with -With$sw)" }
      }
    }
    if ($why) { $script:PacksOn += $p }
  }
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

Set-PackPlan
Write-Host ""
Write-Host "${Pfx}Installing to $Root"

Install-Dir "skills"
Install-Dir "agents"
foreach ($e in $script:PacksOff) {
  $t = Join-Rel $Stage $e
  if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
}
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
if ($Doctrine) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Stage 'agentic-os') | Out-Null
  Copy-Item -LiteralPath $DoctrineSrc -Destination (Join-Rel $Stage $DoctrineRel)
}

# ── Sync $Root against the staged release ─────────────────────────────────────
# Phase 1 adds/updates and plans removals; hook registration is merged next;
# phase 2 removes, prunes empty dirs and writes the manifest — so settings.json
# never points at a hook file that is not on disk, even if the merge throws.

foreach ($item in Get-ChildItem -LiteralPath $Stage -Recurse -Force) {
  if ($item.Name -cnotmatch '^[A-Za-z0-9._@+-]+$') { throw "Error: release contains a path outside [A-Za-z0-9._@+-] — refusing to install: $($item.FullName)" }
}
# Fail fast, before anything is copied: a symlinked shipped dir or an
# unmergeable settings.json throws here.
Assert-NoLinkedDirs
if ($Doctrine) { Assert-NoLinkedDirs @('agentic-os') }
Update-ClaudeHookSettings "check"
$new = Get-TreeHashes $Stage
$old = Read-Manifest $Root
foreach ($k in @($script:PackAdopt.Keys)) {
  if (($k -cmatch '\A[A-Za-z0-9._@+-]+(/[A-Za-z0-9._@+-]+)+\z') -and ($script:PackAdopt[$k] -cmatch '\A[0-9a-f]{64}\z') -and -not $old.ContainsKey($k)) { $old[$k] = $script:PackAdopt[$k] }
}
$all = @{}
foreach ($k in $new.Keys) { $all[$k] = 1 }
foreach ($k in $old.Keys) { $all[$k] = 1 }

$manifest = @{}
$removals = New-Object System.Collections.ArrayList
$added = 0; $updated = 0; $same = 0; $legacyKept = 0

foreach ($rel in (Get-SortedKeys $all)) {
  if (-not (Test-SafeRel $rel)) { Skip-Unsafe $rel; continue }
  $target = Join-Rel $Root $rel
  $csha = if (Test-Path -LiteralPath $target -PathType Leaf) { Get-Sha $target } else { $null }
  $osha = if ($old.ContainsKey($rel)) { $old[$rel] } else { $null }
  if (-not $new.ContainsKey($rel)) {
    # Tracked by the old manifest, dropped by this release.
    if ($rel -cmatch '^hooks/[A-Za-z0-9._-]+\.sh$') { $script:DerivedRetired += $rel.Substring(6) }
    if ($null -eq $csha) { continue }
    if (Test-Unmodified $rel $csha $osha) { [void]$removals.Add(@($rel, "no longer shipped")) }
    else {
      # Stays tracked, so uninstall and -PruneLegacy still see it as modified.
      $manifest[$rel] = $osha
      Kept "keep $rel — no longer shipped, but modified locally"
    }
    continue
  }
  $nsha = $new[$rel]
  $manifest[$rel] = $nsha
  $from = Join-Rel $Stage $rel
  if ($null -eq $csha) {
    Copy-Placed $from $target; $added++
  } elseif ($csha -eq $nsha) {
    $same++
  } elseif (Test-Unmodified $rel $csha $osha) {
    Copy-Placed $from $target; Note "update $rel"; $updated++
  } elseif ($rel.StartsWith("hooks/")) {
    # Shipped hooks are security-relevant: always take the release copy.
    $bak = "$rel.bak.$Stamp"; $n = 1
    while ((Test-Path -LiteralPath (Join-Rel $Root $bak)) -or (Test-ReparsePoint (Join-Rel $Root $bak))) { $bak = "$rel.bak.$Stamp.$n"; $n++ }
    if (-not $DryRun) { Copy-Item -LiteralPath $target -Destination (Join-Rel $Root $bak) }
    Copy-Placed $from $target
    Warn "refresh hook $rel — it differed from the release copy; yours is saved as $bak"
    $updated++
  } elseif ($Force) {
    Copy-Placed $from $target; Note "overwrite $rel (-Force)"; $updated++
  } elseif ($null -eq $osha) {
    Kept "keep $rel — differs from the release copy and predates the manifest (-Force overwrites)"; $legacyKept++
  } else {
    Kept "keep $rel — modified locally (-Force overwrites)"
  }
}

# Retired skills from pre-manifest installs: files the old manifest does not
# track are removed only with -PruneLegacy, listed one by one first.
foreach ($t in $Tombstones) {
  $d = Join-Path (Join-Path $Root "skills") $t
  if (-not (Test-Path -LiteralPath $d -PathType Container) -or (Test-Path -LiteralPath (Join-Path (Join-Path $Stage "skills") $t))) { continue }
  if (Test-ReparsePoint $d) { Warn "skip retired skill skills/$t — it is a symlink; not touched"; continue }
  $legacy = @(foreach ($f in Get-ChildItem -LiteralPath $d -Recurse -File -Force) {
    $rel = "skills/$t/" + ($f.FullName.Substring((Convert-Path -LiteralPath $d).TrimEnd('\', '/').Length + 1) -replace '\\', '/')
    if (-not $rel.StartsWith("skills/$t/") -or -not (Test-SafeRel $rel)) { Skip-Unsafe $rel; continue }
    if (-not $old.ContainsKey($rel)) { $rel }
  })
  if ($legacy.Count -eq 0) { continue }
  # Only a byte-exact copy of an earlier AgenticOS release of that path is ours
  # to delete; anything else (user notes, another tool's files) stays.
  $prunable = 0; $foreign = 0
  foreach ($rel in $legacy) {
    if (Test-Unmodified $rel (Get-Sha (Join-Rel $Root $rel)) $null) {
      $prunable++
      if ($PruneLegacy) { [void]$removals.Add(@($rel, "retired skill $t (-PruneLegacy)")) }
    } else {
      $foreign++
      if ($PruneLegacy) { Warn "keep $rel — not an AgenticOS release file (retired skill $t); it is yours to keep or remove"; $script:Foreign++ }
    }
  }
  if (-not $PruneLegacy) {
    if ($prunable -gt 0) { Warn "retired skill directory skills/$t still holds $prunable AgenticOS file(s) from an earlier release — re-run with -PruneLegacy to remove them" }
    elseif ($foreign -gt 0) { Note "retired skill directory skills/$t holds only files that are not AgenticOS release files; they are yours to keep or remove" }
  }
}

# Every shipped hook must be on disk as a regular file at the release SHA
# before it is registered; otherwise settings.json would run whatever is there.
# A dry run fails on hooks it would have had to skip. On any miss: register
# nothing, write no manifest, exit non-zero (same as install.sh verify_hooks).
$badHooks = @(foreach ($rel in (Get-SortedKeys $new)) {
  if (-not $rel.StartsWith("hooks/")) { continue }
  $t = Join-Rel $Root $rel
  if ($DryRun) { if ($script:UnsafeRels.Contains($rel)) { $rel } }
  elseif (-not (Test-Path -LiteralPath $t -PathType Leaf) -or (Test-ReparsePoint $t) -or ((Get-Sha $t) -ne $new[$rel])) { $rel }
})
if ($badHooks.Count -gt 0) {
  foreach ($h in $badHooks) { Write-Host "  X hook $h is not installed at the release version" }
  Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
  throw "Error: not every AgenticOS hook could be installed at the release version. Files that could be placed were already copied; only hook registration and the manifest update were withheld (planned removals were skipped too). Fix the paths reported above, then re-run to finish."
}

$docFile = Join-Rel $Root $DoctrineRel
if ($script:DocMode -eq 'write' -and -not $DryRun -and (-not (Test-Path -LiteralPath $docFile -PathType Leaf) -or (Test-ReparsePoint $docFile))) {
  Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
  throw "Error: $docFile could not be installed, so CLAUDE.md was not given an import of it; hook registration and the manifest update were withheld. Fix the path reported above, then re-run."
}
Update-ClaudeHookSettings "merge"
# From the doctrine edit until the manifest records it, any stop (a throw,
# Ctrl-C) puts the target back, so a re-run never meets an unrecorded block.
# The restore happens only if the target still holds exactly what was written.
$manifestLanded = $false
try {
  Install-DoctrineBlock $DocRecord

  $dirs = @()
  foreach ($r in $removals) {
    # Re-checked at the point of deletion.
    if (-not (Test-SafeRel $r[0])) { Skip-Unsafe $r[0]; continue }
    Note "remove $($r[0]) ($($r[1]))"
    if (-not $DryRun) { Remove-Item -LiteralPath (Join-Rel $Root $r[0]) -Force }
    $dirs += (Get-RelDir $r[0])
  }
  Remove-EmptyDirs $Root $dirs
  if (-not $DryRun) { Write-Manifest $Root $manifest }
  $manifestLanded = $true
} finally {
  if (-not $manifestLanded -and $script:DocWritten) {
    try {
      # The edit never landed (its write failed): nothing to undo.
      $unchanged = if ($null -eq $script:DocPre) { -not (Test-Path -LiteralPath $DocTarget) -and -not (Test-ReparsePoint $DocTarget) }
                   else { (Test-Path -LiteralPath $DocTarget -PathType Leaf) -and (Read-Latin1 $DocTarget) -ceq $script:DocPre }
      if ($unchanged) { }
      elseif ((Test-Path -LiteralPath $DocTarget -PathType Leaf) -and -not (Test-ReparsePoint $DocTarget) -and
          (Get-Item -LiteralPath $DocTarget -Force).LinkType -ne 'HardLink' -and
          (Get-TextSha (Read-Latin1 $DocTarget)) -eq $script:DocWritten) {
        if ($null -eq $script:DocPre) { Remove-Item -LiteralPath $DocTarget -Force } else { Write-BesideBytes $DocTarget $script:DocPre }
        Write-Host "The install stopped before recording the doctrine block, so $DocTarget was restored to how it was before this run."
      } else {
        Write-Host "Warning: the install stopped before recording the doctrine block in $DocTarget, which has changed since (or is now a link); left as it is."
      }
    } catch {
      Write-Host "Warning: could not restore $DocTarget; delete the lines between the AgenticOS doctrine markers by hand."
    }
  }
}
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
if ($script:DocMode -eq 'write') { Write-Host "${Pfx}The AgenticOS doctrine is imported from $DocTarget; it is kept current while the block is there, until -Uninstall." }
Write-Host ""
if ($script:Kept -gt 0) { Write-Host "$($script:Kept) file(s) you modified were kept; -Force overwrites them." }
if ($script:Foreign -gt 0) { Write-Host "$($script:Foreign) file(s) in retired skill directories are not AgenticOS release files and were left alone; they are yours to keep or remove." }
if ($script:Unsafe -gt 0) { Write-Host "$($script:Unsafe) path(s) were skipped as unsafe and left untouched (see the 'skip' lines above)." }
Write-Host "To update later, re-run this script. To remove AgenticOS, re-run it with -Uninstall."
