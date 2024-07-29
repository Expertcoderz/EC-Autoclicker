; Main autoclicking routines

Start(*) {
    AutoclickerGui["Tab"].Enabled := false
    AutoclickerGui["StartButton"].Enabled := false
    AutoclickerGui["StopButton"].Enabled := true
    AutoclickerGui["StopButton"].Focus()

    if is_simplified_view_on
        ProfileLoad(AutoclickerGui["SimplifiedViewListBox"].Text)

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
    add_log("Starting autoclicking")

    if currentConfig.Scheduling_PreStartDelay_Checkbox
        Sleep currentConfig.Scheduling_PreStartDelay_NumEdit

    while is_autoclicking {
        if currentConfig.General_SoundBeep_Checkbox
            SoundBeep currentConfig.General_SoundBeep_NumEdit

        local coords
        switch currentConfig.Positioning_BoundaryMode_Radio {
            case 1: coords := ""
            case 2: coords := currentConfig.Positioning_XPos_NumEdit " " currentConfig.Positioning_YPos_NumEdit
            case 3:
                coords := Random(currentConfig.Positioning_XMinPos_NumEdit, currentConfig.Positioning_XMaxPos_NumEdit)
                    . " " Random(currentConfig.Positioning_YMinPos_NumEdit, currentConfig.Positioning_YMaxPos_NumEdit)
        }

        if currentConfig.General_ClickHoldDownDuration_NumEdit {
            Click coords, buttonClickData, "Down"
            Sleep currentConfig.General_ClickHoldDownDuration_NumEdit
            Click "Up"
        } else
            Click coords, buttonClickData

        AutoclickerGui["StatusBar"].SetText(" Clicks: " (++clickCount))
        AutoclickerGui["StatusBar"].SetText("Elapsed: " Round((A_TickCount - timeStarted) / 1000, 2), 2)

        local mouseX, mouseY
        MouseGetPos &mouseX, &mouseY
        AutoclickerGui["StatusBar"].SetText(Format("X={} Y={}", mouseX, mouseY), 3, 2)

        if stopCriteria.Length > 0 {
            local passedCriteria := 0
            for check in stopCriteria {
                if !check()
                    continue

                passedCriteria += 1
                if currentConfig.Scheduling_StopAfterMode_DropDownList = 2
                    && passedCriteria < stopCriteria.Length
                    continue

                add_log("Stopping automatically")
                Stop()
                switch currentConfig.Scheduling_PostStopAction_DropDownList {
                    case 2: ExitApp
                    case 3:
                        if WinExist("A")
                            WinClose
                    case 4: Shutdown 0
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
    ExitApp
}
