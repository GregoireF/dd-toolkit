#Requires AutoHotkey v2.0

; Applies well-documented, community-verified Dungeon Defenders (Redux)
; config fixes directly to the game's own install — a different risk
; category from every other module in this toolkit, which only ever
; sends synthetic input to a running game process and touches nothing
; persistent. This one edits a file that stays changed after the game
; closes, so it always backs up before writing and never silently
; invents a section/key it didn't find already in the file.
;
; Currently implemented: the "blurry textures" texture-streaming pool
; size fix (UDKEngine.ini), documented on PCGamingWiki and multiple Steam
; guides — see docs/CORRECTIFS-JEU.md for sources. The values below
; (1536/768/1536/3072) match the "at least 3GB VRAM" recommendation from
; those sources; lower-VRAM values are available as an alternate config
; key (see ApplyTextureFix's LowVram parameter).
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
        return DirExist(path "\UDKGame\Config")
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

        values := lowVram
            ? Map("PoolSize", "1024", "PoolSizeLow", "512", "PoolSizeMedium", "1024", "PoolSizeHigh", "2048")
            : Map("PoolSize", "1536", "PoolSizeLow", "768", "PoolSizeMedium", "1536", "PoolSizeHigh", "3072")

        content := FileRead(iniPath)

        changedCount := 0
        for key, newValue in values {
            pattern := "m)^" key "=\d+\s*$"
            if RegExMatch(content, pattern) {
                content := RegExReplace(content, pattern, key "=" newValue, &replaceCount)
                changedCount += replaceCount
            }
        }

        if (changedCount = 0) {
            MsgBox("Aucune ligne PoolSize/PoolSizeLow/PoolSizeMedium/PoolSizeHigh trouvee dans UDKEngine.ini. Rien n'a ete modifie — ce fichier ne correspond peut-etre pas a la structure attendue (voir docs/CORRECTIFS-JEU.md).", "DD Toolkit", "IconX")
            return
        }

        backupPath := iniPath ".dd-toolkit-backup-" FormatTime(A_Now, "yyyyMMdd-HHmmss")
        FileCopy(iniPath, backupPath)

        FileDelete(iniPath)
        FileAppend(content, iniPath)

        MsgBox(changedCount " valeur(s) de streaming de texture mise(s) a jour dans UDKEngine.ini.`nSauvegarde de l'original : " backupPath "`n`nRedemarre le jeu pour voir l'effet.", "DD Toolkit", "Icon!")
    }

    static StatusText() {
        return this.InstallPath = "" ? "GameTweaks : dossier du jeu non configure" : "GameTweaks : " this.InstallPath
    }
}
