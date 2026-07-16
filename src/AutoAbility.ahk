#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\Common.ahk
#Include Lib\Modules\AutoAbilityModule.ahk

;@Ahk2Exe-SetName AutoAbility
;@Ahk2Exe-SetDescription Generic cooldown-ability presser for Dungeon Defenders Redux
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Standalone entry point: just starts the module. The module itself
; (src/Lib/Modules/AutoAbilityModule.ahk) holds the real logic, shared
; with the unified src/DDToolkit.ahk app.
AutoAbilityModule.Init()

if AutoAbilityModule.Enabled
    DD.Notify("AutoAbility", AutoAbilityModule.ToggleKey " arme/désarme (" AutoAbilityModule.Key " / " Round(AutoAbilityModule.IntervalMs / 1000) "s) — " AutoAbilityModule.PanicKey " = stop d'urgence.")
else
    DD.Notify("AutoAbility", "Desactive dans settings.ini ([AutoAbility] Enabled=false).")
