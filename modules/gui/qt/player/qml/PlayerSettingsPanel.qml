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
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Dialogs
import VLC.Util

// Settings panel of the player, with the Playback, Video, Audio and
// Subtitles tabs. "Show Advanced Settings" opens the effects and
// synchronisation dialog.
PanelCard {
    id: root

    tabs: [
        { text: qsTr("Playback"), icon: VLCIcons.play },
        { text: qsTr("Video"), icon: VLCIcons.topbar_video },
        { text: qsTr("Audio"), icon: VLCIcons.topbar_music },
        { text: qsTr("Subtitles"), icon: VLCIcons.audiosub }
    ]

    currentIndex: PlayerPanelState.settingsTab
    onCurrentIndexChanged: PlayerPanelState.settingsTab = currentIndex

    function _formatDelay(ms) {
        const seconds = ms / 1000
        return qsTr("%1 s").arg((seconds > 0 ? "+" : "") + seconds.toFixed(2))
    }

    // Playback

    PanelWidgets.Page {
        PanelWidgets.LabeledRow {
            Layout.topMargin: VLCStyle.margin_xsmall
            text: qsTr("Show Subtitle Timeline on Seekbar")

            PanelWidgets.Switch {
                checked: MainCtx.seekBarSubtitleTimeline
                onToggled: MainCtx.seekBarSubtitleTimeline = checked
                Accessible.name: qsTr("Show subtitle timeline on seek bar")
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Reverse")

            PanelWidgets.Switch {
                enabled: Player.rewindable && Player.ratechangable
                checked: Player.rate < 0
                onToggled: Player.reverse()
                Accessible.name: qsTr("Play backwards")
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Statistics")

            PanelWidgets.IconButton {
                text: VLCIcons.info
                description: qsTr("Show statistics")
                onClicked: DialogsProvider.mediaStatisticsDialog()
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Sleep Timer")

            PanelWidgets.ComboBox {
                model: PlayerPanelState.sleepTimerChoices.map((minutes) => {
                    return (minutes === 0) ? qsTr("Off") : qsTr("Pause after %1 min").arg(minutes)
                })
                currentIndex: PlayerPanelState.sleepTimerChoices.indexOf(PlayerPanelState.sleepTimerMinutes)
                onActivated: (index) => {
                    PlayerPanelState.sleepTimerMinutes = PlayerPanelState.sleepTimerChoices[index]
                }
                Accessible.name: qsTr("Sleep timer")
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Audio Visualizer")

            PanelWidgets.ComboBox {
                choices: Player.audioVisualization
                Accessible.name: qsTr("Audio visualizer")
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Speed")

            Rectangle {
                implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: speedBoxTheme.bg.secondary

                readonly property ColorContext colorContext: PanelWidgets.BoxTheme { id: speedBoxTheme }

                Widgets.ListLabel {
                    font.weight: Font.Normal
                    anchors.fill: parent
                    leftPadding: VLCStyle.margin_small
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("%1x").arg(+Player.rate.toFixed(2))
                    color: speedTextTheme.fg.primary

                    readonly property ColorContext colorContext: PanelWidgets.Theme { id: speedTextTheme }
                    font.pixelSize: VLCStyle.fontSize_large
                }
            }
        }

        Widgets.SliderExt {
            id: speedSlider

            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

            from: 0.25
            to: 2
            stepSize: 0.25
            snapMode: T.Slider.SnapAlways
            enabled: Player.ratechangable

            value: Math.abs(Player.rate)
            onMoved: Player.rate = (Player.rate < 0 ? -value : value)

            toolTipTextProvider: (value) => qsTr("%1x").arg(+value.toFixed(2))

            Accessible.name: qsTr("Playback speed")
        }

        // Speed values under the slider, each one under its position.
        Item {
            id: speedLabels

            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale) + speedSlider.leftPadding + speedSlider.handleWidth / 2
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale) + speedSlider.rightPadding + speedSlider.handleWidth / 2
            Layout.bottomMargin: VLCStyle.margin_large
            implicitHeight: VLCStyle.fontHeight_normal

            readonly property ColorContext colorContext: PanelWidgets.Theme { id: speedTheme }

            Repeater {
                model: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

                Widgets.ListLabel {
                    required property var modelData
                    required property int index

                    font.weight: Font.Normal
                    x: Helpers.clamp(index / 7 * speedLabels.width - width / 2,
                                     -speedLabels.x + VLCStyle.dp(20, VLCStyle.scale),
                                     speedLabels.width - width)
                    text: modelData
                    color: speedTheme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_normal

                    TapHandler { onTapped: Player.rate = (Player.rate < 0 ? -modelData : modelData) }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    // Video

    PanelWidgets.Page {
        PanelWidgets.Section {
            text: qsTr("Tracks")

            PanelWidgets.IconButton {
                text: VLCIcons.add
                description: qsTr("Add a video file")
                onClicked: DialogsProvider.loadVideoFile()
            }
        }

        PanelWidgets.CheckList {
            model: Player.videoTracks
            emptyText: qsTr("No video tracks")
        }

        PanelWidgets.Separator { Layout.topMargin: VLCStyle.margin_normal }

        PanelWidgets.LabeledRow {
            Layout.topMargin: VLCStyle.margin_xsmall
            text: qsTr("Zoom")
            PanelWidgets.ComboBox { choices: Player.zoom; Accessible.name: qsTr("Zoom") }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Aspect Ratio")
            PanelWidgets.ComboBox { choices: Player.aspectRatio; Accessible.name: qsTr("Aspect ratio") }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Crop")
            PanelWidgets.ComboBox { choices: Player.crop; Accessible.name: qsTr("Crop") }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Fit")
            PanelWidgets.ComboBox { choices: Player.fit; Accessible.name: qsTr("Fit") }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Deinterlace")
            PanelWidgets.ComboBox { choices: Player.deinterlace; Accessible.name: qsTr("Deinterlace") }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Stereo Mode")
            PanelWidgets.ComboBox { choices: Player.videoStereoMode; Accessible.name: qsTr("Video stereo mode") }
        }

        // The colours and the effects are set in the dialog of the effects
        PanelWidgets.ExpandRow {
            Layout.topMargin: VLCStyle.margin_normal
            text: qsTr("Colors")
            onClicked: DialogsProvider.extendedDialog()
        }

        PanelWidgets.WideButton {
            text: qsTr("Open Advanced Settings")
            onClicked: DialogsProvider.extendedDialog()
        }
    }

    // Audio

    PanelWidgets.Page {
        PanelWidgets.Section {
            text: qsTr("Tracks")

            PanelWidgets.IconButton {
                text: VLCIcons.add
                description: qsTr("Add an audio file")
                onClicked: DialogsProvider.loadAudioFile()
            }
        }

        PanelWidgets.CheckList {
            model: Player.audioTracks
            emptyText: qsTr("No audio tracks")
        }

        PanelWidgets.Separator { Layout.topMargin: VLCStyle.margin_normal }

        PanelWidgets.Section {
            text: qsTr("Output Device")
        }

        PanelWidgets.CheckList {
            model: Player.audioDevices
            emptyText: qsTr("No output devices")
        }

        PanelWidgets.Separator { Layout.topMargin: VLCStyle.margin_normal }

        PanelWidgets.LabeledRow {
            Layout.topMargin: VLCStyle.margin_xsmall
            text: qsTr("Stereo Mode")
            // The audio output gives the choices, some outputs have none.
            visible: audioStereoBox.count > 0
            PanelWidgets.ComboBox {
                id: audioStereoBox
                choices: Player.audioStereoMode
                Accessible.name: qsTr("Audio stereo mode")
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Audio Delay")

            PanelWidgets.Stepper {
                valueText: root._formatDelay(Player.audioDelayMS)
                onDecrease: Player.audioDelayMS -= 50
                onIncrease: Player.audioDelayMS += 50
                onReset: Player.audioDelayMS = 0
            }
        }

        PanelWidgets.Separator { Layout.topMargin: VLCStyle.margin_normal }

        // The filters are set in the dialog of the effects
        PanelWidgets.Section {
            text: qsTr("Filters")
        }

        PanelWidgets.ExpandRow {
            text: qsTr("Equalizer")
            onClicked: DialogsProvider.extendedDialog()
        }

        PanelWidgets.ExpandRow {
            text: qsTr("Compressor")
            onClicked: DialogsProvider.extendedDialog()
        }

        PanelWidgets.ExpandRow {
            text: qsTr("Spatializer")
            onClicked: DialogsProvider.extendedDialog()
        }

        PanelWidgets.ExpandRow {
            text: qsTr("Stereo Widener")
            onClicked: DialogsProvider.extendedDialog()
        }

        PanelWidgets.WideButton {
            text: qsTr("Open Advanced Settings")
            onClicked: DialogsProvider.extendedDialog()
        }
    }

    // Subtitles

    PanelWidgets.Page {
        PanelWidgets.Section {
            text: qsTr("Tracks")

            PanelWidgets.IconButton {
                text: VLCIcons.ic_fluent_arrow_download_24_regular
                description: qsTr("Download subtitles")
                onClicked: Player.openVLsub()
            }

            PanelWidgets.IconButton {
                text: VLCIcons.add
                description: qsTr("Add a subtitle file")
                onClicked: DialogsProvider.loadSubtitlesFile()
            }
        }

        PanelWidgets.CheckList {
            model: Player.subtitleTracks
            emptyText: qsTr("No subtitle tracks")
        }

        PanelWidgets.Separator { Layout.topMargin: VLCStyle.margin_normal }

        PanelWidgets.LabeledRow {
            Layout.topMargin: VLCStyle.margin_xsmall
            text: qsTr("Subtitle Delay")

            PanelWidgets.Stepper {
                valueText: root._formatDelay(Player.subtitleDelayMS)
                onDecrease: Player.subtitleDelayMS -= 50
                onIncrease: Player.subtitleDelayMS += 50
                onReset: Player.subtitleDelayMS = 0
            }
        }

        PanelWidgets.LabeledRow {
            text: qsTr("Show Subtitle Timeline on Seekbar")

            PanelWidgets.Switch {
                checked: MainCtx.seekBarSubtitleTimeline
                onToggled: MainCtx.seekBarSubtitleTimeline = checked
                Accessible.name: qsTr("Show subtitle timeline on seek bar")
            }
        }

        PanelWidgets.WideButton {
            text: qsTr("Open Advanced Settings")
            onClicked: DialogsProvider.extendedDialog()
        }
    }
}
