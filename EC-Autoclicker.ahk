#Warn
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force

;@Ahk2Exe-SetCompanyName Expertcoderz
;@Ahk2Exe-SetDescription EC Autoclicker
;@Ahk2Exe-SetVersion 1.1.5

FILE_EXT := ".ac-profile"
REG_KEY_PATH := "HKCU\Software\Expertcoderz\Autoclicker"
RegCreateKey REG_KEY_PATH "\Profiles"

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

program_logs := []
is_autoclicking := false
always_on_top := true

configured_hotkeys := []
are_hotkeys_active := true

RadioGroups := {}
Checkables := {}
makeRadioGroup(name, radioControls, changedCallback := 0) {
    radioControls[1].Name := name
    RadioGroups.%name% := { Controls: radioControls, Callback: changedCallback }
    if changedCallback {
        local ctrl
        for ctrl in radioControls
            ctrl.OnEvent "Click", changedCallback
    }
}
makeCheckable(name, checkbox, callback := 0, controls := []) {
    checkbox.Name := name
    Checkables.%name% := { Checkbox: checkbox, Callback: callback }
    if callback = 1 {
        checkbox.OnEvent "Click", Toggle
        Toggle(*) {
            local ctrl
            for ctrl in controls
                ctrl.Enabled := checkbox.Value
        }
        Checkables.%name%.Callback := Toggle
    } else if callback
        checkbox.OnEvent "Click", callback
}

AutoclickerGui := Gui("+AlwaysOnTop", "EC Autoclicker")
AutoclickerGui.OnEvent "Close", Close

FileMenu := Menu()
FileMenu.Add SZ_TABLE.Menu_File_RunAsAdmin, (*) =>
        Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath '" /restart' : A_AhkPath '" /restart "' A_ScriptFullPath '"'))
FileMenu.SetIcon SZ_TABLE.Menu_File_RunAsAdmin, "imageres.dll", -78
if A_IsAdmin {
    FileMenu.Disable SZ_TABLE.Menu_File_RunAsAdmin
    FileMenu.Rename SZ_TABLE.Menu_File_RunAsAdmin, "Running as administrator"
}
FileMenu.Add SZ_TABLE.Menu_File_Logs, LogsOpen
FileMenu.Add SZ_TABLE.Menu_File_Exit, Close

ProfilesMenu := Menu()
setupProfiles() {
    ProfilesMenu.Delete
    ProfilesMenu.Add SZ_TABLE.Menu_Profiles_Create, ProfileCreate
    ProfilesMenu.Add SZ_TABLE.Menu_Profiles_Manage, ProfileManage
    ProfilesMenu.Add

    Loop Reg REG_KEY_PATH "\Profiles", "K"
        ProfilesMenu.Add A_LoopRegName, ProfileLoad

    add_log "Loaded profiles"
}
setupProfiles()

OptionsMenu := Menu()

PersistentOptions := [
    {
        ValueName: "AlwaysOnTop",
        Default: true,
        Text: SZ_TABLE.Menu_Options_AlwaysOnTop,
        Toggler: toggleAlwaysOnTop
    },
    {
        ValueName: "MinButtonVisible",
        Default: true,
        Text: SZ_TABLE.Menu_Options_MinButtonVisible,
        Toggler: (optionInfo) => AutoclickerGui.Opt((optionInfo.CurrentSetting ? "+" : "-") "MinimizeBox")
    },
    {
        ValueName: "EscToClose",
        Default: false,
        Text: SZ_TABLE.Menu_Options_EscToClose,
        Toggler: (optionInfo) => AutoclickerGui.OnEvent("Escape", Close, optionInfo.CurrentSetting ? 1 : 0)
    },
    {
        ValueName: "HotkeysActive",
        Default: true,
        Text: SZ_TABLE.Menu_Options_HotkeysActive,
        Toggler: toggleHotkeysActive
    },
    {
        ValueName: "AutoUpdate",
        Default: true,
        Text: SZ_TABLE.Menu_Options_AutoUpdate,
        Toggler: (*) => 0
    }
]

HelpMenu := Menu()
HelpMenu.Add SZ_TABLE.Menu_Help_OnlineHelp
    , (*) => Run("https://github.com/Expertcoderz/EC-Autoclicker#readme")
HelpMenu.Add SZ_TABLE.Menu_Help_Report
    , (*) => Run("https://github.com/Expertcoderz/EC-Autoclicker/issues/new/choose")
HelpMenu.Add SZ_TABLE.Menu_Help_Update
    , (*) => CheckForUpdates(true)
if !A_IsCompiled
    HelpMenu.Disable SZ_TABLE.Menu_Help_Update
HelpMenu.Add
HelpMenu.Add SZ_TABLE.Menu_Help_About, AboutOpen

Menus := MenuBar()
Menus.Add SZ_TABLE.Menu_File, FileMenu
Menus.Add SZ_TABLE.Menu_Profiles, ProfilesMenu
Menus.Add SZ_TABLE.Menu_Options, OptionsMenu
Menus.Add SZ_TABLE.Menu_Help, HelpMenu
AutoclickerGui.MenuBar := Menus

AutoclickerGui.AddTab3 "w250 h208 vTab", [
    SZ_TABLE.Tabs.General,
    SZ_TABLE.Tabs.Scheduling,
    SZ_TABLE.Tabs.Positioning,
    SZ_TABLE.Tabs.Hotkeys
]

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.General)

AutoclickerGui.AddGroupBox "w226 h70 Section", "Mouse button"

makeRadioGroup "General_MouseButton_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "&Left"),
    AutoclickerGui.AddRadio("yp", "&Right"),
    AutoclickerGui.AddRadio("yp", "&Middle")
]

AutoclickerGui.AddDropDownList "xs+10 yp+20 w100 vGeneral_ClickCount_DropDownList AltSubmit Choose1", [
    "Single click",
    "Double click",
    "Triple click",
    "No click"
]

AutoclickerGui.AddGroupBox "xs w226 h73 Section", "Click intervals"

makeRadioGroup "General_ClickIntervalMode_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "F&ixed"),
    AutoclickerGui.AddRadio("yp", "R&andomized")
], General_ClickIntervalModeChanged

AutoclickerGui.AddEdit "xs+10 yp+20 w50 vGeneral_ClickIntervalLower_NumEdit Limit Number", "100"
AutoclickerGui.AddText "xp+54 yp+2", "ms"
AutoclickerGui.AddText "xp+24 yp vGeneral_ClickIntervalRange_Text Hidden", "to"
AutoclickerGui.AddEdit "xp+18 yp-2 w50 vGeneral_ClickIntervalUpper_NumEdit Hidden Limit Number", "200"
AutoclickerGui.AddText "xp+54 yp+2 vGeneral_ClickIntervalUpper_UnitText Hidden", "ms"

makeCheckable "General_SoundBeep_Checkbox", AutoclickerGui.AddCheckbox("xs", "Play a &beep at")
    , 1
    , [AutoclickerGui.AddEdit("xp+88 yp-2 w36 vGeneral_SoundBeep_NumEdit Disabled Limit Number", "600")]

AutoclickerGui.AddText "xp+40 yp+2", "Hz at every click"

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Scheduling)

makeCheckable "Scheduling_PreStartDelay_Checkbox", AutoclickerGui.AddCheckbox("Section", "&Delay before starting:")
    , 1
    , [AutoclickerGui.AddEdit("xp+122 yp-2 w50 vScheduling_PreStartDelay_NumEdit Disabled Limit Number", "0")]

AutoclickerGui.AddText "xp+54 ys vScheduling_PreStartDelay_UnitText", "ms"

AutoclickerGui.AddGroupBox "xs ys+25 w226 h148 Section", "Stop after"

makeCheckable "Scheduling_StopAfterNumClicks_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+20", "&Number of clicks:")
    , Scheduling_StopAfterNumClicksToggled

AutoclickerGui.AddEdit "xp+104 yp-2 w45 vScheduling_StopAfterNumClicks_NumEdit Disabled Limit Number", "50"

makeCheckable "Scheduling_StopAfterDuration_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+25", "D&uration:")
    , Scheduling_StopAfterDurationToggled

AutoclickerGui.AddEdit "xp+65 yp-2 w45 vScheduling_StopAfterDuration_NumEdit Disabled Limit Number", "60"
AutoclickerGui.AddText "xp+48 yp+2 vScheduling_StopAfterDuration_UnitText Disabled", "ms"

makeCheckable "Scheduling_StopAfterTime_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+25", "&Time:")
    , Scheduling_StopAfterTimeToggled

AutoclickerGui.AddDateTime "xp+48 yp-2 w100 vScheduling_StopAfterTime_DateTime Disabled", "Time"

AutoclickerGui.AddDropDownList "xs+10 yp+26 w206 vScheduling_StopAfterMode_DropDownList AltSubmit Choose1 Disabled", [
    "Whichever comes first",
    "Whichever comes last"
]

AutoclickerGui.AddText "xs+10 ys+120 vScheduling_PostStopAction_Text Disabled", "&When done:"
AutoclickerGui.AddDropDownList "xp+62 yp-2 w140 vScheduling_PostStopAction_DropDownList AltSubmit Choose1 Disabled", [
    "Do nothing",
    "Quit autoclicker",
    "Close focused window",
    "Logoff"
]

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Positioning)

AutoclickerGui.AddGroupBox "w226 h45 Section", "Boundary"
makeRadioGroup "Positioning_BoundaryMode_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 v Checked", SZ_TABLE.Positioning_Boundary_Mode.None),
    AutoclickerGui.AddRadio("yp", SZ_TABLE.Positioning_Boundary_Mode.Point),
    AutoclickerGui.AddRadio("yp", SZ_TABLE.Positioning_Boundary_Mode.Box)
], Positioning_ChangedModeSelection

PerBoundaryConfigControls := { %SZ_TABLE.Positioning_Boundary_Mode.None%: [], %SZ_TABLE.Positioning_Boundary_Mode.Point%: [
    AutoclickerGui.AddText("xs+10 ys+55 Hidden", "X:"),
    AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_XPos_NumEdit Limit Number Hidden", "0"),
    AutoclickerGui.AddText("xp+45 yp+2 Hidden", "Y:"),
    AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_YPos_NumEdit Limit Number Hidden", "0")], %SZ_TABLE.Positioning_Boundary_Mode.Box%: [
        AutoclickerGui.AddText("xs+10 ys+55 Hidden", "X min:"),
        AutoclickerGui.AddEdit("xp+35 yp-2 w30 vPositioning_XMinPos_NumEdit Limit Number Hidden", "0"),
        AutoclickerGui.AddText("xp+45 yp+2 Hidden", "X max:"),
        AutoclickerGui.AddEdit("xp+35 yp-2 w30 vPositioning_XMaxPos_NumEdit Limit Number Hidden", "0"),
        AutoclickerGui.AddText("xs+10 yp+30 Hidden", "Y min:"),
        AutoclickerGui.AddEdit("xp+35 yp-2 w30 vPositioning_YMinPos_NumEdit Limit Number Hidden", "0"),
        AutoclickerGui.AddText("xp+45 yp+2 Hidden", "Y max:"),
        AutoclickerGui.AddEdit("xp+35 yp-2 w30 vPositioning_YMaxPos_NumEdit Limit Number Hidden", "0")
    ]
}

AutoclickerGui.AddGroupBox "xs yp+44 w226 h45 Section", "Mouse position relative to"
makeRadioGroup "Positioning_RelativeTo_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 vPositioning_RelativeTo_Radio Checked", "Entire &screen"),
    AutoclickerGui.AddRadio("yp", "Focused &window")
]

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Hotkeys)

AutoclickerGui.AddListView("w226 h140 vHotkeys_HotkeyList_ListView -LV0x10 Sort", ["Action", "Global", "Hotkey"])
    .OnEvent("ItemSelect", Hotkeys_ItemSelectionChanged)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(1, 50)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(2, 42)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(3, 130)

AutoclickerGui.AddButton("xm+10 yp+147 w72 vHotkeys_AddHotkey_Button", "&Add")
    .OnEvent("Click", Hotkeys_AddHotkey)
AutoclickerGui.AddButton("yp wp vHotkeys_RemoveHotkey_Button Disabled", "&Remove")
    .OnEvent("Click", Hotkeys_RemoveHotkey)
AutoclickerGui.AddButton("yp wp vHotkeys_ClearAllHotkeys_Button", "&Clear All")
    .OnEvent("Click", Hotkeys_ClearAllHotkeys)

AutoclickerGui["Tab"].UseTab()

AutoclickerGui.AddButton("xm w121 vStartButton Default", "START")
    .OnEvent("Click", Start)
AutoclickerGui.AddButton("yp wp vStopButton Disabled", "STOP")
    .OnEvent("Click", Stop)

AutoclickerGui.AddStatusBar "vStatusBar"
AutoclickerGui["StatusBar"].SetParts(84, 100)
AutoclickerGui["StatusBar"].SetText(" Clicks: 0")
AutoclickerGui["StatusBar"].SetText("Elapsed: 0.0 s", 2)
AutoclickerGui["StatusBar"].SetText("X=? Y=?", 3, 2)

add_log(text) {
    OutputDebug text
    global program_logs
    program_logs.Push { Timestamp: A_Now, Message: text }
    if program_logs.Length > 100
        program_logs.RemoveAt 1
}

showGuiAtAutoclickerGuiPos(gui) {
    local posX, posY
    AutoclickerGui.GetPos &posX, &posY
    gui.Opt (always_on_top ? "+" : "-") "AlwaysOnTop"
    gui.Show "x" posX " y" posY
}

hideOwnedGui(gui, *) {
    gui.Hide
    AutoclickerGui.Opt "-Disabled"
    WinActivate "ahk_id " AutoclickerGui.Hwnd
}

validateProfileNameInput(profileName) {
    if RegExReplace(profileName, "\s") = ""
        return false
    if profileName ~= "[\\/:\*\?`"<>\|]" {
        MsgBox "A profile name can't contain any of the following characters:`n\ / : * ? `" < > |", "Create/Update Profile", "Iconx 8192"
        return false
    }
    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        if A_LoopRegName = profileName {
            if MsgBox(
                "A profile similarly named '" A_LoopRegName "' already exists. Would you like to overwrite it?"
                , "Overwrite Profile", "YesNo Iconi 8192"
            ) = "Yes" {
                RegDeleteKey A_LoopRegKey "\" A_LoopRegName
                return true
            } else
                return false
        }
    }
    return true
}

formatHotkeyText(hotkey) {
    local k, v
    for k, v in Map("~", "", "^", "{ctrl}", "!", "{alt}", "+", "{shift}")
        hotkey := StrReplace(hotkey, k, v)
    return hotkey
}

General_ClickIntervalModeChanged(*) {
    local isRange := !AutoclickerGui["General_ClickIntervalMode_Radio"].Value
    AutoclickerGui["General_ClickIntervalRange_Text"].Visible := isRange
    AutoclickerGui["General_ClickIntervalUpper_NumEdit"].Visible := isRange
    AutoclickerGui["General_ClickIntervalUpper_UnitText"].Visible := isRange
}

Scheduling_updateStopAfter() {
    local activeCount := 0
    for criterionName in ["NumClicks", "Duration", "Time"] {
        if AutoclickerGui["Scheduling_StopAfter" criterionName "_Checkbox"].Value {
            activeCount += 1
            if activeCount = 2
                break
        }
    }
    AutoclickerGui["Scheduling_StopAfterMode_DropDownList"].Enabled := activeCount = 2
    if activeCount < 2
        AutoclickerGui["Scheduling_StopAfterMode_DropDownList"].Value := 1
    AutoclickerGui["Scheduling_PostStopAction_Text"].Enabled := activeCount > 0
    AutoclickerGui["Scheduling_PostStopAction_DropDownList"].Enabled := activeCount > 0
}

Scheduling_StopAfterNumClicksToggled(*) {
    AutoclickerGui["Scheduling_StopAfterNumClicks_NumEdit"].Enabled := AutoclickerGui["Scheduling_StopAfterNumClicks_Checkbox"].Value
    Scheduling_updateStopAfter
}

Scheduling_StopAfterDurationToggled(*) {
    AutoclickerGui["Scheduling_StopAfterDuration_NumEdit"].Enabled := AutoclickerGui["Scheduling_StopAfterDuration_Checkbox"].Value
    AutoclickerGui["Scheduling_StopAfterDuration_UnitText"].Enabled := AutoclickerGui["Scheduling_StopAfterDuration_Checkbox"].Value
    Scheduling_updateStopAfter
}

Scheduling_StopAfterTimeToggled(*) {
    AutoclickerGui["Scheduling_StopAfterTime_DateTime"].Enabled := AutoclickerGui["Scheduling_StopAfterTime_Checkbox"].Value
    Scheduling_updateStopAfter
}

Positioning_ChangedModeSelection(radio, *) {
    for key, list in PerBoundaryConfigControls.OwnProps() {
        for ctrl in list
            ctrl.Visible := key = radio.Text
    }
}

Hotkeys_updateHotkeyBindings() {
    AutoclickerGui["Hotkeys_HotkeyList_ListView"].Delete()
    local hotkeyData
    for hotkeyData in configured_hotkeys {
        AutoclickerGui["Hotkeys_HotkeyList_ListView"].Add(
            , hotkeyData.Action = 1 ? "Start" : "Stop"
            , hotkeyData.Scope = 1 ? "Yes" : "No"
            , hotkeyData.HotkeyText
        )

        Hotkey hotkeyData.Hotkey, hotkeyData.Action = 1 ? Hotkey_start : Hotkey_stop
            , are_hotkeys_active ? "On" : "Off"

        getHotkeyData(hotkey) {
            local hDat
            for hDat in configured_hotkeys {
                if hDat.Hotkey = hotkey
                    return hDat
            }
        }
        Hotkey_start(hotkey) {
            static hotkeyData
            if !IsSet(hotkeyData)
                hotkeyData := getHotkeyData(hotkey)
            if hotkeyData.Scope = 2 && !WinActive("ahk_id " AutoclickerGui.Hwnd)
                return
            if !is_autoclicking
                Start()
        }
        Hotkey_stop(hotkey) {
            static hotkeyData
            if !IsSet(hotkeyData)
                hotkeyData := getHotkeyData(hotkey)
            if hotkeyData.Scope = 2 && !WinActive("ahk_id " AutoclickerGui.Hwnd)
                return
            if is_autoclicking
                Stop()
        }
    }
}

Hotkeys_ItemSelectionChanged(*) {
    AutoclickerGui["Hotkeys_RemoveHotkey_Button"].Enabled := AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetNext()
}

Hotkeys_AddHotkey(*) {
    static KeyBinderGui
    if !IsSet(KeyBinderGui) {
        KeyBinderGui := Gui("-SysMenu +Owner" AutoclickerGui.Hwnd, "Add Hotkey")
        KeyBinderGui.OnEvent "Escape", hideOwnedGui
        KeyBinderGui.OnEvent "Close", hideOwnedGui

        KeyBinderGui.AddText , "Hotkey:"
        KeyBinderGui.AddHotkey "x54 yp w180 vHotkey"

        KeyBinderGui.AddText "xm", "Applies:"
        KeyBinderGui.AddDropDownList "x54 yp w180 vHotkeyScopeDropDownList"
            , ["Globally", "Only when Autoclicker is focused"]

        KeyBinderGui.AddGroupBox "xm w134 Section", "Action"
        KeyBinderGui.AddRadio "xp+10 yp+20 vHotkeyActionRadio", "Start Autoclicker"
        KeyBinderGui.AddRadio "xp", "Stop Autoclicker"

        KeyBinderGui.AddButton("ys+6 w80 Default", "OK")
            .OnEvent("Click", Submit)
        KeyBinderGui.AddButton("xp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(KeyBinderGui))

        add_log "Created hotkey binder GUI"
    }

    KeyBinderGui["Hotkey"].Value := "^F2"
    KeyBinderGui["HotkeyScopeDropDownList"].Choose(1)
    KeyBinderGui["HotkeyActionRadio"].Value := 1
    showGuiAtAutoclickerGuiPos KeyBinderGui
    KeyBinderGui["Hotkey"].Focus()

    Submit(*) {
        hideOwnedGui KeyBinderGui

        local hotkeyText := formatHotkeyText(KeyBinderGui["Hotkey"].Value)

        local hotkeyData
        for hotkeyData in configured_hotkeys {
            if KeyBinderGui["Hotkey"].Value = hotkeyData.Hotkey {
                if MsgBox("The hotkey '" hotkeyText "' is already in use. Would you like to overwrite it?"
                    , "Overwrite Hotkey", "YesNo Iconi 8192"
                ) = "Yes"
                    configured_hotkeys.RemoveAt A_Index
                else
                    return
                break
            }
        }

        configured_hotkeys.Push {
            Hotkey: "~" KeyBinderGui["Hotkey"].Value,
            HotkeyText: hotkeyText,
            Scope: KeyBinderGui["HotkeyScopeDropDownList"].Value,
            Action: KeyBinderGui["HotkeyActionRadio"].Value = 1 ? 1 : 2
        }
        add_log "Added hotkey: " hotkeyText
        Hotkeys_updateHotkeyBindings
    }
}

Hotkeys_RemoveHotkey(*) {
    local rowNum := 0
    Loop {
        rowNum := AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetNext(rowNum)
        if !rowNum
            break
        local hotkeyData
        for hotkeyData in configured_hotkeys {
            if hotkeyData.HotkeyText = AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetText(rowNum, 3) {
                configured_hotkeys.RemoveAt A_Index
                Hotkey hotkeyData.Hotkey, "Off"
                add_log "Removed hotkey: " hotkeyData.HotkeyText
                break
            }
        }
    }
    Hotkeys_updateHotkeyBindings
    Hotkeys_ItemSelectionChanged
}

Hotkeys_ClearAllHotkeys(*) {
    local hotkeyData
    for hotkeyData in configured_hotkeys {
        configured_hotkeys.Delete A_Index
        Hotkey hotkeyData.Hotkey, "Off"
        add_log "Removed hotkey: " hotkeyData.HotkeyText
    }
    configured_hotkeys.Length := 0
    Hotkeys_updateHotkeyBindings
}

ProfileCreate(*) {
    static ProfileNamePromptGui
    if !IsSet(ProfileNamePromptGui) {
        ProfileNamePromptGui := Gui("-SysMenu +Owner" AutoclickerGui.Hwnd, "Create/Update Profile")
        ProfileNamePromptGui.OnEvent "Escape", hideOwnedGui
        ProfileNamePromptGui.OnEvent "Close", hideOwnedGui

        ProfileNamePromptGui.AddText "w206 r2"
            , "The current autoclicker configuration will`nbe saved with the following profile name:"
        ProfileNamePromptGui.AddEdit "wp vProfileNameEdit"

        ProfileNamePromptGui.AddButton("w100 Default", "OK")
            .OnEvent("Click", SubmitPrompt)
        ProfileNamePromptGui.AddButton("yp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(ProfileNamePromptGui))

        add_log "Created profile name prompt GUI"
    }

    ProfileNamePromptGui["ProfileNameEdit"].Value := ""
    ProfileNamePromptGui.Opt "-Disabled"
    AutoclickerGui.Opt "+Disabled"
    showGuiAtAutoclickerGuiPos ProfileNamePromptGui

    SubmitPrompt(*) {
        local profileName := ProfileNamePromptGui["ProfileNameEdit"].Value
        if !validateProfileNameInput(profileName)
            return

        add_log "Reading configuration data"

        local currentConfig := AutoclickerGui.Submit(false)

        RegCreateKey REG_KEY_PATH "\Profiles\" profileName

        local ctrlName, value
        for ctrlName, value in currentConfig.OwnProps() {
            if !InStr(ctrlName, "_")
                continue
            RegWrite value, ctrlName ~= "DateTime" ? "REG_SZ" : "REG_DWORD", REG_KEY_PATH "\Profiles\" profileName, ctrlName
        }

        local serializedHotkeys := ""
        local hotkeyData
        for hotkeyData in configured_hotkeys
            serializedHotkeys .= hotkeyData.Hotkey "%" hotkeyData.Scope "%" hotkeyData.Action "`n"
        RegWrite serializedHotkeys, "REG_MULTI_SZ", REG_KEY_PATH "\Profiles\" profileName, "Hotkeys"

        add_log "Wrote configuration data to registry"

        setupProfiles
        hideOwnedGui ProfileNamePromptGui
    }
}

ProfileManage(*) {
    static ProfilesGui
    if !IsSet(ProfilesGui) {
        ProfilesGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "Autoclicker Profiles")
        ProfilesGui.OnEvent "Escape", hideOwnedGui
        ProfilesGui.OnEvent "Close", hideOwnedGui

        ProfilesGui.AddListView("w150 r10 vProfileList -Hdr -Multi +Sort", ["Profile Name"])
            .OnEvent("ItemSelect", ProfileListSelectionChanged)
        ProfilesGui.AddButton("yp w100 vDeleteButton Disabled", "&Delete")
            .OnEvent("Click", ProfileDelete)
        ProfilesGui.AddButton("xp wp vRenameButton Disabled", "&Rename")
            .OnEvent("Click", ProfileRename)
        ProfilesGui.AddButton("xp wp vExportButton Disabled", "&Export")
            .OnEvent("Click", ProfileExport)
        ProfilesGui.AddButton("xp yp+52 wp", "&Import")
            .OnEvent("Click", ProfileImport)
        ProfilesGui.AddButton("xp wp Default", "&Close")
            .OnEvent("Click", (*) => hideOwnedGui(ProfilesGui))
    }

    refreshProfileList
    showGuiAtAutoclickerGuiPos ProfilesGui

    refreshProfileList(selectProfileName := "") {
        ProfilesGui["ProfileList"].Delete()
        Loop Reg REG_KEY_PATH "\Profiles", "K"
            ProfilesGui["ProfileList"].Add(A_LoopRegName = selectProfileName ? "+Focus +Select" : "", A_LoopRegName)
        ProfileListSelectionChanged
        setupProfiles
    }

    ProfileListSelectionChanged(*) {
        ProfilesGui["DeleteButton"].Enabled := ProfilesGui["ProfileList"].GetNext()
        ProfilesGui["RenameButton"].Enabled := ProfilesGui["ProfileList"].GetNext()
        ProfilesGui["ExportButton"].Enabled := ProfilesGui["ProfileList"].GetNext()
    }

    ProfileDelete(*) {
        local selectedProfileName := ProfilesGui["ProfileList"].GetText(ProfilesGui["ProfileList"].GetNext())
        Loop Reg REG_KEY_PATH "\Profiles", "K" {
            if A_LoopRegName = selectedProfileName {
                RegDeleteKey
                add_log "Deleted profile '" selectedProfileName "'"
                refreshProfileList
                return
            }
        }
        MsgBox "The profile '" selectedProfileName "' does not exist or has already been deleted.", "Error", "Iconx 8192"
        refreshProfileList
    }

    ProfileRename(*) {
        local selectedProfileName := ProfilesGui["ProfileList"].GetText(ProfilesGui["ProfileList"].GetNext())

        static ProfileRenamePromptGui
        if !IsSet(ProfileRenamePromptGui) {
            ProfileRenamePromptGui := Gui("-SysMenu +Owner" ProfilesGui.Hwnd, "Rename Profile")
            ProfileRenamePromptGui.OnEvent "Escape", CancelPrompt
            ProfileRenamePromptGui.OnEvent "Close", CancelPrompt

            ProfileRenamePromptGui.AddText "w206 vPromptText"
            ProfileRenamePromptGui.AddEdit "wp vProfileNameEdit"

            ProfileRenamePromptGui.AddButton("w100 Default", "OK")
                .OnEvent("Click", SubmitPrompt)
            ProfileRenamePromptGui.AddButton("yp wp", "Cancel")
                .OnEvent("Click", CancelPrompt)

            add_log "Created profile name prompt GUI"
        }

        ProfileRenamePromptGui["PromptText"].Text := "The profile '" selectedProfileName "' will be renamed to:"
        ProfileRenamePromptGui["ProfileNameEdit"].Value := ""
        ProfileRenamePromptGui.Opt "-Disabled"
        ProfilesGui.Opt "+Disabled"
        showGuiAtAutoclickerGuiPos ProfileRenamePromptGui

        SubmitPrompt(*) {
            local profileNewName := ProfileRenamePromptGui["ProfileNameEdit"].Value
            if !validateProfileNameInput(profileNewName)
                return

            ProfileRenamePromptGui.Opt "+Disabled"

            Loop Reg REG_KEY_PATH "\Profiles", "K" {
                if A_LoopRegName = selectedProfileName {
                    local newProfileRegPath := A_LoopRegKey "\" profileNewName
                    RegCreateKey newProfileRegPath

                    Loop Reg A_LoopRegKey "\" A_LoopRegName
                        RegWrite RegRead(), A_LoopRegType, newProfileRegPath, A_LoopRegName
                    add_log "Copied reg data to profile '" profileNewName "'"

                    RegDeleteKey
                    add_log "Deleted profile '" selectedProfileName "'"

                    ProfileRenamePromptGui.Hide
                    ProfilesGui.Opt "-Disabled"
                    WinActivate "ahk_id " ProfilesGui.Hwnd
                    refreshProfileList profileNewName
                    setupProfiles
                    return
                }
            }
            MsgBox "The profile '" selectedProfileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
            ProfileRenamePromptGui.Opt "-Disabled"
            refreshProfileList
            setupProfiles
        }

        CancelPrompt(*) {
            ProfileRenamePromptGui.Hide
            ProfilesGui.Opt "-Disabled"
            WinActivate "ahk_id " ProfilesGui.Hwnd
        }
    }

    ProfileExport(*) {
        local selectedProfileName := ProfilesGui["ProfileList"].GetText(ProfilesGui["ProfileList"].GetNext())

        local fileLocation := FileSelect("S16", A_WorkingDir "\" selectedProfileName FILE_EXT
            , "Export Autoclicker Profile", "Autoclicker Profiles (*" FILE_EXT ")"
        )
        if !fileLocation {
            add_log "Export for profile '" selectedProfileName "' cancelled"
            return
        }

        add_log "Exporting profile '" selectedProfileName "'"

        local formatted := ""
        Loop Reg REG_KEY_PATH "\Profiles\" selectedProfileName {
            if A_LoopRegName = "Hotkeys"
                formatted .= "Hotkeys=" StrReplace(RegRead(), "`n", "`t") "`n"
            else
                formatted .= A_LoopRegName "=" RegRead() "`n"
        }

        if FileExist(fileLocation) {
            FileDelete fileLocation
            add_log "Deleted existing file: " fileLocation
        }
        FileAppend formatted, fileLocation
        add_log "Wrote to new file: " fileLocation
    }

    ProfileImport(*) {
        local fileLocations := FileSelect("M",
            , "Import Autoclicker Profile(s)", "Autoclicker Profiles (*.ac-profile)"
        )
        local fileLocation
        for fileLocation in fileLocations {
            add_log "Importing profile from " fileLocation

            ;local profileNameMatch
            ;RegExMatch fileLocation, ".*\\\K(.*?)(\..*)?$", &profileNameMatch
            local profileName ;:= profileNameMatch.1
            SplitPath fileLocation, &profileName

            Loop Reg REG_KEY_PATH "\Profiles", "K" {
                if A_LoopRegName = profileName {
                    if MsgBox(
                        "A profile similarly named '" A_LoopRegName "' already exists. Would you like to overwrite it with the imported profile?"
                        , "Overwrite Profile", "YesNo Iconi 8192"
                    ) = "Yes"
                        RegDeleteKey A_LoopRegKey "\" A_LoopRegName
                    else
                        return
                }
            }

            RegCreateKey REG_KEY_PATH "\Profiles\" profileName

            local e
            try {
                Loop Parse FileRead(fileLocation), "`n" {
                    if !A_LoopField
                        continue
                    local configMatch
                    RegExMatch A_LoopField, "^(?P<Name>\w+?)=(?P<Value>.+)$", &configMatch
                    add_log "Read: " configMatch["Name"] " = " configMatch["Value"]
                    if configMatch["Name"] = "Hotkeys"
                        RegWrite StrReplace(configMatch["Value"], "`t", "`n"), "REG_MULTI_SZ"
                            , REG_KEY_PATH "\Profiles\" profileName, "Hotkeys"
                    else
                        RegWrite configMatch["Value"], configMatch["Name"] ~= "DateTime" ? "REG_SZ" : "REG_DWORD"
                        , REG_KEY_PATH "\Profiles\" profileName, configMatch["Name"]
                }
            } catch as e {
                add_log "Import Profile error: " e.Message
                try RegDeleteKey REG_KEY_PATH "\Profiles\" profileName
                MsgBox Format("
                (
An error occurred whilst importing the profile '{}' from {}.
This is usually due to the file's data being corrupt or invalid.

Message: {}
)", profileName, fileLocation, e.Message), "Import Profile", "Iconx 8192"
                return
            }

            refreshProfileList profileName

            add_log "Finished importing profile '" profileName "'"
        }
    }
}

ProfileLoad(profileName, *) {
    local currentConfig := {}

    add_log "Loading profile '" profileName "'"

    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        if A_LoopRegName = profileName {
            Loop Reg A_LoopRegKey "\" A_LoopRegName
                currentConfig.%A_LoopRegName% := RegRead()

            add_log "Configuration imported"

            try {
                local name, value
                for name, value in currentConfig.OwnProps() {
                    if name = "Hotkeys" {
                        add_log "Update Hotkeys"
                        Hotkeys_ClearAllHotkeys
                        Loop Parse value, "`n" {
                            if !A_LoopField
                                continue
                            local hotkeyDataMatch
                            RegExMatch A_LoopField, "^(?P<Hotkey>.+?)%(?P<Scope>\d)%(?P<Action>\d)$", &hotkeyDataMatch
                            configured_hotkeys.Push {
                                Hotkey: hotkeyDataMatch["Hotkey"],
                                HotkeyText: formatHotkeyText(hotkeyDataMatch["Hotkey"]),
                                Scope: hotkeyDataMatch["Scope"],
                                Action: hotkeyDataMatch["Action"]
                            }
                        }
                        Hotkeys_updateHotkeyBindings
                    } else {
                        add_log "Update: " name " (value=" value ")"
                        local ctrl := AutoclickerGui[name]
                        if ctrl.Type = "Radio" {
                            local radioInfo := RadioGroups.%name%
                            radioInfo.Controls[value].Value := true
                            if radioInfo.Callback
                                radioInfo.Callback.Call radioInfo.Controls[value]
                        } else {
                            ctrl.Value := value
                            if ctrl.Type = "Checkbox" {
                                local checkableInfo := Checkables.%name%
                                if checkableInfo.HasProp("Callback")
                                    checkableInfo.Callback.Call ctrl
                            }
                        }
                    }
                }
                add_log "Configuration GUI updated from profile"
            } catch as e {
                add_log "Load Profile error: " e.Message
                MsgBox Format("
                (
An error occurred whilst loading the profile '{}'.
This is likely due to corrupt data.

Message: {}
)", profileName, e.Message), "Load Profile", "Iconx 8192"
            }
            return
        }
    }
    MsgBox "The profile '" profileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
    setupProfiles
}

LogsOpen(*) {
    static LogsGui
    if !IsSet(LogsGui) {
        LogsGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "Logs")
        LogsGui.OnEvent "Escape", hideOwnedGui
        LogsGui.OnEvent "Close", hideOwnedGui

        LogsGui.AddListView "w300 h180 vList -LV0x10 +NoSortHdr", ["Time", "Message"]
        LogsGui["List"].ModifyCol(2, "NoSort")

        LogsGui.AddButton("w100", "&Refresh")
            .OnEvent("Click", RefreshLogs)
        LogsGui.AddButton("yp wp Default", "&Close")
            .OnEvent("Click", (*) => hideOwnedGui(LogsGui))

        add_log "Created Logs GUI"
    }

    if WinExist("ahk_id " LogsGui.Hwnd)
        WinActivate
    else
        showGuiAtAutoclickerGuiPos LogsGui
    RefreshLogs

    RefreshLogs(*) {
        LogsGui["List"].Delete()

        local data
        for data in program_logs {
            LogsGui["List"].Add(, FormatTime(data.Timestamp, "HH:mm:ss"), data.Message)
        }

        LogsGui["List"].ModifyCol()
    }
}

toggleAlwaysOnTop(optionInfo) {
    global always_on_top := optionInfo.CurrentSetting
    AutoclickerGui.Opt (always_on_top ? "+" : "-") "AlwaysOnTop"
}

toggleHotkeysActive(optionInfo) {
    global are_hotkeys_active := optionInfo.CurrentSetting
    Hotkeys_updateHotkeyBindings
}

OptionsMenuItemCallbackWrapper(optionText, *) {
    local optionInfo
    for i in PersistentOptions {
        if i.Text = optionText {
            optionInfo := i
            break
        }
    }

    optionInfo.CurrentSetting := !optionInfo.CurrentSetting
    RegWrite optionInfo.CurrentSetting, "REG_DWORD", REG_KEY_PATH, optionInfo.ValueName

    OptionsMenu.ToggleCheck optionText
    optionInfo.Toggler

    add_log (optionInfo.CurrentSetting ? "Enabled " : "Disabled ") optionInfo.ValueName
}

ResetOptionsToDefault(*) {
    add_log "Resetting all options to default"

    Loop Reg REG_KEY_PATH {
        if A_LoopRegName != "LastUpdateCheck"
            RegDelete
    }

    local optionInfo
    for optionInfo in PersistentOptions {
        if optionInfo.CurrentSetting != optionInfo.Default {
            optionInfo.CurrentSetting := optionInfo.Default
            optionInfo.Toggler
        }
        if optionInfo.CurrentSetting
            OptionsMenu.Check optionInfo.Text
        else
            OptionsMenu.Uncheck optionInfo.Text
    }
}

AboutOpen(*) {
    AutoclickerGui.Opt "+Disabled"

    static AboutGui
    if !IsSet(AboutGui) {
        AboutGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "About EC Autoclicker")
        AboutGui.OnEvent "Escape", hideOwnedGui
        AboutGui.OnEvent "Close", hideOwnedGui

        AboutGui.AddPicture "w40 h40", A_IsCompiled ? A_ScriptFullPath : A_ProgramFiles "\AutoHotkey\v2\AutoHotkey.exe"
        AboutGui.SetFont "s12 bold"
        AboutGui.AddText "xp+50 yp", "EC Autoclicker version " (A_IsCompiled ? SubStr(FileGetVersion(A_ScriptFullPath), 1, -2) : "?")
        AboutGui.SetFont
        AboutGui.AddText "xp wp", "An open-source configurable autoclicking utility for Windows."
        AboutGui.AddLink "xp", "<a href=`"https://github.com/Expertcoderz/EC-Autoclicker`">https://github.com/Expertcoderz/EC-Autoclicker</a>"

        add_log "Created About GUI"
    }

    showGuiAtAutoclickerGuiPos AboutGui
}

Start(*) {
    AutoclickerGui["Tab"].Enabled := false
    AutoclickerGui["StartButton"].Enabled := false
    AutoclickerGui["StopButton"].Enabled := true
    AutoclickerGui["StopButton"].Focus()

    local currentConfig := AutoclickerGui.Submit(false)

    local buttonClickData := { 1: "L", 2: "R", 3: "M" }.%currentConfig.General_MouseButton_Radio%
    . " " ({ 1: 1, 2: 2, 3: 3, 4: 0 }.%currentConfig.General_ClickCount_DropDownList%)

    CoordMode "Mouse", currentConfig.Positioning_RelativeTo_Radio = 1 ? "Screen" : "Client"

    local clickCount := 0
    local timeStarted := A_TickCount

    local stopCriteria := []
    if currentConfig.Scheduling_StopAfterNumClicks_Checkbox
        stopCriteria.Push () => clickCount >= currentConfig.Scheduling_StopAfterNumClicks_NumEdit
    if currentConfig.Scheduling_StopAfterDuration_Checkbox
        stopCriteria.Push () => A_TickCount - timeStarted >= currentConfig.Scheduling_StopAfterDuration_NumEdit
    if currentConfig.Scheduling_StopAfterTime_Checkbox
        stopCriteria.Push () => A_Now >= currentConfig.Scheduling_StopAfterTime_DateTime

    global is_autoclicking := true
    add_log "Starting autoclicking"

    if currentConfig.Scheduling_PreStartDelay_Checkbox
        Sleep currentConfig.Scheduling_PreStartDelay_NumEdit

    while is_autoclicking {
        if currentConfig.General_SoundBeep_Checkbox
            SoundBeep currentConfig.General_SoundBeep_NumEdit

        local coords
        switch currentConfig.Positioning_BoundaryMode_Radio {
            case 1: coords := ""
            case 2: coords := currentConfig.Positioning_XPos_NumEdit " " currentConfig.Positioning_YPos_NumEdit
            case 3: coords := Random(currentConfig.Positioning_XMinPos_NumEdit, currentConfig.Positioning_XMaxPos_NumEdit)
                    . " " Random(currentConfig.Positioning_YMinPos_NumEdit, currentConfig.Positioning_YMaxPos_NumEdit)
        }

        Click coords, buttonClickData

        AutoclickerGui["StatusBar"].SetText(" Clicks: " (++clickCount))
        AutoclickerGui["StatusBar"].SetText("Elapsed: " Round((A_TickCount - timeStarted) / 1000, 2), 2)

        local mouseX, mouseY
        MouseGetPos &mouseX, &mouseY
        AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)

        if stopCriteria.Length > 0 {
            local passedCriteria := 0
            for check in stopCriteria {
                if check() {
                    passedCriteria += 1
                    if currentConfig.Scheduling_StopAfterMode_DropDownList = 1 || passedCriteria = stopCriteria.Length {
                        add_log "Stopping automatically"
                        Stop
                        switch currentConfig.Scheduling_PostStopAction_DropDownList {
                            case 2: ExitApp
                            case 3:
                                if WinExist("A")
                                    WinClose
                            case 4: Shutdown 0
                        }
                    }
                }
            }
        }

        Sleep currentConfig.General_ClickIntervalMode_Radio = 1
            ? currentConfig.General_ClickIntervalLower_NumEdit
            : Random(currentConfig.General_ClickIntervalLower_NumEdit, currentConfig.General_ClickIntervalUpper_NumEdit)
    }
}

Stop(*) {
    global is_autoclicking := false
    AutoclickerGui["Tab"].Enabled := true
    AutoclickerGui["StopButton"].Enabled := false
    AutoclickerGui["StartButton"].Enabled := true
    AutoclickerGui["StartButton"].Focus()
}

Close(*) {
    global is_autoclicking := false
    ExitApp
}

CheckForUpdates(isManual) {
    if !DllCall("Wininet.dll\InternetGetConnectedState", "Str", "0x40", "Int", 0) {
        add_log "No internet connection; not checking for updates"
        if isManual
            MsgBox "
        (
EC Autoclicker is unable to check for updates as there is currently no internet connection.
Please connect to the internet and try again.
)", "Update", "Icon! 262144"
        return
    }
    add_log "Checking for updates"

    local oHttp := ComObject("WinHttp.Winhttprequest.5.1")
    oHttp.open "GET", "https://api.github.com/repos/Expertcoderz/EC-Autoclicker/releases/latest"
    oHttp.send

    local verNumMatch
    if !RegExMatch(oHttp.responseText, '"tag_name":"v(.*?)"', &verNumMatch) {
        add_log "Unable to obtain latest release version"
        MsgBox "
        (
EC Autoclicker was unable to retrieve its latest version on the web.
Please try again later, or update EC Autoclicker manually if this error reoccurs.
)", "Update", "Iconx 262144"
        return
    }

    local thisVersion := SubStr(FileGetVersion(A_ScriptFullPath), 1, -2)
    if verNumMatch.1 = thisVersion {
        add_log "Current version is up to date with the latest release"
        if isManual
            MsgBox "EC Autoclicker is up to date (" verNumMatch.1 ").", "Update", "Iconi 262144"
        RegWrite A_NowUTC, "REG_SZ", REG_KEY_PATH, "LastUpdateCheck"
        return
    }

    if MsgBox(Format("
        (
A newer version of EC Autoclicker ({}) is available.
Your current version is {}. Would you like to update now?
)", verNumMatch.1, thisVersion), "Update", "YesNo Icon? 262144"
    ) = "Yes" {
        local downloadFilePath := ""
        while !downloadFilePath || FileExist(downloadFilePath)
            downloadFilePath := A_ScriptDir "\" SubStr(A_ScriptName, 1, -4) "-new-" Random(100000, 999999) ".exe"

        add_log "Downloading file"

        try Download "https://github.com/Expertcoderz/EC-Autoclicker/releases/latest/download/EC-Autoclicker.exe"
                , downloadFilePath
        catch as e
            MsgBox "An error occurred in attempting to download the latest version of EC Autoclicker.`n`nMessage: " e.Message
                , "Update", "Iconx 262144"
        else {
            add_log("File downloaded")
            Run "powershell -windowstyle Hidden -command start-sleep 1;"
                . 'remove-item "' A_ScriptFullPath '";'
                . 'rename-item "' downloadFilePath '" "' A_ScriptName '";'
                . 'start-process "' A_ScriptDir '\EC-Autoclicker.exe /updated"', , "Hide"
            ExitApp
        }
    }
}

for optionInfo in PersistentOptions {
    OptionsMenu.Add optionInfo.Text, OptionsMenuItemCallbackWrapper
    optionInfo.CurrentSetting := RegRead(REG_KEY_PATH, optionInfo.ValueName, optionInfo.Default)
    if optionInfo.CurrentSetting != optionInfo.Default
        optionInfo.Toggler
    if optionInfo.CurrentSetting
        OptionsMenu.Check optionInfo.Text
}
OptionsMenu.Add
OptionsMenu.Add SZ_TABLE.Menu_Options_ResetToDefault, ResetOptionsToDefault

AutoclickerGui.Show "x0"
add_log "Welcome to EC Autoclicker"

if A_IsCompiled {
    if A_Args.Length > 0 && A_Args[1] = "/updated" {
        RegWrite A_NowUTC, "REG_SZ", REG_KEY_PATH, "LastUpdateCheck"
        MsgBox "EC Autoclicker has been updated successfully.`nNew version: " SubStr(FileGetVersion(A_ScriptFullPath), 1, -2)
            , "Update", "Iconi 262144"
    } else if RegRead(REG_KEY_PATH, "AutoUpdate", true) && A_NowUTC - RegRead(REG_KEY_PATH, "LastUpdateCheck", 0) >= 604800 {
        add_log "Automatically checking for newer version"
        CheckForUpdates false
    }
}

Loop {
    CoordMode "Mouse", AutoclickerGui["Positioning_RelativeTo_Radio"].Value = 1 ? "Screen" : "Client"
    MouseGetPos &mouseX, &mouseY
    AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)
    Sleep 100
}
