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
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Dialog {
    id: control

    property Item rootWindow: null

    focus: true
    modal: true


    anchors.centerIn: T.Overlay.overlay

    padding: VLCStyle.margin_normal
    margins: VLCStyle.margin_large

    implicitWidth: contentWidth > 0 ? contentWidth + leftPadding + rightPadding : 0
    implicitHeight: (header && header.visible ? header.implicitHeight + spacing : 0)
                    + (footer && footer.visible ? footer.implicitHeight + spacing : 0)
                    + (contentHeight > 0 ? contentHeight + topPadding + bottomPadding : 0)

    closePolicy: Popup.CloseOnEscape

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    T.Overlay.modal: Item {
        Rectangle {
            anchors.fill: blur

            visible: !blur.visible

            color: theme.bg.primary

            opacity: 0.6
        }

        Widgets.DualKawaseBlur {
            id: blur

            anchors.fill: parent
            anchors.margins: MainCtx.windowExtendedMargin

            visible: MainCtx.backdropBlurRequested() && blur.available

            mode: Widgets.DualKawaseBlur.Mode.SixPass

            source: ShaderEffectSource {
                sourceItem: blur.visible ? control.rootWindow : null
                live: true
                hideSource: true
            }

            radius: 2
        }
    }

    // Card of the design: 14 px radius, a darker bar with the title and a
    // close button at the top.
    background: Rectangle {
        color: theme.bg.primary
        radius: VLCStyle.dp(14, VLCStyle.scale)

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)

            visible: (parent.color.a > 0.0)

            color: Qt.rgba(0, 0, 0, 0.46)
        }
    }

    readonly property ColorContext headerContext: ColorContext {
        id: headerTheme
        palette: VLCStyle.palette
        // Slider bg.secondary is the darkest colour of the theme
        colorSet: ColorContext.Slider
    }

    header: Rectangle {
        visible: control.title

        // The header is not a child of the content, it needs its own colours
        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }
        implicitHeight: VLCStyle.dp(50, VLCStyle.scale)
        color: headerTheme.bg.secondary
        radius: VLCStyle.dp(14, VLCStyle.scale)

        // Square bottom corners
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: parent.color
        }

        T.Label {
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.dp(19, VLCStyle.scale)
            anchors.right: closeButton.left
            anchors.verticalCenter: parent.verticalCenter

            text: control.title
            elide: Label.ElideRight
            font.pixelSize: VLCStyle.fontSize_normal
            color: theme.fg.secondary
        }

        Widgets.SvgToolButton {
            id: closeButton

            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(9, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter

            width: VLCStyle.dp(32, VLCStyle.scale)
            height: width
            iconName: "close"
            description: qsTr("Close")
            onClicked: control.reject()
        }
    }

    exit: Transition {
        OpacityAnimator { from: 1.0; to: 0.0 }
    }
    enter: Transition {
        OpacityAnimator { from: 0.0; to: 1.0 }
    }
}
