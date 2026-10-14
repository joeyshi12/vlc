/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQuick.Window


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

T.ItemDelegate {
    id: control

    // Properties

    property string iconTxt: ""

    // Name of an SVG icon of the design (pixmaps/redesign/nav-<name>.svg). It
    // is used instead of `iconTxt` when it is set. The icon variant that is
    // drawn filled is used for `iconSelected`.
    property string iconName: ""
    property bool iconSelected: false

    // Colour of the panel behind the icon, for the parts of the filled icon
    // that are cut out.
    property color panelColor: "#191919"

    property bool showText: true

    property real radius: VLCStyle.dp(6, VLCStyle.scale)

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_xxsmall

    leftInset: implicitLeftInset
    rightInset: implicitRightInset

    topInset: implicitTopInset
    bottomInset: implicitBottomInset

    // The button is 40 px high: the 24 px icon with 8 px above and below it,
    // and 12 px at the sides. The row is 46 px high, which leaves 6 px
    // between two buttons.
    property real implicitLeftInset: VLCStyle.dp(8, VLCStyle.scale)
    property real implicitRightInset: VLCStyle.dp(8, VLCStyle.scale)

    property real implicitTopInset: VLCStyle.dp(3, VLCStyle.scale)
    property real implicitBottomInset: VLCStyle.dp(3, VLCStyle.scale)

    // Accessible

    Accessible.onPressAction: control.clicked()
    AccessibleCompat.id: {
        if (model.depth !== 0 || !model.uri || model.uri.length === 0) return "";
        const navBarIds = {
            "home": "homeNavBar",
            "video": "videoNavBar",
            "music": "musicNavBar",
            "network": "browseNavBar",
            "discover": "discoverNavBar"
        }
        const id = navBarIds[model.uri[0]]
        if (id !== undefined)
            return id
        else
            return ""
    }

    // Tooltip

    T.ToolTip.visible: (showText === false && T.ToolTip.text && (hovered || visualFocus))

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    T.ToolTip.text: text

    // Childs

    ColorContext {
        id: theme
        colorSet: ColorContext.TabButton

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    background: Widgets.AnimatedBackground {
        enabled: theme.initialized
        color: theme.bg.primary
        border.color: visualFocus ? theme.visualFocus : "transparent"

        radius: control.radius
    }

    contentItem: RowLayout {
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        Item {
            // The icon with 4 px around it, as in the design
            Layout.preferredWidth: VLCStyle.dp(30, VLCStyle.scale)
            Layout.fillHeight: true

            Widgets.IconLabel {
                id: iconLabel

                visible: control.iconName === "" && text.length > 0

                anchors.centerIn: parent

                text: control.iconTxt

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                color: theme.fg.primary

                font.pixelSize: VLCStyle.icon_normal
            }

            Image {
                id: svgIcon

                visible: control.iconName !== ""

                anchors.centerIn: parent
                width: VLCStyle.icon_normal
                height: VLCStyle.icon_normal

                property real _eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

                sourceSize: Qt.size(width * _eDPR, height * _eDPR)

                // SVG colours can not be transparent, so the transparency of
                // the colour is applied to the image.
                opacity: theme.fg.primary.a

                readonly property color _color: Qt.rgba(theme.fg.primary.r, theme.fg.primary.g, theme.fg.primary.b, 1.0)

                source: {
                    if (control.iconName === "")
                        return ""
                    const builder = SVGColorImage.colorize("qrc:///redesign/nav-" + control.iconName
                                                           + (control.iconSelected ? "-selected" : "") + ".svg")
                    return (control.iconSelected ? builder.any({ "#D37918": _color, "#8F8F8F": control.panelColor })
                                                 : builder.any({ "#8F8F8F": _color })).uri()
                }

                Accessible.ignored: true
            }
        }

        T.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            text: control.text

            verticalAlignment: Text.AlignVCenter

            color: theme.fg.primary

            elide: Text.ElideRight

            visible: control.showText

            font.pixelSize: VLCStyle.fontSize_large

            font.weight: Font.Normal

            //button text is already exposed
            Accessible.ignored: true

            Behavior on color {
                enabled: theme.initialized

                ColorAnimation {
                    duration: VLCStyle.duration_short
                }
            }
        }
    }
}
