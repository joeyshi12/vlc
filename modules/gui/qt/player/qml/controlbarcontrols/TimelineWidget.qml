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

        SliderBar {
            id: trackPositionSlider

            Layout.fillWidth: true
            Layout.preferredWidth: root.paintOnly ? VLCStyle.dp(120, VLCStyle.scale) : -1
            Layout.alignment: Qt.AlignVCenter

            blockStyle: true
            barHeight: VLCStyle.dp(28, VLCStyle.scale)

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
