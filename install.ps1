# install.ps1 — installs cursor-team-ops into $HOME\.cursor\ on Windows
# Usage: .\install.ps1 [-InstallProfile minimal|standard|full] [-Rules a.mdc,b.mdc] [-Skills a,b]
# (named -InstallProfile, not -Profile, to avoid clashing with PowerShell's automatic $PROFILE variable)
#   minimal  — always-on rules only (agent-behavior, core-development, security-basics), no skills
#   standard — all rules, all skills EXCEPT the requirements/consulting cluster (default)
#   full     — all rules, all skills including the requirements/consulting cluster
#   -Rules / -Skills — explicit allowlist, overrides the profile's list
# The requirements/consulting cluster (requirements-qa, requirements-synthesis,
# spec-driven-development, architecture-decision-records) serves BRD-heavy/client-facing
# workflows, not day-to-day engineering hygiene — opt in with -InstallProfile full or -Skills.
# Re-run after git pull to update.
#
# Symlinks are preferred (requires Developer Mode on Windows 10+ or admin rights).
# Falls back to copying files if symlink creation fails.
#
# NOTE: Hook scripts (git-guard.sh, session-context.sh) are bash scripts.
#       They only work with WSL or Git Bash. If you are on native PowerShell
#       without WSL, rules and skills will be active but hooks will not fire.

param(
    [ValidateSet("minimal", "standard", "full")]
    [string]$InstallProfile = "standard",
    [string[]]$Rules = @(),
    [string[]]$Skills = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$KitDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CursorDir = Join-Path $HOME ".cursor"

$MinimalRules = @("agent-behavior.mdc", "core-development.mdc", "security-basics.mdc")
$ConsultingSkills = @("requirements-qa", "requirements-synthesis", "spec-driven-development", "architecture-decision-records")

function Test-RuleAllowed {
    param([string]$Name)
    if ($Rules.Count -gt 0) { return $Rules -contains $Name }
    switch ($InstallProfile) {
        "minimal" { return $MinimalRules -contains $Name }
        default   { return $true }
    }
}

function Test-SkillAllowed {
    param([string]$Name)
    if ($Skills.Count -gt 0) { return $Skills -contains $Name }
    switch ($InstallProfile) {
        "minimal"  { return $false }
        "standard" { return -not ($ConsultingSkills -contains $Name) }
        "full"     { return $true }
        default    { return $true }
    }
}

$version = (Get-Content (Join-Path $KitDir "VERSION") -Raw).Trim()
Write-Host "Installing Cursor team kit v$version from $KitDir (profile: $InstallProfile)"
Write-Host ""

# ── Helper: try symlink, fall back to copy ────────────────────────────────────
function Install-Item {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label,
        [bool]$IsDir = $false
    )

    # Remove existing target
    if (Test-Path $Target) {
        Remove-Item $Target -Recurse -Force
    }

    $linked = $false
    try {
        if ($IsDir) {
            New-Item -ItemType Junction -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        }
        $linked = $true
    } catch {
        # Symlink failed — fall back to copy
    }

    if (-not $linked) {
        if ($IsDir) {
            Copy-Item -Path $Source -Destination $Target -Recurse -Force
        } else {
            Copy-Item -Path $Source -Destination $Target -Force
        }
        Write-Host "  [$Label] $(Split-Path -Leaf $Target) (copied)"
    } else {
        Write-Host "  [$Label] $(Split-Path -Leaf $Target) (linked)"
    }
}

# ── Directories ───────────────────────────────────────────────────────────────
$null = New-Item -ItemType Directory -Force -Path (Join-Path $CursorDir "rules")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $CursorDir "skills")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $CursorDir "hooks")

# ── Rules ─────────────────────────────────────────────────────────────────────
$rulesTargetDir = Join-Path $CursorDir "rules"
Get-ChildItem (Join-Path $KitDir "rules") -Filter "*.mdc" | ForEach-Object {
    if (Test-RuleAllowed -Name $_.Name) {
        $target = Join-Path $rulesTargetDir $_.Name
        Install-Item -Source $_.FullName -Target $target -Label "rule"
    } else {
        Write-Host "  [rule] $($_.Name) (skipped, profile: $InstallProfile)"
    }
}

# ── Skills (core + community, both installed flat into $HOME\.cursor\skills\) ─
$skillsTargetDir = Join-Path $CursorDir "skills"
foreach ($tier in @("core", "community")) {
    $tierPath = Join-Path $KitDir "skills\$tier"
    if (Test-Path $tierPath) {
        Get-ChildItem $tierPath -Directory | ForEach-Object {
            if (Test-SkillAllowed -Name $_.Name) {
                $target = Join-Path $skillsTargetDir $_.Name
                Install-Item -Source $_.FullName -Target $target -Label "skill/$tier" -IsDir $true
            } else {
                Write-Host "  [skill/$tier] $($_.Name) (skipped, profile: $InstallProfile)"
            }
        }
    }
}

# ── hooks.json ────────────────────────────────────────────────────────────────
$hooksJsonSrc = Join-Path $KitDir "hooks.json"
$hooksJsonDst = Join-Path $CursorDir "hooks.json"
if (Test-Path $hooksJsonDst) {
    # Only back up if the existing file is NOT our own kit file (avoids overwriting
    # the backup on every re-run). Compare content hashes to detect foreign file.
    $dstHash = (Get-FileHash $hooksJsonDst -Algorithm SHA256).Hash
    $srcHash = (Get-FileHash $hooksJsonSrc -Algorithm SHA256).Hash
    if ($dstHash -ne $srcHash) {
        $backup = "$hooksJsonDst.bak"
        Copy-Item $hooksJsonDst $backup -Force
        Write-Host "  [hooks] Backed up existing hooks.json → hooks.json.bak"
    }
}
Install-Item -Source $hooksJsonSrc -Target $hooksJsonDst -Label "hooks"

# ── Hook scripts (bash — only useful under WSL / Git Bash) ────────────────────
$hooksTargetDir = Join-Path $CursorDir "hooks"
Get-ChildItem (Join-Path $KitDir "hooks") -Filter "*.sh" | ForEach-Object {
    $target = Join-Path $hooksTargetDir $_.Name
    Install-Item -Source $_.FullName -Target $target -Label "hook"
}

# ── Record version ────────────────────────────────────────────────────────────
Copy-Item (Join-Path $KitDir "VERSION") (Join-Path $CursorDir ".team-ops-version") -Force

Write-Host ""
Write-Host "Done. Team kit v$version installed to $HOME\.cursor\ (profile: $InstallProfile)"
Write-Host "Other profiles: .\install.ps1 -InstallProfile minimal | full"
Write-Host "  full also installs the requirements/consulting cluster (requirements-qa,"
Write-Host "  requirements-synthesis, spec-driven-development, architecture-decision-records)"
Write-Host "  - skipped by default under 'standard' since most teams don't need it daily."
Write-Host "Or pick exactly what you want: -Rules core-development.mdc,git-safety.mdc -Skills commit-message"
Write-Host "Next: in each repo, run bootstrap-project.sh and sync-project.ps1 so rules/skills"
Write-Host "      appear in Cursor Settings. Then reload Cursor."
Write-Host ""
Write-Host "Note: Hook scripts require WSL or Git Bash. On native PowerShell,"
Write-Host "      hooks (git-guard, session-context) will not fire without Git Bash."
Write-Host ""
