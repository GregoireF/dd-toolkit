#Requires AutoHotkey v2.0

; Tower stacking, as a reusable module (see AutoAbilityModule.ahk's header
; comment for why this is a class instead of top-level globals/hotkeys).
; Registering hotkeys with a class method as the standalone script did
; with static "^1::" labels isn't possible here — hotkey *labels* are a
; top-level-script-only construct, not valid inside a class body — so
; this uses the dynamic HotIfWinActive()/Hotkey() functions instead, with
; one shared handler for all 10 slots (AHK passes the hotkey's own name,
; e.g. "^1", as the callback's first parameter).
class TowerStackingModule {
    static Enabled := false
    static Modifier := "Ctrl"

    static Init() {
        this.Enabled := DD.ReadBool("TowerStacking", "Enabled", true)
        if !this.Enabled
            return

        this.Modifier := DD.Read("TowerStacking", "Modifier", "Ctrl")
        modSymbol := this.ModifierSymbol(this.Modifier)

        SendMode("Input")
        SetKeyDelay(-1, -1) ; zero artificial delay: closer to simultaneous = more reliable stack

        HotIfWinActive(DD.GameCriterion())
        Loop 10 {
            slot := (A_Index = 10) ? "0" : String(A_Index)
            Hotkey(modSymbol slot, ObjBindMethod(this, "HandleHotkey"))
        }
        HotIfWinActive()
    }

    static ModifierSymbol(name) {
        switch StrLower(Trim(name)) {
            case "ctrl", "control": return "^"
            case "alt": return "!"
            case "shift": return "+"
            case "win", "windows": return "#"
            default: return "^"
        }
    }

    ; ThisHotkey is e.g. "^1" — the slot key is always its last character.
    static HandleHotkey(thisHotkey) {
        this.Stack(SubStr(thisHotkey, -1))
    }

    static Stack(slotKey) {
        Send("{" slotKey " down}{Space down}{Space up}{" slotKey " up}")
    }

    static StatusText() {
        if !this.Enabled
            return "TowerStacking : desactive"
        return "TowerStacking : " this.Modifier "+1..0"
    }
}
