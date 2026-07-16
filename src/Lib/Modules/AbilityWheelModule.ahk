#Requires AutoHotkey v2.0

; Jester Wheel of Fortune automation, as a reusable module (see
; AutoAbilityModule.ahk's header for why this is a class). Detection math
; unchanged from the standalone AbilityWheel.ahk this was extracted from —
; see that file's history for the full rationale versus the original
; community source.
;
; Note: closures created here reference the class by its literal name
; (AbilityWheelModule.SpinWheel(...)) rather than a captured `this` — both
; should work, but the class name is unambiguous regardless of closure
; subtleties this repo hasn't independently verified, so it's the safer
; choice given nothing here can be run/tested inside this environment.
class AbilityWheelModule {
    static Enabled := false
    static WheelHotbarSlot := "3"
    static ToleranceRGB := 2
    static Colors := Map()
    static RegisteredCount := 0

    static Init() {
        this.Enabled := DD.ReadBool("AbilityWheel", "Enabled", true)
        if !this.Enabled
            return

        this.WheelHotbarSlot := DD.Read("AbilityWheel", "WheelHotbarSlot", "3")
        this.ToleranceRGB := DD.ReadInt("AbilityWheel", "ToleranceRGB", "2")
        this.RegisteredCount := 0

        this.Colors := Map()
        for name, hex in DD.ReadSection("AbilityWheelColors") {
            try {
                this.Colors[name] := Integer(hex)
            } catch {
                DD.Notify("AbilityWheel", "Couleur ignoree, hex invalide (" name "='" hex "').")
            }
        }

        gameCriterion := DD.GameCriterion()
        for key, value in DD.ReadSection("AbilityWheel") {
            if (SubStr(key, 1, 5) != "Spin.")
                continue

            try {
                parts := StrSplit(value, ",")
                if (parts.Length != 4)
                    throw ValueError("attendu 4 champs Color1,Color2,Color3,Hotkey, trouve " parts.Length)

                c1 := this.ResolveColor(Trim(parts[1]))
                c2 := this.ResolveColor(Trim(parts[2]))
                c3 := this.ResolveColor(Trim(parts[3]))
                hotkeyStr := Trim(parts[4])
                spinName := SubStr(key, StrLen("Spin.") + 1)

                HotIfWinActive(gameCriterion)
                Hotkey(hotkeyStr, (*) => AbilityWheelModule.SpinWheel(c1, c2, c3, spinName))
                HotIfWinActive()
                this.RegisteredCount++
            } catch as err {
                DD.Notify("AbilityWheel", "Entree ignoree (" key "): " err.Message)
            }
        }
    }

    static ResolveColor(name) {
        if !this.Colors.Has(name)
            throw ValueError("Couleur inconnue dans [AbilityWheelColors]: " name)
        return this.Colors[name]
    }

    static CalculateSearchBox(&topLeftX, &topLeftY, &bottomRightX, &bottomRightY, centerX, centerY, windowWidth, windowHeight) {
        boxWidth := 100 * windowWidth / 1920
        boxHeight := 100 * windowHeight / 1080
        halfWidth := Floor(boxWidth / 2)
        halfHeight := Floor(boxHeight / 2)

        topLeftX := Round(centerX - halfWidth)
        topLeftY := Round(centerY - halfHeight)
        bottomRightX := Round(centerX + halfWidth)
        bottomRightY := Round(centerY + halfHeight)
    }

    ; The original community source polled PixelSearch back-to-back with no
    ; delay between attempts — on a fast enough machine that can burn
    ; through all 100 retries in a handful of milliseconds, failing before
    ; the wheel's spin animation has even settled. A small delay spreads
    ; the same retry budget over a controlled ~1.5s window instead, and
    ; costs nothing (PixelSearch itself isn't free either).
    static RetryDelayMs := 15

    static SlotMatches(boxLeft, boxTop, boxRight, boxBottom, colorId) {
        attemptsLeft := 100
        while (attemptsLeft > 0) {
            if PixelSearch(&px, &py, boxLeft, boxTop, boxRight, boxBottom, colorId, this.ToleranceRGB) {
                Send("{Space DownTemp}")
                Sleep(10)
                Send("{Space up}")
                return true
            }
            attemptsLeft--
            if (attemptsLeft > 0)
                Sleep(this.RetryDelayMs)
        }
        return false
    }

    static SpinWheel(colorSlot1, colorSlot2, colorSlot3, spinName) {
        gameCriterion := DD.GameCriterion()
        if !WinExist(gameCriterion) {
            DD.Notify("AbilityWheel", "Le jeu n'est pas au premier plan.")
            return
        }

        WinGetPos(, , &winWidth, &winHeight, gameCriterion)
        CoordMode("Pixel", "Client")

        slotOffset := 0.186 * winHeight - 3
        centerY := Round(winHeight / 2)
        centerX := Round(winWidth / 2)
        x1 := Round(centerX - slotOffset)
        x2 := centerX
        x3 := Round(centerX + slotOffset)

        this.CalculateSearchBox(&tlX1, &tlY1, &brX1, &brY1, x1, centerY, winWidth, winHeight)
        this.CalculateSearchBox(&tlX2, &tlY2, &brX2, &brY2, x2, centerY, winWidth, winHeight)
        this.CalculateSearchBox(&tlX3, &tlY3, &brX3, &brY3, x3, centerY, winWidth, winHeight)

        Send("{" this.WheelHotbarSlot " DownTemp}")
        Sleep(5)
        Send("{" this.WheelHotbarSlot " up}")
        Sleep(100)

        if !this.SlotMatches(tlX1, tlY1, brX1, brY1, colorSlot1) {
            DD.Notify("AbilityWheel", spinName ": slot 1 non detecte, abandon.")
            return
        }
        if !this.SlotMatches(tlX2, tlY2, brX2, brY2, colorSlot2) {
            DD.Notify("AbilityWheel", spinName ": slot 2 non detecte, abandon.")
            return
        }
        if !this.SlotMatches(tlX3, tlY3, brX3, brY3, colorSlot3) {
            DD.Notify("AbilityWheel", spinName ": slot 3 non detecte, abandon.")
            return
        }
        DD.Beep(true)
    }

    static StatusText() {
        if !this.Enabled
            return "AbilityWheel : desactive"
        return "AbilityWheel : " this.RegisteredCount " spin(s) charge(s)"
    }
}
