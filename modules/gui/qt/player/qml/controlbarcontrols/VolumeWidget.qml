/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Player

T.Pane {
    id: root

    property bool paintOnly: false

    readonly property color sliderColor: {
        const theme = volControl.colorContext
        return (volControl.position > _fullvolpos) ? theme.fg.negative : theme.fg.primary
    }

    readonly property var _player: paintOnly ? ({ muted: false, volume: .5 }) : Player
    readonly property int _maxvol: MainCtx.maxVolume
    readonly property real _fullvolpos: 100 / _maxvol
    readonly property real _maxvolpos: _maxvol / 100

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentWidth: volumeWidget.implicitWidth
    contentHeight: volumeWidget.implicitHeight

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    RowLayout {
        id: volumeWidget

        anchors.fill: parent
        spacing: 0

        Widgets.IconToolButton{
            id: volumeBtn

            focus: true
            paintOnly: root.paintOnly
            text: {
                if (_player.muted)
                    return VLCIcons.volume_muted
                else if (_player.volume === 0)
                    return VLCIcons.volume_zero
                else if (_player.volume < .33)
                    return VLCIcons.volume_low
                else if (_player.volume <= .66)
                    return VLCIcons.volume_medium
                else
                    return VLCIcons.volume_high
            }
            description: qsTr("Mute")

            AccessibleCompat.id: "muteButton"

            onClicked: Player.muted = !Player.muted

            Accessible.onIncreaseAction: {
                Player.muted = false
                Player.setVolumeUp()
            }

            Accessible.onDecreaseAction: {
                Player.muted = false
                Player.setVolumeDown()
            }

            Navigation.parentItem: root
            Navigation.rightItem: volControl
        }

        Widgets.SliderExt {
            id: volControl

            implicitWidth: VLCStyle.dp(88, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

            // WARNING: Directly setting the insets break handle and background positioning.
            Binding on topInset {
                when: MainCtx.usingTouch
                value: VLCStyle.touchHandlerMargin
            }
            Binding on bottomInset {
                when: MainCtx.usingTouch
                value: VLCStyle.touchHandlerMargin
            }

            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: VLCStyle.margin_xsmall

            // The volume is drawn as a wedge that is thin on the left and as
            // tall as the control on the right. The part up to the current
            // volume is filled with a gradient from green to red.
            handle: Item {
                x: volControl.leftPadding + volControl.visualPosition * volControl.availableWidth
                y: volControl.topPadding
                implicitWidth: 0
                implicitHeight: volControl.availableHeight
            }

            background: Item {
                x: volControl.leftPadding
                y: volControl.topPadding

                implicitWidth: volControl.implicitWidth
                implicitHeight: volControl.implicitHeight

                width: volControl.availableWidth
                height: volControl.availableHeight

                Canvas {
                    id: wedge

                    anchors.fill: parent

                    readonly property color trackColor: volControl.colorContext.bg.secondary
                    readonly property color focusColor: volControl.colorContext.visualFocus
                    readonly property bool focused: volControl.visualFocus
                    readonly property real level: volControl.visualPosition

                    onTrackColorChanged: requestPaint()
                    onFocusColorChanged: requestPaint()
                    onFocusedChanged: requestPaint()
                    onLevelChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    // Four sided shape with a straight top and bottom edge that
                    // go from `halfLeft` to `halfRight` away from the middle line.
                    // The corners are rounded by drawing the shape smaller and
                    // then drawing a line of width 2 * radius around it.
                    function drawWedge(ctx, x0, x1, halfLeft, halfRight, radius) {
                        const cy = height / 2
                        ctx.beginPath()
                        ctx.moveTo(x0 + radius, cy - halfLeft + radius)
                        ctx.lineTo(x1 - radius, cy - halfRight + radius)
                        ctx.lineTo(x1 - radius, cy + halfRight - radius)
                        ctx.lineTo(x0 + radius, cy + halfLeft - radius)
                        ctx.closePath()
                        ctx.lineJoin = "round"
                        ctx.lineWidth = 2 * radius
                        ctx.fill()
                        ctx.stroke()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()

                        const dp = VLCStyle.dp(1, VLCStyle.scale)

                        if (focused) {
                            ctx.fillStyle = ctx.strokeStyle = focusColor
                            drawWedge(ctx, -1.5 * dp, width + 1.5 * dp, 2.75 * dp + 1.5 * dp, height / 2 + 1.5 * dp, 3.5 * dp)
                        }

                        ctx.fillStyle = ctx.strokeStyle = trackColor
                        drawWedge(ctx, 0, width, 2.75 * dp, height / 2, 2 * dp)

                        // Part of the volume. The gradient covers the whole
                        // width and is cut at the volume, so the colour at the
                        // end of the filled part shows the volume level. The
                        // colours of the design, 20 % darker.
                        const x0 = 1.5 * dp
                        const x1 = width - 1.5 * dp

                        ctx.save()
                        ctx.beginPath()
                        ctx.rect(0, 0, level * width, height)
                        ctx.clip()

                        const gradient = ctx.createLinearGradient(x0, 0, x1, 0)
                        gradient.addColorStop(0.0, "#76A913")
                        gradient.addColorStop(0.579, "#8E8713")
                        gradient.addColorStop(0.792, "#A96113")
                        gradient.addColorStop(1.0, "#CC2C2C")
                        ctx.fillStyle = ctx.strokeStyle = gradient
                        drawWedge(ctx, x0, x1, 2.0 * dp, 12.5 * dp, 1.5 * dp)
                        ctx.restore()
                    }
                }
            }

            property bool _inhibitPlayerVolumeUpdate: false

            // FIXME: Currently we are not updating the ShiftModifier status while dragging. This
            //        could be fixed with a custom Slider based on a MouseArea.
            property bool _shiftPressed: false

            property real _clamp: 0.01

            property bool _keyPressed: false

            property bool filterEvents: false

            color: root.sliderColor

            from: 0
            to: root._maxvolpos
            opacity: _player.muted ? 0.5 : 1

            enabled: !root.paintOnly // disables event handling depending on this

            toolTipTextProvider: function (value) {
                // the real value i.e 'Player.volume' bounds can be different
                // from bounds of this widget and we want to show the current
                // volume here, so directly use Player.volume instead of "value"

                return Math.round(Player.volume * 100) + "%"
            }

            Accessible.name: qsTr("Volume")
            AccessibleCompat.id: "volumeSlider"

            Keys.onPressed: (event) => {
                if (KeyHelper.matchOk(event)) {
                    event.accepted = true

                    _keyPressed = true
                } else {
                    Navigation.defaultKeyAction(event)
                }
            }

            Keys.onReleased: (event) => {
                if (_keyPressed === false)
                    return

                _keyPressed = false

                if (KeyHelper.matchOk(event)) {
                    Player.muted = !Player.muted
                }
            }

            function _syncVolumeWithPlayer() {
                volControl._inhibitPlayerVolumeUpdate = true
                volControl.value = _player.volume
                volControl._inhibitPlayerVolumeUpdate = false
            }

            function _adjustPlayerVolume() {
                Player.muted = false

                let value = volControl.value

                // NOTE: We are clamping the value to make it easier to restore the default volume.
                if (_shiftPressed === false) {
                    if (Math.abs(value - 1.0) < _clamp)
                        value = 1.0
                    else
                        _clamp = 0.01
                }

                Player.volume = value

                volControl.value = value
            }

            Component.onCompleted: {
                root.paintOnlyChanged.connect(_syncVolumeWithPlayer)
                volControl._syncVolumeWithPlayer()
            }

            Connections {
                target: Player
                enabled: !paintOnly

                function onVolumeChanged() { volControl._syncVolumeWithPlayer() }
            }

            Binding on Widgets.PointingToolTipAttached.visible {
                when: sliderMouseArea.pressed
                value: true
            }

            Navigation.leftItem: volumeBtn
            Navigation.parentItem: root

            Keys.onUpPressed: (event) => {
                Player.muted = false
                Player.setVolumeUp()
            }

            Keys.onDownPressed: (event) => {
                Player.muted = false
                Player.setVolumeDown()
            }

            Keys.priority: Keys.BeforeItem

            onValueChanged: {
                if (paintOnly)
                    return

                if (!volControl._inhibitPlayerVolumeUpdate) {
                    if (filterEvents) {
                        Qt.callLater(volControl._adjustPlayerVolume)
                    } else {
                        volControl._adjustPlayerVolume()
                        filterEvents = true
                    }
                }
            }

            Rectangle{
                id: tickmark

                parent: volControl.background

                x : parent.width * root._fullvolpos
                width: VLCStyle.dp(1, VLCStyle.scale)
                height: parent.height
                radius: VLCStyle.dp(2, VLCStyle.scale)

                // NOTE: This shouldn't be visible when the volume stops before a 100.
                visible: (root._maxvol > 100)

                // The design does not show a mark at 100 %. The item is kept
                // for the click helper below.
                color: "transparent"

                // NOTE: This is a helper to select the default volume when clicking on the
                //       tickmark. We apply a higher clamp value to achieve that behavior on
                //       the Slider.
                MouseArea {
                    anchors.fill: parent

                    anchors.margins: -(VLCStyle.dp(4, VLCStyle.scale))

                    onPressed: (mouse) => {
                        mouse.accepted = false

                        if (mouse.modifiers === Qt.ShiftModifier)
                            return

                        volControl._clamp = 0.1
                    }
                }
            }

            MouseArea {
                id: sliderMouseArea

                anchors.fill: parent

                acceptedButtons: (Qt.LeftButton | Qt.RightButton)
                cursorShape: root.paintOnly ? Qt.ArrowCursor : Qt.PointingHandCursor

                onPressed: (mouse) => {
                    if (root.paintOnly) {
                        mouse.accepted = true
                        return
                    }

                    volControl._shiftPressed = (mouse.modifiers === Qt.ShiftModifier)

                    if (mouse.button === Qt.LeftButton) {
                        mouse.accepted = false

                        return
                    }

                    volControl.filterEvents = false
                    adjustVolume(mouse)
                }

                onPositionChanged: (mouse) => {
                    if (mouse.buttons & Qt.RightButton)
                        adjustVolume(mouse)
                }

                onWheel: (wheel) => {

                    if ((Math.abs(wheel.pixelDelta.x) % 120 > 0) || (Math.abs(wheel.pixelDelta.y) % 120 > 0)) {
                        let delta = 0
                        if (Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y))
                            delta = wheel.pixelDelta.x
                        else
                            delta = wheel.pixelDelta.y

                        if (wheel.inverted)
                            delta = -delta
                        volControl.value += 0.001 * delta
                    }
                    else
                        wheelToVLC.qmlWheelEvent(wheel)

                    wheel.accepted = true
                }

                function adjustVolume(mouse) {
                    mouse.accepted = true

                    const pos = mouse.x * root._maxvolpos / width

                    if (pos < 0.25)
                        volControl.value = 0
                    else if (pos < 0.75)
                        volControl.value = 0.5
                    else if (pos < 1.125)
                        volControl.value = 1
                    else
                        volControl.value = 1.25
                }

                WheelToVLCConverter {
                    id: wheelToVLC

                    function handle(steps: int) {
                        if (steps > 0)
                            Player.setVolumeUp(steps)
                        else
                            Player.setVolumeDown(-steps)
                    }

                    Component.onCompleted: {
                        wheelUpDown.connect(wheelToVLC.handle)
                        wheelLeftRight.connect(wheelToVLC.handle)
                    }
                }
            }
        }
    }
}
