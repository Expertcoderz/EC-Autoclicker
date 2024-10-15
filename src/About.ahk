; "About" GUI

AboutOpen(*) {
    AutoclickerGui.Opt("+Disabled")

    static AboutGui
    if !IsSet(AboutGui) {
        AboutGui := Gui("-MinimizeBox +Owner" AutoclickerGui.Hwnd, "About EC Autoclicker")
        AboutGui.OnEvent("Escape", hideOwnedGui)
        AboutGui.OnEvent("Close", hideOwnedGui)

        AboutGui.AddPicture("w40 h40", A_IsCompiled ? A_ScriptFullPath : A_AhkPath)
        AboutGui.SetFont("s12 bold")
        AboutGui.AddText("xp+50 yp", "EC Autoclicker version "
            . (A_IsCompiled ? SubStr(FileGetVersion(A_ScriptFullPath), 1, -2) : "?"))
        AboutGui.SetFont()
        AboutGui.AddText("xp wp", "An open-source configurable autoclicking utility for Windows.")
        AboutGui.AddLink("xp", '<a href="https://github.com/' GITHUB_REPO '">https://github.com/'
            . GITHUB_REPO "</a>")

        add_log("Created About GUI")
    }

    showGuiAtAutoclickerGuiPos(AboutGui)
}
