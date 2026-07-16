#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"
#Include "%A_ScriptDir%\..\src\Lib\Modules\GameTweaksModule.ahk"

ahu.RegisterSuite(GameTweaksSuite)

class GameTweaksSuite extends AutoHotUnitSuite {
    beforeEach() {
        Shims.Reset()
    }

    ; ResolveInstallPath()/AutoDetectInstallPath() can call DD.Write to
    ; persist a newly-found InstallPath into the fixture ini — reset both
    ; the in-memory static and the on-disk fixture value after every test
    ; so a later test run (or a git diff on tests/settings.ini) never sees
    ; a stray scratch path left over from this suite.
    afterEach() {
        GameTweaksModule.InstallPath := ""
        DD.Write("GameTweaks", "InstallPath", "")
    }

    ; No hotkeys involved — just reads config. Safe unconditionally.
    init_loadsInstallPathFromIni() {
        GameTweaksModule.Init()
        this.assert.equal(GameTweaksModule.InstallPath, "")
    }

    computeFixedContent_updatesAllFourKeys_normalVram() {
        input := "[TextureStreaming]`nPoolSize=256`nPoolSizeLow=256`nPoolSizeMedium=384`nPoolSizeHigh=512`n"
        result := GameTweaksModule.ComputeFixedContent(input, false, &changed)
        this.assert.equal(changed, 4)
        this.assert.isTrue(InStr(result, "PoolSize=1536") > 0)
        this.assert.isTrue(InStr(result, "PoolSizeLow=768") > 0)
        this.assert.isTrue(InStr(result, "PoolSizeMedium=1536") > 0)
        this.assert.isTrue(InStr(result, "PoolSizeHigh=3072") > 0)
    }

    computeFixedContent_usesLowerValues_lowVram() {
        input := "PoolSize=256`nPoolSizeLow=256`nPoolSizeMedium=384`nPoolSizeHigh=512`n"
        result := GameTweaksModule.ComputeFixedContent(input, true, &changed)
        this.assert.equal(changed, 4)
        this.assert.isTrue(InStr(result, "PoolSize=1024") > 0)
        this.assert.isTrue(InStr(result, "PoolSizeHigh=2048") > 0)
    }

    ; The real-world false-positive risk this regex has to avoid: matched
    ; and fixed once already against a real installed UDKEngine.ini this
    ; session (see docs/CORRECTIFS-JEU.md) — pinned here so a future regex
    ; change can't silently regress it.
    computeFixedContent_doesNotTouchUnrelatedPoolSizeSubstring() {
        input := "CommonAudioPoolSize=64`nPoolSize=256`n"
        result := GameTweaksModule.ComputeFixedContent(input, false, &changed)
        this.assert.equal(changed, 1)
        this.assert.isTrue(InStr(result, "CommonAudioPoolSize=64") > 0)
        this.assert.isTrue(InStr(result, "PoolSize=1536") > 0)
    }

    computeFixedContent_reportsZeroChangesWhenNoMatchingLines() {
        input := "SomeOtherSetting=42`n"
        result := GameTweaksModule.ComputeFixedContent(input, false, &changed)
        this.assert.equal(changed, 0)
        this.assert.equal(result, input)
    }

    ; Regression test: an earlier `\s*$` pattern was greedy enough to eat
    ; the line's own trailing newline (and would have eaten further blank
    ; lines too, since \s matches \n) instead of just an optional trailing
    ; \r — this pins the fix so it can't quietly regress.
    computeFixedContent_preservesTrailingNewlineAndFollowingLines_crlf() {
        input := "PoolSize=256`r`nNextSetting=1`r`n"
        result := GameTweaksModule.ComputeFixedContent(input, false, &changed)
        this.assert.equal(result, "PoolSize=1536`r`nNextSetting=1`r`n")
    }

    computeVsyncContent_enablesVsync() {
        result := GameTweaksModule.ComputeVsyncContent("UseVsync=False`n", true, &changed)
        this.assert.equal(changed, 1)
        this.assert.equal(result, "UseVsync=True`n")
    }

    computeVsyncContent_disablesVsync() {
        result := GameTweaksModule.ComputeVsyncContent("UseVsync=True`n", false, &changed)
        this.assert.equal(changed, 1)
        this.assert.equal(result, "UseVsync=False`n")
    }

    computeVsyncContent_reportsZeroWhenLineMissing() {
        input := "SomeOtherSetting=42`n"
        result := GameTweaksModule.ComputeVsyncContent(input, true, &changed)
        this.assert.equal(changed, 0)
        this.assert.equal(result, input)
    }

    ; Values and section confirmed against a real installed UDKEngine.ini
    ; this session (see docs/CORRECTIFS-JEU.md) — all 9 keys found exactly
    ; once each under [SystemSettings].
    computePerformanceContent_updatesAllNineKeys() {
        input := "DetailMode=2`r`nGraphicsQualityMode=2`r`nDynamicShadows=True`r`nAmbientOcclusion=True`r`nUseHighQualityBloom=True`r`nSkeletalMeshLODBias=0`r`nParticleLODBias=0`r`nMaxAnisotropy=8`r`nMaxMultisamples=1`r`n"
        result := GameTweaksModule.ComputePerformanceContent(input, &changed)
        this.assert.equal(changed, 9)
        this.assert.isTrue(InStr(result, "DetailMode=0") > 0)
        this.assert.isTrue(InStr(result, "GraphicsQualityMode=0") > 0)
        this.assert.isTrue(InStr(result, "DynamicShadows=False") > 0)
        this.assert.isTrue(InStr(result, "AmbientOcclusion=False") > 0)
        this.assert.isTrue(InStr(result, "UseHighQualityBloom=False") > 0)
        this.assert.isTrue(InStr(result, "SkeletalMeshLODBias=1") > 0)
        this.assert.isTrue(InStr(result, "ParticleLODBias=2") > 0)
        this.assert.isTrue(InStr(result, "MaxAnisotropy=1") > 0)
        this.assert.isTrue(InStr(result, "MaxMultisamples=1") > 0)
    }

    computePerformanceContent_reportsPartialMatchWhenSomeKeysMissing() {
        input := "DetailMode=2`r`nSomeUnrelatedSetting=1`r`n"
        result := GameTweaksModule.ComputePerformanceContent(input, &changed)
        this.assert.equal(changed, 1)
        this.assert.isTrue(InStr(result, "DetailMode=0") > 0)
        this.assert.isTrue(InStr(result, "SomeUnrelatedSetting=1") > 0)
    }

    computePerformanceContent_reportsZeroWhenNoMatchingLines() {
        input := "SomeOtherSetting=42`r`n"
        result := GameTweaksModule.ComputePerformanceContent(input, &changed)
        this.assert.equal(changed, 0)
        this.assert.equal(result, input)
    }

    looksLikeGameFolder_trueWhenUDKGameConfigSubfolderExists() {
        scratch := A_Temp "\dd-toolkit-test-" A_TickCount "-real"
        DirCreate(scratch "\UDKGame\Config")
        this.assert.isTrue(GameTweaksModule.LooksLikeGameFolder(scratch))
        DirDelete(scratch, true)
    }

    looksLikeGameFolder_falseWhenSubfolderMissing() {
        scratch := A_Temp "\dd-toolkit-test-" A_TickCount "-empty"
        DirCreate(scratch)
        this.assert.isFalse(GameTweaksModule.LooksLikeGameFolder(scratch))
        DirDelete(scratch, true)
    }

    looksLikeGameFolder_falseWhenPathDoesNotExistAtAll() {
        this.assert.isFalse(GameTweaksModule.LooksLikeGameFolder(A_Temp "\dd-toolkit-test-does-not-exist-" A_TickCount))
    }

    statusText_reportsUnconfigured() {
        GameTweaksModule.InstallPath := ""
        this.assert.equal(GameTweaksModule.StatusText(), "GameTweaks : dossier du jeu non configure")
    }

    statusText_reportsInstallPathWhenConfigured() {
        GameTweaksModule.InstallPath := "C:\Games\Dungeon Defenders"
        this.assert.equal(GameTweaksModule.StatusText(), "GameTweaks : C:\Games\Dungeon Defenders")
    }

    ; --- AutoDetectInstallPath: RegRead is shimmed (see Shims.ahk) since
    ; the real registry contents vary machine to machine (this dev
    ; machine happens to have a real Steam+DD install, per this session's
    ; earlier findings, but CI never will) — shimming keeps this
    ; deterministic everywhere. Real scratch folders are used for the
    ; DirExist-based LooksLikeGameFolder check, since plain file I/O
    ; carries none of the OS-input risk Send/PixelSearch do. ---

    autoDetectInstallPath_findsGameViaHkcuSteamPath() {
        scratchSteam := A_Temp "\dd-toolkit-test-steam-hkcu-" A_TickCount
        DirCreate(scratchSteam "\steamapps\common\Dungeon Defenders\UDKGame\Config")
        Shims.RegReadBehavior["HKCU\Software\Valve\Steam|SteamPath"] := scratchSteam
        result := GameTweaksModule.AutoDetectInstallPath()
        this.assert.equal(result, scratchSteam "\steamapps\common\Dungeon Defenders")
        DirDelete(scratchSteam, true)
    }

    autoDetectInstallPath_fallsBackToHklmWhenHkcuFails() {
        scratchSteam := A_Temp "\dd-toolkit-test-steam-hklm-" A_TickCount
        DirCreate(scratchSteam "\steamapps\common\Dungeon Defenders\UDKGame\Config")
        ; HKCU deliberately left unconfigured in Shims.RegReadBehavior -> throws.
        Shims.RegReadBehavior["HKLM\Software\Valve\Steam|InstallPath"] := scratchSteam
        result := GameTweaksModule.AutoDetectInstallPath()
        this.assert.equal(result, scratchSteam "\steamapps\common\Dungeon Defenders")
        DirDelete(scratchSteam, true)
    }

    autoDetectInstallPath_returnsEmptyWhenBothRegistryLookupsFail() {
        result := GameTweaksModule.AutoDetectInstallPath()
        this.assert.equal(result, "")
    }

    autoDetectInstallPath_returnsEmptyWhenSteamFoundButGameFolderMissing() {
        scratchSteam := A_Temp "\dd-toolkit-test-steam-nogame-" A_TickCount
        DirCreate(scratchSteam) ; Steam "installed" here, but no game subfolder
        Shims.RegReadBehavior["HKCU\Software\Valve\Steam|SteamPath"] := scratchSteam
        result := GameTweaksModule.AutoDetectInstallPath()
        this.assert.equal(result, "")
        DirDelete(scratchSteam, true)
    }

    ; --- ResolveInstallPath ---

    resolveInstallPath_returnsExistingConfiguredPathWithoutPrompting() {
        scratch := A_Temp "\dd-toolkit-test-resolve-valid-" A_TickCount
        DirCreate(scratch "\UDKGame\Config")
        GameTweaksModule.InstallPath := scratch
        result := GameTweaksModule.ResolveInstallPath()
        this.assert.equal(result, scratch)
        this.assert.equal(Shims.MsgBoxCalls.Length, 0)
        DirDelete(scratch, true)
    }

    resolveInstallPath_autoDetectsAndCachesWhenNothingConfigured() {
        GameTweaksModule.InstallPath := ""
        scratchSteam := A_Temp "\dd-toolkit-test-resolve-auto-" A_TickCount
        DirCreate(scratchSteam "\steamapps\common\Dungeon Defenders\UDKGame\Config")
        Shims.RegReadBehavior["HKCU\Software\Valve\Steam|SteamPath"] := scratchSteam
        result := GameTweaksModule.ResolveInstallPath()
        expected := scratchSteam "\steamapps\common\Dungeon Defenders"
        this.assert.equal(result, expected)
        this.assert.equal(GameTweaksModule.InstallPath, expected)
        DirDelete(scratchSteam, true)
    }

    resolveInstallPath_fallsBackToDirSelectWhenAutoDetectFails() {
        GameTweaksModule.InstallPath := ""
        scratchChosen := A_Temp "\dd-toolkit-test-resolve-picked-" A_TickCount
        DirCreate(scratchChosen "\UDKGame\Config")
        Shims.DirSelectResult := scratchChosen
        result := GameTweaksModule.ResolveInstallPath()
        this.assert.equal(result, scratchChosen)
        DirDelete(scratchChosen, true)
    }

    resolveInstallPath_returnsEmptyWhenUserCancelsDirSelect() {
        GameTweaksModule.InstallPath := ""
        Shims.DirSelectResult := ""
        result := GameTweaksModule.ResolveInstallPath()
        this.assert.equal(result, "")
        this.assert.equal(Shims.MsgBoxCalls.Length, 0)
    }

    resolveInstallPath_warnsAndReturnsEmptyWhenChosenFolderIsWrong() {
        GameTweaksModule.InstallPath := ""
        scratchWrong := A_Temp "\dd-toolkit-test-resolve-wrong-" A_TickCount
        DirCreate(scratchWrong) ; no UDKGame\Config subfolder
        Shims.DirSelectResult := scratchWrong
        result := GameTweaksModule.ResolveInstallPath()
        this.assert.equal(result, "")
        this.assert.equal(Shims.MsgBoxCalls.Length, 1)
        DirDelete(scratchWrong, true)
    }

    ; --- Apply*Fix: real scratch UDKEngine.ini, never the real one ---

    _fixtureGameFolder(name) {
        scratch := A_Temp "\dd-toolkit-test-apply-" name "-" A_TickCount
        DirCreate(scratch "\UDKGame\Config")
        return scratch
    }

    applyTextureFix_writesBackupAndUpdatesRealFile() {
        scratch := this._fixtureGameFolder("texture")
        iniPath := scratch "\UDKGame\Config\UDKEngine.ini"
        FileAppend("PoolSize=256`r`nPoolSizeLow=256`r`nPoolSizeMedium=384`r`nPoolSizeHigh=512`r`n", iniPath)
        GameTweaksModule.InstallPath := scratch

        GameTweaksModule.ApplyTextureFix(false)

        newContent := FileRead(iniPath)
        this.assert.isTrue(InStr(newContent, "PoolSize=1536") > 0)
        backups := []
        Loop Files, scratch "\UDKGame\Config\UDKEngine.ini.dd-toolkit-backup-*"
            backups.Push(A_LoopFileName)
        this.assert.equal(backups.Length, 1)
        this.assert.equal(Shims.MsgBoxCalls.Length, 1)

        DirDelete(scratch, true)
    }

    applyTextureFix_warnsWithoutWritingWhenNoMatchingLines() {
        scratch := this._fixtureGameFolder("texture-nomatch")
        iniPath := scratch "\UDKGame\Config\UDKEngine.ini"
        FileAppend("SomeOtherSetting=1`r`n", iniPath)
        GameTweaksModule.InstallPath := scratch

        GameTweaksModule.ApplyTextureFix(false)

        this.assert.equal(FileRead(iniPath), "SomeOtherSetting=1`r`n")
        this.assert.equal(Shims.MsgBoxCalls.Length, 1)
        backups := []
        Loop Files, scratch "\UDKGame\Config\UDKEngine.ini.dd-toolkit-backup-*"
            backups.Push(A_LoopFileName)
        this.assert.equal(backups.Length, 0)

        DirDelete(scratch, true)
    }

    applyVsyncFix_writesBackupAndUpdatesRealFile() {
        scratch := this._fixtureGameFolder("vsync")
        iniPath := scratch "\UDKGame\Config\UDKEngine.ini"
        FileAppend("UseVsync=False`r`n", iniPath)
        GameTweaksModule.InstallPath := scratch

        GameTweaksModule.ApplyVsyncFix(true)

        this.assert.equal(FileRead(iniPath), "UseVsync=True`r`n")
        backups := []
        Loop Files, scratch "\UDKGame\Config\UDKEngine.ini.dd-toolkit-backup-*"
            backups.Push(A_LoopFileName)
        this.assert.equal(backups.Length, 1)

        DirDelete(scratch, true)
    }

    applyPerformanceFix_writesBackupAndUpdatesRealFile() {
        scratch := this._fixtureGameFolder("perf")
        iniPath := scratch "\UDKGame\Config\UDKEngine.ini"
        FileAppend("DetailMode=2`r`nGraphicsQualityMode=2`r`n", iniPath)
        GameTweaksModule.InstallPath := scratch

        GameTweaksModule.ApplyPerformanceFix()

        newContent := FileRead(iniPath)
        this.assert.isTrue(InStr(newContent, "DetailMode=0") > 0)
        this.assert.isTrue(InStr(newContent, "GraphicsQualityMode=0") > 0)
        backups := []
        Loop Files, scratch "\UDKGame\Config\UDKEngine.ini.dd-toolkit-backup-*"
            backups.Push(A_LoopFileName)
        this.assert.equal(backups.Length, 1)

        DirDelete(scratch, true)
    }

    applyTextureFix_showsErrorWhenIniFileMissing() {
        scratch := this._fixtureGameFolder("noini")
        GameTweaksModule.InstallPath := scratch
        GameTweaksModule.ApplyTextureFix(false)
        this.assert.equal(Shims.MsgBoxCalls.Length, 1)
        DirDelete(scratch, true)
    }
}
