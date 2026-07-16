#Requires AutoHotkey v2.0

; Apprentice charge-shot timing, as a reusable module (see
; AutoAbilityModule.ahk's header for why this is a class).
;
; Why this macro and not the other 3 the Steam automation guide/DD wiki
; mentioned: staves benefit from a partially-charged shot (~70% charge is
; cited by the DD wiki as a good benchmark) fired with consistent timing —
; a real, documented mechanic. Minion Line Placement, Aura Stacking, and
; Upgrade Automation were all considered and explicitly dropped:
;   - Redux specifically removed the minion-collision timer that made a
;     placement macro valuable elsewhere ("For Redux, there is no timer
;     for minion collision" — DD wiki, DD_Life_Hacks).
;   - "Aura stacking" isn't frame-perfect stacking at all — it's just
;     placing 2-3 *different* auras on the same spot, which don't collide
;     with each other; no special macro technique is actually needed.
;   - Upgrading already has a built-in bulk tool ("Pro Mode": Shift+click
;     = 10 upgrades, Ctrl+click = 50 at once) — an external macro would
;     only add value for an unattended AFK loop, a different risk category
;     than the input-precision assists the rest of this toolkit provides.
;
; This macro holds the attack button for a fixed, configurable duration
; then releases it automatically — one keypress, one consistent charge,
; instead of manually timing a hold by feel.
class ChargeShotModule {
    static Enabled := false
    static TriggerKey := "^Space"
    static ChargeMs := 500
    static AttackButton := "LButton"

    static Init() {
        this.Enabled := DD.ReadBool("ChargeShot", "Enabled", true)
        if !this.Enabled
            return

        this.TriggerKey := DD.Read("ChargeShot", "TriggerKey", "^Space")
        this.ChargeMs := DD.ReadInt("ChargeShot", "ChargeMs", "500")
        this.AttackButton := DD.Read("ChargeShot", "AttackButton", "LButton")

        HotIfWinActive(DD.GameCriterion())
        Hotkey(this.TriggerKey, ObjBindMethod(this, "FireChargedShot"))
        HotIfWinActive()
    }

    static FireChargedShot(*) {
        Send("{" this.AttackButton " down}")
        Sleep(this.ChargeMs)
        Send("{" this.AttackButton " up}")
        DD.Beep(true)
    }

    static StatusText() {
        if !this.Enabled
            return "ChargeShot : desactive"
        return "ChargeShot : " this.TriggerKey " -> charge " this.ChargeMs "ms puis relache"
    }
}
