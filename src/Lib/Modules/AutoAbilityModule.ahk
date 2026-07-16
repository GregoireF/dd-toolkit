#Requires AutoHotkey v2.0

; Cooldown-ability presser, as a reusable module. State lives in
; class-scoped statics (not bare globals) specifically so this module can
; be #Include'd alongside the other three in DDToolkit.ahk without any of
; them clobbering each other's same-named variables (they'd all have been
; called e.g. "intervalMs" as plain globals otherwise).
class AutoAbilityModule {
    static Enabled := false
    static Key := "e"
    static IntervalMs := 47000
    static ToggleKey := "F2"
    static PanicKey := "F3"
    static Running := false

    ; Reads config and registers hotkeys. Safe to call even when disabled
    ; in settings.ini — it just does nothing (no hotkeys registered).
    static Init() {
        this.Enabled := DD.ReadBool("AutoAbility", "Enabled", true)
        if !this.Enabled
            return

        this.Key := DD.Read("AutoAbility", "Key", "e")
        this.IntervalMs := DD.ReadInt("AutoAbility", "IntervalMs", "47000")
        this.ToggleKey := DD.Read("AutoAbility", "ToggleKey", "F2")
        this.PanicKey := DD.Read("AutoAbility", "PanicKey", "F3")
        this.Running := false

        HotIfWinActive(DD.GameCriterion())
        Hotkey(this.ToggleKey, ObjBindMethod(this, "Toggle"))
        Hotkey(this.PanicKey, ObjBindMethod(this, "Panic"))
        HotIfWinActive()
    }

    static PressAbility() {
        Send(this.Key)
    }

    static Toggle(*) {
        this.Running := !this.Running
        DD.Beep(this.Running)
        SetTimer(ObjBindMethod(this, "PressAbility"), this.Running ? this.IntervalMs : 0)
    }

    static Panic(*) {
        this.Running := false
        SetTimer(ObjBindMethod(this, "PressAbility"), 0)
        DD.Beep(false)
    }

    ; Short one-line summary for the tray tooltip / GUI status column.
    static StatusText() {
        if !this.Enabled
            return "AutoAbility : desactive"
        state := this.Running ? "arme" : "au repos"
        return "AutoAbility : " state " (" this.ToggleKey " -> " this.Key " / " Round(this.IntervalMs / 1000) "s)"
    }
}
