<#
.SYNOPSIS
    Bumps the project version in one command instead of editing three places
    by hand.
.DESCRIPTION
    Updates, in order:
      1. VERSION
      2. The ";@Ahk2Exe-SetVersion" directive in every src/*.ahk
      3. CHANGELOG.md — moves the current "## Unreleased" content under a new
         dated "## [X.Y.Z] - yyyy-MM-dd" section (Keep a Changelog style),
         leaving "## Unreleased" empty above it for the next round.
    All files are read/written as UTF-8 without BOM via .NET APIs directly —
    Windows PowerShell 5.1's Get-Content/Set-Content -Encoding utf8 mis-decodes
    accented characters when the source has no BOM and adds a BOM on write,
    which would corrupt the (accented, BOM-less) French text in this repo.
    Does NOT commit, tag, or push — review the diff yourself, then:
        git add -A
        git commit -m "chore(release): vX.Y.Z"
        git tag vX.Y.Z
        git push && git push --tags
    Pushing the tag triggers .github/workflows/release.yml, which builds the
    .exe files and attaches them to a GitHub Release using this same
    CHANGELOG section as the release notes.
.EXAMPLE
    .\scripts\Bump-Version.ps1 -Version 0.2.0
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8Text([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8Text([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

# 1. VERSION
Write-Utf8Text (Join-Path $root "VERSION") "$Version`n"

# 2. Ahk2Exe version directives (4-part Windows file version)
$fileVersion = "$Version.0"
$srcScripts = Get-ChildItem (Join-Path $root "src") -Filter "*.ahk"
foreach ($script in $srcScripts) {
    $text = Read-Utf8Text $script.FullName
    $updated = $text -replace ';@Ahk2Exe-SetVersion [\d.]+', ";@Ahk2Exe-SetVersion $fileVersion"
    Write-Utf8Text $script.FullName $updated
}

# 3. CHANGELOG.md
$changelogPath = Join-Path $root "CHANGELOG.md"
$content = Read-Utf8Text $changelogPath
$date = Get-Date -Format "yyyy-MM-dd"

$pattern = "(?ms)^## Unreleased\r?\n(.*?)(?=^## |\z)"
$match = [regex]::Match($content, $pattern)
if (-not $match.Success) {
    throw "Impossible de trouver une section '## Unreleased' dans CHANGELOG.md"
}
$unreleasedBody = $match.Groups[1].Value.TrimEnd("`r", "`n")

$replacement = "## Unreleased`n`n## [$Version] - $date`n$unreleasedBody`n`n"
$newContent = $content.Substring(0, $match.Index) + $replacement + $content.Substring($match.Index + $match.Length)
Write-Utf8Text $changelogPath $newContent

Write-Output "Version -> $Version"
Write-Output "Fichiers modifies: VERSION, $($srcScripts.Count) script(s) dans src/, CHANGELOG.md"
Write-Output ""
Write-Output "Prochaines etapes (rien n'a ete commit/tag/push automatiquement):"
Write-Output "  git add -A"
Write-Output "  git commit -m `"chore(release): v$Version`""
Write-Output "  git tag v$Version"
Write-Output "  git push && git push --tags"
