# EC Autoclicker

The EC (Expertcoderz) Autoclicker is an open source, advanced GUI autoclicking utility for Windows, written fully in
[AutoHotkey](https://www.autohotkey.com/) v2. It aims to provide a large variety of configurability and functionality
never before seen in other popular autoclicking tools.

![image](https://user-images.githubusercontent.com/81153405/197328970-f0222c1d-2c1c-4de3-b224-79b9c817aee1.png)

Executables provided in Releases are compiled using [Ahk2Exe](https://github.com/AutoHotkey/Ahk2Exe),
with [UPX](https://upx.github.io/) for compression.

## Features

* Configurable click intervals (fixed or randomized)
* The ability to choose from whether to click the left/right/middle mouse button
* The ability to choose from performing single/double/triple clicks
* Definable pre-start delay
* Automatic stop after a specific number of clicks, when a specific duration has passed and/or at a specific time
* The ability to position the mouse cursor at a specific location every click or randomly within a specific boundary
* Profiles – saved and named sets of autoclicking configurations that can be created/renamed/deleted/exported and imported
* Persistent miscellaneous GUI settings
* Automatic update checking (optional)

## Upcoming Features

* Configurable start/stop hotkeys
* Mouse button hold-down
* "Simplified View" mode — only a list of profiles and the Start/Stop button are displayed
* Ability to select between different units (ms/s/min/h) for inputting duration values

## Getting Started

### Method 1: Compiled executable from Releases

(This is the most stable method and is recommended if you do not intend to modify EC Autoclicker's source.)

**Prerequisites:** None, as EC Autoclicker is a portable standalone application—no installation or external dependencies is required.

Download the executable file from the [latest release](https://github.com/Expertcoderz/EC-Autoclicker/releases/latest)
and run it to use EC Autoclicker.

*You may receive antivirus warnings when downloading/opening the EC Autoclicker executable because Expertcoderz
doesn't know how to get them [signed](https://en.wikipedia.org/wiki/Code_signing).*

### Method 2: Uncompiled AHK script (source)

**Prerequisites:** [AutoHotkey v2 Beta](https://www.autohotkey.com/download/ahk-v2.exe) must be installed.

**Note:** In its uncompiled script form, EC Autoclicker is unable to check for newer versions online
(neither automatically nor manually).

Download `EC-Autoclicker.ahk` from the [`main`](https://github.com/Expertcoderz/EC-Autoclicker/tree/main) branch
and run it with AHK v2 to use EC Autoclicker.

You will receive the latest (and possibly experimental) version of EC Autoclicker, regardless of whether or not it
is the same as the one published in Releases.

## Notes

* In order for automated clicks to have effect on windows belonging to elevated processes, EC Autoclicker must be
  run as administrator.
* The X and Y mouse position coordinates displayed at the bottom right corner respect the screen/window
  relativity configuration under the *Positioning* tab.
* Persistent settings/options are stored in the Windows Registry under `HKEY_CURRENT_USER\Software\Expertcoderz\Autoclicker`.
  Profiles are stored as keys under the `Autoclicker\Profiles` subkey.
* Automatic updates, if enabled, only take place up to once a week and happen after a confirmation prompt which is
  displayed when EC Autoclicker is launched (if there is an update available).

## Contributing

Contributions to EC Autoclicker in the form of bug fixes, enhancements, and even feature additions are welcome.

Before considering to open a pull request (PR), make sure that ***if it is meant to fix an issue,
that issue must already be [submitted](https://github.com/Expertcoderz/EC-Autoclicker/issues/new/choose)*** such
that it can be linked in your PR description.

Similarly, if it is meant to introduce an enhancement or new feature, it is strongly encouraged that you [open a
feature request](https://github.com/Expertcoderz/EC-Autoclicker/issues/new/choose) first before actually working
on the PR. This gives an opportunity for your idea to be maintainer-evaluated and to receive feedback that potentially
saves time in having to edit/rewrite your code.

Before submitting a PR, ensure that you include the following in its description:

1. A concise overview of the change(s) being made—whether it is a fix for a specific issue, an enhancement to the user
  interface or performance, or an introduction of a new feature.
2. An elaboration on the purpose and benefit(s) of the changes presented by the PR. If it is a fix for a UI bug,
   for example, give a "before and after" comparison of the relevant interface's behavior to show how the bug
   no longer appears under the same conditions that it did occur in.
3. A description of any tests that were used to make sure that the changes achieve what they are meant to, and
   that no unintended behavior or broken functionality is introduced.

Please **do not** submit a PR that:

* Comprises purely of code formatting changes; code refactoring, however, may be acceptable.
* Hasn't been tested successfully.
* Fixes multiple issues that aren't interrelated or owing to the same root cause; please instead submit multiple PRs per issue.
* Is missing any or all of the information in its PR description mentioned in the previous list.

## License

EC Autoclicker is licensed under the open source GNU GPL v3.0.
Any modified copies of EC Autoclicker must remain open source and under the same license.
