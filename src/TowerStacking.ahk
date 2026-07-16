#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\TowerStackingModule.ahk

;@Ahk2Exe-SetName TowerStacking
;@Ahk2Exe-SetDescription Tower stacking macro for Dungeon Defenders Redux
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Standalone entry point: just starts the module. The module itself
; (src/Lib/Modules/TowerStackingModule.ahk) holds the real logic, shared
; with the unified src/DDToolkit.ahk app.
TowerStackingModule.Init()

if TowerStackingModule.Enabled
    DD.Notify("Tower Stacking", "Prêt — " TowerStackingModule.Modifier "+1..0 pour stacker pendant que le jeu est au premier plan.")
else
    DD.Notify("Tower Stacking", "Desactive dans settings.ini ([TowerStacking] Enabled=false).")
