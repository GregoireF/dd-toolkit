#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\AutoClickerModule.ahk

;@Ahk2Exe-SetName AutoClicker
;@Ahk2Exe-SetDescription Configurable turbo-fire autoclicker (left/right) for Dungeon Defenders Redux
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Standalone entry point: just starts the module. The module itself
; (src/Lib/Modules/AutoClickerModule.ahk) holds the real logic, shared
; with the unified src/DDToolkit.ahk app.
AutoClickerModule.Init()

if AutoClickerModule.Enabled
    DD.Notify("AutoClicker", AutoClickerModule.LeftToggleKey " = turbo clic gauche, " AutoClickerModule.RightToggleKey " = turbo clic droit (actif tant que le bouton est maintenu).")
else
    DD.Notify("AutoClicker", "Desactive dans settings.ini ([AutoClicker] Enabled=false).")
