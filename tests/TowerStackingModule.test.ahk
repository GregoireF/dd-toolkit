#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\TowerStackingModule.ahk"

ahu.RegisterSuite(TowerStackingSuite)

class TowerStackingSuite extends AutoHotUnitSuite {
    ; Init() calls Hotkey()/HotIfWinActive() 10 times — both shimmed (see
    ; tests/Shims.ahk), so no real hotkey is ever registered.
    beforeEach() {
        Shims.Reset()
    }

    init_loadsConfigFromIni() {
        TowerStackingModule.Init()
        this.assert.isTrue(TowerStackingModule.Enabled)
        this.assert.equal(TowerStackingModule.Modifier, "Alt")
    }

    modifierSymbol_mapsKnownNames() {
        this.assert.equal(TowerStackingModule.ModifierSymbol("Ctrl"), "^")
        this.assert.equal(TowerStackingModule.ModifierSymbol("control"), "^")
        this.assert.equal(TowerStackingModule.ModifierSymbol("Alt"), "!")
        this.assert.equal(TowerStackingModule.ModifierSymbol("Shift"), "+")
        this.assert.equal(TowerStackingModule.ModifierSymbol("Win"), "#")
        this.assert.equal(TowerStackingModule.ModifierSymbol("windows"), "#")
    }

    modifierSymbol_isCaseAndWhitespaceTolerant() {
        this.assert.equal(TowerStackingModule.ModifierSymbol("  CTRL  "), "^")
    }

    modifierSymbol_defaultsToCtrlForUnknownName() {
        this.assert.equal(TowerStackingModule.ModifierSymbol("Nonsense"), "^")
    }

    statusText_reportsDisabled() {
        TowerStackingModule.Enabled := false
        this.assert.equal(TowerStackingModule.StatusText(), "TowerStacking : desactive")
    }

    statusText_reportsModifierWhenEnabled() {
        TowerStackingModule.Enabled := true
        TowerStackingModule.Modifier := "Alt"
        this.assert.equal(TowerStackingModule.StatusText(), "TowerStacking : Alt+1..0")
    }

    ; Send() is shimmed (see Shims.ahk) — the real Stack()/HandleHotkey()
    ; run for real, but the keys only ever land in Shims.SentCalls.
    stack_sendsSlotKeyAndSpaceCombo() {
        TowerStackingModule.Stack("3")
        this.assert.equal(Shims.SentCalls.Length, 1)
        this.assert.equal(Shims.SentCalls[1], "{3 down}{Space down}{Space up}{3 up}")
    }

    handleHotkey_extractsSlotFromHotkeyNameAndStacks() {
        TowerStackingModule.HandleHotkey("^7")
        this.assert.equal(Shims.SentCalls.Length, 1)
        this.assert.equal(Shims.SentCalls[1], "{7 down}{Space down}{Space up}{7 up}")
    }
}
