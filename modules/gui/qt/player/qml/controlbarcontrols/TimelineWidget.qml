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
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util
import VLC.Dialogs

// Current time, seek bar and duration in one row. When this control is part of
// the control bar layout, the control bar does not show its own seek bar row.
T.Control {
    id: root

    // Buttons of the zoom of the subtitle timeline, at both ends of the bar
    component ZoomButton : T.Button {
        id: zoomButton

        property string glyph
        property string description

        Layout.preferredWidth: VLCStyle.dp(20, VLCStyle.scale)
        Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
        Layout.alignment: Qt.AlignVCenter

        focusPolicy: Qt.StrongFocus

        T.ToolTip.visible: hovered
        T.ToolTip.delay: VLCStyle.delayToolTipAppear
        T.ToolTip.text: description
        Accessible.name: description

        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: Qt.rgba(theme.accent.r * 0.26, theme.accent.g * 0.26, theme.accent.b * 0.26, 1)
            opacity: zoomButton.enabled ? 1 : 0.4
            border.width: zoomButton.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: Text {
            text: zoomButton.glyph
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.DemiBold
            color: theme.accent
        }
    }


    property bool paintOnly: false

    // The control takes the free width of the control bar. The toolbar editor
    // shows it at its implicit size.
    Layout.fillWidth: !paintOnly
    Layout.minimumWidth: paintOnly ? -1 : VLCStyle.dp(160, VLCStyle.scale)

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    leftPadding: VLCStyle.margin_xsmall

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    Accessible.role: Accessible.Grouping
    Accessible.name: qsTr("Timeline")

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.ToolButton
    }

    TextMetrics {
        id: timeTextMetrics

        font.pixelSize: VLCStyle.fontSize_large

        // Some extra space to compensate non-monospaced fonts. Length might not
        // be reported in some cases, so both values are checked.
        text: (root.paintOnly || (Player.time.isSubHour() && Player.length.isSubHour())) ? "-00:00-" : "-00:00:00-"
    }

    readonly property ColorContext sliderColorContext: ColorContext {
        id: sliderTheme
        colorSet: ColorContext.Slider
    }

    contentItem: RowLayout {
        spacing: VLCStyle.margin_xsmall

        T.Label {
            id: mediaTime

            readonly property bool hovered: mediaTimeHover.hovered

            Layout.preferredWidth: timeTextMetrics.width + leftPadding + rightPadding
            Layout.fillHeight: true

            leftPadding: VLCStyle.margin_xsmall
            rightPadding: VLCStyle.margin_xsmall

            color: theme.fg.primary
            font: timeTextMetrics.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: {
                if (root.paintOnly)
                    return "00:00"
                const length = Player.length
                return Player.time.formatHMS(length.isSubSecond() ? VLCTick.SubSecondFormattedAsMS : 0)
            }

            Accessible.name: qsTr("Elapsed time, click to jump to a specific time")

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: mediaTime.hovered ? sliderTheme.bg.secondary : "transparent"
            }

            HoverHandler {
                id: mediaTimeHover
                enabled: !root.paintOnly
            }

            TapHandler {
                enabled: !root.paintOnly
                onTapped: DialogsProvider.gotoTimeDialog()
            }

            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: mediaTime
                property: "mutabilityGroup"
                when: (mediaTime.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.ModerateMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }
        }

        // Zoom of the subtitle timeline: the bar shows 1 / zoom of the media
        // around the playback position, and follows it.
        QtObject {
            id: timelineZoom

            readonly property bool active: !root.paintOnly && MediaTimeline.subtitlesRequested
                                           && trackPositionSlider.subtitleCues.length > 0
            property int level: 0                       // the bar shows 1 / 2^level of the media
            readonly property real span: 1 / Math.pow(2, level)
            property real start: 0

            onActiveChanged: if (!active) level = 0
            onLevelChanged: center(Player.position)

            function center(position) {
                start = Helpers.clamp(position - span / 2, 0, 1 - span)
            }

            function pan(direction) {
                start = Helpers.clamp(start + direction * span / 2, 0, 1 - span)
            }
        }

        Connections {
            target: Player
            enabled: timelineZoom.level > 0
            function onPositionChanged() {
                if (Player.position < timelineZoom.start || Player.position > timelineZoom.start + timelineZoom.span)
                    timelineZoom.center(Player.position)
            }
        }

        RowLayout {
            visible: timelineZoom.active
            spacing: VLCStyle.dp(2, VLCStyle.scale)

            ZoomButton {
                glyph: "\u2039"
                description: qsTr("Show an earlier part")
                enabled: timelineZoom.level > 0 && timelineZoom.start > 0
                onClicked: timelineZoom.pan(-1)
            }
            ZoomButton {
                glyph: "\u2212"
                description: qsTr("Zoom out")
                enabled: timelineZoom.level > 0
                onClicked: timelineZoom.level--
            }
        }

        SliderBar {
            id: trackPositionSlider

            viewStart: timelineZoom.level > 0 ? timelineZoom.start : 0
            viewEnd: timelineZoom.level > 0 ? timelineZoom.start + timelineZoom.span : 1

            Layout.fillWidth: true
            Layout.preferredWidth: root.paintOnly ? VLCStyle.dp(120, VLCStyle.scale) : -1
            Layout.alignment: Qt.AlignVCenter

            blockStyle: true
            barHeight: VLCStyle.dp(28, VLCStyle.scale)

            // Audio only media show the audio level, video shows the subtitle
            // lines when enabled in the playback settings. The data comes from
            // MediaTimeline, which Player.qml asks to read the media.
            readonly property bool showWaveform: !root.paintOnly && MediaTimeline.waveformRequested
                                                 && MediaTimeline.hasWaveform
            readonly property int waveformBarCount: Math.max(0, Math.floor((width - VLCStyle.dp(8, VLCStyle.scale))
                                                                          / waveformBarSpacing))
            property int _waveformRevision: 0

            Connections {
                target: MediaTimeline
                function onWaveformChanged() { trackPositionSlider._waveformRevision++ }
            }

            waveform: {
                void(_waveformRevision)
                return showWaveform ? MediaTimeline.waveform(waveformBarCount) : []
            }

            subtitleCues: (!root.paintOnly && MediaTimeline.subtitlesRequested) ? MediaTimeline.subtitleCues : []

            enabled: !root.paintOnly
                     && (Player.playingState === Player.PLAYING_STATE_PLAYING
                         || Player.playingState === Player.PLAYING_STATE_PAUSED)

            focus: true
            activeFocusOnTab: true

            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Progress")
            AccessibleCompat.id: "progressSlider"

            Navigation.parentItem: root

            Keys.onPressed: (event) => Navigation.defaultKeyAction(event)
        }

        RowLayout {
            visible: timelineZoom.active
            spacing: VLCStyle.dp(2, VLCStyle.scale)

            ZoomButton {
                glyph: "+"
                description: qsTr("Zoom in")
                enabled: timelineZoom.level < 6
                onClicked: timelineZoom.level++
            }
            ZoomButton {
                glyph: "\u203A"
                description: qsTr("Show a later part")
                enabled: timelineZoom.level > 0 && timelineZoom.start + timelineZoom.span < 1
                onClicked: timelineZoom.pan(1)
            }
        }

        T.Label {
            id: mediaRemainingTime

            readonly property bool hovered: mediaRemainingTimeHover.hovered

            readonly property bool showRemainingTime: (MainCtx.showRemainingTime && Player.remainingTime.valid())

            Layout.preferredWidth: timeTextMetrics.width + leftPadding + rightPadding
            Layout.fillHeight: true

            leftPadding: VLCStyle.margin_xsmall
            rightPadding: VLCStyle.margin_xsmall

            color: theme.fg.primary
            font: timeTextMetrics.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: {
                if (root.paintOnly)
                    return "00:00"
                return showRemainingTime ? "-" + Player.remainingTime.formatHMS()
                                         : Player.length.formatHMS()
            }

            Accessible.name: qsTr("Duration, click to switch between total and remaining time")

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: mediaRemainingTime.hovered ? sliderTheme.bg.secondary : "transparent"
            }

            HoverHandler {
                id: mediaRemainingTimeHover
                enabled: !root.paintOnly
            }

            TapHandler {
                enabled: !root.paintOnly
                onTapped: MainCtx.showRemainingTime = !MainCtx.showRemainingTime
            }

            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: mediaRemainingTime
                property: "mutabilityGroup"
                when: (mediaRemainingTime.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.ModerateMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }

            Widgets.ToolTipExt {
                colorContext.palette: theme.palette

                visible: mediaRemainingTime.hovered && MainCtx.showRemainingTime && Player.rate !== 1
                delay: VLCStyle.delayToolTipAppear
                text: {
                    if (!visible)
                        return ""

                    const playbackSpeed = Math.abs(Player.rate)
                    const adjustedRemainingTime = Player.remainingTime.scale(1 / playbackSpeed)
                        ? Player.remainingTime.scale(1 / playbackSpeed)
                        : Player.remainingTime

                    return qsTr("%1 (%2x)")
                        .arg(adjustedRemainingTime.formatHMS())
                        .arg(+Player.rate.toFixed(2))
                }

                x: (parent.width - width) / 2
            }
        }
    }

    function showChapterMarks() {
        trackPositionSlider.showChapterMarks()
    }
}
