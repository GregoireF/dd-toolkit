#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\AbilityWheelModule.ahk

;@Ahk2Exe-SetName AbilityWheel
;@Ahk2Exe-SetDescription Jester Wheel of Fortune automation for Dungeon Defenders Redux
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Standalone entry point: just starts the module. The module itself
; (src/Lib/Modules/AbilityWheelModule.ahk) holds the real logic, shared
; with the unified src/DDToolkit.ahk app. Detection math is unchanged from
; the community source this was originally rebuilt from — see the
; module's own header comment for the full rationale.

AbilityWheelModule.Init()

if AbilityWheelModule.Enabled
    DD.Notify("AbilityWheel", AbilityWheelModule.RegisteredCount " spin(s) charge(s) depuis settings.ini.")
else
    DD.Notify("AbilityWheel", "Desactive dans settings.ini ([AbilityWheel] Enabled=false).")
