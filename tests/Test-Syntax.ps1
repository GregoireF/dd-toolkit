<#
.SYNOPSIS
    Smoke-tests every top-level script in src/ for syntax/load errors.
.DESCRIPTION
    This is NOT a functional test — it can't click through Dungeon Defenders
    for you. It launches each script with AutoHotkey v2 and checks whether
    it stays resident. Both scripts in this repo register hotkeys, which
    makes AHK keep them running automatically (implicit #Persistent); a
    script that instead exits almost immediately failed to parse or hit a
    runtime error during its auto-execute section. Any script added later
    without a hotkey/timer needs an explicit `Persistent` for this check to
    mean anything.
.EXAMPLE
    .\tests\Test-Syntax.ps1
#>
param(
    [string]$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $AhkExe)) {
    Write-Error "AutoHotkey v2 introuvable a: $AhkExe`nInstalle-le depuis https://www.autohotkey.com/, ou repasse le chemin avec -AhkExe."
    exit 1
}

$root = Split-Path $PSScriptRoot -Parent
$scripts = Get-ChildItem (Join-Path $root "src") -Filter "*.ahk"

$failed = @()
foreach ($script in $scripts) {
    Write-Output "Checking $($script.Name)..."
    $proc = Start-Process -FilePath $AhkExe -ArgumentList "/ErrorStdOut", "`"$($script.FullName)`"" -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 2500 # generous margin against slow/loaded CI runners

    if ($proc.HasExited) {
        $failed += $script.Name
        Write-Output "  FAIL - exited immediately (exit code $($proc.ExitCode)), likely a syntax/load error"
    } else {
        Write-Output "  OK - still resident"
        Stop-Process -Id $proc.Id -Force
    }
}

if ($failed.Count -gt 0) {
    Write-Error "Scripts en erreur: $($failed -join ', ')"
    exit 1
}

Write-Output "Tous les scripts se chargent sans erreur."
