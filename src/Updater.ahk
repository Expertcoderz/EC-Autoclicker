; Automatic updates checking and handling

CheckForUpdates(isManual) {
    if !DllCall("Wininet.dll\InternetGetConnectedState", "Str", "0x40", "Int", 0) {
        add_log("No internet connection; not checking for updates")
        if isManual
            MsgBox "
(
EC Autoclicker is unable to check for updates as there is currently no internet connection.
Please connect to the internet and try again.
)", "Update", "Icon! 262144"
        return
    }
    add_log("Checking for updates")

    local oHttp := ComObject("WinHttp.Winhttprequest.5.1")
    oHttp.open("GET", "https://api.github.com/repos/" GITHUB_REPO "/releases/latest")
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

    local thisVersion := SubStr(FileGetVersion(A_ScriptFullPath), 1, -2)
    if verNumMatch.1 = thisVersion {
        add_log("Current version is up to date with the latest release")
        RegWrite A_NowUTC, "REG_SZ", REG_KEY_PATH, "LastUpdateCheck"
        if isManual
            MsgBox "EC Autoclicker is up to date (" verNumMatch.1 ").", "Update", "Iconi 262144"
        return
    }

    if MsgBox(Format("
(
A newer version of EC Autoclicker ({}) is available.
Your current version is {}. Would you like to update now?
)", verNumMatch.1, thisVersion), "Update", "YesNo Icon? 262144"
    ) = "Yes" {
        local downloadFileTargetName := "EC-Autoclicker" (A_Is64bitOS ? "_x64" : "") ".exe"

        local downloadFileInitialPath
        Loop
            downloadFileInitialPath := A_ScriptDir "\" downloadFileTargetName ".new-" Random(100000, 9999999)
        Until !FileExist(downloadFileInitialPath)

        add_log("Downloading file")

        try
            Download "https://github.com/" GITHUB_REPO "/releases/latest/download/" downloadFileTargetName
                , downloadFileInitialPath
        catch as err
            MsgBox "An error occurred in attempting to download the latest version of EC Autoclicker."
                . "`n`nMessage: " err.Message
                , "Update"
                , "Iconx 262144"
        else {
            add_log("File downloaded")
            Run "powershell.exe -WindowStyle Hidden -Command Start-Sleep -Seconds 1;"
                . "Remove-Item -LiteralPath '" A_ScriptFullPath "';"
                . "Rename-Item -LiteralPath '" downloadFileInitialPath "' -NewName '" downloadFileTargetName "';"
                . "Start-Process -FilePath '" A_ScriptDir "\" downloadFileTargetName "' -ArgumentList '/updated'"
                , , "Hide"
            ExitApp
        }
    }
}

if A_IsCompiled {
    if A_Args.Length > 0 && A_Args[1] = "/updated" {
        RegWrite A_NowUTC, "REG_SZ", REG_KEY_PATH, "LastUpdateCheck"
        MsgBox "EC Autoclicker has been updated successfully.`nNew version: " SubStr(FileGetVersion(A_ScriptFullPath), 1, -2)
            , "Update", "Iconi 262144"
    } else if RegRead(REG_KEY_PATH, "AutoUpdate", true)
        && A_NowUTC - RegRead(REG_KEY_PATH, "LastUpdateCheck", 0) >= 604800
    {
        add_log("Automatically checking for newer version")
        CheckForUpdates(false)
    }
}
