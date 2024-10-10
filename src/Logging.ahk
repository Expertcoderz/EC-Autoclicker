; Logging functionality and GUI to view logs

logs := []

add_log(text) {
    OutputDebug text
    global logs
    logs.Push({ Timestamp: A_Now, Message: text })
    if logs.Length > 100
        logs.RemoveAt(1)
}

LogsOpen(*) {
    static LogsGui
    if !IsSet(LogsGui) {
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

        for entry in logs
            LogsGui["List"].Add(, FormatTime(entry.Timestamp, "HH:mm:ss"), entry.Message)

        LogsGui["List"].ModifyCol()
    }
}
