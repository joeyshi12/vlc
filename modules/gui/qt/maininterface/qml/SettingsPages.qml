/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Util
import VLC.Dialogs


// Pages of the settings dialog. Each row reads and writes one option of the
// VLC configuration (ConfigOption). Rows whose option does not exist in this
// build of VLC are hidden.
QtObject {
    id: pages

    // App

    component General : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Appearance")

            SettingsWidgets.Row {
                text: qsTr("Interface language")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "language" } }
            }

            SettingsWidgets.Row {
                text: qsTr("Theme")

                // Same order as the design: Light, Dark, System
                SettingsWidgets.Segmented {
                    readonly property var schemes: [ColorSchemeModel.Day, ColorSchemeModel.Night, ColorSchemeModel.System]
                    entries: [qsTr("Light"), qsTr("Dark"), qsTr("System")]
                    currentIndex: schemes.indexOf(MainCtx.colorScheme.scheme)
                    // The rows of the colour scheme model are System, Day, Night
                    onPicked: (index) => {
                        const row = [1, 2, 0][index]
                        MainCtx.colorScheme.setData(MainCtx.colorScheme.index(row, 0), true, Qt.CheckStateRole)
                    }
                }
            }

            SettingsWidgets.Row {
                text: qsTr("Accent color")
                info: qsTr("Used after VLC is started again")

                Rectangle {
                    readonly property ConfigOption option: ConfigOption { name: "qt-accent-color" }
                    readonly property var colors: ["#D37918", "#E15032", "#C49E23", "#19A234", "#18AAD3", "#185DD3", "#8E42FF", "#F052B3", "#AFAFAF"]
                    readonly property SettingsWidgets.Pal pal: SettingsWidgets.Pal { }

                    implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: pal.field

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                        spacing: VLCStyle.dp(4, VLCStyle.scale)

                        Repeater {
                            model: parent.parent.colors

                            delegate: MouseArea {
                                id: swatch

                                required property int index
                                required property string modelData

                                readonly property bool current: {
                                    const v = String(parent.parent.option.value).toUpperCase()
                                    return v === modelData || (index === 0 && v === "DEFAULT")
                                }

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: parent.parent.option.value = (index === 0) ? "default" : modelData

                                Accessible.role: Accessible.RadioButton
                                Accessible.name: modelData
                                Accessible.checked: current

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: VLCStyle.dp(32, VLCStyle.scale)
                                    height: width
                                    radius: VLCStyle.dp(4, VLCStyle.scale)
                                    color: swatch.current ? swatch.parent.parent.pal.accentDim(Qt.lighter(swatch.modelData, 1.0)) : "transparent"

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: VLCStyle.dp(20, VLCStyle.scale)
                                        height: width
                                        radius: VLCStyle.dp(1, VLCStyle.scale)
                                        color: swatch.modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Startup")

            SettingsWidgets.Row {
                text: qsTr("Show confirmation and error dialogs")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-error-dialogs" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Check for updates automatically")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-updates-notif" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Diagnostics")

            SettingsWidgets.Row {
                text: qsTr("Save a log")
                SettingsWidgets.Switch { option: ConfigOption { name: "file-logging" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Log file")
                SettingsWidgets.PathField { option: ConfigOption { name: "logfile" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Log details")
                SettingsWidgets.Dropdown {
                    option: ConfigOption { name: "log-verbose" }
                    entries: [{ value: -1, text: qsTr("Default") }, { value: 0, text: qsTr("Errors only") },
                              { value: 1, text: qsTr("Warnings") }, { value: 2, text: qsTr("Debug") }]
                }
            }
        }

        SettingsWidgets.AdvancedToggle { }

        SettingsWidgets.Section {
            title: qsTr("Advanced Options")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Log format")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "logmode" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Collect playback statistics")
                SettingsWidgets.Switch { option: ConfigOption { name: "stats" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Open configurations folder")
                SettingsWidgets.Button {
                    readonly property ConfigOption helper: ConfigOption { }
                    text: qsTr("Open"); onClicked: helper.openConfigDirectory()
                }
            }
            SettingsWidgets.Row {
                text: qsTr("All settings")
                SettingsWidgets.Button { text: qsTr("Open"); onClicked: DialogsProvider.prefsDialog() }
            }
            SettingsWidgets.Row {
                text: qsTr("Reset all settings")
                SettingsWidgets.Button {
                    readonly property ConfigOption helper: ConfigOption { }
                    text: qsTr("Reset")
                    onClicked: {
                        if (DialogsProvider.questionDialog(qsTr("Reset all settings to their default values?")))
                            helper.resetAll(MainCtx)
                    }
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Developer Options")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Write to the system log")
                SettingsWidgets.Switch { option: ConfigOption { name: "syslog" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Include debug messages in the system log")
                SettingsWidgets.Switch { option: ConfigOption { name: "syslog-debug" } }
            }
            SettingsWidgets.Row {
                text: qsTr("System log identity")
                SettingsWidgets.TextField { option: ConfigOption { name: "syslog-ident" } }
            }
            SettingsWidgets.Row {
                text: qsTr("System log facility")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "syslog-facility" } }
            }
        }
    }

    component Interface : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Skin")

            SettingsWidgets.Row {
                text: qsTr("Use a custom skin")
                available: skinOption.available
                SettingsWidgets.Switch {
                    readonly property ConfigOption intf: ConfigOption { name: "intf" }
                    bindOption: false
                    checked: String(intf.value) === "skins2"
                    onToggled: intf.value = checked ? "skins2" : ""
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Skin file")
                SettingsWidgets.PathField { option: ConfigOption { id: skinOption; name: "skins2-last" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Window")

            SettingsWidgets.Row {
                text: qsTr("Play video inside main window")
                SettingsWidgets.Switch { option: ConfigOption { name: "embedded-video" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Resize window to fit video")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-video-autoresize" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Keep window above other windows")
                SettingsWidgets.Switch { option: ConfigOption { name: "video-on-top" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show window decorations")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-titlebar" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show the file name in the title bar")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-name-in-title" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Playback Controls")

            SettingsWidgets.Row {
                text: qsTr("Start in compact mode")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-minimal-view" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Auto-hide the controls")
                SettingsWidgets.Switch {
                    option: ConfigOption { name: "qt-pin-controls" }
                    inverted: true
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Hide after")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "mouse-hide-timeout" }
                    from: 0; to: 10; stepSize: 0.5; factor: 1000
                    labels: [qsTr("0 s"), qsTr("5 s"), qsTr("10 s")]
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Show controls in fullscreen")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-fs-controller" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Notifications and System Tray")

            SettingsWidgets.Row {
                text: qsTr("Show a system tray icon")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-system-tray" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Start minimized to the tray")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-start-minimized" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show a popup when the track changes")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "qt-notification" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Playlist")

            SettingsWidgets.Row {
                text: qsTr("Show the playlist as a tree")
                SettingsWidgets.Switch { option: ConfigOption { name: "playlist-tree" } }
            }
        }

        SettingsWidgets.AdvancedToggle { }

        SettingsWidgets.Section {
            title: qsTr("Advanced Options")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Pause video when window is minimized")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-pause-minimized" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Bring VLC to the front when playback starts")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "qt-auto-raise" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show cover art in the window when playing audio")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-bgcone" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show the file browser inside the open dialog")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-embedded-open" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Allow the app icon to change")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-icon-change" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Fullscreen controls sensitivity")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "qt-fs-sensitivity" }
                    labels: [qsTr("Low"), qsTr("Medium"), qsTr("High")]
                }
            }
        }
    }

    component Privacy : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("History")

            SettingsWidgets.Row {
                text: qsTr("Save recently played items")
                SettingsWidgets.Switch { option: ConfigOption { name: "save-recentplay" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Remember the playback position")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "restore-playback-pos" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Network")

            SettingsWidgets.Row {
                text: qsTr("Fetch titles and cover art from the internet")
                SettingsWidgets.Switch { option: ConfigOption { name: "metadata-network-access" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Last.fm username")
                SettingsWidgets.TextField { option: ConfigOption { name: "lastfm-username" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Last.fm submission URL")
                SettingsWidgets.TextField { option: ConfigOption { name: "scrobbler-url" } }
            }
        }
    }

    component Controls : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Keyboard Shortcuts")

            SettingsWidgets.Row {
                text: qsTr("Edit Keyboard Shortcuts")
                SettingsWidgets.Button {
                    text: qsTr("Edit")
                    onClicked: shortcutsDialog.open()

                    ShortcutsDialog {
                        id: shortcutsDialog
                        parent: T.Overlay.overlay
                    }
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Skip Amounts")

            SettingsWidgets.Row {
                text: qsTr("Very short skip (s)")
                SettingsWidgets.TextField { option: ConfigOption { name: "extrashort-jump-size" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Short skip (s)")
                SettingsWidgets.TextField { option: ConfigOption { name: "short-jump-size" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Medium skip (s)")
                SettingsWidgets.TextField { option: ConfigOption { name: "medium-jump-size" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Long skip (s)")
                SettingsWidgets.TextField { option: ConfigOption { name: "long-jump-size" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Mouse")

            SettingsWidgets.Row {
                text: qsTr("Scroll wheel")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "hotkeys-y-wheel-mode" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Horizontal scroll")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "hotkeys-x-wheel-mode" } }
            }
        }
    }

    // Media

    component Playback : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Startup")

            SettingsWidgets.Row {
                text: qsTr("Continue where you left off")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "restore-playback-pos" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Start playing as soon as a file opens")
                SettingsWidgets.Switch { option: ConfigOption { name: "playlist-autostart" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Default playback speed")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "rate" }
                    from: 0.25; to: 2; stepSize: 0.25
                    labels: ["0.25", "0.5", "0.75", "1", "1.25", "1.5", "1.75", "2"]
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Tracks")

            SettingsWidgets.Row {
                text: qsTr("Preferred video quality")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "preferred-resolution" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Preferred menu language")
                SettingsWidgets.TextField { option: ConfigOption { name: "menu-language" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Default audio track")
                SettingsWidgets.TextField { option: ConfigOption { name: "audio-track" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Default subtitle track")
                SettingsWidgets.TextField { option: ConfigOption { name: "sub-track" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Order")

            SettingsWidgets.Row {
                text: qsTr("Repeat")
                SettingsWidgets.Dropdown {
                    readonly property ConfigOption loop: ConfigOption { name: "loop" }
                    readonly property ConfigOption repeat: ConfigOption { name: "repeat" }
                    entries: [{ value: 0, text: qsTr("Off") }, { value: 1, text: qsTr("Current item") }, { value: 2, text: qsTr("All") }]
                    selectedValue: repeat.value ? 1 : (loop.value ? 2 : 0)
                    onPicked: (v) => { repeat.value = (v === 1); loop.value = (v === 2) }
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Shuffle")
                SettingsWidgets.Switch { option: ConfigOption { name: "random" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Stop after each item")
                SettingsWidgets.Switch { option: ConfigOption { name: "play-and-stop" } }
            }
            SettingsWidgets.Row {
                text: qsTr("When playback finishes")
                SettingsWidgets.Dropdown {
                    readonly property ConfigOption pause: ConfigOption { name: "play-and-pause" }
                    readonly property ConfigOption exit: ConfigOption { name: "play-and-exit" }
                    entries: [{ value: 0, text: qsTr("Stop") }, { value: 1, text: qsTr("Pause on the last frame") }, { value: 2, text: qsTr("Quit") }]
                    selectedValue: exit.value ? 2 : (pause.value ? 1 : 0)
                    onPicked: (v) => { pause.value = (v === 1); exit.value = (v === 2) }
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Seeking")

            SettingsWidgets.Row {
                text: qsTr("Seek precisely")
                SettingsWidgets.Switch {
                    option: ConfigOption { name: "input-fast-seek" }
                    inverted: true
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Files & Discs")

            SettingsWidgets.Row {
                text: qsTr("Default optical drive")
                SettingsWidgets.PathField { option: ConfigOption { name: "dvd" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Repair damaged AVI files")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "avi-index" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Load matching .mkv files from the same folder")
                SettingsWidgets.Switch { option: ConfigOption { name: "mkv-preload-local-dir" } }
            }
        }

        SettingsWidgets.AdvancedToggle { }

        SettingsWidgets.Section {
            title: qsTr("Advanced Options")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Time-shift buffer folder")
                SettingsWidgets.PathField { option: ConfigOption { name: "input-timeshift-path" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Time-shift buffer size (bytes)")
                SettingsWidgets.TextField { option: ConfigOption { name: "input-timeshift-granularity" } }
            }
        }
    }

    component Video : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Output")

            SettingsWidgets.Row {
                text: qsTr("Enable video")
                SettingsWidgets.Switch { option: ConfigOption { name: "video" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Start videos in fullscreen")
                SettingsWidgets.Switch { option: ConfigOption { name: "fullscreen" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Stop the screensaver during playback")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "disable-screensaver" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Play video as desktop wallpaper")
                SettingsWidgets.Switch { option: ConfigOption { name: "video-wallpaper" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Deinterlacing")

            SettingsWidgets.Row {
                text: qsTr("Deinterlacing")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "deinterlace" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Method")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "deinterlace-mode" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Framing")

            SettingsWidgets.Row {
                text: qsTr("Aspect ratio")
                SettingsWidgets.TextField {
                    option: ConfigOption { name: "aspect-ratio" }
                    placeholderText: qsTr("Automatic")
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Crop")
                SettingsWidgets.TextField {
                    option: ConfigOption { name: "crop" }
                    placeholderText: qsTr("None")
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Scale video to the window")
                SettingsWidgets.Switch { option: ConfigOption { name: "autoscale" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Zoom")
                SettingsWidgets.TextField { option: ConfigOption { name: "zoom" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Position in the window")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "align" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Snapshots")

            SettingsWidgets.Row {
                text: qsTr("Save to")
                SettingsWidgets.PathField { option: ConfigOption { name: "snapshot-path" } }
            }
            SettingsWidgets.Row {
                text: qsTr("File name prefix")
                SettingsWidgets.TextField { option: ConfigOption { name: "snapshot-prefix" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Format")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "snapshot-format" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Number files sequentially")
                SettingsWidgets.Switch { option: ConfigOption { name: "snapshot-sequential" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show a preview after capture")
                SettingsWidgets.Switch { option: ConfigOption { name: "snapshot-preview" } }
            }
        }

        SettingsWidgets.AdvancedToggle { }

        SettingsWidgets.Section {
            title: qsTr("Advanced Options")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Video output")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "vout" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Drop frames that are late")
                SettingsWidgets.Switch { option: ConfigOption { name: "drop-late-frames" } }
            }
        }
    }

    component Audio : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Output")

            SettingsWidgets.Row {
                text: qsTr("Enable audio")
                SettingsWidgets.Switch { option: ConfigOption { name: "audio" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Output module")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "aout" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Speaker setup")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "stereo-mode" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Volume")

            SettingsWidgets.Row {
                text: qsTr("Maximum volume")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "qt-max-volume" }
                    stepSize: 5
                    labels: ["", "", ""]
                    Component.onCompleted: labels = [Math.round(from) + "%", Math.round((from + to) / 2) + "%", Math.round(to) + "%"]
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Remember the volume")
                SettingsWidgets.Switch { option: ConfigOption { name: "volume-save" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Volume step")
                SettingsWidgets.TextField { option: ConfigOption { name: "volume-step" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Loudness")

            SettingsWidgets.Row {
                text: qsTr("Normalize loudness")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "norm-max-level" }
                    module: "normvol"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Target level")
                SettingsWidgets.TextField { option: ConfigOption { name: "norm-max-level" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Replay gain")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "audio-replay-gain-mode" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Replay gain preamp")
                SettingsWidgets.TextField { option: ConfigOption { name: "audio-replay-gain-preamp" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Effects")

            SettingsWidgets.Row {
                text: qsTr("Equalizer")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "equalizer-preset" }
                    module: "equalizer"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Equalizer preset")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "equalizer-preset" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Two-pass")
                SettingsWidgets.Switch { option: ConfigOption { name: "equalizer-2pass" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Spatial audio")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "spatializer-roomsize" }
                    module: "spatializer"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Stereo widening")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "stereowiden-delay" }
                    module: "stereo_widen"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Compressor")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "compressor-rms-peak" }
                    module: "compressor"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Pitch shift")
                SettingsWidgets.TextField { option: ConfigOption { name: "pitch-shift" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Chorus/flanger")
                SettingsWidgets.ModuleSwitch {
                    option: ConfigOption { name: "delay-time" }
                    module: "chorus_flanger"
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Karaoke")
                SettingsWidgets.ModuleSwitch { module: "karaoke" }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Tracks")

            SettingsWidgets.Row {
                text: qsTr("Preferred audio language")
                SettingsWidgets.TextField { option: ConfigOption { name: "audio-language" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Audio delay (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "audio-desync" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Visualization")

            SettingsWidgets.Row {
                text: qsTr("Visualizer")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "audio-visual" } }
            }
        }
    }

    component Subtitles : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Tracks & Languages")

            SettingsWidgets.Row {
                text: qsTr("Enable subtitles")
                SettingsWidgets.Switch { option: ConfigOption { name: "spu" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Preferred language")
                SettingsWidgets.TextField { option: ConfigOption { name: "sub-language" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Text encoding")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "subsdec-encoding" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Loading Subtitles")

            SettingsWidgets.Row {
                text: qsTr("Load subtitle files automatically")
                SettingsWidgets.Switch { option: ConfigOption { name: "sub-autodetect-file" } }
            }
            SettingsWidgets.Row {
                text: qsTr("File name matching")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "sub-autodetect-fuzzy" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Appearance")

            SettingsWidgets.Row {
                text: qsTr("Font")
                SettingsWidgets.TextField { option: ConfigOption { name: "freetype-font" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Font size")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "freetype-rel-fontsize" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Bold")
                SettingsWidgets.Switch { option: ConfigOption { name: "freetype-bold" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Text color")
                SettingsWidgets.ColorField { option: ConfigOption { name: "freetype-color" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Text opacity")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "freetype-opacity" }
                    labels: ["0%", "50%", "100%"]
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Outline thickness")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "freetype-outline-thickness" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Outline color")
                SettingsWidgets.ColorField { option: ConfigOption { name: "freetype-outline-color" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Shadow color")
                SettingsWidgets.ColorField { option: ConfigOption { name: "freetype-shadow-color" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Shadow opacity")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "freetype-shadow-opacity" }
                    labels: ["0%", "50%", "100%"]
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Background color")
                SettingsWidgets.ColorField { option: ConfigOption { name: "freetype-background-color" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Background opacity")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "freetype-background-opacity" }
                    labels: ["0%", "50%", "100%"]
                }
            }
            SettingsWidgets.Row {
                text: qsTr("Vertical position (pixels from the bottom)")
                SettingsWidgets.TextField { option: ConfigOption { name: "sub-margin" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Timing")

            SettingsWidgets.Row {
                text: qsTr("Subtitle delay")
                SettingsWidgets.Slider {
                    // The option is in tenths of a second
                    option: ConfigOption { name: "sub-delay" }
                    from: -5; to: 5; stepSize: 0.1; factor: 10
                    labels: ["-5 s", "0 s", "+5 s"]
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("On-Screen Messages")

            SettingsWidgets.Row {
                text: qsTr("Show feedback for shortcuts")
                SettingsWidgets.Switch { option: ConfigOption { name: "osd" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show filename when a video starts")
                SettingsWidgets.Switch { option: ConfigOption { name: "video-title-show" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show filename for")
                SettingsWidgets.Slider {
                    option: ConfigOption { name: "video-title-timeout" }
                    from: 1; to: 10; stepSize: 0.5; factor: 1000
                    labels: ["1 s", "10 s"]
                }
            }
        }
    }

    component Library : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Opening Files")

            SettingsWidgets.Row {
                text: qsTr("Only allow one VLC window")
                SettingsWidgets.Switch { option: ConfigOption { name: "one-instance" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Apply to files opened from the file manager")
                SettingsWidgets.Switch { option: ConfigOption { name: "one-instance-when-started-from-file" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Add to the playlist instead of replacing it")
                SettingsWidgets.Switch { option: ConfigOption { name: "playlist-enqueue" } }
            }
            SettingsWidgets.Row {
                text: qsTr("When opening a folder")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "recursive" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Show hidden files")
                SettingsWidgets.Switch { option: ConfigOption { name: "show-hiddenfiles" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Metadata & Artwork")

            SettingsWidgets.Row {
                text: qsTr("Fetch titles and artwork from the internet")
                SettingsWidgets.Switch { option: ConfigOption { name: "metadata-network-access" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Use the media library")
                SettingsWidgets.Switch { option: ConfigOption { name: "media-library" } }
            }
        }
    }

    // System

    component Network : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Buffering")

            SettingsWidgets.Row {
                text: qsTr("Local files (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "file-caching" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Discs (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "disc-caching" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Network streams (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "network-caching" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Live capture (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "live-caching" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Proxy")

            SettingsWidgets.Row {
                text: qsTr("HTTP proxy")
                SettingsWidgets.TextField {
                    option: ConfigOption { name: "http-proxy" }
                    placeholderText: qsTr("System proxy")
                }
            }
            SettingsWidgets.Row {
                text: qsTr("HTTP proxy password")
                SettingsWidgets.TextField {
                    option: ConfigOption { name: "http-proxy-pwd" }
                    echoMode: TextInput.Password
                }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Security")

            SettingsWidgets.Row {
                text: qsTr("Verify certificates against the system trust store")
                SettingsWidgets.Switch { option: ConfigOption { name: "gnutls-system-trust" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Cipher preference")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "gnutls-priorities" } }
            }
        }
    }

    component Performance : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Decoding")

            SettingsWidgets.Row {
                text: qsTr("Hardware-accelerated decoding")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "dec-dev" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Video post-processing")
                SettingsWidgets.TextField { option: ConfigOption { name: "postproc-q" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Skip the H.264 loop filter")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "avcodec-skiploopfilter" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Decoding threads")
                SettingsWidgets.TextField { option: ConfigOption { name: "avcodec-threads" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Smooth Playback")

            SettingsWidgets.Row {
                text: qsTr("Drop frames when the system can't keep up")
                SettingsWidgets.Switch { option: ConfigOption { name: "drop-late-frames" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Give VLC real-time priority")
                SettingsWidgets.Switch { option: ConfigOption { name: "high-priority" } }
            }
        }

        SettingsWidgets.AdvancedToggle { }

        SettingsWidgets.Section {
            title: qsTr("Developer")
            advanced: true

            SettingsWidgets.Row {
                text: qsTr("Clock synchronisation")
                SettingsWidgets.Dropdown { option: ConfigOption { name: "clock-synchro" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Clock jitter (ms)")
                SettingsWidgets.TextField { option: ConfigOption { name: "clock-jitter" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Clock reference averaging")
                SettingsWidgets.TextField { option: ConfigOption { name: "cr-average" } }
            }
        }
    }

    component Recording : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Recording")

            SettingsWidgets.Row {
                text: qsTr("Save recordings to")
                SettingsWidgets.PathField { option: ConfigOption { name: "input-record-path" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Record without re-encoding when possible")
                SettingsWidgets.Switch { option: ConfigOption { name: "input-record-native" } }
            }
        }

        SettingsWidgets.Section {
            title: qsTr("Streaming")

            SettingsWidgets.Row {
                text: qsTr("Play locally while streaming")
                SettingsWidgets.Switch { option: ConfigOption { name: "sout-display" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Include audio")
                SettingsWidgets.Switch { option: ConfigOption { name: "sout-audio" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Include video")
                SettingsWidgets.Switch { option: ConfigOption { name: "sout-video" } }
            }
            SettingsWidgets.Row {
                text: qsTr("Include subtitles")
                SettingsWidgets.Switch { option: ConfigOption { name: "sout-spu" } }
            }
        }
    }

    component Extensions : SettingsWidgets.Page {
        SettingsWidgets.Section {
            title: qsTr("Add-ons")

            SettingsWidgets.Row {
                text: qsTr("Plugins and extensions")
                SettingsWidgets.Button { text: qsTr("Open"); onClicked: DialogsProvider.pluginDialog() }
            }
            SettingsWidgets.Row {
                text: qsTr("Load add-ons on startup")
                SettingsWidgets.Switch { option: ConfigOption { name: "qt-autoload-extensions" } }
            }
        }
    }
}
