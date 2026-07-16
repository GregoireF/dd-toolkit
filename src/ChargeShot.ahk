#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\ChargeShotModule.ahk

;@Ahk2Exe-SetName ChargeShot
;@Ahk2Exe-SetDescription Consistent-timing charge shot for Dungeon Defenders Redux
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors, MIT License

; Standalone entry point: just starts the module. See
; src/Lib/Modules/ChargeShotModule.ahk for the logic and the rationale for
; why this macro exists but Minion Line Placement / Aura Stacking /
; Upgrade Automation don't.
ChargeShotModule.Init()

if ChargeShotModule.Enabled
    DD.Notify("ChargeShot", ChargeShotModule.TriggerKey " -> charge " ChargeShotModule.ChargeMs "ms puis relache automatiquement.")
else
    DD.Notify("ChargeShot", "Desactive dans settings.ini ([ChargeShot] Enabled=false).")
