<#
.SYNOPSIS
    One-time setup: points git at the versioned .githooks/ folder instead of
    the untracked, per-clone .git/hooks/ directory.
.DESCRIPTION
    Run this once after cloning. It only changes local repo config
    (core.hooksPath) — nothing is pushed or shared with other clones, each
    contributor runs it themselves.
.EXAMPLE
    .\scripts\Install-Hooks.ps1
#>
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

Push-Location $root
try {
    git config core.hooksPath .githooks
    # $ErrorActionPreference = "Stop" only catches PowerShell/cmdlet errors —
    # an external command like git.exe failing (e.g. not in a git repo yet)
    # just sets $LASTEXITCODE and keeps going, it doesn't throw. Check it
    # explicitly or this silently prints "OK" even when git config failed.
    if ($LASTEXITCODE -ne 0) {
        throw "git config a echoue (code $LASTEXITCODE) - es-tu bien a la racine d'un repo git ?"
    }
    Write-Output "OK - core.hooksPath = .githooks (verifie avec: git config core.hooksPath)"
}
finally {
    Pop-Location
}
