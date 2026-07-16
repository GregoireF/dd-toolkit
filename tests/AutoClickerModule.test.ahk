#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\AutoClickerModule.ahk"

ahu.RegisterSuite(AutoClickerSuite)

class AutoClickerSuite extends AutoHotUnitSuite {
    ; Init() calls Hotkey()/HotIfWinActive() (both shimmed, see
    ; tests/Shims.ahk — no real hotkey is ever registered). The toggle
    ; keys aren't game-scoped by design (arming must work regardless of
    ; focus), but even in real usage they only ever flip a bool and beep,
    ; never send input.
    beforeEach() {
        Shims.Reset()
    }

    init_loadsConfigFromIni() {
        AutoClickerModule.Init()
        this.assert.isTrue(AutoClickerModule.Enabled)
        this.assert.equal(AutoClickerModule.IntervalMs, 10)
        this.assert.equal(AutoClickerModule.LeftToggleKey, "NumpadMult")
        this.assert.equal(AutoClickerModule.RightToggleKey, "NumpadDiv")
        this.assert.isTrue(AutoClickerModule.ScopeToGame)
        this.assert.isFalse(AutoClickerModule.LeftActive)
        this.assert.isFalse(AutoClickerModule.RightActive)
    }

    ; Regression test for a real bug caught here: SetKeyDelay only governs
    ; *keyboard* keys sent by Send/SendEvent — it has zero effect on mouse
    ; buttons (verified against AutoHotkey's own docs), which need
    ; SetMouseDelay instead. This module only ever sends LButton/RButton,
    ; so the old SetKeyDelay(IntervalMs, IntervalMs) call was silently a
    ; no-op: the configured click rate never actually applied.
    init_configuresMouseDelayNotKeyDelay() {
        AutoClickerModule.Init()
        this.assert.equal(Shims.SetMouseDelayCalls.Length, 1)
        this.assert.equal(Shims.SetMouseDelayCalls[1], 10)
        this.assert.equal(Shims.SetKeyDelayCalls.Length, 0)
    }

    ; ToggleLeft/ToggleRight never call Send — just flip a flag and beep
    ; (SoundBeep, audible but harmless) — safe to call directly for real.
    toggleLeft_flipsLeftActive() {
        AutoClickerModule.LeftActive := false
        AutoClickerModule.ToggleLeft()
        this.assert.isTrue(AutoClickerModule.LeftActive)
        AutoClickerModule.ToggleLeft()
        this.assert.isFalse(AutoClickerModule.LeftActive)
    }

    toggleRight_flipsRightActive() {
        AutoClickerModule.RightActive := false
        AutoClickerModule.ToggleRight()
        this.assert.isTrue(AutoClickerModule.RightActive)
        AutoClickerModule.ToggleRight()
        this.assert.isFalse(AutoClickerModule.RightActive)
    }

    statusText_reportsDisabled() {
        AutoClickerModule.Enabled := false
        this.assert.equal(AutoClickerModule.StatusText(), "AutoClicker : desactive")
    }

    statusText_reportsBothArmed() {
        AutoClickerModule.Enabled := true
        AutoClickerModule.LeftActive := true
        AutoClickerModule.RightActive := true
        AutoClickerModule.LeftToggleKey := "CapsLock"
        AutoClickerModule.RightToggleKey := "F6"
        this.assert.equal(AutoClickerModule.StatusText(), "AutoClicker : G=CapsLock (ARME) / D=F6 (ARME)")
    }

    statusText_reportsBothAtRest() {
        AutoClickerModule.Enabled := true
        AutoClickerModule.LeftActive := false
        AutoClickerModule.RightActive := false
        AutoClickerModule.LeftToggleKey := "CapsLock"
        AutoClickerModule.RightToggleKey := "F6"
        this.assert.equal(AutoClickerModule.StatusText(), "AutoClicker : G=CapsLock (repos) / D=F6 (repos)")
    }

    shouldFireLeft_falseWhenNotActive() {
        AutoClickerModule.LeftActive := false
        AutoClickerModule.ScopeToGame := false
        this.assert.isFalse(AutoClickerModule.ShouldFireLeft())
    }

    shouldFireLeft_trueWhenActiveAndUnscoped() {
        AutoClickerModule.LeftActive := true
        AutoClickerModule.ScopeToGame := false
        this.assert.isTrue(AutoClickerModule.ShouldFireLeft())
    }

    ; GetKeyState(button, "P") is shimmed (see Shims.ahk) to simulate a
    ; button physically held for exactly N polls — real GetKeyState(,"P")
    ; is immune to synthetic input by AHK's own design, so this is the
    ; only way to exercise this loop at all, in any environment, not just
    ; this one. SendEvent is shimmed too, so the "clicks" only ever land
    ; in Shims.SentEventCalls.
    turboFire_sendsOnceForEachTickThePhysicalButtonStaysHeld() {
        Shims.KeyStatePMode["LButton"] := 3
        AutoClickerModule.TurboFire("LButton")
        this.assert.equal(Shims.SentEventCalls.Length, 3)
        this.assert.equal(Shims.SentEventCalls[1], "{LButton}")
    }

    ; The realistic case for every automated run: nothing is physically
    ; holding the button, so the loop must not iterate at all.
    turboFire_sendsNothingWhenButtonNotPhysicallyHeld() {
        AutoClickerModule.TurboFire("LButton")
        this.assert.equal(Shims.SentEventCalls.Length, 0)
    }

    fireLeft_delegatesToTurboFireWithLButton() {
        Shims.KeyStatePMode["LButton"] := 1
        AutoClickerModule.FireLeft()
        this.assert.equal(Shims.SentEventCalls.Length, 1)
        this.assert.equal(Shims.SentEventCalls[1], "{LButton}")
    }

    fireRight_delegatesToTurboFireWithRButton() {
        Shims.KeyStatePMode["RButton"] := 1
        AutoClickerModule.FireRight()
        this.assert.equal(Shims.SentEventCalls.Length, 1)
        this.assert.equal(Shims.SentEventCalls[1], "{RButton}")
    }
}
