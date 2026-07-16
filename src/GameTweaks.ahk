#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\GameTweaksModule.ahk

;@Ahk2Exe-SetName GameTweaks
;@Ahk2Exe-SetDescription Applies known and documented Dungeon Defenders Redux config fixes
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Standalone tool (not a background macro — no repeating hotkeys):
; double-click, read what it does, click the button. Deliberately shows an
; explanation window first rather than immediately popping a folder-picker
; dialog at launch — both a better first impression and safer for
; tests/Test-Syntax.ps1's smoke test, which can't interact with a native
; file dialog in a non-interactive CI session. Also reachable from
; DDToolkit's settings window. See docs/CORRECTIFS-JEU.md for what this
; does and doesn't automate, and why.
GameTweaksModule.Init()

g := Gui("+AlwaysOnTop", "DD Toolkit - Correctifs du jeu")
g.OnEvent("Close", (*) => ExitApp())
g.Add("Text", "w440", "Corrige les textures floues (limite de streaming trop basse) en modifiant UDKEngine.ini. Une sauvegarde de l'original est toujours créée avant modification. Sources et détails : docs/CORRECTIFS-JEU.md.")
chkLowVram := g.Add("CheckBox", , "Ma carte graphique a moins de 3 Go de VRAM")
btnApply := g.Add("Button", "w200 y+15 Default", "Corriger les textures")
btnApply.OnEvent("Click", (*) => GameTweaksModule.ApplyTextureFix(chkLowVram.Value = 1))
btnClose := g.Add("Button", "w200 x+10", "Fermer")
btnClose.OnEvent("Click", (*) => ExitApp())
g.Show()
