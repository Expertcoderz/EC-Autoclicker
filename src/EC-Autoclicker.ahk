#Warn
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force

;@Ahk2Exe-SetCompanyName Expertcoderz
;@Ahk2Exe-SetDescription EC Autoclicker
;@Ahk2Exe-SetVersion 1.2.3

GITHUB_REPO := "Expertcoderz/EC-Autoclicker"

FILE_EXT := ".ac-profile"
REG_KEY_PATH := "HKCU\Software\Expertcoderz\Autoclicker"

is_autoclicking := false

is_simplified_view_on := false
is_always_on_top_on := true

configured_hotkeys := []
are_hotkeys_active := true

; This dictionary stores text used for GUI controls that may (potentially) be
; referenced after the controls' creation, e.g. as in MenuBar.Disable().
SZ_TABLE := {
    ; Menus
    Menu_File: "&File",
    Menu_Profiles: "&Profiles",
    Menu_Options: "&Options",
    Menu_Help: "&Help",
    ; File Menu
    Menu_File_RunAsAdmin: "Run As &Administrator",
    Menu_File_Logs: "View &Logs",
    Menu_File_Exit: "E&xit",
    ; Profiles Menu
    Menu_Profiles_Create: "&Save...",
    Menu_Profiles_Manage: "&Manage",
    ; Options Menu
    Menu_Options_SimplifiedView: "&Simplified View",
    Menu_Options_AlwaysOnTop: "&Always On Top",
    Menu_Options_MinButtonVisible: "&Minimize Button Visible",
    Menu_Options_EscToClose: "&ESC To Close",
    Menu_Options_HotkeysActive: "&Hotkeys Active",
    Menu_Options_AutoUpdate: "Automatic &Updates",
    Menu_Options_ResetToDefault: "&Reset All Options",
    ; Help Menu
    Menu_Help_OnlineHelp: "&Online Help",
    Menu_Help_Report: "&Report Bug",
    Menu_Help_Update: "&Check for Updates",
    Menu_Help_About: "&About",
    ; Tabs
    Tabs: {
        General: "General",
        Scheduling: "Scheduling",
        Positioning: "Positioning",
        Hotkeys: "Hotkeys"
    },
    ; Positioning
    Positioning_Boundary_Mode: {
        None: "&User-controlled",
        Point: "Po&int",
        Box: "&Box"
    },
    ; Hotkeys
    Hotkeys: {
        Start: "Start",
        Stop: "Stop"
    }
}

RadioGroups := {}
Checkables := {}

; The order in which script files are included is important.
#Include AutoclickerGui.ahk
#Include Util.ahk
#Include Logging.ahk
#Include StartStopClose.ahk
#Include Profiles.ahk
#Include Options.ahk
#Include About.ahk

AutoclickerGui.Show("x0")
add_log("Showed main GUI")

#Include Updater.ahk

Loop {
    CoordMode "Mouse", AutoclickerGui["Positioning_RelativeTo_Radio"].Value = 1 ? "Screen" : "Client"
    MouseGetPos &mouseX, &mouseY
    AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)
    Sleep 100
}
