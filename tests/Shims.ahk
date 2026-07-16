#Requires AutoHotkey v2.0

; Test-only replacements for the OS-interacting built-ins the modules call.
; AHK v2 lets a same-named user-defined function override a built-in for
; the rest of the script (verified empirically before relying on this) —
; so these definitions replace the real functions for this ENTIRE test
; process, letting every test exercise the real Send()/PixelSearch()/
; Hotkey()-calling code paths without a single real keystroke, click,
; screen read, or hotkey registration ever reaching the OS.
;
; Hotkey()/HotIfWinActive() specifically: every module's Init() registers
; real hotkeys, and a test fixture needs *some* key string for each one.
; Shimming these two means that string's real-world safety no longer
; depends on picking an obscure key by convention — no test hotkey is ever
; actually registered with Windows, period, so the fixture can use any key
; name without risk of colliding with anything a real user (or a separate
; multi-client window-switcher tool) has bound for real.
;
; Because the override is global and total (there's no "call the real one
; as a fallback" once a name is shadowed), nothing else in this suite may
; rely on genuine OS behavior of these functions — as of this writing
; nothing does. If a future test genuinely needs the real OS behavior of
; one of these, it belongs in a separate, non-shimmed test process, not
; here.
class Shims {
    static SentCalls := []
    static SentEventCalls := []
    ; Array of {callback, period} — lets tests assert not just the period
    ; but also that arm/disarm calls reused the *same* callback reference
    ; (see AutoAbilityModule.ahk's BoundPressAbility comment for why that
    ; distinction is exactly the bug this shim exists to catch).
    static SetTimerCalls := []
    ; key name -> remaining "physically held" ticks. GetKeyState(key, "P")
    ; returns true and decrements once per call while > 0, then false —
    ; simulating a button held for exactly that many polls, the same shape
    ; as AutoClickerModule.TurboFire()'s while-loop. Real GetKeyState(,"P")
    ; is immune to synthetic Send()/SendEvent() by AHK's own design (this
    ; was verified empirically too) — no test can fake a physical hold
    ; through real input, only through this shim.
    static KeyStatePMode := Map()
    ; "" = PixelSearch never finds a match; otherwise {x, y} of the match.
    static PixelSearchResult := ""
    ; Single fixed color every PixelGetColor() call returns.
    static PixelGetColorResult := 0x000000
    static FakeWindowExists := false
    static FakeWindowPos := { x: 0, y: 0, w: 1920, h: 1080 }
    ; "" = user cancelled the (real, modal, blocking) folder picker.
    static DirSelectResult := ""
    static MsgBoxCalls := []
    ; "KeyName|ValueName" -> return value. Absent = throws, matching real
    ; RegRead's behavior for a missing key/value with no Default argument
    ; (every call in this codebase omits Default and relies on try/catch).
    static RegReadBehavior := Map()
    ; Array of {keyName, callback} — every Hotkey() registration attempt,
    ; real or not (see the class header for why none are ever real).
    static HotkeyCalls := []
    ; SetKeyDelay/SetMouseDelay have no OS-input side effect at all (pure
    ; internal AHK config) — shimmed only so tests can assert *which one*
    ; a module actually called, not for safety. See
    ; AutoClickerModule.ahk's SetMouseDelay comment for why that
    ; distinction is exactly the bug this shim exists to catch.
    static SetKeyDelayCalls := []
    static SetMouseDelayCalls := []

    static Reset() {
        this.SentCalls := []
        this.SentEventCalls := []
        this.SetTimerCalls := []
        this.KeyStatePMode := Map()
        this.PixelSearchResult := ""
        this.PixelGetColorResult := 0x000000
        this.FakeWindowExists := false
        this.FakeWindowPos := { x: 0, y: 0, w: 1920, h: 1080 }
        this.DirSelectResult := ""
        this.MsgBoxCalls := []
        this.RegReadBehavior := Map()
        this.HotkeyCalls := []
        this.SetKeyDelayCalls := []
        this.SetMouseDelayCalls := []
    }
}

Send(keys) {
    Shims.SentCalls.Push(keys)
}

SendEvent(keys) {
    Shims.SentEventCalls.Push(keys)
}

GetKeyState(keyName, mode := "") {
    if (mode = "P") {
        remaining := Shims.KeyStatePMode.Has(keyName) ? Shims.KeyStatePMode[keyName] : 0
        if (remaining > 0) {
            Shims.KeyStatePMode[keyName] := remaining - 1
            return true
        }
        return false
    }
    return false
}

PixelSearch(&outX, &outY, x1, y1, x2, y2, colorId, variation := 0) {
    if (Shims.PixelSearchResult != "") {
        outX := Shims.PixelSearchResult.x
        outY := Shims.PixelSearchResult.y
        return true
    }
    return false
}

PixelGetColor(x, y, mode := "") {
    return Shims.PixelGetColorResult
}

SetKeyDelay(delay := "", pressDuration := "", play := "") {
    Shims.SetKeyDelayCalls.Push(delay)
}

SetMouseDelay(delay := "", play := "") {
    Shims.SetMouseDelayCalls.Push(delay)
}

SetTimer(callback := "", period := "", priority := "") {
    Shims.SetTimerCalls.Push({ callback: callback, period: period })
}

Hotkey(keyName, callback := "", options := "") {
    Shims.HotkeyCalls.Push({ keyName: keyName, callback: callback })
}

; Context-setting only for the (also shimmed) Hotkey() above — a no-op.
HotIfWinActive(winTitle := "", winText := "") {
}

WinExist(criterion := "") {
    return Shims.FakeWindowExists ? 99999 : 0
}

WinGetPos(&x := "", &y := "", &w := "", &h := "", criterion := "") {
    x := Shims.FakeWindowPos.x
    y := Shims.FakeWindowPos.y
    w := Shims.FakeWindowPos.w
    h := Shims.FakeWindowPos.h
}

; Real DirSelect() is a real, modal, blocking folder-picker dialog — if
; ever called for real inside an automated test, it would hang forever
; waiting for a human to interact with it.
DirSelect(startingFolder := "", options := "", prompt := "") {
    return Shims.DirSelectResult
}

; Real MsgBox() is also real and modal/blocking, for the same reason.
MsgBox(text := "", title := "", options := "") {
    Shims.MsgBoxCalls.Push({ text: text, title: title, options: options })
    return "OK"
}

RegRead(keyName, valueName := "", default := "") {
    lookupKey := keyName "|" valueName
    if Shims.RegReadBehavior.Has(lookupKey)
        return Shims.RegReadBehavior[lookupKey]
    throw Error("simulated RegRead failure for " lookupKey)
}
