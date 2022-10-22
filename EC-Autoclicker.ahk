#Warn
#Requires AutoHotkey v2.0-beta
#NoTrayIcon
#SingleInstance Force

;@Ahk2Exe-SetCompanyName Expertcoderz
;@Ahk2Exe-SetDescription EC Autoclicker
;@Ahk2Exe-SetVersion 1.0.1

FILE_EXT := ".ac-profile"
REG_KEY_PATH := "HKCU\Software\Expertcoderz\Autoclicker"
RegCreateKey REG_KEY_PATH "\Profiles"

STRING_TABLE := {
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
    }
}

program_logs := []
is_autoclicking := false
always_on_top := true

RadioGroups := {}
Checkables := {}
makeRadioGroup(name, radioControls, changedCallback := 0) {
    radioControls[1].Name := name
    RadioGroups.%name% := { Controls: radioControls, Callback: changedCallback }
    if changedCallback {
        local ctrl
        for ctrl in radioControls
            ctrl.OnEvent("Click", changedCallback)
    }
}
makeCheckable(name, checkbox, callback := 0, controls := []) {
    checkbox.Name := name
    Checkables.%name% := { Checkbox: checkbox, Callback: callback }
    if callback = 1 {
        checkbox.OnEvent("Click", Toggle)
        Toggle(*) {
            for ctrl in controls
                ctrl.Enabled := checkbox.Value
        }
        Checkables.%name%.Callback := Toggle
    } else if callback
        checkbox.OnEvent("Click", callback)
}

AutoclickerGui := Gui("+AlwaysOnTop", "EC Autolicker")
AutoclickerGui.OnEvent("Close", Close)

FileMenu := Menu()
FileMenu.Add(STRING_TABLE.Menu_File_RunAsAdmin, (*) =>
        Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath '" /restart' : A_AhkPath '" /restart "' A_ScriptFullPath '"')))
FileMenu.SetIcon(STRING_TABLE.Menu_File_RunAsAdmin, "imageres.dll", -78)
if A_IsAdmin {
    FileMenu.Disable(STRING_TABLE.Menu_File_RunAsAdmin)
    FileMenu.Rename(STRING_TABLE.Menu_File_RunAsAdmin, "Running as administrator")
}
FileMenu.Add(STRING_TABLE.Menu_File_Logs, OpenLogs)
FileMenu.Add(STRING_TABLE.Menu_File_Exit, Close)

ProfilesMenu := Menu()

setupProfiles() {
    ProfilesMenu.Delete()
    ProfilesMenu.Add(STRING_TABLE.Menu_Profiles_Create, ProfileCreate)
    ProfilesMenu.Add(STRING_TABLE.Menu_Profiles_Manage, ProfileManage)
    ProfilesMenu.Add()

    Loop Reg REG_KEY_PATH "\Profiles", "K"
        ProfilesMenu.Add(A_LoopRegName, ProfileLoad)

    add_log("Loaded profiles")
}
setupProfiles()

OptionsMenu := Menu()

setupOptions() {
    toggleAlwaysOnTop(optionInfo) {
        global always_on_top := optionInfo.CurrentSetting
        AutoclickerGui.Opt((always_on_top ? "+" : "-") "AlwaysOnTop")
    }
    static PERSISTENT_OPTIONS := [{ ValueName: "AlwaysOnTop",
        Default: true,
        Text: STRING_TABLE.Menu_Options_AlwaysOnTop,
        Toggler: toggleAlwaysOnTop
    },
        { ValueName: "MinButtonVisible",
            Default: true,
            Text: STRING_TABLE.Menu_Options_MinButtonVisible,
            Toggler: (optionInfo) => AutoclickerGui.Opt((optionInfo.CurrentSetting ? "+" : "-") "MinimizeBox")
        },
            {
                ValueName: "EscToClose",
                Default: false,
                Text: STRING_TABLE.Menu_Options_EscToClose,
                Toggler: (optionInfo) => AutoclickerGui.OnEvent("Escape", Close, optionInfo.CurrentSetting ? 1 : 0)
            },
                { ValueName: "HotkeysActive",
                    Default: true,
                    Text: STRING_TABLE.Menu_Options_HotkeysActive,
                    Toggler: (optionInfo) => 0
                },
                    {
                        ValueName: "AutoUpdate",
                        Default: true,
                        Text: STRING_TABLE.Menu_Options_AutoUpdate,
                        Toggler: (*) => 0
                    }
        ]
    local optionInfo, savedSetting
    for optionInfo in PERSISTENT_OPTIONS {
        if !optionInfo.HasProp("CurrentSetting")
            OptionsMenu.Add(optionInfo.Text, MenuItemCallbackWrapper)
        optionInfo.CurrentSetting := RegRead(REG_KEY_PATH, optionInfo.ValueName, optionInfo.Default)
        if optionInfo.CurrentSetting != optionInfo.Default
            optionInfo.Toggler()
        if optionInfo.CurrentSetting
            OptionsMenu.Check(optionInfo.Text)
    }

    MenuItemCallbackWrapper(optionText, *) {
        local optionInfo
        for i in PERSISTENT_OPTIONS {
            if i.Text = optionText {
                optionInfo := i
                break
            }
        }
        optionInfo.CurrentSetting := !optionInfo.CurrentSetting
        OptionsMenu.ToggleCheck(optionText)
        RegWrite optionInfo.CurrentSetting, "REG_DWORD", REG_KEY_PATH, optionInfo.ValueName
        optionInfo.Toggler()
        add_log((optionInfo.CurrentSetting ? "Enabled " : "Disabled ") optionInfo.ValueName)
    }
    add_log("Loaded options")
}
setupOptions()

OptionsMenu.Add()
OptionsMenu.Add(STRING_TABLE.Menu_Options_ResetToDefault, ResetOptionsToDefault)

HelpMenu := Menu()
HelpMenu.Add(STRING_TABLE.Menu_Help_OnlineHelp
    , (*) => Run("https://github.com/Expertcoderz/EC-Autoclicker#readme"))
HelpMenu.Add(STRING_TABLE.Menu_Help_Report
    , (*) => Run("https://github.com/Expertcoderz/EC-Autoclicker/issues/new/choose"))
HelpMenu.Add(STRING_TABLE.Menu_Help_Update
    , (*) => CheckForNewerVersion(true))
if !A_IsCompiled
    HelpMenu.Disable(STRING_TABLE.Menu_Help_Update)
HelpMenu.Add()
HelpMenu.Add(STRING_TABLE.Menu_Help_About, OpenAbout)

Menus := MenuBar()
Menus.Add(STRING_TABLE.Menu_File, FileMenu)
Menus.Add(STRING_TABLE.Menu_Profiles, ProfilesMenu)
Menus.Add(STRING_TABLE.Menu_Options, OptionsMenu)
Menus.Add(STRING_TABLE.Menu_Help, HelpMenu)
AutoclickerGui.MenuBar := Menus

AutoclickerGui.AddTab3("w250 h205 vTab"
    , [
    STRING_TABLE.Tabs.General,
    STRING_TABLE.Tabs.Scheduling,
    STRING_TABLE.Tabs.Positioning,
    STRING_TABLE.Tabs.Hotkeys
    ]
)

AutoclickerGui["Tab"].UseTab(STRING_TABLE.Tabs.General)

AutoclickerGui.AddGroupBox("w226 h70 Section", "Mouse button")

makeRadioGroup("General_MouseButton_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "&Left"),
    AutoclickerGui.AddRadio("yp", "&Right"),
    AutoclickerGui.AddRadio("yp", "&Middle")])

AutoclickerGui.AddDropDownList("xs+10 yp+20 w100 vGeneral_ClickCount_DropDownList AltSubmit Choose1"
    , [
    "Single click",
    "Double click",
    "Triple click",
    "No click"
    ]
)

AutoclickerGui.AddGroupBox("xs w226 h73 Section", "Click intervals")

makeRadioGroup("General_ClickIntervalMode_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "F&ixed"),
    AutoclickerGui.AddRadio("yp", "R&andomized")], General_ClickIntervalModeChanged)

AutoclickerGui.AddEdit("xs+10 yp+20 w50 vGeneral_ClickIntervalLower_NumEdit Limit Number", "100")
AutoclickerGui.AddText("xp+54 yp+2", "ms")
AutoclickerGui.AddText("xp+24 yp vGeneral_ClickIntervalRange_Text Hidden", "to")
AutoclickerGui.AddEdit("xp+18 yp-2 w50 vGeneral_ClickIntervalUpper_NumEdit Hidden Limit Number", "200")
AutoclickerGui.AddText("xp+54 yp+2 vGeneral_ClickIntervalUpper_UnitText Hidden", "ms")

makeCheckable("General_SoundBeep_Checkbox", AutoclickerGui.AddCheckbox("xs", "Play a &beep at")
    , 1
    , [AutoclickerGui.AddEdit("xp+88 yp-2 w36 vGeneral_SoundBeep_NumEdit Disabled Limit Number", "600")]
)
AutoclickerGui.AddText("xp+40 yp+2", "Hz at every click")

AutoclickerGui["Tab"].UseTab(STRING_TABLE.Tabs.Scheduling)

makeCheckable("Scheduling_PreStartDelay_Checkbox", AutoclickerGui.AddCheckbox("Section", "&Delay before starting:")
    , 1
    , [AutoclickerGui.AddEdit("xp+122 yp-2 w50 vScheduling_PreStartDelay_NumEdit Disabled Limit Number", "0")]
)
AutoclickerGui.AddText("xp+54 ys vScheduling_PreStartDelay_UnitText", "ms")

AutoclickerGui.AddGroupBox("xs ys+25 w226 h148 Section", "Stop after")

makeCheckable("Scheduling_StopAfterNumClicks_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+20", "&Number of clicks:")
    , Scheduling_StopAfterNumClicksToggled
)
AutoclickerGui.AddEdit("xp+100 yp-2 w45 vScheduling_StopAfterNumClicks_NumEdit Disabled Limit Number", "50")

makeCheckable("Scheduling_StopAfterDuration_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+25", "D&uration:")
    , Scheduling_StopAfterDurationToggled
)
AutoclickerGui.AddEdit("xp+65 yp-2 w45 vScheduling_StopAfterDuration_NumEdit Disabled Limit Number", "60")
AutoclickerGui.AddText("xp+48 yp+2 vScheduling_StopAfterDuration_UnitText Disabled", "ms")

makeCheckable("Scheduling_StopAfterTime_Checkbox", AutoclickerGui.AddCheckbox("xs+10 yp+25", "&Time:")
    , Scheduling_StopAfterTimeToggled
)
AutoclickerGui.AddDateTime("xp+48 yp-2 w80 vScheduling_StopAfterTime_DateTime Disabled", "Time")

AutoclickerGui.AddDropDownList("xs+10 yp+26 w206 vScheduling_StopAfterMode_DropDownList AltSubmit Choose1 Disabled"
    , [
    "Whichever comes first",
    "Whichever comes last"
    ]
)

AutoclickerGui.AddText("xs+10 ys+120 vScheduling_PostStopAction_Text Disabled", "&When done:")
AutoclickerGui.AddDropDownList("xp+62 yp-2 w140 vScheduling_PostStopAction_DropDownList AltSubmit Choose1 Disabled"
    , [
    "Do nothing",
    "Quit autoclicker",
    "Close focused window",
    "Logoff"
    ]
)

AutoclickerGui["Tab"].UseTab(STRING_TABLE.Tabs.Positioning)

AutoclickerGui.AddGroupBox("w226 h45 Section", "Boundary")
makeRadioGroup("Positioning_BoundaryMode_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 v Checked", STRING_TABLE.Positioning_Boundary_Mode.None),
    AutoclickerGui.AddRadio("yp", STRING_TABLE.Positioning_Boundary_Mode.Point),
    AutoclickerGui.AddRadio("yp", STRING_TABLE.Positioning_Boundary_Mode.Box)], Positioning_ChangedModeSelection)

PerBoundaryConfigControls := { %STRING_TABLE.Positioning_Boundary_Mode.None%: [], %STRING_TABLE.Positioning_Boundary_Mode.Point%: [
    AutoclickerGui.AddText("xs+10 ys+55 Hidden", "X:"),
    AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_XPos_NumEdit Limit Number Hidden", "0"),
    AutoclickerGui.AddText("xp+45 yp+2 Hidden", "Y:"),
    AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_YPos_NumEdit Limit Number Hidden", "0")], %STRING_TABLE.Positioning_Boundary_Mode.Box%: [
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

AutoclickerGui.AddGroupBox("xs yp+40 w226 h45 Section", "Mouse position relative to")
makeRadioGroup("Positioning_RelativeTo_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 vPositioning_RelativeTo_Radio Checked", "Entire &screen"),
    AutoclickerGui.AddRadio("yp", "Focused &window")])

AutoclickerGui["Tab"].UseTab(STRING_TABLE.Tabs.Hotkeys)

AutoclickerGui.AddText(, "Configurable hotkeys are coming soon!")

AutoclickerGui["Tab"].UseTab()

AutoclickerGui.AddButton("xm w121 vStartButton Default", "START")
    .OnEvent("Click", Start)
AutoclickerGui.AddButton("yp wp vStopButton Disabled", "STOP")
    .OnEvent("Click", Stop)

AutoclickerGui.AddStatusBar("vStatusBar")
AutoclickerGui["StatusBar"].SetParts(84, 100)
AutoclickerGui["StatusBar"].SetText(" Clicks: 0")
AutoclickerGui["StatusBar"].SetText("Elapsed: 0.0 s", 2)
AutoclickerGui["StatusBar"].SetText("X=? Y=?", 3, 2)

add_log(text) {
    OutputDebug text
    global program_logs
    program_logs.Push({ Timestamp: A_Now, Message: text })
    if program_logs.Length > 100
        program_logs.RemoveAt(1)
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
    Scheduling_updateStopAfter()
}

Scheduling_StopAfterDurationToggled(*) {
    AutoclickerGui["Scheduling_StopAfterDuration_NumEdit"].Enabled := AutoclickerGui["Scheduling_StopAfterDuration_Checkbox"].Value
    AutoclickerGui["Scheduling_StopAfterDuration_UnitText"].Enabled := AutoclickerGui["Scheduling_StopAfterDuration_Checkbox"].Value
    Scheduling_updateStopAfter()
}

Scheduling_StopAfterTimeToggled(*) {
    AutoclickerGui["Scheduling_StopAfterTime_DateTime"].Enabled := AutoclickerGui["Scheduling_StopAfterTime_Checkbox"].Value
    Scheduling_updateStopAfter()
}

Positioning_ChangedModeSelection(radio, *) {
    for key, list in PerBoundaryConfigControls.OwnProps() {
        for ctrl in list
            ctrl.Visible := key = radio.Text
    }
}

showGuiAtAutoclickerGuiPos(gui) {
    local posX, posY
    AutoclickerGui.GetPos(&posX, &posY)
    global always_on_top
    gui.Opt((always_on_top ? "+" : "-") "AlwaysOnTop")
    gui.Show("x" posX " y" posY)
}

hideOwnedGui(gui, *) {
    gui.Hide()
    AutoclickerGui.Opt("-Disabled")
    WinActivate "ahk_id " AutoclickerGui.Hwnd
}

profileNamePrompt(title, text, callback) {
    static currentCallback
    static ProfileNamePromptGui := ""
    if !ProfileNamePromptGui {
        ProfileNamePromptGui := Gui("-SysMenu +Owner" AutoclickerGui.Hwnd)
        ProfileNamePromptGui.OnEvent("Escape", hideOwnedGui)
        ProfileNamePromptGui.OnEvent("Close", hideOwnedGui)

        ProfileNamePromptGui.AddText("w206 r2 vPromptText")
        ProfileNamePromptGui.AddEdit("wp vProfileNameEdit")

        ProfileNamePromptGui.AddButton("w100 Default", "OK")
            .OnEvent("Click", (*) => CallbackWrapper(currentCallback))
        ProfileNamePromptGui.AddButton("yp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(ProfileNamePromptGui))
    }

    CallbackWrapper(currentCallback) {
        local profileName := ProfileNamePromptGui["ProfileNameEdit"].Value
        if RegExReplace(profileName, "\s") = ""
            return
        if RegExMatch(profileName, "[\\/:\*\?`"<>\|]") {
            MsgBox "A profile name can't contain any of the following characters:`n\ / : * ? `" < > |", "Create Profile", "Iconx 8192"
            return
        }
        Loop Reg REG_KEY_PATH "\Profiles", "K" {
            if A_LoopRegName = profileName {
                if MsgBox(
                    "A profile similarly named '" A_LoopRegName "' already exists. Would you like to overwrite it with the new configuration set?"
                    , "Overwrite Profile", "YesNo Iconi 8192"
                ) = "Yes"
                    RegDeleteKey A_LoopRegKey "\" A_LoopRegName
                else
                    return
            }
        }
        ProfileNamePromptGui.Opt("+Disabled")
        currentCallback(profileName)
        setupProfiles()
        hideOwnedGui(ProfileNamePromptGui)
    }

    currentCallback := callback
    ProfileNamePromptGui.Title := title
    ProfileNamePromptGui["PromptText"].Text := text
    ProfileNamePromptGui["ProfileNameEdit"].Value := ""
    ProfileNamePromptGui.Opt("-Disabled")
    showGuiAtAutoclickerGuiPos(ProfileNamePromptGui)
}

ProfileCreate(*) {
    AutoclickerGui.Opt("+Disabled")

    profileNamePrompt("Create Profile"
        , "The current autoclicker configuration will`nbe saved with the following profile name:"
        , SubmitPrompt
    )

    SubmitPrompt(profileName) {
        add_log("Reading configuration data")

        local currentConfig := AutoclickerGui.Submit(false)

        RegCreateKey REG_KEY_PATH "\Profiles\" profileName

        for ctrlName, value in currentConfig.OwnProps() {
            local ctrlType := AutoclickerGui[ctrlName].Type
            if !InStr(ctrlName, "_")
                continue
            RegWrite value, InStr(ctrlName, "NumEdit", , -1, -1)
                || ctrlType = "Checkbox" || ctrlType = "Radio" || ctrlType = "DropDownList"
                ? "REG_DWORD" : "REG_SZ", REG_KEY_PATH "\Profiles\" profileName, ctrlName
        }

        add_log("Wrote configuration data to registry")
    }
}

ProfileManage(*) {
    static ProfilesGui := ""
    local selectedProfileName := ""
    if !ProfilesGui {
        ProfilesGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "Autoclicker Profiles")
        ProfilesGui.OnEvent("Escape", hideOwnedGui)
        ProfilesGui.OnEvent("Close", hideOwnedGui)

        ProfilesGui.AddListView("w150 r10 vProfileList -Hdr -Multi +Sort", ["Profile Name"])
            .OnEvent("ItemSelect", UpdateSelectedProfile)
        ProfilesGui.AddButton("yp w100", "&Delete")
            .OnEvent("Click", ProfileDelete)
        ProfilesGui.AddButton("xp wp", "&Rename")
            .OnEvent("Click", ProfileRename)
        ProfilesGui.AddButton("xp wp", "&Export")
            .OnEvent("Click", ProfileExport)
        ProfilesGui.AddButton("xp yp+52 wp", "&Import")
            .OnEvent("Click", ProfileImport)
        ProfilesGui.AddButton("xp wp Default", "&Close")
            .OnEvent("Click", (*) => hideOwnedGui(ProfilesGui))
        ProfilesGui.AddStatusBar("vStatusBar", " Selected Profile: None")
    }

    refreshProfileList()
    showGuiAtAutoclickerGuiPos(ProfilesGui)

    refreshProfileList(selectProfileName := "") {
        ProfilesGui["ProfileList"].Delete()
        Loop Reg REG_KEY_PATH "\Profiles", "K"
            ProfilesGui["ProfileList"].Add(A_LoopRegName = selectProfileName ? "+Focus +Select" : "", A_LoopRegName)
    }

    UpdateSelectedProfile(listview, itemNumber, selected) {
        if selected {
            selectedProfileName := listview.GetText(itemNumber)
            ProfilesGui["StatusBar"].SetText(" Selected Profile: " listview.GetText(itemNumber))
        } else if !listview.GetNext() {
            selectedProfileName := ""
            ProfilesGui["StatusBar"].SetText(" Selected Profile: None")
        }
    }

    ProfileDelete(*) {
        if !selectedProfileName
            return SoundPlay("*64")
        Loop Reg REG_KEY_PATH "\Profiles", "K" {
            if A_LoopRegName = selectedProfileName {
                RegDeleteKey
                add_log("Deleted profile '" selectedProfileName "'")
                refreshProfileList()
                selectedProfileName := ""
                ProfilesGui["StatusBar"].SetText(" Selected Profile: None")
                setupProfiles()
                return
            }
        }
        MsgBox "The profile '" selectedProfileName "' does not exist or has already been deleted.", "Error", "Iconx 8192"
        refreshProfileList()
        setupProfiles()
    }

    ProfileRename(*) {
        if !selectedProfileName
            return SoundPlay("*64")
        profileNamePrompt("Rename Profile"
            , "The profile '" selectedProfileName "' will be renamed to:"
            , SubmitPrompt
        )
        SubmitPrompt(newProfileName) {
            Loop Reg REG_KEY_PATH "\Profiles", "K" {
                if A_LoopRegName = selectedProfileName {
                    local newProfileRegPath := A_LoopRegKey "\" newProfileName
                    RegCreateKey newProfileRegPath
                    Loop Reg A_LoopRegKey "\" A_LoopRegName
                        RegWrite RegRead(), A_LoopRegType, newProfileRegPath, A_LoopRegName
                    add_log("Copied reg data to profile '" newProfileName "'")
                    RegDeleteKey
                    add_log("Deleted profile '" selectedProfileName "'")
                    refreshProfileList(newProfileName)
                    selectedProfileName := newProfileName
                    ProfilesGui["StatusBar"].SetText(" Selected Profile: " newProfileName)
                    return
                }
            }
            MsgBox "The profile '" selectedProfileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
            refreshProfileList()
        }
    }

    ProfileExport(*) {
        if !selectedProfileName
            return SoundPlay("*64")
        local fileLocation := FileSelect("S16", A_WorkingDir "\" selectedProfileName FILE_EXT
            , "Export Autoclicker Profile", "Autoclicker Profiles (*" FILE_EXT ")"
        )
        if !fileLocation {
            add_log("Export for profile '" selectedProfileName "' cancelled")
            return
        }
        add_log("Exporting profile '" selectedProfileName "'")
        local formatted := ""
        local ctrlName, value
        for ctrlName, value in AutoclickerGui.Submit(false).OwnProps() {
            if !InStr(ctrlName, "_")
                continue
            formatted .= ctrlName "=" value "`n"
        }
        if FileExist(fileLocation) {
            FileDelete fileLocation
            add_log("Deleted existing file: " fileLocation)
        }
        FileAppend formatted, fileLocation
        add_log("Wrote to new file: " fileLocation)
    }

    ProfileImport(*) {
        local fileLocations := FileSelect("M",
            , "Import Autoclicker Profile(s)", "Autoclicker Profiles (*.ac-profile)"
        )
        local fileLocation
        for fileLocation in fileLocations {
            add_log("Importing profile from " fileLocation)
            local profileNameMatch
            RegExMatch(fileLocation, ".*\\\K(.*?)(\..*)?$", &profileNameMatch)
            MsgBox profileNameMatch.0, profileNameMatch.HasProp("1") ? profileNameMatch.1 : "e"
        }
    }
}

ProfileLoad(profileName, *) {
    local currentConfig := {}

    add_log("Loading profile '" profileName "'")

    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        if A_LoopRegName = profileName {
            Loop Reg A_LoopRegKey "\" A_LoopRegName
                currentConfig.%A_LoopRegName% := RegRead()

            add_log("Configuration imported")

            try {
                local name, value
                for name, value in currentConfig.OwnProps() {
                    add_log("Update: " name " (value=" String(value) ")")
                    local ctrl := AutoclickerGui[name]
                    if ctrl.Type = "Radio" {
                        local radioInfo := RadioGroups.%name%
                        radioInfo.Controls[value].Value := true
                        if radioInfo.Callback
                            radioInfo.Callback.Call(radioInfo.Controls[value])
                    } else {
                        ctrl.Value := value
                        if ctrl.Type = "Checkbox" {
                            local checkableInfo := Checkables.%name%
                            if checkableInfo.HasProp("Callback")
                                checkableInfo.Callback.Call(ctrl)
                        }
                    }
                }
                add_log("Configuration GUI updated from profile")
            } catch as e
                MsgBox(
                    "An error occurred whilst loading the profile '" profileName "'. This is likely due to corrupt data.`n`nMessage: " e.Message
                    , "Load Profile", "Iconx 8192"
                )
            return
        }
    }
    MsgBox "The profile '" profileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
    setupProfiles()
}

OpenLogs(*) {
    static LogsGui := ""
    if !LogsGui {
        LogsGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "Logs")
        LogsGui.OnEvent("Escape", hideOwnedGui)
        LogsGui.OnEvent("Close", hideOwnedGui)

        LogsGui.AddListView("w300 h180 vList -LV0x10 +NoSortHdr", ["Time", "Message"])
        LogsGui["List"].ModifyCol(2, "NoSort")

        LogsGui.AddButton("w100", "&Refresh")
            .OnEvent("Click", RefreshLogs)
        LogsGui.AddButton("yp wp Default", "&Close")
            .OnEvent("Click", (*) => hideOwnedGui(LogsGui))

        add_log("Created Logs GUI")
    }

    if WinExist("ahk_id " LogsGui.Hwnd)
        WinActivate
    else
        showGuiAtAutoclickerGuiPos(LogsGui)
    RefreshLogs()

    RefreshLogs(*) {
        LogsGui["List"].Delete()

        local data
        for data in program_logs {
            LogsGui["List"].Add(, FormatTime(data.Timestamp, "HH:mm:ss"), data.Message)
        }

        LogsGui["List"].ModifyCol()
    }
}

OpenAbout(*) {
    AutoclickerGui.Opt("+Disabled")

    static AboutGui := ""
    if !AboutGui {
        AboutGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "About EC Autoclicker")
        AboutGui.OnEvent("Escape", hideOwnedGui)
        AboutGui.OnEvent("Close", hideOwnedGui)

        AboutGui.AddPicture("w40 h40", A_IsCompiled ? A_ScriptFullPath : "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe")
        AboutGui.SetFont("s12 bold")
        AboutGui.AddText("xp+50 yp", "EC Autoclicker version " (A_IsCompiled ? FileGetVersion(A_ScriptFullPath) : "?"))
        AboutGui.SetFont()
        AboutGui.AddLink("xp", "<a>https://github.com/Expertcoderz/EC-Autoclicker</a>")

        add_log("Created About GUI")
    }

    showGuiAtAutoclickerGuiPos(AboutGui)
}

ResetOptionsToDefault(*) {
    add_log("Resetting all options to default")
    Loop Reg REG_KEY_PATH {
        if A_LoopRegName != "LastUpdateCheck"
            RegDelete
    }
    setupOptions()
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
        stopCriteria.Push(() => clickCount >= currentConfig.Scheduling_StopAfterNumClicks_NumEdit)
    if currentConfig.Scheduling_StopAfterDuration_Checkbox
        stopCriteria.Push(() => A_TickCount - timeStarted >= currentConfig.Scheduling_StopAfterDuration_NumEdit)
    if currentConfig.Scheduling_StopAfterTime_Checkbox
        stopCriteria.Push(() => A_Now >= currentConfig.Scheduling_StopAfterTime_DateTime)

    global is_autoclicking := true
    add_log("Starting")

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

        Click coords buttonClickData

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
                        add_log("Stopping automatically")
                        Stop()
                        switch currentConfig.Scheduling_PostStopAction_DropDownList {
                            case 2: ExitApp
                            case 3:
                            {
                                if WinExist("A")
                                    WinClose
                            }
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

AutoclickerGui.Show("x0")
add_log("Welcome to EC Autoclicker")

CheckForNewerVersion(isManual) {
    add_log("Checking for newer version")

    local oHttp := ComObject("WinHttp.Winhttprequest.5.1")
    oHttp.open("GET", "https://api.github.com/repos/Expertcoderz/EC-Autoclicker/releases/latest")
    oHttp.send()

    local verNumMatch
    if !RegExMatch(oHttp.responseText, '"tag_name":"v(.*?)"', &verNumMatch) {
        add_log("Unable to obtain latest release version")
        MsgBox "
        (
EC Autoclicker was unable to retrieve its latest version on the web.
Please try again later, or update EC Autoclicker manually if this error reoccurs.
)", "Update", "Iconx 262144"
        return
    }
    local thisVersion := SubStr(FileGetVersion(A_ScriptFullPath), 1, StrLen(FileGetVersion(A_ScriptFullPath)) - 2)
    if verNumMatch.1 = thisVersion {
        add_log("Version is up to date with the latest release")
        if isManual
            MsgBox "Your version of EC Autoclicker is the latest (" verNumMatch.1 ")."
                , "Update", "Iconi 262144"
        RegWrite A_NowUTC, "REG_DWORD", REG_KEY_PATH, "LastUpdateCheck"
        return
    }
    if MsgBox(Format("
        (
A newer version of EC Autoclicker ({}) is available.
Your current version is {}. Would you like to update now?
)", verNumMatch.1, thisVersion), "Update", "YesNo Icon? 262144") = "Yes" {
        local DOWNLOAD_FILE_NAME := "EC-Autoclicker-New.exe"
        if A_ScriptName = DOWNLOAD_FILE_NAME {
            MsgBox "Please rename EC Autoclicker to something else before updating it.", "Update", "Iconx 262144"
            return
        }
        add_log("Downloading file")
        try Download "https://github.com/Expertcoderz/EC-Autoclicker/releases/latest/download/EC-Autoclicker.exe"
                , A_ScriptDir "\" DOWNLOAD_FILE_NAME
        catch as e
            MsgBox "An error occurred in attempting to download the latest version of EC Autoclicker.`n`nMessage: " e.Message
                , "Update", "Iconx 262144"
        else {
            add_log("Running downloaded file and exiting")
            Run A_ScriptDir "\" DOWNLOAD_FILE_NAME ' /replace:"' A_ScriptFullPath '"'
            ExitApp
        }
    }
}

if A_IsCompiled {
    if A_Args.Length > 0 && RegExMatch(A_Args[1], "^/replace:.+$") {
        RegWrite A_NowUTC, "REG_DWORD", REG_KEY_PATH, "LastUpdateCheck"
        FileMove A_ScriptFullPath, A_ScriptDir "\" SubStr(A_Args[1], 8), true
        MsgBox "EC Autoclicker has been updated successfully.", "Update", "Iconi 262144"
    } else if RegRead(REG_KEY_PATH, "AutoUpdate", false) && A_NowUTC - RegRead(REG_KEY_PATH, "LastUpdateCheck", 0) >= 604800
        CheckForNewerVersion(false)
}

Loop {
    CoordMode "Mouse", AutoclickerGui["Positioning_RelativeTo_Radio"].Value = 1 ? "Screen" : "Client"
    MouseGetPos &mouseX, &mouseY
    AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)
    Sleep 100
}
