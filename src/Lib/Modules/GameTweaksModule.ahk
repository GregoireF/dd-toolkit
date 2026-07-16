#Requires AutoHotkey v2.0

; Applies well-documented, community-verified Dungeon Defenders (Redux)
; config fixes directly to the game's own install — a different risk
; category from every other module in this toolkit, which only ever
; sends synthetic input to a running game process and touches nothing
; persistent. This one edits a file that stays changed after the game
; closes, so it always backs up before writing and never silently
; invents a section/key it didn't find already in the file.
;
; Currently implemented:
; - The "blurry textures" texture-streaming pool size fix (UDKEngine.ini),
;   documented on PCGamingWiki and multiple Steam guides — see
;   docs/CORRECTIFS-JEU.md for sources. The values below (1536/768/1536/3072)
;   match the "at least 3GB VRAM" recommendation from those sources;
;   lower-VRAM values are available as an alternate config key (see
;   ApplyTextureFix's LowVram parameter).
; - An optional V-Sync toggle (UseVsync in UDKEngine.ini) — a preference
;   (tearing vs. input latency), not a bug fix, so it's opt-in via a
;   checkbox rather than applied automatically like the texture fix. See
;   docs/CORRECTIFS-JEU.md for the source.
; - An optional performance-tweaks bundle (DetailMode, GraphicsQualityMode,
;   DynamicShadows, AmbientOcclusion, UseHighQualityBloom,
;   SkeletalMeshLODBias, ParticleLODBias, MaxAnisotropy, MaxMultisamples —
;   all in [SystemSettings]) — trades some visual quality for FPS without
;   dropping the whole in-launcher preset to "Low". All 9 keys confirmed
;   against a real installed UDKEngine.ini this session. Opt-in, same
;   reasoning as V-Sync. See docs/CORRECTIFS-JEU.md for the source.
;
; Deliberately NOT automated here: the "-nolauncher" black-screen fix
; (that's a Steam launch-option / client-side setting, not a game file —
; editing Steam's own config carries its own risks and isn't verified to
; the same standard as the ini fix). Documented instead.
class GameTweaksModule {
    static InstallPath := ""

    static Init() {
        this.InstallPath := DD.Read("GameTweaks", "InstallPath", "")
    }

    ; Returns the confirmed install path — silently, with no prompt at all,
    ; if it can be auto-detected (already configured, or found via Steam's
    ; own registry entry + its default library). Only asks the user to
    ; pick a folder as a last resort, for the minority of setups this
    ; can't find on its own (game installed on a Steam library added on a
    ; second drive, non-Steam copy, etc.).
    static ResolveInstallPath() {
        if (this.InstallPath != "" && this.LooksLikeGameFolder(this.InstallPath))
            return this.InstallPath

        autoDetected := this.AutoDetectInstallPath()
        if (autoDetected != "") {
            this.InstallPath := autoDetected
            DD.Write("GameTweaks", "InstallPath", autoDetected)
            return autoDetected
        }

        chosen := DirSelect(, , "Selectionne le dossier d'installation de Dungeon Defenders (celui qui contient le sous-dossier UDKGame)")
        if (chosen = "")
            return ""

        if !this.LooksLikeGameFolder(chosen) {
            MsgBox("Ce dossier ne contient pas de sous-dossier UDKGame\Config — es-tu sur que c'est la racine d'installation du jeu ?", "DD Toolkit", "IconX")
            return ""
        }

        this.InstallPath := chosen
        DD.Write("GameTweaks", "InstallPath", chosen)
        return chosen
    }

    ; Checks Steam's own registry entry for its install path, then that
    ; install's default game library (steamapps\common\...). Doesn't parse
    ; libraryfolders.vdf for additional custom libraries on other drives —
    ; that covers the common case cheaply; anyone with a moved library
    ; falls through to the folder picker, same as before this existed.
    ; Never throws: any registry/path failure just means "not found".
    static AutoDetectInstallPath() {
        steamPath := ""
        try {
            steamPath := RegRead("HKCU\Software\Valve\Steam", "SteamPath")
        } catch {
            try {
                steamPath := RegRead("HKLM\Software\Valve\Steam", "InstallPath")
            } catch {
                return ""
            }
        }

        steamPath := StrReplace(steamPath, "/", "\")
        candidate := steamPath "\steamapps\common\Dungeon Defenders"
        return this.LooksLikeGameFolder(candidate) ? candidate : ""
    }

    static LooksLikeGameFolder(path) {
        return !!DirExist(path "\UDKGame\Config")
    }

    ; Pure string transform (no file I/O) so tests/GameTweaksModule.test.ahk
    ; can exercise the actual regex logic directly — this is the riskiest
    ; part of the module (a wrong pattern could silently touch the wrong
    ; line, e.g. CommonAudioPoolSize) and is worth covering without needing
    ; a real UDKEngine.ini on disk.
    static ComputeFixedContent(content, lowVram, &changedCount) {
        values := lowVram
            ? Map("PoolSize", "1024", "PoolSizeLow", "512", "PoolSizeMedium", "1024", "PoolSizeHigh", "2048")
            : Map("PoolSize", "1536", "PoolSizeLow", "768", "PoolSizeMedium", "1536", "PoolSizeHigh", "3072")

        changedCount := 0
        for key, newValue in values {
            ; (?=\r?$), a lookahead — not \r?$, and not the original \s*$.
            ; \s*$ was greedy and \s matches \n too, so it silently ate the
            ; line's own newline (and would've eaten further blank lines
            ; after it). Consuming \r?$ directly (no lookahead) was just as
            ; wrong the other way: \r? is optional but still *consumes* the
            ; \r when present, and since the replacement text doesn't
            ; include \r, RegExReplace dropped it from the output. A
            ; lookahead asserts the CRLF/LF line ending is there without
            ; consuming it, so it's left completely untouched either way.
            ; Caught by tests/GameTweaksModule.test.ahk's exact-equality
            ; CRLF regression test.
            pattern := "m)^" key "=\d+(?=\r?$)"
            if RegExMatch(content, pattern) {
                content := RegExReplace(content, pattern, key "=" newValue, &replaceCount)
                changedCount += replaceCount
            }
        }
        return content
    }

    ; Finds existing "Key=number" lines anywhere in UDKEngine.ini and
    ; replaces their values in place — deliberately not IniWrite/IniRead
    ; targeting a specific [Section], because the exact bracketed section
    ; header for these keys isn't reliably confirmed across the sources
    ; this was researched from (they show screenshots, not text). Editing
    ; whichever line already has the key, wherever it is, sidesteps that
    ; uncertainty entirely and never creates a new, wrong, silently-inert
    ; section.
    static ApplyTextureFix(lowVram := false) {
        installPath := this.ResolveInstallPath()
        if (installPath = "")
            return

        iniPath := installPath "\UDKGame\Config\UDKEngine.ini"
        if !FileExist(iniPath) {
            MsgBox("UDKEngine.ini introuvable a:`n" iniPath, "DD Toolkit", "IconX")
            return
        }

        content := FileRead(iniPath)
        newContent := this.ComputeFixedContent(content, lowVram, &changedCount)

        if (changedCount = 0) {
            MsgBox("Aucune ligne PoolSize/PoolSizeLow/PoolSizeMedium/PoolSizeHigh trouvee dans UDKEngine.ini. Rien n'a ete modifie — ce fichier ne correspond peut-etre pas a la structure attendue (voir docs/CORRECTIFS-JEU.md).", "DD Toolkit", "IconX")
            return
        }

        backupPath := this.WriteBackedUpIni(iniPath, newContent)
        MsgBox(changedCount " valeur(s) de streaming de texture mise(s) a jour dans UDKEngine.ini.`nSauvegarde de l'original : " backupPath "`n`nRedemarre le jeu pour voir l'effet.", "DD Toolkit", "Icon!")
    }

    ; Pure string transform for the V-Sync toggle — same line-search
    ; approach as ComputeFixedContent (source: a Steam Community discussion
    ; specifying the [SystemSettings] section, but matching the key
    ; anywhere in the file sidesteps depending on that section boundary
    ; being exactly right).
    static ComputeVsyncContent(content, enable, &changedCount) {
        pattern := "m)^UseVsync=\w+(?=\r?$)"
        changedCount := 0
        if RegExMatch(content, pattern)
            content := RegExReplace(content, pattern, "UseVsync=" (enable ? "True" : "False"), &changedCount)
        return content
    }

    ; Toggles vertical sync — fixes screen tearing at the cost of the usual
    ; V-Sync input-latency tradeoff, which is why this is an explicit
    ; opt-in checkbox rather than an automatic fix like ApplyTextureFix.
    static ApplyVsyncFix(enable := true) {
        installPath := this.ResolveInstallPath()
        if (installPath = "")
            return

        iniPath := installPath "\UDKGame\Config\UDKEngine.ini"
        if !FileExist(iniPath) {
            MsgBox("UDKEngine.ini introuvable a:`n" iniPath, "DD Toolkit", "IconX")
            return
        }

        content := FileRead(iniPath)
        newContent := this.ComputeVsyncContent(content, enable, &changedCount)

        if (changedCount = 0) {
            MsgBox("Ligne UseVsync introuvable dans UDKEngine.ini. Rien n'a ete modifie — ce fichier ne correspond peut-etre pas a la structure attendue (voir docs/CORRECTIFS-JEU.md).", "DD Toolkit", "IconX")
            return
        }

        backupPath := this.WriteBackedUpIni(iniPath, newContent)
        MsgBox((enable ? "V-Sync active." : "V-Sync desactive.") "`nSauvegarde de l'original : " backupPath "`n`nRedemarre le jeu pour voir l'effet.", "DD Toolkit", "Icon!")
    }

    ; Pure string transform for the performance-tweaks bundle — same
    ; line-search, lookahead-based approach as the other two fixes above.
    ; \w+ (not \d+): DynamicShadows/AmbientOcclusion/UseHighQualityBloom
    ; are True/False, not numbers.
    static ComputePerformanceContent(content, &changedCount) {
        values := Map(
            "DetailMode", "0",
            "GraphicsQualityMode", "0",
            "DynamicShadows", "False",
            "AmbientOcclusion", "False",
            "UseHighQualityBloom", "False",
            "SkeletalMeshLODBias", "1",
            "ParticleLODBias", "2",
            "MaxAnisotropy", "1",
            "MaxMultisamples", "1",
        )

        changedCount := 0
        for key, newValue in values {
            pattern := "m)^" key "=\w+(?=\r?$)"
            if RegExMatch(content, pattern) {
                content := RegExReplace(content, pattern, key "=" newValue, &replaceCount)
                changedCount += replaceCount
            }
        }
        return content
    }

    ; Trades some visual quality (cel-shading outlines, dynamic shadows,
    ; ambient occlusion, bloom quality, LOD bias, anisotropic filtering)
    ; for FPS without dropping the whole in-launcher quality preset to
    ; "Low" — a real tradeoff, so opt-in via a button, not automatic.
    static ApplyPerformanceFix() {
        installPath := this.ResolveInstallPath()
        if (installPath = "")
            return

        iniPath := installPath "\UDKGame\Config\UDKEngine.ini"
        if !FileExist(iniPath) {
            MsgBox("UDKEngine.ini introuvable a:`n" iniPath, "DD Toolkit", "IconX")
            return
        }

        content := FileRead(iniPath)
        newContent := this.ComputePerformanceContent(content, &changedCount)

        if (changedCount = 0) {
            MsgBox("Aucune des lignes de reglages performance trouvee dans UDKEngine.ini. Rien n'a ete modifie — ce fichier ne correspond peut-etre pas a la structure attendue (voir docs/CORRECTIFS-JEU.md).", "DD Toolkit", "IconX")
            return
        }

        backupPath := this.WriteBackedUpIni(iniPath, newContent)
        MsgBox(changedCount " reglage(s) de performance mis a jour dans UDKEngine.ini (ombres dynamiques, ambient occlusion, bloom haute qualite et niveaux de detail reduits).`nSauvegarde de l'original : " backupPath "`n`nRedemarre le jeu pour voir l'effet.", "DD Toolkit", "Icon!")
    }

    ; Shared backup-then-write step for every ini-patching fix in this
    ; module — always back up before writing, never write without one.
    static WriteBackedUpIni(iniPath, newContent) {
        backupPath := iniPath ".dd-toolkit-backup-" FormatTime(A_Now, "yyyyMMdd-HHmmss")
        FileCopy(iniPath, backupPath)
        FileDelete(iniPath)
        FileAppend(newContent, iniPath)
        return backupPath
    }

    static StatusText() {
        return this.InstallPath = "" ? "GameTweaks : dossier du jeu non configure" : "GameTweaks : " this.InstallPath
    }
}
