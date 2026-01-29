#Warn
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force

;@Ahk2Exe-SetCompanyName Expertcoderz
;@Ahk2Exe-SetDescription EC Autoclicker
;@Ahk2Exe-SetVersion 1.4.0

A_IconTip := "EC Autoclicker"

GITHUB_REPO := "Expertcoderz/EC-Autoclicker"

FILE_EXT := ".ac-profile"
REG_KEY_PATH := "HKCU\Software\Expertcoderz\Autoclicker"

; Global variables that must be referenced in multiple script files.
is_autoclicking := false
is_simplified_view_on := false
is_always_on_top_on := true
are_hotkeys_active := true
has_profiles := false
configured_targets := []
configured_hotkeys := []

RadioGroups := {}
Checkables := {}

; This dictionary stores text used for GUI controls that may (potentially) be
; referenced after the controls' creation, e.g. as in MenuBar.Disable().
SZ_TABLE := {
    ; Tray Menu
    TrayMenu_Start: "&Start",
    TrayMenu_Stop: "Sto&p",
    TrayMenu_Open: "&Open GUI",
    TrayMenu_Exit: "E&xit",

    ; Window Menu Bar
    Menu_File: "&File",
    Menu_Profiles: "&Profiles",
    Menu_Options: "&Options",
    Menu_Help: "&Help",
    ; File Menu
    Menu_File_RunAsAdmin: "Run As &Administrator",
    Menu_File_Collapse: "&Collapse to tray",
    Menu_File_Logs: "View &Logs",
    Menu_File_Exit: "E&xit",
    ; Profiles Menu
    Menu_Profiles_Create: "&Save...",
    Menu_Profiles_Manage: "&Manage",
    Menu_Profiles_Default: "&Default Profile",
    ; Options Menu
    Menu_Options_SimplifiedView: "&Simplified View",
    Menu_Options_AlwaysOnTop: "&Always On Top",
    Menu_Options_MinButtonVisible: "&Minimize Button Visible",
    Menu_Options_EscToClose: "&ESC To Close",
    Menu_Options_HotkeysActive: "&Hotkeys Active",
    Menu_Options_StartCollapsed: "&Start Collapsed",
    Menu_Options_AutoUpdate: "Automatic &Updates",
    Menu_Options_ResetToDefault: "&Reset All Options",
    ; Help Menu
    Menu_Help_OnlineHelp: "&Online Help",
    Menu_Help_Report: "&Report Bug",
    Menu_Help_Update: "&Check for Updates",
    Menu_Help_About: "&About",

    ; Window Tabs
    Tabs: {
        General: "General",
        Scheduling: "Scheduling",
        Positioning: "Positioning",
        Hotkeys: "Hotkeys"
    },
    ; Positioning
    Positioning_TargetType: {
        Point: "Po&int",
        Box: "&Box (random distribution)"
    }
}

Collapse(*) {
    A_IconHidden := false
    AutoclickerGui.Hide()
}
Expand(*) {
    A_IconHidden := true
    AutoclickerGui.Show()
}

A_TrayMenu.Delete()
A_TrayMenu.Add(SZ_TABLE.TrayMenu_Start, Start)
A_TrayMenu.Add(SZ_TABLE.TrayMenu_Stop, Stop)
A_TrayMenu.Add()
A_TrayMenu.Add(SZ_TABLE.TrayMenu_Open, Expand)
A_TrayMenu.Add(SZ_TABLE.TrayMenu_Exit, Close)

; The order in which script files are included is important.
#Include AutoclickerGui.ahk
#Include Util.ahk
#Include Logging.ahk
#Include StartStopClose.ahk
#Include Profiles.ahk
#Include Options.ahk
#Include About.ahk
#Include Updater.ahk

CoordMode "Mouse", "Screen"
SetTimer updateAutoclickerGuiStatusBar, 100

updateAutoclickerGuiStatusBar() {
    local mouseX, mouseY
    MouseGetPos &mouseX, &mouseY
    AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)
}
