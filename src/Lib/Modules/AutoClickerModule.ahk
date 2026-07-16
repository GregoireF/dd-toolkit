#Requires AutoHotkey v2.0

; Turbo-fire autoclicker, as a reusable module (see AutoAbilityModule.ahk's
; header for why this is a class). LButton/RButton firing depends on a
; *compound* condition (armed AND, optionally, game-focused) that a plain
; WinTitle string can't express — so this uses the generic HotIf(callback)
; function (a boolean-returning predicate), not HotIfWinActive(criterion).
; This is the legitimate use of HotIf() the earlier bug (see CLAUDE.md) was
; a misuse of: HotIf() wants a callback, and here it actually gets one.
class AutoClickerModule {
    static Enabled := false
    static IntervalMs := 20
    static LeftToggleKey := "CapsLock"
    static RightToggleKey := "Insert"
    static ScopeToGame := true
    static LeftActive := false
    static RightActive := false

    static Init() {
        this.Enabled := DD.ReadBool("AutoClicker", "Enabled", true)
        if !this.Enabled
            return

        this.IntervalMs := DD.ReadInt("AutoClicker", "IntervalMs", "20")
        this.LeftToggleKey := DD.Read("AutoClicker", "LeftToggleKey", "CapsLock")
        this.RightToggleKey := DD.Read("AutoClicker", "RightToggleKey", "Insert")
        this.ScopeToGame := DD.ReadBool("AutoClicker", "ScopeToGame", true)
        this.LeftActive := false
        this.RightActive := false

        ; SetKeyDelay only governs *keyboard* keys sent by Send/SendEvent —
        ; it has zero effect on mouse buttons like LButton/RButton, which
        ; are governed by SetMouseDelay instead (verified against
        ; AutoHotkey's own docs). This module only ever sends mouse
        ; buttons, so the SetKeyDelay call here was silently a no-op:
        ; IntervalMs never actually controlled the click rate at all.
        SetMouseDelay(this.IntervalMs)

        ; Toggle keys always work regardless of ScopeToGame — arming/
        ; disarming sends no input, so there's nothing to scope.
        Hotkey(this.LeftToggleKey, ObjBindMethod(this, "ToggleLeft"))
        Hotkey(this.RightToggleKey, ObjBindMethod(this, "ToggleRight"))

        HotIf(ObjBindMethod(this, "ShouldFireLeft"))
        Hotkey("LButton", ObjBindMethod(this, "FireLeft"))
        HotIf(ObjBindMethod(this, "ShouldFireRight"))
        Hotkey("RButton", ObjBindMethod(this, "FireRight"))
        HotIf() ; reset context so it doesn't leak onto hotkeys defined after this
    }

    static ShouldFireLeft(*) {
        return this.LeftActive && (!this.ScopeToGame || WinActive(DD.GameCriterion()))
    }

    static ShouldFireRight(*) {
        return this.RightActive && (!this.ScopeToGame || WinActive(DD.GameCriterion()))
    }

    static ToggleLeft(*) {
        this.LeftActive := !this.LeftActive
        DD.Beep(this.LeftActive)
    }

    static ToggleRight(*) {
        this.RightActive := !this.RightActive
        DD.Beep(this.RightActive)
    }

    static FireLeft(*) {
        this.TurboFire("LButton")
    }

    static FireRight(*) {
        this.TurboFire("RButton")
    }

    ; Fires repeated synthetic clicks for as long as the *physical* button
    ; ("P" mode) stays down.
    static TurboFire(button) {
        while GetKeyState(button, "P")
            SendEvent("{" button "}")
    }

    static StatusText() {
        if !this.Enabled
            return "AutoClicker : desactive"
        left := this.LeftActive ? "ARME" : "repos"
        right := this.RightActive ? "ARME" : "repos"
        return "AutoClicker : G=" this.LeftToggleKey " (" left ") / D=" this.RightToggleKey " (" right ")"
    }
}
