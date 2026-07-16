<#
.SYNOPSIS
    Runs the unit test suite (tests/RunTests.ahk) against a real AutoHotkey v2 interpreter.
.DESCRIPTION
    Complements Test-Syntax.ps1 (which only proves a script loads) with
    real assertions on the pure logic pieces of Common.ahk and the
    modules: ini parsing, the GameTweaksModule regex file patch, and
    AbilityWheelModule's search-box geometry. Uses AutoHotUnit
    (tests/vendor/AutoHotUnit.ahk, MIT-licensed, vendored directly since
    it's a single file with no other dependencies).
.EXAMPLE
    .\tests\Run-UnitTests.ps1 -AhkExe "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
#>
param(
    [string]$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $AhkExe)) {
    Write-Error "AutoHotkey v2 introuvable a: $AhkExe`nInstalle-le depuis https://www.autohotkey.com/, ou repasse le chemin avec -AhkExe."
    exit 1
}

$script = Join-Path $PSScriptRoot "RunTests.ahk"

# Start-Process -Wait -PassThru, not the `&` call operator — the same
# fix already applied in build/Build-All.ps1 after discovering `&` returns
# before a spawned AutoHotkey process actually finishes and reports an
# empty/stale exit code.
$proc = Start-Process -FilePath $AhkExe -ArgumentList "`"$script`"" -Wait -PassThru -NoNewWindow
exit $proc.ExitCode
