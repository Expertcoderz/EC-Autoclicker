; Main GUI window construction

makeRadioGroup(name, radioControls, changedCallback := 0) {
    radioControls[1].Name := name
    RadioGroups.%name% := { Controls: radioControls, Callback: changedCallback }
    if changedCallback {
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

AutoclickerGui := Gui("+AlwaysOnTop", "EC Autoclicker")

FileMenu := Menu()
FileMenu.Add(
    SZ_TABLE.Menu_File_RunAsAdmin
    , (*) => Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath '" /restart' : A_AhkPath '" /restart "' A_ScriptFullPath '"'))
)
FileMenu.SetIcon(SZ_TABLE.Menu_File_RunAsAdmin, "imageres.dll", -78)
if A_IsAdmin {
    FileMenu.Disable(SZ_TABLE.Menu_File_RunAsAdmin)
    FileMenu.Rename(SZ_TABLE.Menu_File_RunAsAdmin, "Running as administrator")
}
FileMenu.Add(SZ_TABLE.Menu_File_Logs, LogsOpen)
FileMenu.Add(SZ_TABLE.Menu_File_Exit, Close)

ProfilesMenu := Menu()

OptionsMenu := Menu()

HelpMenu := Menu()
HelpMenu.Add(
    SZ_TABLE.Menu_Help_OnlineHelp
    , (*) => Run("https://github.com/" GITHUB_REPO "#readme")
)
HelpMenu.Add(
    SZ_TABLE.Menu_Help_Report
    , (*) => Run("https://github.com/" GITHUB_REPO "/issues/new/choose")
)
HelpMenu.Add(
    SZ_TABLE.Menu_Help_Update
    , (*) => CheckForUpdates(true)
)
if !A_IsCompiled
    HelpMenu.Disable(SZ_TABLE.Menu_Help_Update)
HelpMenu.Add()
HelpMenu.Add(SZ_TABLE.Menu_Help_About, AboutOpen)

Menus := MenuBar()
Menus.Add(SZ_TABLE.Menu_File, FileMenu)
Menus.Add(SZ_TABLE.Menu_Profiles, ProfilesMenu)
Menus.Add(SZ_TABLE.Menu_Options, OptionsMenu)
Menus.Add(SZ_TABLE.Menu_Help, HelpMenu)
AutoclickerGui.MenuBar := Menus

AutoclickerGui.AddTab3("w248 h208 vTab", [
    SZ_TABLE.Tabs.General,
    SZ_TABLE.Tabs.Scheduling,
    SZ_TABLE.Tabs.Positioning,
    SZ_TABLE.Tabs.Hotkeys
])

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.General)

AutoclickerGui.AddGroupBox("w226 h70 Section", "Mouse button")

makeRadioGroup("General_MouseButton_Radio", [
    AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "&Left"),
    AutoclickerGui.AddRadio("yp", "&Right"),
    AutoclickerGui.AddRadio("yp", "&Middle")
])

AutoclickerGui.AddDropDownList("xs+10 yp+20 w100 vGeneral_ClickCount_DropDownList AltSubmit Choose1", [
    "Single click",
    "Double click",
    "Triple click",
    "No click"
])

AutoclickerGui.AddGroupBox("xs w226 h73 Section", "Click intervals")

makeRadioGroup(
    "General_ClickIntervalMode_Radio"
    , [
        AutoclickerGui.AddRadio("xs+10 yp+20 Checked", "F&ixed"),
        AutoclickerGui.AddRadio("yp", "R&andomized")
    ]
    , General_ClickIntervalModeChanged
)

AutoclickerGui.AddEdit("xs+10 yp+20 w50 vGeneral_ClickIntervalLower_NumEdit Limit Number", "100")
AutoclickerGui.AddText("xp+54 yp+2", "ms")
AutoclickerGui.AddText("xp+24 yp vGeneral_ClickIntervalRange_Text Hidden", "to")
AutoclickerGui.AddEdit("xp+18 yp-2 w50 vGeneral_ClickIntervalUpper_NumEdit Hidden Limit Number", "200")
AutoclickerGui.AddText("xp+54 yp+2 vGeneral_ClickIntervalUpper_UnitText Hidden", "ms")

makeCheckable(
    "General_SoundBeep_Checkbox"
    , AutoclickerGui.AddCheckbox("xs", "Play a &beep at")
    , 1
    , [AutoclickerGui.AddEdit("xp+90 yp-2 w36 vGeneral_SoundBeep_NumEdit Disabled Limit Number", "600")]
)
AutoclickerGui.AddText("xp+42 yp+2", "Hz at every click")

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Scheduling)

makeCheckable(
    "Scheduling_PreStartDelay_Checkbox"
    , AutoclickerGui.AddCheckbox("Section", "&Delay before starting:")
    , 1
    , [AutoclickerGui.AddEdit("xp+124 yp-2 w50 vScheduling_PreStartDelay_NumEdit Disabled Limit Number", "0")]
)
AutoclickerGui.AddText("xp+56 ys vScheduling_PreStartDelay_UnitText", "ms")

AutoclickerGui.AddGroupBox("xs ys+25 w226 h148 Section", "Stop after")

makeCheckable(
    "Scheduling_StopAfterNumClicks_Checkbox"
    , AutoclickerGui.AddCheckbox("xs+10 yp+20", "&Number of clicks:")
    , Scheduling_StopAfterNumClicksToggled
)
AutoclickerGui.AddEdit("xp+104 yp-2 w45 vScheduling_StopAfterNumClicks_NumEdit Disabled Limit Number", "50")

makeCheckable(
    "Scheduling_StopAfterDuration_Checkbox"
    , AutoclickerGui.AddCheckbox("xs+10 yp+25", "D&uration:")
    , Scheduling_StopAfterDurationToggled
)
AutoclickerGui.AddEdit("xp+67 yp-2 w45 vScheduling_StopAfterDuration_NumEdit Disabled Limit Number", "60")
AutoclickerGui.AddText("xp+50 yp+2 vScheduling_StopAfterDuration_UnitText Disabled", "ms")

makeCheckable(
    "Scheduling_StopAfterTime_Checkbox"
    , AutoclickerGui.AddCheckbox("xs+10 yp+25", "&Time:")
    , Scheduling_StopAfterTimeToggled
)
AutoclickerGui.AddDateTime("xp+48 yp-2 w100 vScheduling_StopAfterTime_DateTime Disabled", "Time")

AutoclickerGui.AddDropDownList("xs+10 yp+26 w206 vScheduling_StopAfterMode_DropDownList AltSubmit Choose1 Disabled", [
    "Whichever comes first",
    "Whichever comes last"
])

AutoclickerGui.AddText("xs+10 ys+120 vScheduling_PostStopAction_Text Disabled", "&When done:")
AutoclickerGui.AddDropDownList("xp+62 yp-2 w140 vScheduling_PostStopAction_DropDownList AltSubmit Choose1 Disabled", [
    "Do nothing",
    "Quit autoclicker",
    "Close focused window",
    "Logoff"
])

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Positioning)

AutoclickerGui.AddGroupBox("w226 h45 Section", "Boundary")
makeRadioGroup(
    "Positioning_BoundaryMode_Radio"
    , [
        AutoclickerGui.AddRadio("xs+10 yp+20 v Checked", SZ_TABLE.Positioning_Boundary_Mode.None),
        AutoclickerGui.AddRadio("yp", SZ_TABLE.Positioning_Boundary_Mode.Point),
        AutoclickerGui.AddRadio("yp", SZ_TABLE.Positioning_Boundary_Mode.Box)
    ]
    , Positioning_ChangedModeSelection
)

PerBoundaryConfigControls := {
    %SZ_TABLE.Positioning_Boundary_Mode.None%: [],
    %SZ_TABLE.Positioning_Boundary_Mode.Point%: [
        AutoclickerGui.AddText("xs+10 ys+55 Hidden", "X:"),
        AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_XPos_NumEdit Limit Number Hidden", "0"),
        AutoclickerGui.AddText("xp+45 yp+2 Hidden", "Y:"),
        AutoclickerGui.AddEdit("xp+20 yp-2 w30 vPositioning_YPos_NumEdit Limit Number Hidden", "0")
    ],
    %SZ_TABLE.Positioning_Boundary_Mode.Box%: [
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

AutoclickerGui.AddGroupBox("xs yp+44 w226 h45 Section", "Mouse position relative to")
makeRadioGroup(
    "Positioning_RelativeTo_Radio"
    , [
        AutoclickerGui.AddRadio("xs+10 yp+20 vPositioning_RelativeTo_Radio Checked", "Entire &screen"),
        AutoclickerGui.AddRadio("yp", "Focused &window")
    ]
)

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

AutoclickerGui.AddText("xm ym vSimplifiedViewHeaderText Hidden", "Select a profile:")
AutoclickerGui.AddListBox("xp yp+20 w248 h188 vSimplifiedViewListBox Hidden Sort 0x100")

AutoclickerGui.AddButton("xm w121 vStartButton Default", "START")
    .OnEvent("Click", Start)
AutoclickerGui.AddButton("yp wp vStopButton Disabled", "STOP")
    .OnEvent("Click", Stop)

AutoclickerGui.AddStatusBar("vStatusBar")
AutoclickerGui["StatusBar"].SetParts(84, 100)
AutoclickerGui["StatusBar"].SetText(" Clicks: 0")
AutoclickerGui["StatusBar"].SetText("Elapsed: 0.0", 2)
AutoclickerGui["StatusBar"].SetText("X=? Y=?", 3, 2)

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

Hotkeys_updateHotkeyBindings() {
    AutoclickerGui["Hotkeys_HotkeyList_ListView"].Delete()

    for hotkeyData in configured_hotkeys {
        AutoclickerGui["Hotkeys_HotkeyList_ListView"].Add(
            , hotkeyData.Action = 1 ? "Start"
                : hotkeyData.Action = 2 ? "Stop"
                : hotkeyData.Action = 3 ? "Toggle"
                : "Close"
            , hotkeyData.Scope = 1 ? "Yes" : "No"
            , hotkeyData.HotkeyText
        )

        #MaxThreadsPerHotkey 2 ; needed for Toggle Autoclicker to work
        Hotkey hotkeyData.Hotkey, HotkeyEvent, are_hotkeys_active ? "On" : "Off"
        #MaxThreadsPerHotkey

        HotkeyEvent(hotkey) {
            local hotkeyData
            for hDat in configured_hotkeys {
                if hDat.Hotkey = hotkey {
                    hotkeyData := hDat
                    break
                }
            }

            if hotkeyData.Scope = 2 && !WinActive("ahk_id " AutoclickerGui.Hwnd)
                return
    
            switch hotkeyData.Action {
                case 1:
                    if !is_autoclicking
                        Start()
                case 2:
                    if is_autoclicking
                        Stop()
                case 3:
                    if is_autoclicking
                        Stop()
                    else
                        Start()
                case 4:
                    ExitApp
            }
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
        KeyBinderGui.OnEvent("Escape", hideOwnedGui)
        KeyBinderGui.OnEvent("Close", hideOwnedGui)

        KeyBinderGui.AddText(, "Hotkey:")
        KeyBinderGui.AddHotkey("x54 yp w180 vHotkey")

        KeyBinderGui.AddText("xm", "Applies:")
        KeyBinderGui.AddDropDownList(
            "x54 yp w180 vHotkeyScopeDropDownList"
            , ["Globally", "Only when Autoclicker is focused"]
        )

        KeyBinderGui.AddGroupBox("xm w134 r4 Section", "Action")
        KeyBinderGui.AddRadio("xp+10 yp+20 vHotkeyActionStartRadio", "Start Autoclicker")
        KeyBinderGui.AddRadio("xp vHotkeyActionStopRadio", "Stop Autoclicker")
        KeyBinderGui.AddRadio("xp vHotkeyActionToggleRadio", "Toggle Autoclicker")
        KeyBinderGui.AddRadio("xp", "Close Autoclicker")

        KeyBinderGui.AddButton("ys+43 w80 Default", "OK")
            .OnEvent("Click", Submit)
        KeyBinderGui.AddButton("xp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(KeyBinderGui))

        add_log("Created hotkey binder GUI")
    }

    KeyBinderGui["Hotkey"].Value := "^F2"
    KeyBinderGui["HotkeyScopeDropDownList"].Choose(1)
    KeyBinderGui["HotkeyActionStartRadio"].Value := 1
    showGuiAtAutoclickerGuiPos(KeyBinderGui)
    KeyBinderGui["Hotkey"].Focus()

    Submit(*) {
        hideOwnedGui(KeyBinderGui)

        for hotkeyData in configured_hotkeys {
            if "~" KeyBinderGui["Hotkey"].Value = hotkeyData.Hotkey {
                if MsgBox(
                    "The hotkey '" hotkeyText "' is already in use. Would you like to overwrite it?"
                    , "Overwrite Hotkey"
                    , "YesNo Iconi 8192"
                ) = "Yes"
                    configured_hotkeys.RemoveAt(A_Index)
                else
                    return
                break
            }
        }

        local hotkeyText := formatHotkeyText(KeyBinderGui["Hotkey"].Value)

        configured_hotkeys.Push {
            Hotkey: "~" KeyBinderGui["Hotkey"].Value,
            HotkeyText: hotkeyText,
            Scope: KeyBinderGui["HotkeyScopeDropDownList"].Value,
            Action: KeyBinderGui["HotkeyActionStartRadio"].Value = 1 ? 1
                : KeyBinderGui["HotkeyActionStopRadio"].Value = 1 ? 2
                : KeyBinderGui["HotkeyActionToggleRadio"].Value = 1 ? 3
                : 4
        }
        add_log("Added hotkey: " hotkeyText)
        Hotkeys_updateHotkeyBindings()
    }
}

Hotkeys_RemoveHotkey(*) {
    local rowNum := 0
    Loop {
        rowNum := AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetNext(rowNum)
        if !rowNum
            break

        for hotkeyData in configured_hotkeys {
            if hotkeyData.HotkeyText = AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetText(rowNum, 3) {
                configured_hotkeys.RemoveAt(A_Index)
                Hotkey hotkeyData.Hotkey, "Off"
                add_log("Removed hotkey: " hotkeyData.HotkeyText)
                break
            }
        }
    }

    Hotkeys_updateHotkeyBindings()
    Hotkeys_ItemSelectionChanged()
}

Hotkeys_ClearAllHotkeys(*) {
    for hotkeyData in configured_hotkeys {
        configured_hotkeys.Delete(A_Index)
        Hotkey hotkeyData.Hotkey, "Off"
        add_log("Removed hotkey: " hotkeyData.HotkeyText)
    }
    configured_hotkeys.Length := 0
    Hotkeys_updateHotkeyBindings()
}
