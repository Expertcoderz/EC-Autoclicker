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
                ctrl.Enabled := checkbox.Value != 0
        }
        Checkables.%name%.Callback := Toggle
    } else if callback
        checkbox.OnEvent("Click", callback)
}

AutoclickerGui := Gui("+AlwaysOnTop", "EC Autoclicker")

AutoclickerGui.OnEvent("Close", Close)

FileMenu := Menu()
FileMenu.Add(
    SZ_TABLE.Menu_File_RunAsAdmin
    , (*) => Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath '" /restart'
        : A_AhkPath '" /restart "' A_ScriptFullPath '"'))
)
FileMenu.SetIcon(SZ_TABLE.Menu_File_RunAsAdmin, "imageres.dll", -78)
if A_IsAdmin {
    FileMenu.Disable(SZ_TABLE.Menu_File_RunAsAdmin)
    FileMenu.Rename(SZ_TABLE.Menu_File_RunAsAdmin, "Running as administrator")
}
FileMenu.Add(SZ_TABLE.Menu_File_Collapse, Collapse)
FileMenu.Add(SZ_TABLE.Menu_File_Logs, LogsOpen)
FileMenu.Add(SZ_TABLE.Menu_File_Exit, Close)

ProfilesMenu := Menu()
; ProfilesMenu is managed by Profiles.ahk.

OptionsMenu := Menu()
; OptionsMenu is managed by Options.ahk.

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

AutoclickerGui.AddDropDownList("xs+10 yp+20 w85 vGeneral_ClickCount_DropDownList AltSubmit Choose1", [
    "Single click",
    "Double click",
    "Triple click",
    "No click"
])

AutoclickerGui.AddText("xp+95 yp+4", "Hold for:")
AutoclickerGui.AddEdit("xp+45 yp-4 w50 vGeneral_ClickHoldDownDuration_NumEdit Limit Number", "0")
AutoclickerGui.AddText("xp+54 yp+4", "ms")

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

AutoclickerGui.AddListView("w226 h115 vPositioning_TargetList_ListView -LV0x10 NoSortHdr"
    , ["#", "Type", "Coordinates"])
    .OnEvent("ItemSelect", Positioning_ItemSelectionChanged)
AutoclickerGui["Positioning_TargetList_ListView"].OnEvent("DoubleClick", Positioning_EditTarget)
AutoclickerGui["Positioning_TargetList_ListView"].ModifyCol(1, 25)
AutoclickerGui["Positioning_TargetList_ListView"].ModifyCol(2, 40)
AutoclickerGui["Positioning_TargetList_ListView"].ModifyCol(3, 157)

AutoclickerGui.AddButton("xm+10 yp+122 w72 vPositioning_AddTarget_Button", "&Add")
    .OnEvent("Click", Positioning_AddTarget)
AutoclickerGui.AddButton("yp wp vPositioning_RemoveTarget_Button Disabled", "&Remove")
    .OnEvent("Click", Positioning_RemoveTarget)
AutoclickerGui.AddButton("yp wp vPositioning_ClearAllTargets_Button", "&Clear All")
    .OnEvent("Click", Positioning_ClearAllTargets)

AutoclickerGui.AddButton("xm+10 yp+30 w72 vPositioning_EditTarget_Button Disabled", "&Edit")
    .OnEvent("Click", Positioning_EditTarget)
AutoclickerGui.AddButton("yp wp vPositioning_MoveTargetUp_Button Disabled", "Move &Up")
    .OnEvent("Click", (*) => Positioning_transposeTargets(-1))
AutoclickerGui.AddButton("yp wp vPositioning_MoveTargetDown_Button Disabled", "Move &Down")
    .OnEvent("Click", (*) => Positioning_transposeTargets(1))

AutoclickerGui["Tab"].UseTab(SZ_TABLE.Tabs.Hotkeys)

AutoclickerGui.AddListView("w226 h145 vHotkeys_HotkeyList_ListView -LV0x10 NoSortHdr"
    , ["Action", "Scope", "Hotkey"])
    .OnEvent("ItemSelect", Hotkeys_ItemSelectionChanged)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(1, 50)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(2, 42)
AutoclickerGui["Hotkeys_HotkeyList_ListView"].ModifyCol(3, 130)

AutoclickerGui.AddButton("xm+10 yp+152 w72 vHotkeys_AddHotkey_Button", "&Add")
    .OnEvent("Click", Hotkeys_AddHotkey)
AutoclickerGui.AddButton("yp wp vHotkeys_RemoveHotkey_Button Disabled", "&Remove")
    .OnEvent("Click", Hotkeys_RemoveHotkey)
AutoclickerGui.AddButton("yp wp vHotkeys_ClearAllHotkeys_Button", "&Clear All")
    .OnEvent("Click", Hotkeys_ClearAllHotkeys)

AutoclickerGui["Tab"].UseTab()

AutoclickerGui.AddText("xm ym vSimplifiedViewHeaderText Hidden"
    , "Select a profile:"
    "`n`n(No profiles are currently defined."
    "`nPlease leave Simplified View and create a profile.)")
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
    local isRange := AutoclickerGui["General_ClickIntervalMode_Radio"].Value == 0
    AutoclickerGui["General_ClickIntervalRange_Text"].Visible := isRange
    AutoclickerGui["General_ClickIntervalUpper_NumEdit"].Visible := isRange
    AutoclickerGui["General_ClickIntervalUpper_UnitText"].Visible := isRange
}

Scheduling_updateStopAfter() {
    local activeCount := 0
    for criterionName in ["NumClicks", "Duration", "Time"] {
        if AutoclickerGui["Scheduling_StopAfter" criterionName "_Checkbox"].Value != 0 {
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

Positioning_formatTargetCoords(targetData) {
    switch targetData.Type {
    case "Point":
        return targetData.X ", " targetData.Y
    case "Box":
        return targetData.XMin ", " targetData.YMin
            . " -- " targetData.XMax ", " targetData.YMax
    }
}

Positioning_updateTargetsList(*) {
    AutoclickerGui["Positioning_TargetList_ListView"].Delete()

    local cumulativeApplicableClickCount := 1
    for targetData in configured_targets {
        AutoclickerGui["Positioning_TargetList_ListView"].Add(
            , cumulativeApplicableClickCount
            , targetData.Type
            , Positioning_formatTargetCoords(targetData)
            . (targetData.RelativeTo == "Screen" ? " (ABS)" : " (REL)")
        )
        cumulativeApplicableClickCount += targetData.ApplicableClickCount
    }
}

Positioning_ItemSelectionChanged(*) {
    local selectedNum := AutoclickerGui["Positioning_TargetList_ListView"].GetNext()

    ; "Edit" button should be enabled only if exactly one target is selected.
    AutoclickerGui["Positioning_EditTarget_Button"].Enabled := selectedNum
        && AutoclickerGui["Positioning_TargetList_ListView"].GetNext(selectedNum) == 0

    AutoclickerGui["Positioning_MoveTargetUp_Button"].Enabled := selectedNum
    AutoclickerGui["Positioning_MoveTargetDown_Button"].Enabled := selectedNum
    AutoclickerGui["Positioning_RemoveTarget_Button"].Enabled := selectedNum
}

Positioning_prepareTargetEditor(submitCallback) {
    ; Make it a static variable to prevent capturing by Submit().
    static currentSubmitCallback
    currentSubmitCallback := submitCallback

    static TargetEditorGui
    static PerTypeCoordControls
    if !IsSet(TargetEditorGui) {
        TargetEditorGui := Gui("-SysMenu +Owner" AutoclickerGui.Hwnd, "Add Target")

        TargetEditorGui.OnEvent("Escape", hideOwnedGui)
        TargetEditorGui.OnEvent("Close", hideOwnedGui)

        TargetEditorGui.AddText("ym+2", "Applies for:")
        TargetEditorGui.AddEdit("xp+56 yp-2 w45 vTargetApplicableClickCountEdit Limit Number", "1")
        TargetEditorGui.AddText("xp+48 yp+2", "contiguous click(s)")

        TargetEditorGui.AddText("xm yp+24", "Delay every click for:")
        TargetEditorGui.AddEdit("xp+98 yp-2 w45 vTargetDelayEdit Limit Number", "0")
        TargetEditorGui.AddText("xp+48 yp+2", "ms")

        TargetEditorGui.AddGroupBox("xm w226 h110 Section", "Coordinates")
        TargetEditorGui.AddRadio("xs+10 yp+20 vTargetTypePointRadio", SZ_TABLE.Positioning_TargetType.Point)
            .OnEvent("Click", TargetTypeSelectionChanged)
        TargetEditorGui.AddRadio("yp vTargetTypeBoxRadio", SZ_TABLE.Positioning_TargetType.Box)
            .OnEvent("Click", TargetTypeSelectionChanged)

        PerTypeCoordControls := {
            TargetTypePointRadio: [
                TargetEditorGui.AddText("xs+10 ys+50 Hidden", "X:"),
                TargetEditorGui.AddEdit("xp+20 yp-2 w30 vTargetXPosNumEdit Limit Number Hidden", "0"),
                TargetEditorGui.AddText("xp+45 yp+2 Hidden", "Y:"),
                TargetEditorGui.AddEdit("xp+20 yp-2 w30 vTargetYPosNumEdit Limit Number Hidden", "0")
            ],
            TargetTypeBoxRadio: [
                TargetEditorGui.AddText("xs+10 ys+50 Hidden", "X min:"),
                TargetEditorGui.AddEdit("xp+34 yp-2 w30 vTargetXMinPosNumEdit Limit Number Hidden", "0"),
                TargetEditorGui.AddText("xp+45 yp+2 Hidden", "Y min:"),
                TargetEditorGui.AddEdit("xp+35 yp-2 w30 vTargetYMinPosNumEdit Limit Number Hidden", "0"),
                TargetEditorGui.AddText("xs+10 yp+30 Hidden", "X max:"),
                TargetEditorGui.AddEdit("xp+34 yp-2 w30 vTargetXMaxPosNumEdit Limit Number Hidden", "0"),
                TargetEditorGui.AddText("xp+45 yp+2 Hidden", "Y max:"),
                TargetEditorGui.AddEdit("xp+35 yp-2 w30 vTargetYMaxPosNumEdit Limit Number Hidden", "0")
            ]
        }

        TargetEditorGui.AddGroupBox("xs yp+40 w145 h59 Section", "Position relative to")
        TargetEditorGui.AddRadio("xs+10 yp+20 vTargetRelativeToScreenRadio", "Entire &screen (ABS)")
            .OnEvent("Click", TargetRelativeToSelectionChanged)
        TargetEditorGui.AddRadio("xp vTargetRelativeToFocusedRadio", "Focused &window (REL)")
            .OnEvent("Click", TargetRelativeToSelectionChanged)

        TargetEditorGui.AddButton("ys+6 w80 Default", "OK")
            .OnEvent("Click", Submit)
        TargetEditorGui.AddButton("xp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(TargetEditorGui))

        TargetEditorGui.AddStatusBar("vStatusBar")
        TargetEditorGui["StatusBar"].SetParts(40)
        TargetEditorGui["StatusBar"].SetText(" (ABS)")
        TargetEditorGui["StatusBar"].SetText("X=? Y=?", 2, 2)

        add_log("Created target adder GUI")

        TargetTypeSelectionChanged(TargetEditorGui["TargetTypePointRadio"])
    }

    SetTimer updateTargetAdderGuiStatusBar, 100

    updateTargetAdderGuiStatusBar() {
        CoordMode "Mouse", TargetEditorGui["TargetRelativeToScreenRadio"].Value != 0 ? "Screen" : "Client"
        local mouseX, mouseY
        MouseGetPos &mouseX, &mouseY
        TargetEditorGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 2, 2)
        if !ControlGetVisible(TargetEditorGui.Hwnd, "ahk_id " TargetEditorGui.Hwnd)
            SetTimer , 0 ; mark timer for deletion
    }

    TargetTypeSelectionChanged(radio, *) {
        for key, list in PerTypeCoordControls.OwnProps() {
            for ctrl in list
                ctrl.Visible := key == radio.Name
        }
    }

    TargetRelativeToSelectionChanged(radio, *) {
        TargetEditorGui["StatusBar"].SetText(radio.Name == "TargetRelativeToScreenRadio" ? " (ABS)" : " (REL)")
    }

    updateState() {
        TargetTypeSelectionChanged(TargetEditorGui["TargetTypePointRadio"].Value != 0
            ? TargetEditorGui["TargetTypePointRadio"]
            : TargetEditorGui["TargetTypeBoxRadio"])

        TargetRelativeToSelectionChanged(TargetEditorGui["TargetRelativeToScreenRadio"].Value != 0
            ? TargetEditorGui["TargetRelativeToScreenRadio"]
            : TargetEditorGui["TargetRelativeToFocusedRadio"])
    }

    Submit(*) {
        hideOwnedGui(TargetEditorGui)

        local targetData := {
            ApplicableClickCount: TargetEditorGui["TargetApplicableClickCountEdit"].Value,
            Delay: TargetEditorGui["TargetDelayEdit"].Value,
            Type: TargetEditorGui["TargetTypePointRadio"].Value != 0 ? "Point" : "Box",
            RelativeTo: TargetEditorGui["TargetRelativeToScreenRadio"].Value != 0 ? "Screen" : "Client"
        }
        if TargetEditorGui["TargetTypePointRadio"].Value != 0 {
            targetData.X := Number(TargetEditorGui["TargetXPosNumEdit"].Value)
            targetData.Y := Number(TargetEditorGui["TargetYPosNumEdit"].Value)
        } else {
            targetData.XMin := Number(TargetEditorGui["TargetXMinPosNumEdit"].Value)
            targetData.YMin := Number(TargetEditorGui["TargetYMinPosNumEdit"].Value)
            targetData.XMax := Number(TargetEditorGui["TargetXMaxPosNumEdit"].Value)
            targetData.YMax := Number(TargetEditorGui["TargetYMaxPosNumEdit"].Value)
        }

        currentSubmitCallback(targetData)
    }

    return [TargetEditorGui, updateState]
}

Positioning_AddTarget(*) {
    local ret := Positioning_prepareTargetEditor(Submit)
    local TargetEditorGui := ret[1]
    local updateState := ret[2]

    TargetEditorGui["TargetApplicableClickCountEdit"].Value := 1
    TargetEditorGui["TargetDelayEdit"].Value := 0
    TargetEditorGui["TargetTypePointRadio"].Value := 1
    TargetEditorGui["TargetTypeBoxRadio"].Value := 0
    TargetEditorGui["TargetXPosNumEdit"].Value := 0
    TargetEditorGui["TargetYPosNumEdit"].Value := 0
    TargetEditorGui["TargetXMinPosNumEdit"].Value := 0
    TargetEditorGui["TargetYMinPosNumEdit"].Value := 0
    TargetEditorGui["TargetXMaxPosNumEdit"].Value := 0
    TargetEditorGui["TargetYMaxPosNumEdit"].Value := 0
    TargetEditorGui["TargetRelativeToScreenRadio"].Value := 1
    TargetEditorGui["TargetRelativeToFocusedRadio"].Value := 0

    updateState()
    showGuiAtAutoclickerGuiPos(TargetEditorGui)

    Submit(targetData) {
        configured_targets.Push(targetData)

        Positioning_updateTargetsList()
        Positioning_ItemSelectionChanged()
    }
}

Positioning_EditTarget(*) {
    local ret := Positioning_prepareTargetEditor(Submit)
    local TargetEditorGui := ret[1]
    local updateState := ret[2]

    ; targetIdx is declared static to prevent capturing by Submit().
    static targetIdx
    targetIdx := AutoclickerGui["Positioning_TargetList_ListView"].GetNext()
    if targetIdx < 1
        return

    local targetData := configured_targets[targetIdx]
    TargetEditorGui["TargetApplicableClickCountEdit"].Value := targetData.ApplicableClickCount
    TargetEditorGui["TargetDelayEdit"].Value := 0
    switch targetData.Type {
    case "Point":
        TargetEditorGui["TargetTypePointRadio"].Value := 1
        TargetEditorGui["TargetTypeBoxRadio"].Value := 0
        TargetEditorGui["TargetXPosNumEdit"].Value := targetData.X
        TargetEditorGui["TargetYPosNumEdit"].Value := targetData.Y
        TargetEditorGui["TargetXMinPosNumEdit"].Value := 0
        TargetEditorGui["TargetYMinPosNumEdit"].Value := 0
        TargetEditorGui["TargetXMaxPosNumEdit"].Value := 0
        TargetEditorGui["TargetYMaxPosNumEdit"].Value := 0
    case "Box":
        TargetEditorGui["TargetTypePointRadio"].Value := 0
        TargetEditorGui["TargetTypeBoxRadio"].Value := 1
        TargetEditorGui["TargetXPosNumEdit"].Value := 0
        TargetEditorGui["TargetYPosNumEdit"].Value := 0
        TargetEditorGui["TargetXMinPosNumEdit"].Value := targetData.XMin
        TargetEditorGui["TargetYMinPosNumEdit"].Value := targetData.YMin
        TargetEditorGui["TargetXMaxPosNumEdit"].Value := targetData.XMax
        TargetEditorGui["TargetYMaxPosNumEdit"].Value := targetData.YMax
    }
    TargetEditorGui["TargetRelativeToScreenRadio"].Value := targetData.RelativeTo == "Screen"
    TargetEditorGui["TargetRelativeToFocusedRadio"].Value := targetData.RelativeTo == "Client"

    updateState()
    showGuiAtAutoclickerGuiPos(TargetEditorGui)

    Submit(targetData) {
        configured_targets[targetIdx] := targetData

        Positioning_updateTargetsList()
        AutoclickerGui["Positioning_TargetList_ListView"].Modify(targetIdx, "+Select")
        Positioning_ItemSelectionChanged()
    }
}

Positioning_transposeTargets(offset) {
    add_log "Transposing targets by offset " offset

    local rowNumsToReselect := []
    local rowNum := 0
    Loop {
        rowNum := AutoclickerGui["Positioning_TargetList_ListView"].GetNext(rowNum)
        if !rowNum
            break

        local neighborNum := rowNum + offset
        if neighborNum < 1 || neighborNum > configured_targets.Length {
            rowNumsToReselect.Push(rowNum)
            continue
        }

        local neighborTarget := configured_targets[neighborNum]
        configured_targets[neighborNum] := configured_targets[rowNum]
        configured_targets[rowNum] := neighborTarget

        rowNumsToReselect.Push(neighborNum)
    }

    Positioning_updateTargetsList()

    for num in rowNumsToReselect
        AutoclickerGui["Positioning_TargetList_ListView"].Modify(num, "+Select")

    AutoclickerGui["Positioning_EditTarget_Button"].Enabled := rowNumsToReselect.Length = 1
}

Positioning_RemoveTarget(*) {
    add_log "Removing targets"

    local nRemoved := 0
    local rowNum := 0
    Loop {
        rowNum := AutoclickerGui["Positioning_TargetList_ListView"].GetNext(rowNum)
        if !rowNum
            break

        configured_targets.RemoveAt(rowNum - nRemoved++)
    }

    Positioning_updateTargetsList()
    Positioning_ItemSelectionChanged()
}

Positioning_ClearAllTargets(*) {
    configured_targets.Length := 0
    Positioning_updateTargetsList()
    Positioning_ItemSelectionChanged()
}

Hotkeys_updateHotkeyBindings() {
    AutoclickerGui["Hotkeys_HotkeyList_ListView"].Delete()

    for hotkeyData in configured_hotkeys {
        AutoclickerGui["Hotkeys_HotkeyList_ListView"].Add(
            , hotkeyData.Action
            , hotkeyData.Scope
            , formatHotkeyText(hotkeyData.Hotkey)
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

            if hotkeyData.Scope == "Global" && !WinActive("ahk_id " AutoclickerGui.Hwnd)
                return
    
            switch hotkeyData.Action {
            case "Start":
                if !is_autoclicking
                    Start()
            case "Stop":
                if is_autoclicking
                    Stop()
            case "Toggle":
                if is_autoclicking
                    Stop()
                else
                    Start()
            case "Close":
                ExitApp
            }
        }
    }
}

Hotkeys_ItemSelectionChanged(*) {
    AutoclickerGui["Hotkeys_RemoveHotkey_Button"].Enabled
        := AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetNext() != 0
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
                    "The hotkey '" formatHotkeyText(hotkeyData.Hotkey) "' is already in use."
                    . " Would you like to overwrite it?"
                    , "Overwrite Hotkey"
                    , "YesNo Iconi 8192 Owner" AutoclickerGui.Hwnd
                ) = "Yes"
                    configured_hotkeys.RemoveAt(A_Index)
                else
                    return
                break
            }
        }

        configured_hotkeys.Push {
            Hotkey: "~" KeyBinderGui["Hotkey"].Value,
            Scope: ["Global", "Local"][KeyBinderGui["HotkeyScopeDropDownList"].Value],
            Action: KeyBinderGui["HotkeyActionStartRadio"].Value = 1 ? "Start"
                : KeyBinderGui["HotkeyActionStopRadio"].Value = 1 ? "Stop"
                : KeyBinderGui["HotkeyActionToggleRadio"].Value = 1 ? "Toggle"
                : "Close"
        }
        add_log("Added hotkey: " formatHotkeyText(KeyBinderGui["Hotkey"].Value))
        Hotkeys_updateHotkeyBindings()
        Hotkeys_ItemSelectionChanged()
    }
}

Hotkeys_RemoveHotkey(*) {
    add_log "Starting hotkeys removal"
    local rowNum := 0
    local nRemoved := 0
    Loop {
        rowNum := AutoclickerGui["Hotkeys_HotkeyList_ListView"].GetNext(rowNum)
        if !rowNum
            break
        add_log("Removing hotkey: " formatHotkeyText(configured_hotkeys[rowNum - nRemoved].Hotkey))
        Hotkey configured_hotkeys[rowNum - nRemoved].Hotkey, "Off"
        configured_hotkeys.RemoveAt(rowNum - nRemoved++)
    }

    Hotkeys_updateHotkeyBindings()
    Hotkeys_ItemSelectionChanged()
}

Hotkeys_ClearAllHotkeys(*) {
    for hotkeyData in configured_hotkeys {
        Hotkey hotkeyData.Hotkey, "Off"
        add_log("Removed hotkey: " formatHotkeyText(hotkeyData.Hotkey))
    }
    configured_hotkeys.Length := 0
    Hotkeys_updateHotkeyBindings()
    Hotkeys_ItemSelectionChanged()
}
