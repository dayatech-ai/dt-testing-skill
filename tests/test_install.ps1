# Native Windows installer checks; run in PowerShell 5.1 or 7 on Windows.
# Downloads are simulated; all writes stay inside an isolated temporary directory.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$installer = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/install.ps1'
$fixture = Join-Path (Split-Path -Parent $PSScriptRoot) 'dist'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('dt-testing-check-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testRoot
function Assert-True($condition, $message) {
    if (-not $condition) { throw "Assertion failed: $message" }
}
function Assert-Fails([scriptblock]$action, [string]$pattern) {
    $caught = $null
    try { & $action } catch { $caught = $_ }
    Assert-True ($null -ne $caught) 'Expected failure'
    Assert-True ($caught.ToString() -match $pattern) "Unexpected failure: $caught"
}
# These functions replace network calls in the child installer scope.
function Invoke-RestMethod {
    param($Uri, $Headers, $TimeoutSec)
    Assert-True ($Uri -eq 'https://api.github.com/repos/owner/repo/releases/latest') 'Latest URL'
    return @{ tag_name = 'v0.0.0'; draft = $false; prerelease = $false }
}
function Invoke-WebRequest {
    param([switch]$UseBasicParsing, $Uri, $Headers, $OutFile, $TimeoutSec)
    Assert-True ($Uri -like 'https://github.com/owner/repo/releases/download/v0.0.0/*') 'Pinned asset URL'
    $asset = ($Uri -split '/')[-1]
    Copy-Item -LiteralPath (Join-Path $fixture $asset) -Destination $OutFile
}
try {
    $project = Join-Path $testRoot 'project with spaces'
    $null = New-Item -ItemType Directory -Path $project
    & $installer -Agent all -Project $project -DryRun
    Assert-True (@(Get-ChildItem -LiteralPath $project -Force).Count -eq 0) 'Dry run does not write'
    & $installer -Agent all -Project $project
    foreach ($path in @('.claude/skills', '.agents/skills', '.opencode/skills')) {
        $skill = Join-Path (Join-Path $project $path) 'dt-testing'
        Assert-True (Test-Path -LiteralPath (Join-Path $skill 'SKILL.md')) 'Installed skill'
        Assert-True (Test-Path -LiteralPath (Join-Path $skill 'references/workflow.md')) 'Installed references'
    }
    Assert-Fails { & $installer -Agent all -Project $project } 'Destination exists'
    $target = Join-Path $project '.agents/skills/dt-testing'
    Set-Content -LiteralPath (Join-Path $target 'custom.md') -Value 'local changes'
    & $installer -Agent codex -Project $project -Repo owner/repo -Update
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $target 'custom.md'))) 'Replacement removes old files'
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $project '.agents/skill-backups') -Recurse -Filter custom.md)
    Assert-True ($backups.Count -eq 1) 'Local changes backed up'
    Assert-True ((Get-Content -LiteralPath $backups[0].FullName -Raw).Trim() -eq 'local changes') 'Backup contents'
    $metadata = Get-Content -LiteralPath (Join-Path $target '.release.json') -Raw | ConvertFrom-Json
    Assert-True ($metadata.version -eq 'v0.0.0') 'Installed version'
    & $installer -Agent codex -Project $project -Repo owner/repo -Version 0.0.0 -Update -DryRun

    # Auto selection in an isolated project (never installs into the real profile).
    function Get-Command {
        param($Name, $ErrorAction)
        if ($Name -eq 'codex') { return @{ Name = 'codex' } }
    }
    & $installer -Project $project -Repo owner/repo
    $afterAuto = @(Get-ChildItem -LiteralPath (Join-Path $project '.agents/skill-backups'))
    Assert-True ($afterAuto.Count -eq 1) 'Same version auto run does not create a backup'
    Remove-Item Function:\Get-Command

    # Corrupt a copied checksum fixture and verify the existing installation is preserved.
    $badFixture = Join-Path $testRoot 'bad-fixture'
    Copy-Item -LiteralPath $fixture -Destination $badFixture -Recurse
    $fixture = $badFixture
    Set-Content -LiteralPath (Join-Path $fixture 'SHA256SUMS') -Value 'bad  dt-testing.zip'
    $previous = (Get-FileHash -LiteralPath (Join-Path $target 'SKILL.md')).Hash
    Assert-Fails { & $installer -Agent codex -Project $project -Repo owner/repo -Update } 'checksum'
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $target 'SKILL.md')).Hash -eq $previous) 'Failed download preserves installation'
    Assert-Fails { & $installer -Agent codex -Project $project -Version 1.2.3 } 'requires -Repo'
    Write-Host 'Windows installer checks passed.'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
