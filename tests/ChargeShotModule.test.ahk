#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\ChargeShotModule.ahk"

ahu.RegisterSuite(ChargeShotSuite)

class ChargeShotSuite extends AutoHotUnitSuite {
    ; Init() calls Hotkey()/HotIfWinActive() — both shimmed (see
    ; tests/Shims.ahk), so no real hotkey is ever registered.
    beforeEach() {
        Shims.Reset()
    }

    init_loadsConfigFromIni() {
        ChargeShotModule.Init()
        this.assert.isTrue(ChargeShotModule.Enabled)
        this.assert.equal(ChargeShotModule.TriggerKey, "NumpadSub")
        this.assert.equal(ChargeShotModule.ChargeMs, 300)
        this.assert.equal(ChargeShotModule.AttackButton, "RButton")
    }

    statusText_reportsDisabled() {
        ChargeShotModule.Enabled := false
        this.assert.equal(ChargeShotModule.StatusText(), "ChargeShot : desactive")
    }

    statusText_reportsTriggerAndDurationWhenEnabled() {
        ChargeShotModule.Enabled := true
        ChargeShotModule.TriggerKey := "^Space"
        ChargeShotModule.ChargeMs := 500
        this.assert.equal(ChargeShotModule.StatusText(), "ChargeShot : ^Space -> charge 500ms puis relache")
    }

    ; Send() is shimmed (see Shims.ahk) — FireChargedShot() really holds
    ; and releases AttackButton, but only inside Shims.SentCalls, never a
    ; real mouse button. ChargeMs kept tiny so the (real) Sleep() between
    ; the two Send() calls doesn't slow the suite down.
    fireChargedShot_holdsConfiguredButtonForChargeDuration() {
        ChargeShotModule.AttackButton := "LButton"
        ChargeShotModule.ChargeMs := 5
        ChargeShotModule.FireChargedShot()
        this.assert.equal(Shims.SentCalls.Length, 2)
        this.assert.equal(Shims.SentCalls[1], "{LButton down}")
        this.assert.equal(Shims.SentCalls[2], "{LButton up}")
    }
}
