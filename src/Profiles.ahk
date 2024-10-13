; Profiles handling backend and UI

validateProfileNameInput(profileName) {
    if RegExReplace(profileName, "\s") = "" ; blank input
        return false

    if profileName ~= "[\\/:\*\?`"<>\|]" {
        MsgBox "A profile name can't contain any of the following characters:`n\ / : * ? `" < > |"
            , "Create/Update Profile"
            , "Iconx 8192"
        return false
    }

    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        if A_LoopRegName = profileName {
            if MsgBox(
                "A profile similarly named '" A_LoopRegName "' already exists. Would you like to overwrite it?"
                , "Overwrite Profile"
                , "YesNo Iconi 8192"
            ) = "Yes" {
                RegDeleteKey A_LoopRegKey "\" A_LoopRegName
                return true
            } else
                return false
        }
    }

    return true
}

assertProfileExists(profileName) {
    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        if A_LoopRegName = profileName
            return true
    }
    MsgBox "The profile '" profileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
    return false
}

refreshProfileSelectionLists() {
    ProfilesMenu.Delete()
    ProfilesMenu.Add(SZ_TABLE.Menu_Profiles_Create, ProfileCreate)
    ProfilesMenu.Add(SZ_TABLE.Menu_Profiles_Manage, ProfileManage)
    ProfilesMenu.Add()

    if is_simplified_view_on
        ProfilesMenu.Disable(SZ_TABLE.Menu_Profiles_Create)
    else
        ProfilesMenu.Enable(SZ_TABLE.Menu_Profiles_Create)

    AutoclickerGui["SimplifiedViewListBox"].Delete()

    local numProfiles := 0
    Loop Reg REG_KEY_PATH "\Profiles", "K" {
        numProfiles++
        ProfilesMenu.Add(A_LoopRegName, ProfileLoad)
        AutoclickerGui["SimplifiedViewListBox"].Add([A_LoopRegName])
    }

    if numProfiles < 1 {
        if is_simplified_view_on
            AutoclickerGui["StartButton"].Enabled := false
        else
            AutoclickerGui["StartButton"].Enabled := !is_autoclicking
    } else {
        AutoclickerGui["SimplifiedViewListBox"].Value := 1
        AutoclickerGui["StartButton"].Enabled := !is_autoclicking
    }

    add_log("Loaded " numProfiles " profile(s)")
}

ProfileLoad(profileName, *) {
    add_log("Loading profile '" profileName "'")

    if !assertProfileExists(profileName) {
        refreshProfileSelectionLists()
        return
    }

    try {
        Loop Reg REG_KEY_PATH "\Profiles\" profileName {
            local value := RegRead()

            switch A_LoopRegName {
            case "Targets":
                add_log("Update Targets")
                Positioning_ClearAllTargets()

                Loop Parse value, "`n" {
                    if !A_LoopField
                        continue

                    local targetDataMatch
                    RegExMatch A_LoopField, "^(?P<ApplicableClickCount>.+?)%(?P<Type>\d?)"
                        . "%(?P<Coords>.+?)%(?P<RelativeTo>\d)$", &targetDataMatch

                    local targetData := {
                        ApplicableClickCount: targetDataMatch["ApplicableClickCount"],
                        Type: targetDataMatch["Type"],
                        RelativeTo: targetDataMatch["RelativeTo"]
                    }

                    local coords := StrSplit(targetDataMatch["Coords"], ",")
                    switch targetDataMatch["Type"] {
                    case 1:
                        targetData.X := coords[1],
                        targetData.Y := coords[2]
                    case 2:
                        targetData.XMin := coords[1],
                        targetData.YMin := coords[2],
                        targetData.XMax := coords[3],
                        targetData.YMax := coords[4]
                    }

                    configured_targets.Push(targetData)
                }

                Positioning_updateTargetsList()
            case "Hotkeys":
                add_log("Update Hotkeys")
                Hotkeys_ClearAllHotkeys()

                Loop Parse value, "`n" {
                    if !A_LoopField
                        continue

                    local hotkeyDataMatch
                    RegExMatch A_LoopField, "^(?P<Hotkey>.+?)%(?P<Scope>\d)%(?P<Action>\d)$", &hotkeyDataMatch

                    configured_hotkeys.Push({
                        Hotkey: hotkeyDataMatch["Hotkey"],
                        HotkeyText: formatHotkeyText(hotkeyDataMatch["Hotkey"]),
                        Scope: hotkeyDataMatch["Scope"],
                        Action: hotkeyDataMatch["Action"]
                    })
                }

                Hotkeys_updateHotkeyBindings()
            default:
                add_log("Update: " A_LoopRegName " (value=" value ")")
                local ctrl := AutoclickerGui[A_LoopRegName]

                if ctrl.Type = "Radio" {
                    local radioInfo := RadioGroups.%A_LoopRegName%
                    radioInfo.Controls[value].Value := true
                    if radioInfo.Callback
                        radioInfo.Callback.Call(radioInfo.Controls[value])
                } else {
                    ctrl.Value := value
                    if ctrl.Type = "Checkbox" {
                        local checkableInfo := Checkables.%A_LoopRegName%
                        if checkableInfo.HasProp("Callback")
                            checkableInfo.Callback.Call(ctrl)
                    }
                }
            }
        }

        add_log("Completed profile load")
    } catch as err {
        add_log("Load Profile error: " err.Message)
        MsgBox Format("
(
An error occurred whilst loading the profile '{}'.
This is likely due to corrupt data.

Message: {}
)", profileName, err.Message), "Load Profile", "Iconx 8192"
    }
}

ProfileCreate(*) {
    static ProfileNamePromptGui
    if !IsSet(ProfileNamePromptGui) {
        ProfileNamePromptGui := Gui("-SysMenu +Owner" AutoclickerGui.Hwnd, "Create/Update Profile")
        ProfileNamePromptGui.OnEvent("Escape", hideOwnedGui)
        ProfileNamePromptGui.OnEvent("Close", hideOwnedGui)

        ProfileNamePromptGui.AddText(
            "w206 r2"
            , "The current autoclicker configuration will`nbe saved with the following profile name:"
        )
        ProfileNamePromptGui.AddEdit("wp vProfileNameEdit")

        ProfileNamePromptGui.AddButton("w100 Default", "OK")
            .OnEvent("Click", SubmitPrompt)
        ProfileNamePromptGui.AddButton("yp wp", "Cancel")
            .OnEvent("Click", (*) => hideOwnedGui(ProfileNamePromptGui))

        add_log("Created profile name prompt GUI")
    }

    ProfileNamePromptGui["ProfileNameEdit"].Value := ""
    ProfileNamePromptGui.Opt("-Disabled")
    AutoclickerGui.Opt("+Disabled")
    showGuiAtAutoclickerGuiPos(ProfileNamePromptGui)

    SubmitPrompt(*) {
        local profileName := ProfileNamePromptGui["ProfileNameEdit"].Value
        if !validateProfileNameInput(profileName)
            return

        add_log("Reading configuration data")

        local currentConfig := AutoclickerGui.Submit(false)

        RegCreateKey REG_KEY_PATH "\Profiles\" profileName

        for ctrlName, value in currentConfig.OwnProps() {
            if !InStr(ctrlName, "_")
                ; Ignore any controls (e.g. SimplifiedViewListBox) that lack
                ; underscores in their names since they are not part of the
                ; profile configuration.
                continue

            RegWrite value
                , ctrlName ~= "DateTime" ? "REG_SZ" : "REG_DWORD"
                , REG_KEY_PATH "\Profiles\" profileName
                , ctrlName
        }

        local serializedTargets := ""
        for targetData in configured_targets
            serializedTargets .= targetData.ApplicableClickCount "%" targetData.Type
                . "%" (targetData.Type = 1 ? targetData.X "," targetData.Y
                : targetData.XMin "," targetData.YMin "," targetData.XMax "," targetData.YMax)
                . "%" targetData.RelativeTo "`n"

        RegWrite serializedTargets
            , "REG_MULTI_SZ"
            , REG_KEY_PATH "\Profiles\" profileName
            , "Targets"

        local serializedHotkeys := ""
        for hotkeyData in configured_hotkeys
            serializedHotkeys .= hotkeyData.Hotkey "%" hotkeyData.Scope "%" hotkeyData.Action "`n"

        RegWrite serializedHotkeys
            , "REG_MULTI_SZ"
            , REG_KEY_PATH "\Profiles\" profileName
            , "Hotkeys"

        add_log("Wrote configuration data to registry")

        refreshProfileSelectionLists()
        hideOwnedGui(ProfileNamePromptGui)
    }
}

ProfileManage(*) {
    static ProfilesGui
    if !IsSet(ProfilesGui) {
        ProfilesGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "Autoclicker Profiles")
        ProfilesGui.OnEvent("Escape", hideOwnedGui)
        ProfilesGui.OnEvent("Close", hideOwnedGui)

        ProfilesGui.AddListView("w150 h162 vProfileList -Hdr -Multi +Sort", ["Profile Name"])
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

    refreshProfileList()
    showGuiAtAutoclickerGuiPos(ProfilesGui)

    refreshProfileList(selectProfileName := "") {
        ProfilesGui["ProfileList"].Delete()
        Loop Reg REG_KEY_PATH "\Profiles", "K"
            ProfilesGui["ProfileList"].Add(A_LoopRegName = selectProfileName ? "+Focus +Select" : "", A_LoopRegName)

        ProfileListSelectionChanged()
        refreshProfileSelectionLists()
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
                add_log("Deleted profile '" selectedProfileName "'")
                refreshProfileList()
                return
            }
        }
        MsgBox "The profile '" selectedProfileName "' does not exist or has already been deleted.", "Error", "Iconx 8192"
        refreshProfileList()
    }

    ProfileRename(*) {
        local selectedProfileName := ProfilesGui["ProfileList"].GetText(ProfilesGui["ProfileList"].GetNext())

        static ProfileRenamePromptGui
        if !IsSet(ProfileRenamePromptGui) {
            ProfileRenamePromptGui := Gui("-SysMenu +Owner" ProfilesGui.Hwnd, "Rename Profile")
            ProfileRenamePromptGui.OnEvent("Escape", CancelPrompt)
            ProfileRenamePromptGui.OnEvent("Close", CancelPrompt)

            ProfileRenamePromptGui.AddText("w206 vPromptText")
            ProfileRenamePromptGui.AddEdit("wp vProfileNameEdit")

            ProfileRenamePromptGui.AddButton("w100 Default", "OK")
                .OnEvent("Click", SubmitPrompt)
            ProfileRenamePromptGui.AddButton("yp wp", "Cancel")
                .OnEvent("Click", CancelPrompt)

            add_log("Created profile name prompt GUI")
        }

        ProfileRenamePromptGui["PromptText"].Text := "The profile '" selectedProfileName "' will be renamed to:"
        ProfileRenamePromptGui["ProfileNameEdit"].Value := ""
        ProfileRenamePromptGui.Opt("-Disabled")
        ProfilesGui.Opt("+Disabled")
        showGuiAtAutoclickerGuiPos(ProfileRenamePromptGui)

        SubmitPrompt(*) {
            local profileNewName := ProfileRenamePromptGui["ProfileNameEdit"].Value
            if !validateProfileNameInput(profileNewName)
                return

            ProfileRenamePromptGui.Opt("+Disabled")

            Loop Reg REG_KEY_PATH "\Profiles", "K" {
                if A_LoopRegName = selectedProfileName {
                    local newProfileRegPath := A_LoopRegKey "\" profileNewName
                    RegCreateKey newProfileRegPath

                    Loop Reg A_LoopRegKey "\" A_LoopRegName
                        RegWrite RegRead(), A_LoopRegType, newProfileRegPath, A_LoopRegName
                    add_log("Copied reg data to profile '" profileNewName "'")

                    RegDeleteKey
                    add_log("Deleted profile '" selectedProfileName "'")

                    ProfileRenamePromptGui.Hide()
                    ProfilesGui.Opt("-Disabled")
                    WinActivate "ahk_id " ProfilesGui.Hwnd
                    refreshProfileList(profileNewName)
                    return
                }
            }
            MsgBox "The profile '" selectedProfileName "' does not exist or has been deleted.", "Error", "Iconx 8192"
            ProfileRenamePromptGui.Opt("-Disabled")
            refreshProfileList()
        }

        CancelPrompt(*) {
            ProfileRenamePromptGui.Hide()
            ProfilesGui.Opt("-Disabled")
            WinActivate "ahk_id " ProfilesGui.Hwnd
        }
    }

    ProfileExport(*) {
        local selectedProfileName := ProfilesGui["ProfileList"].GetText(ProfilesGui["ProfileList"].GetNext())

        local fileLocation := FileSelect(
            "S16", A_WorkingDir "\" selectedProfileName FILE_EXT
            , "Export Autoclicker Profile"
            , "Autoclicker Profiles (*" FILE_EXT ")"
        )
        if !fileLocation {
            add_log("Export for profile '" selectedProfileName "' cancelled")
            return
        }

        add_log("Exporting profile '" selectedProfileName "'")

        local formatted := ""
        Loop Reg REG_KEY_PATH "\Profiles\" selectedProfileName {
            if A_LoopRegName = "Targets" || A_LoopRegName = "Hotkeys"
                formatted .= A_LoopRegName "=" StrReplace(RegRead(), "`n", "`t") "`n"
            else
                formatted .= A_LoopRegName "=" RegRead() "`n"
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
            , "Import Autoclicker Profile(s)", "Autoclicker Profiles (*" FILE_EXT ")"
        )
        for fileLocation in fileLocations {
            add_log("Importing profile from " fileLocation)

            local profileName
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

            try {
                Loop Parse FileRead(fileLocation), "`n" {
                    if !A_LoopField
                        continue

                    local configMatch
                    RegExMatch A_LoopField, "^(?P<Name>\w+?)=(?P<Value>.+)$", &configMatch
                    add_log("Read: " configMatch["Name"] " = " configMatch["Value"])

                    RegWrite (configMatch["Name"] = "Targets" || configMatch["Name"] = "Hotkeys"
                        ? StrReplace(configMatch["Value"], "`t", "`n") : configMatch["Value"])
                        , configMatch["Name"] ~= "DateTime" ? "REG_SZ" : "REG_DWORD"
                        , REG_KEY_PATH "\Profiles\" profileName
                        , configMatch["Name"]
                }
            } catch as err {
                add_log("Import Profile error: " err.Message)
                try RegDeleteKey REG_KEY_PATH "\Profiles\" profileName

                MsgBox Format("
(
An error occurred whilst importing the profile '{}' from {}.
This is usually due to the file's data being corrupt or invalid.

Message: {}
)", profileName, fileLocation, err.Message), "Import Profile", "Iconx 8192"
                return
            }

            refreshProfileList(profileName)
            add_log("Finished importing profile '" profileName "'")
        }
    }
}

refreshProfileSelectionLists()

RegCreateKey REG_KEY_PATH "\Profiles"

if A_Args.Length > 0 && A_Args[1] = "/profile" {
    add_log("Detected /profile switch")

    if A_Args.Length < 2 {
        MsgBox "A profile name must be specified.", "Error", "Iconx 262144"
        ExitApp
    }

    if !assertProfileExists(A_Args[2])
        ExitApp

    Collapse()
 
    ProfileLoad(A_Args[2])
    Start()
} else if RegRead(REG_KEY_PATH, "StartCollapsed", false)
    Collapse()
else
    AutoclickerGui.Show()
