#Requires AutoHotkey v2.0
#SingleInstance Force

; Unit tests for the pure logic pieces (ini parsing, regex-based file
; patching, geometry math) that tests/Test-Syntax.ps1 can't catch — that
; one only proves a script *loads*, not that its logic is correct. Each
; *.test.ahk file registers its own suite; this is just the entry point
; that pulls the framework and every suite together, then runs them.
;
; Run via tests/Run-UnitTests.ps1 (wraps this with a real exit code, same
; Start-Process -Wait -PassThru pattern as build/Build-All.ps1 — the `&`
; call operator doesn't reliably wait for a spawned AutoHotkey process
; either).

#Include "%A_ScriptDir%\vendor\AutoHotUnit.ahk"

; Some suites now call a module's real Init() to cover config-loading and
; hotkey registration, not just pure logic. Registering a hotkey makes AHK
; persistent, and AutoHotUnitCLIReporter.onRunComplete() ends the run with
; Exit(count) — which only exits the *current thread*, not the whole
; process (verified empirically: a script that registers one hotkey and
; then calls Exit() never terminates on its own). Left as the vendor
; default, that would hang tests/Run-UnitTests.ps1 forever until the CI
; job's own timeout. ExitApp(), also verified empirically, terminates the
; process regardless of any registered hotkey — so this subclass swaps
; just that one call, keeping the exact same output format.
class CIReporter extends AutoHotUnitCLIReporter {
    onRunComplete() {
        this.printLine("")
        postfix := "All tests passed."
        if (this.failures.Length > 0)
            postfix := this.failures.Length . " test(s) failed."
        this.printLine("Test run complete. " postfix)

        if (this.failures.Length > 0)
            this.printLine("")

        for i, failure in this.failures
            this.printLine(this.red failure this.reset)

        ExitApp(this.failures.Length)
    }
}
ahu := AutoHotUnitManager(CIReporter())

; Shadows Send/SendEvent/GetKeyState/PixelSearch/WinExist/WinGetPos for the
; rest of this process — see Shims.ahk's own header for why this is safe
; and what it makes possible (real coverage of every Send()-calling method
; without any real synthetic input ever reaching the OS).
#Include "%A_ScriptDir%\Shims.ahk"

#Include "%A_ScriptDir%\Common.test.ahk"
#Include "%A_ScriptDir%\AutoAbilityModule.test.ahk"
#Include "%A_ScriptDir%\AutoClickerModule.test.ahk"
#Include "%A_ScriptDir%\ChargeShotModule.test.ahk"
#Include "%A_ScriptDir%\TowerStackingModule.test.ahk"
#Include "%A_ScriptDir%\AbilityWheelModule.test.ahk"
#Include "%A_ScriptDir%\GameTweaksModule.test.ahk"

ahu.RunSuites()
