#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\AutoAbilityModule.ahk"

ahu.RegisterSuite(AutoAbilitySuite)

class AutoAbilitySuite extends AutoHotUnitSuite {
    ; Init() calls Hotkey()/HotIfWinActive() — both shimmed (see
    ; tests/Shims.ahk), so no real hotkey is ever registered.
    beforeEach() {
        Shims.Reset()
    }

    init_loadsConfigFromIni() {
        AutoAbilityModule.Init()
        this.assert.isTrue(AutoAbilityModule.Enabled)
        this.assert.equal(AutoAbilityModule.Key, "q")
        this.assert.equal(AutoAbilityModule.IntervalMs, 5000)
        this.assert.equal(AutoAbilityModule.ToggleKey, "NumpadEnter")
        this.assert.equal(AutoAbilityModule.PanicKey, "NumpadAdd")
        this.assert.isFalse(AutoAbilityModule.Running)
    }

    statusText_reportsDisabled() {
        AutoAbilityModule.Enabled := false
        this.assert.equal(AutoAbilityModule.StatusText(), "AutoAbility : desactive")
    }

    statusText_reportsArmedState() {
        AutoAbilityModule.Enabled := true
        AutoAbilityModule.Running := true
        AutoAbilityModule.ToggleKey := "F2"
        AutoAbilityModule.Key := "e"
        AutoAbilityModule.IntervalMs := 47000
        this.assert.equal(AutoAbilityModule.StatusText(), "AutoAbility : arme (F2 -> e / 47s)")
    }

    statusText_reportsRestState() {
        AutoAbilityModule.Enabled := true
        AutoAbilityModule.Running := false
        AutoAbilityModule.ToggleKey := "F2"
        AutoAbilityModule.Key := "q"
        AutoAbilityModule.IntervalMs := 30000
        this.assert.equal(AutoAbilityModule.StatusText(), "AutoAbility : au repos (F2 -> q / 30s)")
    }

    ; Send() is shimmed (see Shims.ahk) — this calls the real PressAbility(),
    ; but the "keypress" only ever lands in Shims.SentCalls, never the OS.
    pressAbility_sendsConfiguredKey() {
        AutoAbilityModule.Key := "q"
        AutoAbilityModule.PressAbility()
        this.assert.equal(Shims.SentCalls.Length, 1)
        this.assert.equal(Shims.SentCalls[1], "q")
    }

    ; SetTimer is shimmed (see Shims.ahk) — deterministic, no real elapsed
    ; time needed, and no risk of a real repeating timer outliving this
    ; test and contaminating a later one's Shims.SentCalls (which is
    ; exactly what happened during development here, before switching to
    ; this shim-based design: a genuinely-armed 20ms real timer kept
    ; firing into later suites because of the bug below).
    toggle_armsTimerWithConfiguredIntervalAndFlipsRunning() {
        AutoAbilityModule.Init()
        AutoAbilityModule.Running := false
        AutoAbilityModule.IntervalMs := 5000
        AutoAbilityModule.Toggle()
        this.assert.isTrue(AutoAbilityModule.Running)
        this.assert.equal(Shims.SetTimerCalls.Length, 1)
        this.assert.equal(Shims.SetTimerCalls[1].period, 5000)
    }

    ; Regression test for a real bug caught here: SetTimer with a positive
    ; period never fires on its own the instant it's armed — the first
    ; tick only happens after a full IntervalMs elapses (verified against
    ; AutoHotkey's own docs). With the 47s default, arming used to mean
    ; "beep, then nothing for 47 seconds", easily read as "doesn't work"
    ; by anyone testing for less than a minute. Toggle() now presses once
    ; immediately when arming, in addition to arming the repeating timer.
    toggle_pressesAbilityImmediatelyWhenArming() {
        AutoAbilityModule.Key := "e"
        AutoAbilityModule.Running := false
        AutoAbilityModule.Toggle()
        this.assert.equal(Shims.SentCalls.Length, 1)
        this.assert.equal(Shims.SentCalls[1], "e")
    }

    toggle_doesNotPressAbilityWhenDisarming() {
        AutoAbilityModule.Init()
        AutoAbilityModule.Running := true
        AutoAbilityModule.Toggle()
        this.assert.equal(Shims.SentCalls.Length, 0)
    }

    toggle_disarmsWhenTogglingOff() {
        AutoAbilityModule.Init()
        AutoAbilityModule.Running := true
        AutoAbilityModule.Toggle()
        this.assert.isFalse(AutoAbilityModule.Running)
        this.assert.equal(Shims.SetTimerCalls[Shims.SetTimerCalls.Length].period, 0)
    }

    panic_disarmsRunningState() {
        AutoAbilityModule.Init()
        AutoAbilityModule.Running := true
        AutoAbilityModule.Panic()
        this.assert.isFalse(AutoAbilityModule.Running)
        this.assert.equal(Shims.SetTimerCalls[Shims.SetTimerCalls.Length].period, 0)
    }

    ; Regression test for a real bug caught here: ObjBindMethod() returns
    ; a brand-new object every call, and SetTimer identifies "which timer"
    ; solely by callback reference — so Panic() calling
    ; SetTimer(ObjBindMethod(this,"PressAbility"), 0) with a freshly-bound
    ; instance never actually disarmed the timer Toggle() armed with a
    ; *different* instance of the same binding (verified empirically: a
    ; real 20ms-period timer kept firing for hundreds more ms after the
    ; "disarm" call). Fixed by binding PressAbility once in Init()
    ; (BoundPressAbility) and reusing that same reference everywhere. This
    ; test pins it by checking reference identity (ObjPtr), not just that
    ; *a* SetTimer(..., 0) call happened.
    panic_disarmsTheExactTimerThatToggleArmed() {
        AutoAbilityModule.Init()
        AutoAbilityModule.IntervalMs := 5000
        AutoAbilityModule.Toggle()
        armedCallback := Shims.SetTimerCalls[Shims.SetTimerCalls.Length].callback
        AutoAbilityModule.Panic()
        disarmedCallback := Shims.SetTimerCalls[Shims.SetTimerCalls.Length].callback
        this.assert.equal(ObjPtr(armedCallback), ObjPtr(disarmedCallback))
    }
}
