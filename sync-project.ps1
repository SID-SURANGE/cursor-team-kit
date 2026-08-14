# sync-project.ps1 — copy team rules and skills into a repo's .cursor/ for Settings UI visibility
# Usage: .\sync-project.ps1 [-RepoDir path] [-SyncProfile minimal|standard|full] [-Rules a.mdc,b.mdc] [-Skills a,b]
#   minimal  — always-on rules only (agent-behavior, core-development, security-basics), no skills
#   standard — all rules, all skills EXCEPT the requirements/consulting cluster (default)
#   full     — all rules, all skills including the requirements/consulting cluster
#   -Rules / -Skills — explicit allowlist, overrides the profile's list
# The requirements/consulting cluster (requirements-qa, requirements-synthesis,
# spec-driven-development, architecture-decision-records) serves BRD-heavy/client-facing
# workflows, not day-to-day engineering hygiene — opt in with -SyncProfile full or -Skills.
# Defaults to current directory. Safe to re-run.

param(
    [string]$RepoDir = (Get-Location).Path,
    [ValidateSet("minimal", "standard", "full")]
    [string]$SyncProfile = "standard",
    [string[]]$Rules = @(),
    [string[]]$Skills = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$KitDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoDir = (Resolve-Path $RepoDir).Path

$MinimalRules = @("agent-behavior.mdc", "core-development.mdc", "security-basics.mdc")
$ConsultingSkills = @("requirements-qa", "requirements-synthesis", "spec-driven-development", "architecture-decision-records")

function Test-RuleAllowed {
    param([string]$Name)
    if ($Rules.Count -gt 0) { return $Rules -contains $Name }
    switch ($SyncProfile) {
        "minimal" { return $MinimalRules -contains $Name }
        default   { return $true }
    }
}

function Test-SkillAllowed {
    param([string]$Name)
    if ($Skills.Count -gt 0) { return $Skills -contains $Name }
    switch ($SyncProfile) {
        "minimal"  { return $false }
        "standard" { return -not ($ConsultingSkills -contains $Name) }
        "full"     { return $true }
        default    { return $true }
    }
}

Write-Host "Syncing team kit rules and skills into: $RepoDir (profile: $SyncProfile)"
Write-Host ""

$rulesDst = Join-Path $RepoDir ".cursor\rules"
$skillsDst = Join-Path $RepoDir ".cursor\skills"
New-Item -ItemType Directory -Force -Path $rulesDst, $skillsDst | Out-Null

Get-ChildItem (Join-Path $KitDir "rules") -Filter "*.mdc" | ForEach-Object {
    if (Test-RuleAllowed -Name $_.Name) {
        Copy-Item $_.FullName (Join-Path $rulesDst $_.Name) -Force
        Write-Host "  [rule]  $($_.Name)"
    } else {
        Write-Host "  [rule]  $($_.Name) (skipped, profile: $SyncProfile)"
    }
}

foreach ($tier in @("core", "community")) {
    $tierPath = Join-Path $KitDir "skills\$tier"
    if (-not (Test-Path $tierPath)) { continue }
    Get-ChildItem $tierPath -Directory | ForEach-Object {
        if (Test-SkillAllowed -Name $_.Name) {
            $target = Join-Path $skillsDst $_.Name
            if (Test-Path $target) { Remove-Item $target -Recurse -Force }
            Copy-Item $_.FullName $target -Recurse -Force
            Write-Host "  [skill] $($_.Name)"
        } else {
            Write-Host "  [skill] $($_.Name) (skipped, profile: $SyncProfile)"
        }
    }
}

Write-Host ""
Write-Host "Done. (profile: $SyncProfile) Reload Cursor (Developer: Reload Window) and check Settings → Rules, Commands"
Write-Host "with the project tab selected."
Write-Host "Other profiles: .\sync-project.ps1 -SyncProfile minimal | full"
