#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent() ; guarantee residency even if every module ends up disabled in settings.ini

#Include Lib\Common.ahk
#Include Lib\Modules\AutoAbilityModule.ahk
#Include Lib\Modules\TowerStackingModule.ahk
#Include Lib\Modules\AutoClickerModule.ahk
#Include Lib\Modules\AbilityWheelModule.ahk
#Include Lib\Modules\ChargeShotModule.ahk
#Include Lib\Modules\GameTweaksModule.ahk

;@Ahk2Exe-SetName DDToolkit
;@Ahk2Exe-SetDescription DD Toolkit - unified control panel for every Dungeon Defenders Redux macro
;@Ahk2Exe-SetVersion 0.1.0.0
;@Ahk2Exe-SetCopyright DD Toolkit contributors - MIT License

; Single tray-resident app running every macro in one process, with a
; tabbed settings window instead of hand-editing settings.ini. This is the
; recommended entry point for anyone who isn't comfortable with config
; files — see docs/DEMARRAGE.md. The individual scripts (AutoAbility.ahk,
; TowerStacking.ahk, AutoClicker.ahk, AbilityWheel.ahk, ChargeShot.ahk,
; GameTweaks.ahk) still exist standalone for anyone who wants just one
; tool without the tray app around it; they share the exact same module
; code as this one.
;
; Every setting change (tray menu or GUI) writes to settings.ini then
; calls Reload() — there is deliberately no separate in-memory "live"
; state to keep in sync with the file; the file is the only source of
; truth, and Reload() is a built-in, well-tested way to restart cleanly.

AutoAbilityModule.Init()
TowerStackingModule.Init()
AutoClickerModule.Init()
AbilityWheelModule.Init()
ChargeShotModule.Init()
GameTweaksModule.Init()

A_IconTip := "DD Toolkit"

A_TrayMenu.Delete()
A_TrayMenu.Add("Réglages...", (*) => SettingsWindow.Open())
A_TrayMenu.Add("Corriger les textures du jeu...", (*) => GameTweaksModule.ApplyTextureFix())
A_TrayMenu.Add("Recharger", (*) => Reload())
A_TrayMenu.Add() ; separator
A_TrayMenu.Add("Quitter", (*) => ExitApp())
A_TrayMenu.Default := "Réglages..."
A_TrayMenu.ClickCount := 1 ; a single left-click opens Settings, like a normal app tray icon

UpdateTrayTooltip()
SetTimer(UpdateTrayTooltip, 3000)

UpdateTrayTooltip() {
    lines := [
        AutoAbilityModule.StatusText(),
        TowerStackingModule.StatusText(),
        AutoClickerModule.StatusText(),
        AbilityWheelModule.StatusText(),
        ChargeShotModule.StatusText(),
        GameTweaksModule.StatusText(),
    ]
    tip := "DD Toolkit`n"
    for line in lines
        tip .= line "`n"
    ; Windows caps tray tooltips at 127 characters — trim defensively so a
    ; long status line doesn't throw instead of just getting cut off.
    A_IconTip := SubStr(Trim(tip, "`n"), 1, 127)
}

; ---------------------------------------------------------------------------

class SettingsWindow {
    ; All declared explicitly (rather than created ad hoc via `this.x :=`
    ; inside Build()) — assigning to an undeclared name from inside a
    ; static method isn't guaranteed to behave like a real static
    ; property in AHK v2, only an explicit `static` declaration is.
    static Instance := ""
    static chkAA := ""
    static editAAKey := ""
    static editAAInterval := ""
    static hkAAToggle := ""
    static hkAAPanic := ""
    static chkTS := ""
    static ddlTSModifier := ""
    static chkAC := ""
    static editACInterval := ""
    static hkACLeft := ""
    static hkACRight := ""
    static chkACScope := ""
    static chkAW := ""
    static editAWSlot := ""
    static editAWTolerance := ""
    static chkCS := ""
    static hkCSTrigger := ""
    static editCSCharge := ""
    static ddlCSButton := ""
    static txtGT := ""
    static chkGTLowVram := ""
    static chkGTVsync := ""

    static Open(*) {
        if (this.Instance != "") {
            try {
                this.Instance.Show()
                return
            }
            ; Instance existed but its underlying window is gone — fall
            ; through and rebuild.
        }
        this.Instance := this.Build()
        this.Instance.Show()
    }

    static Build() {
        g := Gui("+AlwaysOnTop", "DD Toolkit - Réglages")
        g.OnEvent("Close", (*) => g.Hide())
        g.MarginX := 15
        g.MarginY := 12

        g.Add("Text", "w480", "Ces réglages sont écrits dans config/settings.ini. Le bouton Enregistrer relance automatiquement le programme (Reload) pour les appliquer.")

        tabs := g.Add("Tab3", "w500 y+10", [
            "AutoAbility", "TowerStacking", "AutoClicker", "AbilityWheel", "ChargeShot", "Correctifs jeu",
        ])

        ; ---------------- AutoAbility ----------------
        tabs.UseTab(1)
        this.chkAA := g.Add("CheckBox", "y+15 Checked" (AutoAbilityModule.Enabled ? "1" : "0"), "Activé")
        g.Add("Text", , "Touche envoyée (ex: e) :")
        this.editAAKey := g.Add("Edit", "w150", AutoAbilityModule.Key)
        g.Add("Text", , "Intervalle, en secondes :")
        this.editAAInterval := g.Add("Edit", "w150", Round(AutoAbilityModule.IntervalMs / 1000))
        g.Add("Text", , "Touche pour armer/désarmer :")
        this.hkAAToggle := g.Add("Hotkey", "w150", AutoAbilityModule.ToggleKey)
        g.Add("Text", , "Touche d'arrêt d'urgence :")
        this.hkAAPanic := g.Add("Hotkey", "w150", AutoAbilityModule.PanicKey)

        ; ---------------- TowerStacking ----------------
        tabs.UseTab(2)
        this.chkTS := g.Add("CheckBox", "y+15 Checked" (TowerStackingModule.Enabled ? "1" : "0"), "Activé")
        g.Add("Text", , "Touche modificatrice (avec 1..0) :")
        modifierOptions := ["Ctrl", "Alt", "Shift", "Win"]
        this.ddlTSModifier := g.Add("DropDownList", "w150", modifierOptions)
        chosenIndex := 1
        for i, opt in modifierOptions {
            if (opt = TowerStackingModule.Modifier) {
                chosenIndex := i
                break
            }
        }
        this.ddlTSModifier.Choose(chosenIndex)

        ; ---------------- AutoClicker ----------------
        tabs.UseTab(3)
        this.chkAC := g.Add("CheckBox", "y+15 Checked" (AutoClickerModule.Enabled ? "1" : "0"), "Activé")
        g.Add("Text", , "Délai entre clics, en millisecondes (plus petit = plus rapide) :")
        this.editACInterval := g.Add("Edit", "w150", AutoClickerModule.IntervalMs)
        g.Add("Text", , "Touche pour armer le clic gauche :")
        this.hkACLeft := g.Add("Hotkey", "w150", AutoClickerModule.LeftToggleKey)
        g.Add("Text", , "Touche pour armer le clic droit :")
        this.hkACRight := g.Add("Hotkey", "w150", AutoClickerModule.RightToggleKey)
        this.chkACScope := g.Add("CheckBox", "Checked" (AutoClickerModule.ScopeToGame ? "1" : "0"), "Actif seulement quand Dungeon Defenders est au premier plan")

        ; ---------------- AbilityWheel ----------------
        tabs.UseTab(4)
        this.chkAW := g.Add("CheckBox", "y+15 Checked" (AbilityWheelModule.Enabled ? "1" : "0"), "Activé")
        g.Add("Text", , "Case de la barre de raccourcis qui ouvre la roue :")
        this.editAWSlot := g.Add("Edit", "w150", AbilityWheelModule.WheelHotbarSlot)
        g.Add("Text", , "Tolérance de détection des couleurs (0 = exact) :")
        this.editAWTolerance := g.Add("Edit", "w150", AbilityWheelModule.ToleranceRGB)
        g.Add("Text", "w460", "Les combinaisons (Spin.*) et les couleurs se règlent encore directement dans config/settings.ini — voir CONTRIBUTING.md.")
        g.Add("Text", "w460 y+10", "Un spin qui ne se déclenche pas ? En jeu, appuie sur Ctrl+Alt+D (DiagnosticKey) : la roue s'ouvre et un rapport affiche la vraie couleur lue dans chaque case, à comparer avec [AbilityWheelColors]. Voir le README.")

        ; ---------------- ChargeShot ----------------
        tabs.UseTab(5)
        this.chkCS := g.Add("CheckBox", "y+15 Checked" (ChargeShotModule.Enabled ? "1" : "0"), "Activé")
        g.Add("Text", , "Touche pour déclencher un tir chargé :")
        this.hkCSTrigger := g.Add("Hotkey", "w150", ChargeShotModule.TriggerKey)
        g.Add("Text", , "Durée de charge, en millisecondes :")
        this.editCSCharge := g.Add("Edit", "w150", ChargeShotModule.ChargeMs)
        g.Add("Text", , "Bouton à maintenir :")
        buttonOptions := ["LButton", "RButton"]
        this.ddlCSButton := g.Add("DropDownList", "w150", buttonOptions)
        csIndex := 1
        for i, opt in buttonOptions {
            if (opt = ChargeShotModule.AttackButton) {
                csIndex := i
                break
            }
        }
        this.ddlCSButton.Choose(csIndex)

        ; ---------------- Correctifs jeu ----------------
        tabs.UseTab(6)
        g.Add("Text", "w460 y+15", "Corrige les textures floues connues de Dungeon Defenders Redux (voir docs/CORRECTIFS-JEU.md). Modifie un fichier du jeu — une sauvegarde est toujours créée avant.")
        this.txtGT := g.Add("Text", "w460", GameTweaksModule.StatusText())
        this.chkGTLowVram := g.Add("CheckBox", , "Ma carte graphique a moins de 3 Go de VRAM")
        btnFix := g.Add("Button", "w200", "Corriger les textures maintenant")
        btnFix.OnEvent("Click", (*) => GameTweaksModule.ApplyTextureFix(this.chkGTLowVram.Value = 1))

        g.Add("Text", "w460 y+15", "Optionnel : active la V-Sync pour supprimer le tearing d'ecran, au prix d'un peu de latence en plus (comme sur la plupart des jeux). Decoche pour la desactiver a la place.")
        this.chkGTVsync := g.Add("CheckBox", , "Activer la V-Sync")
        btnVsync := g.Add("Button", "w200", "Appliquer le reglage V-Sync")
        btnVsync.OnEvent("Click", (*) => GameTweaksModule.ApplyVsyncFix(this.chkGTVsync.Value = 1))

        g.Add("Text", "w460 y+15", "Optionnel : baisse quelques reglages graphiques cibles (ombres dynamiques, ambient occlusion, cel-shading, LOD) pour gagner en FPS sans repasser tout le jeu en qualite 'Basse'.")
        btnPerf := g.Add("Button", "w200", "Ameliorer les performances")
        btnPerf.OnEvent("Click", (*) => GameTweaksModule.ApplyPerformanceFix())

        tabs.UseTab() ; stop routing controls into a tab

        ; ---------------- Buttons ----------------
        btnSave := g.Add("Button", "w150 y+15 Default", "Enregistrer")
        btnSave.OnEvent("Click", (*) => this.Save(g))
        btnCancel := g.Add("Button", "w150 x+10", "Fermer sans enregistrer")
        btnCancel.OnEvent("Click", (*) => g.Hide())

        return g
    }

    static Save(g) {
        acInterval := 0
        awTolerance := 0
        aaSeconds := 0
        csCharge := 0

        try {
            aaSeconds := Number(this.editAAInterval.Value)
            acInterval := Integer(this.editACInterval.Value)
            awTolerance := Integer(this.editAWTolerance.Value)
            csCharge := Integer(this.editCSCharge.Value)
        } catch {
            MsgBox("Un des champs numériques contient une valeur invalide. Corrige-le avant d'enregistrer.", "DD Toolkit", "Icon!")
            return
        }

        DD.WriteBool("AutoAbility", "Enabled", this.chkAA.Value = 1)
        DD.Write("AutoAbility", "Key", this.editAAKey.Value)
        DD.Write("AutoAbility", "IntervalMs", Round(aaSeconds * 1000))
        DD.Write("AutoAbility", "ToggleKey", this.hkAAToggle.Value)
        DD.Write("AutoAbility", "PanicKey", this.hkAAPanic.Value)

        DD.WriteBool("TowerStacking", "Enabled", this.chkTS.Value = 1)
        DD.Write("TowerStacking", "Modifier", this.ddlTSModifier.Text)

        DD.WriteBool("AutoClicker", "Enabled", this.chkAC.Value = 1)
        DD.Write("AutoClicker", "IntervalMs", acInterval)
        DD.Write("AutoClicker", "LeftToggleKey", this.hkACLeft.Value)
        DD.Write("AutoClicker", "RightToggleKey", this.hkACRight.Value)
        DD.WriteBool("AutoClicker", "ScopeToGame", this.chkACScope.Value = 1)

        DD.WriteBool("AbilityWheel", "Enabled", this.chkAW.Value = 1)
        DD.Write("AbilityWheel", "WheelHotbarSlot", this.editAWSlot.Value)
        DD.Write("AbilityWheel", "ToleranceRGB", awTolerance)

        DD.WriteBool("ChargeShot", "Enabled", this.chkCS.Value = 1)
        DD.Write("ChargeShot", "TriggerKey", this.hkCSTrigger.Value)
        DD.Write("ChargeShot", "ChargeMs", csCharge)
        DD.Write("ChargeShot", "AttackButton", this.ddlCSButton.Text)

        Reload()
    }
}
