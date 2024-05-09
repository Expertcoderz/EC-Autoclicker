; Miscellaneous utility functions (may be dependent on AutoclickerGui)

showGuiAtAutoclickerGuiPos(gui) {
    local posX, posY
    AutoclickerGui.GetPos(&posX, &posY)
    gui.Opt((is_always_on_top_on ? "+" : "-") "AlwaysOnTop")
    gui.Show("x" posX " y" posY)
}

hideOwnedGui(gui, *) {
    gui.Hide()
    AutoclickerGui.Opt("-Disabled")
    WinActivate "ahk_id " AutoclickerGui.Hwnd
}

formatHotkeyText(hotkey) {
    for k, v in Map("~", "", "^", "{ctrl}", "!", "{alt}", "+", "{shift}")
        hotkey := StrReplace(hotkey, k, v)
    return hotkey
}
