#Requires AutoHotkey v2.0

; Cooldown-ability presser, as a reusable module. State lives in
; class-scoped statics (not bare globals) specifically so this module can
; be #Include'd alongside the other three in DDToolkit.ahk without any of
; them clobbering each other's same-named variables (they'd all have been
; called e.g. "intervalMs" as plain globals otherwise).
;
; Default hotkeys deliberately avoid the F-row: some players reserve F1-F12
; (or higher, via a separate window-switcher tool) for managing multiple
; simultaneous game clients/characters, and a toolkit default shouldn't
; compete for that space. ScrollLock/Pause are conventional AHK-community
; choices for exactly this reason — essentially never bound by any game.
class AutoAbilityModule {
    static Enabled := false
    static Key := "e"
    static IntervalMs := 47000
    static ToggleKey := "ScrollLock"
    static PanicKey := "Pause"
    static Running := false
    ; SetTimer identifies "which timer" solely by callback reference, and
    ; ObjBindMethod() returns a brand-new object every time it's called —
    ; two separately-created bindings of the same target+method are NOT
    ; the same callback as far as SetTimer is concerned (verified
    ; empirically: SetTimer(ObjBindMethod(this,"X"), 0) called with a
    ; fresh binding never disarms a timer armed with a different one).
    ; Toggle() and Panic() call SetTimer at different times, so the bound
    ; method MUST be created once and reused by both, or Panic() silently
    ; fails to stop the real timer while still reporting "stopped" — this
    ; shipped that way from v0.1.0 until caught here while writing tests.
    static BoundPressAbility := ""

    ; Reads config and registers hotkeys. Safe to call even when disabled
    ; in settings.ini — it just does nothing (no hotkeys registered).
    static Init() {
        this.Enabled := DD.ReadBool("AutoAbility", "Enabled", true)
        if !this.Enabled
            return

        this.Key := DD.Read("AutoAbility", "Key", "e")
        this.IntervalMs := DD.ReadInt("AutoAbility", "IntervalMs", "47000")
        this.ToggleKey := DD.Read("AutoAbility", "ToggleKey", "ScrollLock")
        this.PanicKey := DD.Read("AutoAbility", "PanicKey", "Pause")
        this.Running := false
        this.BoundPressAbility := ObjBindMethod(this, "PressAbility")

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
        ; SetTimer with a positive period never fires on its own the
        ; instant it's armed — the first tick only happens after a full
        ; IntervalMs has elapsed (verified against AutoHotkey's own docs).
        ; With the 47s default, arming used to mean "beep, then nothing
        ; for 47 seconds" — exactly what a quick real-world test would
        ; read as "doesn't work". Press once immediately on arm instead.
        if this.Running
            this.PressAbility()
        SetTimer(this.BoundPressAbility, this.Running ? this.IntervalMs : 0)
    }

    static Panic(*) {
        this.Running := false
        SetTimer(this.BoundPressAbility, 0)
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
