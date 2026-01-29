; Miscellaneous utility functions (may be dependent on AutoclickerGui)

showGuiAtAutoclickerGuiPos(gui) {
    local posX, posY
    AutoclickerGui.GetPos(&posX, &posY)

    AutoclickerGui.Opt("+Disabled")
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

; Converts { key1: "value1", key2: "value2" } => '"key1=value1","key2=value2"'
; Note: Property names MUST NOT contain double quotes.
serializeObject(obj) {
    local str := ""
    for name, value in obj.OwnProps()
        str .= '"' name "=" StrReplace(value, '"', '""') '",'
    return SubStr(str, 1, -1)
}

; Converts '"key1=value1","key2=value2"' => { key1: "value1", key2: "value2" }
; Keys not found in the template are ignored.
; Keys in the template but missing from the string are set to
; their corresponding value in the template.
deserializeObject(str, template) {
    local obj := {}

    Loop Parse str, "CSV" {
        local parts := StrSplit(A_LoopField, "=", , 2)
        if parts.Length != 2
            throw ValueError("Invalid field #" A_Index " in object string: " str)

        if template.HasProp(parts[1])
            obj.%parts[1]% := parts[2]
    }

    for name, value in template.OwnProps() {
        if !obj.HasProp(name)
            obj.%name% := value
    }

    return obj
}
