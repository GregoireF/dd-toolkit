#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetName Setup
;@Ahk2Exe-SetDescription DD Toolkit installer - desktop shortcut and optional Windows startup
;@Ahk2Exe-SetVersion 0.2.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Entirely optional convenience tool for non-technical users: creates a
; Desktop shortcut to DDToolkit.exe (and, if asked, a shortcut in the
; per-user Windows Startup folder), both pointing at wherever this .exe
; itself is sitting. Nothing is copied elsewhere, no registry writes, no
; Windows service, no admin rights needed — skippable entirely by just
; running DDToolkit.exe directly instead.

targetExe := A_ScriptDir "\DDToolkit.exe"

g := Gui("+AlwaysOnTop", "DD Toolkit - Installation")
g.OnEvent("Close", (*) => ExitApp())
g.Add("Text", "w440", "Crée un raccourci vers DD Toolkit sur ton Bureau, et si tu veux, le lance automatiquement à chaque démarrage de Windows. Rien d'autre n'est installé : pas de service, pas de modification du registre, pas besoin de droits administrateur.")

if !FileExist(targetExe) {
    g.Add("Text", "w440 y+15", "DDToolkit.exe est introuvable dans ce dossier (" A_ScriptDir "). Vérifie que ce programme est resté dans le même dossier que les autres .exe extraits du zip.")
    btnCloseOnly := g.Add("Button", "w200 y+15 Default", "Fermer")
    btnCloseOnly.OnEvent("Click", (*) => ExitApp())
    g.Show()
    return
}

chkStartup := g.Add("CheckBox", "y+15", "Lancer DD Toolkit automatiquement à l'ouverture de session Windows")
btnInstall := g.Add("Button", "w200 y+15 Default", "Créer le raccourci")
btnInstall.OnEvent("Click", (*) => DoInstall(chkStartup.Value = 1))
btnClose := g.Add("Button", "w200 x+10", "Fermer")
btnClose.OnEvent("Click", (*) => ExitApp())

; Only shown when genuinely absent — not needed at all to run the .exe
; files in this folder (they bundle their own AutoHotkey runtime), only
; useful for editing/running the .ahk source scripts directly.
ahkV2Path := A_ProgramFiles "\AutoHotkey\v2\AutoHotkey64.exe"
if !FileExist(ahkV2Path) {
    g.Add("Text", "w440 y+15", "AutoHotkey v2 n'est pas détecté sur ce PC. Ce n'est PAS nécessaire pour utiliser les .exe de ce dossier — utile seulement si tu veux modifier ou lancer directement les scripts .ahk sources.")
    btnInstallAhk := g.Add("Button", "w200", "Installer AutoHotkey v2 automatiquement")
    btnInstallAhk.OnEvent("Click", (*) => InstallAutoHotkey())
}

g.Show()

InstallAutoHotkey(*) {
    choice := MsgBox("Télécharger et installer AutoHotkey v2 maintenant ? Source officielle (github.com/AutoHotkey/AutoHotkey), installation silencieuse pour ton compte utilisateur uniquement — pas besoin d'être administrateur.", "DD Toolkit", "YesNo Icon?")
    if (choice != "Yes")
        return

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest", false)
        whr.SetRequestHeader("User-Agent", "dd-toolkit-setup")
        whr.Send()

        if !RegExMatch(whr.ResponseText, '"browser_download_url":\s*"([^"]+_setup\.exe)"', &m) {
            MsgBox("Impossible de trouver l'installeur AutoHotkey v2 sur la page officielle des releases. Installe-le manuellement depuis https://www.autohotkey.com/", "DD Toolkit", "IconX")
            return
        }

        whrDownload := ComObject("WinHttp.WinHttpRequest.5.1")
        whrDownload.Open("GET", m[1], false)
        whrDownload.SetRequestHeader("User-Agent", "dd-toolkit-setup")
        whrDownload.Send()

        if (whrDownload.Status != 200) {
            MsgBox("Le téléchargement a échoué (code " whrDownload.Status "). Installe AutoHotkey v2 manuellement depuis https://www.autohotkey.com/", "DD Toolkit", "IconX")
            return
        }

        installerPath := A_Temp "\AutoHotkey_v2_setup.exe"
        ; ResponseBody (raw bytes), not ResponseText (text-decoded — would
        ; corrupt a binary), written out through ADODB.Stream.
        stream := ComObject("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(whrDownload.ResponseBody)
        stream.SaveToFile(installerPath, 2)
        stream.Close()

        RunWait('"' installerPath '" /silent')
        FileDelete(installerPath)

        if FileExist(ahkV2Path)
            MsgBox("AutoHotkey v2 installé avec succès.", "DD Toolkit", "Icon!")
        else
            MsgBox("L'installation ne semble pas avoir abouti. Essaie manuellement depuis https://www.autohotkey.com/", "DD Toolkit", "IconX")
    } catch as err {
        MsgBox("Erreur pendant le téléchargement/l'installation : " err.Message "`n`nInstalle AutoHotkey v2 manuellement depuis https://www.autohotkey.com/", "DD Toolkit", "IconX")
    }
}

DoInstall(addToStartup) {
    desktopLink := A_Desktop "\DD Toolkit.lnk"
    FileCreateShortcut(targetExe, desktopLink, A_ScriptDir, , "DD Toolkit - macros Dungeon Defenders Redux")

    message := "Raccourci créé sur le Bureau."

    if addToStartup {
        startupLink := A_Startup "\DD Toolkit.lnk"
        FileCreateShortcut(targetExe, startupLink, A_ScriptDir, , "DD Toolkit - macros Dungeon Defenders Redux")
        message .= "`n`nDD Toolkit se lancera désormais automatiquement à l'ouverture de session Windows (raccourci dans le dossier Démarrage — supprime-le de là si tu changes d'avis)."
    }

    MsgBox(message, "DD Toolkit", "Icon!")
}
