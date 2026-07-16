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
    ; Separate from the Spin.* hotkeys — reads the 3 slot colors without
    ; requiring any of them to match, so a real in-game test can show
    ; exactly what's actually there. Avoids the F-row for the same reason
    ; every other default in this project does now.
    static DiagnosticKey := "^!d"

    static Init() {
        this.Enabled := DD.ReadBool("AbilityWheel", "Enabled", true)
        if !this.Enabled
            return

        this.WheelHotbarSlot := DD.Read("AbilityWheel", "WheelHotbarSlot", "3")
        this.ToleranceRGB := DD.ReadInt("AbilityWheel", "ToleranceRGB", "2")
        this.DiagnosticKey := DD.Read("AbilityWheel", "DiagnosticKey", "^!d")
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

        HotIfWinActive(gameCriterion)
        Hotkey(this.DiagnosticKey, ObjBindMethod(this, "DiagnoseSlots"))
        HotIfWinActive()

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

    ; Shared by SpinWheel() and DiagnoseSlots() — computes the 3 slot
    ; search boxes for whatever window size is currently detected.
    static ComputeSlotBoxes(winWidth, winHeight, &tlX1, &tlY1, &brX1, &brY1, &tlX2, &tlY2, &brX2, &brY2, &tlX3, &tlY3, &brX3, &brY3) {
        slotOffset := 0.186 * winHeight - 3
        centerY := Round(winHeight / 2)
        centerX := Round(winWidth / 2)
        x1 := Round(centerX - slotOffset)
        x2 := centerX
        x3 := Round(centerX + slotOffset)

        this.CalculateSearchBox(&tlX1, &tlY1, &brX1, &brY1, x1, centerY, winWidth, winHeight)
        this.CalculateSearchBox(&tlX2, &tlY2, &brX2, &brY2, x2, centerY, winWidth, winHeight)
        this.CalculateSearchBox(&tlX3, &tlY3, &brX3, &brY3, x3, centerY, winWidth, winHeight)
    }

    static SpinWheel(colorSlot1, colorSlot2, colorSlot3, spinName) {
        gameCriterion := DD.GameCriterion()
        if !WinExist(gameCriterion) {
            DD.Notify("AbilityWheel", "Le jeu n'est pas au premier plan.")
            return
        }

        WinGetPos(, , &winWidth, &winHeight, gameCriterion)
        CoordMode("Pixel", "Client")

        this.ComputeSlotBoxes(winWidth, winHeight, &tlX1, &tlY1, &brX1, &brY1, &tlX2, &tlY2, &brX2, &brY2, &tlX3, &tlY3, &brX3, &brY3)

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

    ; Opens the wheel exactly like SpinWheel() does, but instead of
    ; searching for a match, reads and reports the actual color sitting at
    ; the center of each of the 3 slot search boxes — win/lose regardless
    ; of whether it matches anything in [AbilityWheelColors]. Meant to be
    ; triggered in-game (DiagnosticKey, default Ctrl+Alt+D) when spins
    ; aren't detecting correctly, to tell you *what's actually there*
    ; instead of just "no match" — the two most likely explanations being
    ; wrong hex values for this game version/monitor, or a wrong
    ; WheelHotbarSlot not actually opening the wheel at all. Writes to
    ; wheel-diagnostic.txt next to the script/exe in addition to the
    ; on-screen MsgBox, so the report is easy to copy/share.
    static DiagnoseSlots(*) {
        gameCriterion := DD.GameCriterion()
        if !WinExist(gameCriterion) {
            DD.Notify("AbilityWheel", "Le jeu n'est pas au premier plan.")
            return
        }

        WinGetPos(, , &winWidth, &winHeight, gameCriterion)
        CoordMode("Pixel", "Client")

        this.ComputeSlotBoxes(winWidth, winHeight, &tlX1, &tlY1, &brX1, &brY1, &tlX2, &tlY2, &brX2, &brY2, &tlX3, &tlY3, &brX3, &brY3)

        Send("{" this.WheelHotbarSlot " DownTemp}")
        Sleep(5)
        Send("{" this.WheelHotbarSlot " up}")
        Sleep(300)

        color1 := PixelGetColor(Round((tlX1 + brX1) / 2), Round((tlY1 + brY1) / 2))
        color2 := PixelGetColor(Round((tlX2 + brX2) / 2), Round((tlY2 + brY2) / 2))
        color3 := PixelGetColor(Round((tlX3 + brX3) / 2), Round((tlY3 + brY3) / 2))

        report := "Fenetre detectee : " winWidth "x" winHeight "`n`n"
        report .= "Zone 1 [" tlX1 "," tlY1 " a " brX1 "," brY1 "] -> couleur lue : " Format("0x{:06X}", color1) "`n"
        report .= "Zone 2 [" tlX2 "," tlY2 " a " brX2 "," brY2 "] -> couleur lue : " Format("0x{:06X}", color2) "`n"
        report .= "Zone 3 [" tlX3 "," tlY3 " a " brX3 "," brY3 "] -> couleur lue : " Format("0x{:06X}", color3) "`n`n"
        report .= "Couleurs connues dans [AbilityWheelColors] :`n"
        for name, hex in this.Colors
            report .= "  " name " = " Format("0x{:06X}", hex) "`n"
        report .= "`nSi aucune des 3 couleurs lues ne ressemble a une couleur connue ci-dessus,"
        report .= " la roue ne s'est peut-etre pas ouverte (WheelHotbarSlot=" this.WheelHotbarSlot " incorrect ?)"
        report .= " ou les valeurs hex dans settings.ini doivent etre mises a jour."

        FileAppend(report "`n`n---`n`n", A_ScriptDir "\wheel-diagnostic.txt")
        MsgBox(report, "DD Toolkit - Diagnostic Roue", "Icon!")
    }

    static StatusText() {
        if !this.Enabled
            return "AbilityWheel : desactive"
        return "AbilityWheel : " this.RegisteredCount " spin(s) charge(s)"
    }
}
