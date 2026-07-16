#Requires AutoHotkey v2.0

; Shared helpers for every script in src/. Included with:
;   #Include Lib\Common.ahk

class DD {
    ; Same folder as the running script/exe first — this is what makes a
    ; standalone .exe downloaded from a GitHub Release (see
    ; build/Build-All.ps1, which copies settings.ini next to the compiled
    ; exes) self-contained with no repo checkout needed. Falls back to the
    ; repo's own dev layout (src/ and config/ as siblings) when running
    ; from source.
    static ConfigPath := DD.ResolveConfigPath()

    static ResolveConfigPath() {
        sameDir := A_ScriptDir "\settings.ini"
        if FileExist(sameDir)
            return sameDir
        return A_ScriptDir "\..\config\settings.ini"
    }

    static Read(section, key, default) {
        return IniRead(DD.ConfigPath, section, key, default)
    }

    ; Integer read that can't crash a script's auto-execute section over a
    ; typo — a malformed number in settings.ini falls back to Default (with
    ; a notification) instead of throwing and killing the whole script.
    static ReadInt(section, key, default) {
        raw := DD.Read(section, key, default)
        try {
            return Integer(raw)
        } catch {
            DD.Notify("Config", "Valeur non numerique pour [" section "] " key "='" raw "', repli sur " default ".")
            return Integer(default)
        }
    }

    ; Case/whitespace-tolerant boolean read ("true"/"True"/" 1 " all work).
    static ReadBool(section, key, default) {
        raw := Trim(DD.Read(section, key, default ? "true" : "false"))
        return (StrLower(raw) = "true" || raw = "1")
    }

    ; Returns every key=value pair of an ini section as a Map, for scripts
    ; that need an open-ended list of entries (e.g. AbilityWheel's spins)
    ; instead of a handful of fixed named settings.
    static ReadSection(section) {
        result := Map()
        try {
            raw := IniRead(DD.ConfigPath, section)
        } catch {
            return result
        }
        if (raw = "")
            return result
        for line in StrSplit(raw, "`n", "`r") {
            pos := InStr(line, "=")
            if (line = "" || !pos)
                continue
            key := SubStr(line, 1, pos - 1)
            value := SubStr(line, pos + 1)
            result[key] := value
        }
        return result
    }

    ; IniWrite's parameter order is (Value, Filename, Section, Key) — the
    ; Value comes first, unlike IniRead where the file comes first. Only
    ; ever called against settings.ini, which always exists on disk
    ; already (shipped in the repo/release bundle) — IniWrite only falls
    ; back to creating a fresh UTF-16-with-BOM file when the target
    ; doesn't exist yet, which should never happen here.
    static Write(section, key, value) {
        IniWrite(value, DD.ConfigPath, section, key)
    }

    static WriteBool(section, key, value) {
        DD.Write(section, key, value ? "true" : "false")
    }

    static GameExe() {
        return DD.Read("Game", "ProcessName", "DunDefGame.exe")
    }

    static GameCriterion() {
        return "ahk_exe " DD.GameExe()
    }

    ; Short beep pair used as an audible on/off indicator so you don't have
    ; to alt-tab or look at a tray icon to check a toggle's state.
    static Beep(on) {
        SoundBeep(on ? 1200 : 600, 120)
    }

    static Notify(title, text) {
        TrayTip(title, text, 1)
    }
}
