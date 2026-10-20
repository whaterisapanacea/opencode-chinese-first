# SPDX-License-Identifier: MPL-2.0

[CmdletBinding()]
param(
    [string]$ConfigDir
)

$ErrorActionPreference = 'Stop'

if (-not $ConfigDir) {
    if ($env:XDG_CONFIG_HOME) {
        $ConfigDir = Join-Path $env:XDG_CONFIG_HOME 'opencode'
    } else {
        $ConfigDir = Join-Path $HOME '.config\opencode'
    }
}

$SkillId = 'chinese-first'
$Source = Join-Path $PSScriptRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $Source)) {
    throw "SKILL.md was not found next to this script: $Source"
}

$SkillDir = Join-Path (Join-Path $ConfigDir 'skills') $SkillId
New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
Copy-Item -LiteralPath $Source -Destination (Join-Path $SkillDir 'SKILL.md') -Force
Write-Host "Installed skill to $SkillDir"

$fullSkillPath = [System.IO.Path]::GetFullPath((Join-Path $SkillDir 'SKILL.md'))
$homePath = [System.IO.Path]::GetFullPath($HOME)
$separator = [System.IO.Path]::DirectorySeparatorChar
if ($fullSkillPath.StartsWith($homePath + $separator, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $fullSkillPath.Substring($homePath.Length).TrimStart('\', '/') -replace '\\', '/'
    $instructionPath = '~/' + $relative
} else {
    $instructionPath = $fullSkillPath -replace '\\', '/'
}

$ConfigPath = Join-Path $ConfigDir 'opencode.jsonc'
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    $jsonPath = Join-Path $ConfigDir 'opencode.json'
    if (Test-Path -LiteralPath $jsonPath) {
        $ConfigPath = $jsonPath
    }
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    $content = @"
{
  "`$schema": "https://opencode.ai/config.json",
  "instructions": [
    "$instructionPath"
  ]
}
"@
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ConfigPath, $content, $utf8)
    Write-Host "Created $ConfigPath with the default language instruction."
    Write-Host "Restart OpenCode or run: opencode reload"
    return
}

$raw = [System.IO.File]::ReadAllText($ConfigPath)
if ($raw -match 'chinese-first') {
    Write-Host "Config already references chinese-first: $ConfigPath"
    Write-Host "Restart OpenCode or run: opencode reload"
    return
}

if ($raw -match '(?m)^\s*"instructions"\s*:') {
    Write-Host "Config already has an instructions array. Add this path manually:"
    Write-Host "  $instructionPath"
    Write-Host "File: $ConfigPath"
    exit 2
}

$backup = "$ConfigPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $ConfigPath -Destination $backup -Force

$index = $raw.IndexOf('{')
if ($index -lt 0) {
    throw "Could not find the opening brace in $ConfigPath"
}

$snippet = @"
  "instructions": [
    "$instructionPath"
  ],
"@
$newContent = $raw.Substring(0, $index + 1) + "`r`n" + $snippet + "`r`n" + $raw.Substring($index + 1)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ConfigPath, $newContent, $utf8)

Write-Host "Backed up config to $backup"
Write-Host "Added the instructions entry to $ConfigPath"
Write-Host "Restart OpenCode or run: opencode reload"
