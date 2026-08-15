#requires -Version 5.1
<#
.SYNOPSIS
Install/update dt-testing from local source or a public GitHub Release.
.EXAMPLE
.\install.ps1 -Repo OWNER/REPO -Agent all -Global
.EXAMPLE
.\install.ps1 -Repo OWNER/REPO -Agent codex -Project C:\work\project -Update
#>
[CmdletBinding(DefaultParameterSetName = 'Global')]
param(
    [ValidateSet('claude-code', 'antigravity', 'opencode', 'codex', 'all')]
    [string]$Agent,
    [Parameter(Mandatory = $true, ParameterSetName = 'Project')]
    [string]$Project,
    [Parameter(ParameterSetName = 'Global')]
    [switch]$Global,
    [ValidatePattern('^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$')]
    [string]$Repo = '',
    [ValidatePattern('^(latest|v?[0-9]+\.[0-9]+\.[0-9]+)$')]
    [string]$Version = 'latest',
    [switch]$Update,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$work = $null
$stage = $null
try {
    $releaseRepo = '__DT_RELEASE_REPO__'
    if (-not $Repo -and $releaseRepo -ne ('__DT_' + 'RELEASE_REPO__')) { $Repo = $releaseRepo }
    if (-not $Project) { $Global = $true }
    $automatic = -not $Agent
    $agents = @()
    if ($automatic) {
        $Update = $true
        $userRoot = [Environment]::GetFolderPath('UserProfile')
        $signals = [ordered]@{
            'claude-code' = @('claude', '.claude')
            'antigravity' = @('antigravity', '.gemini/antigravity')
            'opencode' = @('opencode', '.config/opencode')
            'codex' = @('codex', '.codex')
        }
        foreach ($name in $signals.Keys) {
            $signal = $signals[$name]
            if ((Get-Command $signal[0] -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $userRoot $signal[1]))) { $agents += $name }
        }
        if ($agents.Count -eq 0) {
            $Agent = Read-Host 'Choose claude-code, antigravity, opencode, codex, or all'
            if ($Agent -notin @('claude-code', 'antigravity', 'opencode', 'codex', 'all')) { throw 'Use -Agent NAME to choose an agent' }
        } else { Write-Host "Detected agents: $($agents -join ', ')" }
    }
    if ($agents.Count -eq 0) { $agents = @($Agent) }
    if ($Global) { $root = [Environment]::GetFolderPath('UserProfile') }
    else { $root = $Project }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Project directory does not exist: $root" }
    $root = (Resolve-Path -LiteralPath $root).ProviderPath
    if (-not $Repo -and $Version -ne 'latest') { throw '-Version requires -Repo' }
    $paths = [ordered]@{
        'claude-code' = '.claude/skills'
        'antigravity' = '.agents/skills'
        'opencode' = '.opencode/skills'
        'codex' = '.agents/skills'
    }
    if ($Global) {
        $paths['antigravity'] = '.gemini/config/skills'
        $paths['opencode'] = '.config/opencode/skills'
    }
    $selected = @()
    foreach ($name in $agents) {
        if ($name -eq 'all') { $selected += @($paths.Values) }
        else { $selected += $paths[$name] }
    }
    $selected = @($selected | Select-Object -Unique)
    $targets = @($selected | ForEach-Object { Join-Path (Join-Path $root $_) 'dt-testing' })
    foreach ($target in $targets) {
        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if ($existing) {
            if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing linked destination: $target" }
            if (-not $Update -or -not $existing.PSIsContainer) { throw "Destination exists: $target (use -Update)" }
        }
    }
    if ($Repo) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $headers = @{ 'User-Agent' = 'dt-testing-installer' }
        if ($Version -eq 'latest') {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers -TimeoutSec 60
            $tag = $release.tag_name
            if ($release.draft -or $release.prerelease) { throw 'Expected a published stable release' }
        } else { $tag = 'v' + $Version.TrimStart('v') }
        if ($tag -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') { throw 'Expected a stable release tag' }
        $work = Join-Path ([IO.Path]::GetTempPath()) ('dt-testing-' + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $work
        foreach ($asset in @('dt-testing.zip', 'SHA256SUMS')) {
            $destination = Join-Path $work $asset
            Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$Repo/releases/download/$tag/$asset" -Headers $headers -OutFile $destination -TimeoutSec 60
            if ((Get-Item -LiteralPath $destination).Length -gt 2000000) { throw 'Download exceeds 2 MB limit' }
        }
        $checksums = Get-Content -LiteralPath (Join-Path $work 'SHA256SUMS')
        $expected = @($checksums | Where-Object { $_ -match '^([a-fA-F0-9]{64})\s+dt-testing\.zip$' } | ForEach-Object { ($_ -split '\s+')[0] })
        $zipPath = Join-Path $work 'dt-testing.zip'
        if ($expected.Count -ne 1 -or (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -ne $expected[0]) { throw 'Release checksum mismatch' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $total = 0
            foreach ($entry in $archive.Entries) {
                if ($entry.FullName -cnotmatch '^dt-testing/(SKILL\.md|VERSION|references/[a-zA-Z0-9_-]+\.md)$') { throw "Unsafe release archive path: $($entry.FullName)" }
                $total += $entry.Length
                if ($total -gt 2000000) { throw 'Expanded release exceeds 2 MB limit' }
            }
            foreach ($entry in $archive.Entries) {
                $destination = Join-Path $work $entry.FullName
                $null = New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force
                # Stream into a regular file; never restore archive link metadata.
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $false)
            }
        } finally { $archive.Dispose() }
        $source = Join-Path $work 'dt-testing'
        if ((Get-Content -LiteralPath (Join-Path $source 'VERSION') -Raw).Trim() -ne $tag.Substring(1)) { throw 'Package version does not match release tag' }
        $metadata = @{ repo = $Repo; version = $tag } | ConvertTo-Json -Compress
        [IO.File]::WriteAllText((Join-Path $source '.release.json'), $metadata, (New-Object Text.UTF8Encoding($false)))
    } else { $source = Join-Path (Split-Path -Parent $PSScriptRoot) 'dt-testing' }
    if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) { throw "Skill source missing: $source" }
    foreach ($target in $targets) {
        if ($automatic -and $Repo -and (Test-Path -LiteralPath (Join-Path $target 'SKILL.md')) -and (Test-Path -LiteralPath (Join-Path $target 'VERSION')) -and (Test-Path -LiteralPath (Join-Path $target '.release.json'))) {
            $installed = $null
            try { $installed = Get-Content -LiteralPath (Join-Path $target '.release.json') -Raw | ConvertFrom-Json } catch { }
            if ($installed -and $installed.repo -eq $Repo -and $installed.version -eq $tag -and (Get-Content -LiteralPath (Join-Path $target 'VERSION') -Raw).Trim() -eq $tag.Substring(1)) {
                Write-Host "Already up to date: $target ($tag)"; continue
            }
        }
        if ($DryRun) { Write-Host "Would install: $target"; continue }
        $parent = Split-Path -Parent $target
        $null = New-Item -ItemType Directory -Path $parent -Force
        $stage = Join-Path $parent ('.dt-testing-' + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $stage
        $staged = Join-Path $stage 'dt-testing'
        Copy-Item -LiteralPath $source -Destination $staged -Recurse -Force
        $backup = $null
        if (Test-Path -LiteralPath $target) {
            $backupRoot = Join-Path (Split-Path -Parent $parent) 'skill-backups'
            $null = New-Item -ItemType Directory -Path $backupRoot -Force
            $backup = Join-Path $backupRoot ('dt-testing-' + [guid]::NewGuid().ToString('N'))
            Move-Item -LiteralPath $target -Destination $backup
        }
        try { Move-Item -LiteralPath $staged -Destination $target }
        catch {
            if ($backup) { Move-Item -LiteralPath $backup -Destination $target }
            throw
        }
        if ($backup) { Write-Host "Backup: $backup" }
        Remove-Item -LiteralPath $stage -Force
        $stage = $null
        Write-Host "Installed: $target"
    }
} finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force }
}
