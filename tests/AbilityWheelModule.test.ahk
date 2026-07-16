#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\AbilityWheelModule.ahk"

ahu.RegisterSuite(AbilityWheelSuite)

class AbilityWheelSuite extends AutoHotUnitSuite {
    ; Init() calls Hotkey()/HotIfWinActive() for each valid Spin.* entry —
    ; both shimmed (see tests/Shims.ahk), so no real hotkey is ever
    ; registered. The fixture ([AbilityWheel] in tests/settings.ini)
    ; deliberately includes two malformed Spin.* entries (unknown color
    ; name, wrong field count) alongside one valid one, so this also
    ; exercises Init()'s error-tolerance path (each bad entry is skipped
    ; and reported via DD.Notify — a real but harmless tray toast — rather
    ; than crashing the whole Init()).
    beforeEach() {
        Shims.Reset()
    }

    init_registersOnlyValidSpinEntries() {
        AbilityWheelModule.Init()
        this.assert.isTrue(AbilityWheelModule.Enabled)
        this.assert.equal(AbilityWheelModule.WheelHotbarSlot, "3")
        this.assert.equal(AbilityWheelModule.ToleranceRGB, 2)
        this.assert.equal(AbilityWheelModule.Colors["TestColor1"], 0x111111)
        this.assert.equal(AbilityWheelModule.RegisteredCount, 1)
        this.assert.equal(AbilityWheelModule.DiagnosticKey, "NumpadMult")
    }

    computeSlotBoxes_matchesTheThreeCalculateSearchBoxCalls() {
        AbilityWheelModule.ComputeSlotBoxes(1920, 1080, &tlX1, &tlY1, &brX1, &brY1, &tlX2, &tlY2, &brX2, &brY2, &tlX3, &tlY3, &brX3, &brY3)
        ; Slot 2 is dead center; slots 1/3 are offset by 0.186*1080-3 either way.
        this.assert.equal(tlX2, 910)
        this.assert.equal(brX2, 1010)
        this.assert.isTrue(tlX1 < tlX2)
        this.assert.isTrue(brX3 > brX2)
    }

    calculateSearchBox_centersOnGivenPoint_at1080p() {
        AbilityWheelModule.CalculateSearchBox(&left, &top, &right, &bottom, 960, 540, 1920, 1080)
        this.assert.equal(left, 910)
        this.assert.equal(right, 1010)
        this.assert.equal(top, 490)
        this.assert.equal(bottom, 590)
    }

    calculateSearchBox_scalesDownProportionallyWithResolution() {
        ; Half of 1920x1080 -> the search box span should halve too (100px -> 50px).
        AbilityWheelModule.CalculateSearchBox(&left, &top, &right, &bottom, 480, 270, 960, 540)
        this.assert.equal(right - left, 50)
        this.assert.equal(bottom - top, 50)
    }

    resolveColor_returnsKnownColor() {
        AbilityWheelModule.Colors := Map("Sword", 0x72C1E2)
        this.assert.equal(AbilityWheelModule.ResolveColor("Sword"), 0x72C1E2)
    }

    resolveColor_throwsForUnknownName() {
        AbilityWheelModule.Colors := Map("Sword", 0x72C1E2)
        threw := false
        try {
            AbilityWheelModule.ResolveColor("NotAColor")
        } catch as err {
            threw := true
        }
        this.assert.isTrue(threw)
    }

    statusText_reportsDisabled() {
        AbilityWheelModule.Enabled := false
        this.assert.equal(AbilityWheelModule.StatusText(), "AbilityWheel : desactive")
    }

    statusText_reportsRegisteredCountWhenEnabled() {
        AbilityWheelModule.Enabled := true
        AbilityWheelModule.RegisteredCount := 5
        this.assert.equal(AbilityWheelModule.StatusText(), "AbilityWheel : 5 spin(s) charge(s)")
    }

    ; WinExist/WinGetPos/PixelSearch/Send are all shimmed (see Shims.ahk) —
    ; SpinWheel() runs for real end to end, but every OS query/input is
    ; faked and deterministic. WinExist=false here is also the real,
    ; unfakeable state whenever no Dungeon Defenders window exists.
    spinWheel_notifiesAndDoesNothingWhenGameNotRunning() {
        Shims.FakeWindowExists := false
        AbilityWheelModule.SpinWheel(0x111111, 0x222222, 0x333333, "Test")
        this.assert.equal(Shims.SentCalls.Length, 0)
    }

    spinWheel_opensWheelAndConfirmsAllThreeSlotsOnFullMatch() {
        Shims.FakeWindowExists := true
        Shims.FakeWindowPos := { x: 0, y: 0, w: 1920, h: 1080 }
        Shims.PixelSearchResult := { x: 500, y: 500 }
        AbilityWheelModule.WheelHotbarSlot := "3"
        AbilityWheelModule.SpinWheel(0x111111, 0x222222, 0x333333, "Test")
        ; 2 for opening the wheel (hotbar slot down/up) + 2 per matched
        ; slot (Space down/up) x 3 slots = 8.
        this.assert.equal(Shims.SentCalls.Length, 8)
        this.assert.equal(Shims.SentCalls[1], "{3 DownTemp}")
        this.assert.equal(Shims.SentCalls[2], "{3 up}")
        this.assert.equal(Shims.SentCalls[3], "{Space DownTemp}")
        this.assert.equal(Shims.SentCalls[4], "{Space up}")
    }

    ; SlotMatches() retries up to 100 times with RetryDelayMs between
    ; attempts when nothing matches — dropped to 0 here so the "never
    ; found" path (100 real retries) doesn't add ~1.5s of wall-clock time
    ; to the suite; the retry *count* logic itself is untouched.
    spinWheel_abandonsAfterFirstSlotNeverMatches() {
        Shims.FakeWindowExists := true
        Shims.FakeWindowPos := { x: 0, y: 0, w: 1920, h: 1080 }
        Shims.PixelSearchResult := ""
        savedDelay := AbilityWheelModule.RetryDelayMs
        AbilityWheelModule.RetryDelayMs := 0
        AbilityWheelModule.SpinWheel(0x111111, 0x222222, 0x333333, "Test")
        AbilityWheelModule.RetryDelayMs := savedDelay
        ; Only the hotbar-slot open — slot 1 never matches, so SpinWheel
        ; abandons before any Space Send() ever happens.
        this.assert.equal(Shims.SentCalls.Length, 2)
    }

    ; Direct coverage of SlotMatches() itself, not just via SpinWheel().
    slotMatches_returnsTrueAndSendsSpaceOnImmediateMatch() {
        Shims.PixelSearchResult := { x: 10, y: 10 }
        result := AbilityWheelModule.SlotMatches(0, 0, 100, 100, 0xFF0000)
        this.assert.isTrue(result)
        this.assert.equal(Shims.SentCalls.Length, 2)
        this.assert.equal(Shims.SentCalls[1], "{Space DownTemp}")
        this.assert.equal(Shims.SentCalls[2], "{Space up}")
    }

    slotMatches_returnsFalseAndSendsNothingAfterAllRetriesExhausted() {
        Shims.PixelSearchResult := ""
        savedDelay := AbilityWheelModule.RetryDelayMs
        AbilityWheelModule.RetryDelayMs := 0
        result := AbilityWheelModule.SlotMatches(0, 0, 100, 100, 0xFF0000)
        AbilityWheelModule.RetryDelayMs := savedDelay
        this.assert.isFalse(result)
        this.assert.equal(Shims.SentCalls.Length, 0)
    }

    ; MsgBox/PixelGetColor/FileAppend are all real-or-shimmed safely (see
    ; Shims.ahk) — DiagnoseSlots() runs for real end to end.
    diagnoseSlots_notifiesAndDoesNothingWhenGameNotRunning() {
        Shims.FakeWindowExists := false
        AbilityWheelModule.DiagnoseSlots()
        this.assert.equal(Shims.SentCalls.Length, 0)
        this.assert.equal(Shims.MsgBoxCalls.Length, 0)
    }

    diagnoseSlots_opensWheelAndReportsSampledColors() {
        Shims.FakeWindowExists := true
        Shims.FakeWindowPos := { x: 0, y: 0, w: 1920, h: 1080 }
        Shims.PixelGetColorResult := 0xABCDEF
        AbilityWheelModule.WheelHotbarSlot := "3"
        AbilityWheelModule.Colors := Map("TestColor1", 0x111111)

        ; Real FileAppend/FileDelete against a scratch log path, never the
        ; real one next to a shipped exe.
        logPath := A_ScriptDir "\wheel-diagnostic.txt"
        if FileExist(logPath)
            FileDelete(logPath)

        AbilityWheelModule.DiagnoseSlots()

        this.assert.equal(Shims.SentCalls.Length, 2)
        this.assert.equal(Shims.SentCalls[1], "{3 DownTemp}")
        this.assert.equal(Shims.MsgBoxCalls.Length, 1)
        this.assert.isTrue(InStr(Shims.MsgBoxCalls[1].text, "0xABCDEF") > 0)
        this.assert.isTrue(InStr(Shims.MsgBoxCalls[1].text, "TestColor1 = 0x111111") > 0)
        this.assert.isTrue(FileExist(logPath) != "")

        FileDelete(logPath)
    }
}
