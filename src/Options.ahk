; Options menu handling

PersistentOptions := [
    {
        ValueName: "SimplifiedView",
        Default: false,
        Text: SZ_TABLE.Menu_Options_SimplifiedView,
        Toggler: toggleSimplifiedView
    },
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
        ValueName: "StartCollapsed",
        Default: false,
        Text: SZ_TABLE.Menu_Options_StartCollapsed,
        Toggler: (*) => 0
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

toggleSimplifiedView(optionInfo) {
    global is_simplified_view_on := optionInfo.CurrentSetting
    AutoclickerGui["Tab"].Visible := !is_simplified_view_on
    AutoclickerGui["SimplifiedViewHeaderText"].Visible := is_simplified_view_on
    AutoclickerGui["SimplifiedViewListBox"].Visible := is_simplified_view_on

    refreshProfileSelectionLists()
}

toggleAlwaysOnTop(optionInfo) {
    global is_always_on_top_on := optionInfo.CurrentSetting
    AutoclickerGui.Opt((is_always_on_top_on ? "+" : "-") "AlwaysOnTop")
}

toggleHotkeysActive(optionInfo) {
    global are_hotkeys_active := optionInfo.CurrentSetting
    Hotkeys_updateHotkeyBindings()
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

    OptionsMenu.ToggleCheck(optionText)
    optionInfo.Toggler()

    add_log((optionInfo.CurrentSetting ? "Enabled " : "Disabled ") optionInfo.ValueName)
}

ResetOptionsToDefault(*) {
    add_log("Resetting all options to default")

    Loop Reg REG_KEY_PATH {
        if A_LoopRegName != "LastUpdateCheck"
            RegDelete
    }

    for optionInfo in PersistentOptions {
        if optionInfo.CurrentSetting != optionInfo.Default {
            optionInfo.CurrentSetting := optionInfo.Default
            optionInfo.Toggler()
        }
        if optionInfo.CurrentSetting
            OptionsMenu.Check(optionInfo.Text)
        else
            OptionsMenu.Uncheck(optionInfo.Text)
    }
}

setupOptionsMenu() {
    for optionInfo in PersistentOptions {
        OptionsMenu.Add(optionInfo.Text, OptionsMenuItemCallbackWrapper)

        optionInfo.CurrentSetting := RegRead(REG_KEY_PATH, optionInfo.ValueName, optionInfo.Default)

        if optionInfo.CurrentSetting != optionInfo.Default
            optionInfo.Toggler()
        if optionInfo.CurrentSetting
            OptionsMenu.Check(optionInfo.Text)
    }

    OptionsMenu.Add()
    OptionsMenu.Add(SZ_TABLE.Menu_Options_ResetToDefault, ResetOptionsToDefault)
}

setupOptionsMenu()
