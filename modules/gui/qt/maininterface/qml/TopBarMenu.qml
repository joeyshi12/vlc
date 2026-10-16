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
import VLC.Dialogs
import VLC.Style
import VLC.Widgets as Widgets

// Main overflow menu. It uses the same surfaces, spacing, rounded corners and
// focus treatment as the rest of the redesigned interface.
T.Popup {
    id: root

    x: 0
    y: parent ? parent.height + VLCStyle.dp(4, VLCStyle.scale) : 0

    implicitWidth: VLCStyle.dp(265, VLCStyle.scale)
    implicitHeight: contentColumn.implicitHeight + topPadding + bottomPadding

    padding: VLCStyle.dp(4, VLCStyle.scale)

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    focus: true

    required property Item overlayParent

    readonly property bool _dark: VLCStyle.palette.isDark
    // Opaque popup surfaces avoid blending the full menu on every pointer
    // move. This matches the solid panel surfaces used by the application.
    readonly property color _surface: _dark ? "#191919" : "#D5D5D5"
    readonly property color _hoverSurface: _dark ? "#2A2A2A" : "#E0E0E0"
    readonly property color _text: _dark ? "#EAEAEA" : "#2E2E2E"
    readonly property color _mutedText: _dark ? "#8F8F8F" : "#3C3C3C"
    readonly property color _divider: _dark ? "#222222" : "#ACACAC"

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    component MenuEntry : T.ItemDelegate {
        id: entry

        required property string iconText
        signal triggered()

        width: root.availableWidth
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        topPadding: VLCStyle.dp(8, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(8, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus
        hoverEnabled: false

        HoverHandler {
            id: entryHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
        }

        onClicked: {
            root.close()
            triggered()
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: entry.down || entryHover.hovered ? root._hoverSurface : "transparent"
            border.width: entry.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.IconLabel {
                Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)

                text: entry.iconText
                // Keep the glyph node unchanged while the pointer moves.
                color: entry.visualFocus ? theme.accent : root._mutedText
                font.pixelSize: VLCStyle.icon_normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Widgets.LabelExt {
                Layout.fillWidth: true

                text: entry.text
                color: root._text
                font.pixelSize: VLCStyle.fontSize_normal
                font.weight: Font.Normal
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    component MenuSeparator : Rectangle {
        implicitHeight: VLCStyle.dp(1, VLCStyle.scale)
        color: root._divider

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
        Layout.topMargin: VLCStyle.dp(4, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(4, VLCStyle.scale)
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._surface

        border.width: VLCStyle.dp(1, VLCStyle.scale)
        border.color: root._divider
    }

    contentItem: ColumnLayout {
        id: contentColumn

        spacing: 0

        MenuEntry {
            iconText: VLCIcons.add
            text: qsTr("Open File...")
            onTriggered: DialogsProvider.simpleOpenDialog()
        }

        MenuEntry {
            iconText: VLCIcons.dvd_menu
            text: qsTr("Open Disc...")
            onTriggered: DialogsProvider.openDiscDialog()
        }

        MenuEntry {
            iconText: VLCIcons.stream
            text: qsTr("Open Network Stream...")
            onTriggered: DialogsProvider.openNetDialog()
        }

        MenuSeparator { }

        MenuEntry {
            iconText: VLCIcons.effect_filter
            text: qsTr("Customize Player")
            onTriggered: DialogsProvider.showToolbarEditorDialog()
        }

        MenuEntry {
            iconText: VLCIcons.settings
            text: qsTr("Settings")
            onTriggered: root.openSettings()
        }

        MenuSeparator { }

        MenuEntry {
            iconText: VLCIcons.info
            text: qsTr("About VLC")
            onTriggered: DialogsProvider.aboutDialog()
        }

        MenuEntry {
            iconText: VLCIcons.close
            text: qsTr("Quit VLC")
            onTriggered: DialogsProvider.quit()
        }
    }

    property var _settingsDialog: null
    property var _settingsClosedHandler: null

    function openSettings() {
        // A close schedules the unused dialog for deletion. Cancel that work
        // when Settings is opened again before the timer expires.
        settingsUnloadTimer.stop()

        if (!_settingsDialog) {
            const component = Qt.createComponent("qrc:///qt/qml/VLC/MainInterface/SettingsDialog.qml")
            if (component.status !== Component.Ready) {
                console.warn("Unable to open Settings:", component.errorString())
                return
            }
            _settingsDialog = component.createObject(root.overlayParent)
            _settingsClosedHandler = () => settingsUnloadTimer.restart()
            _settingsDialog.closed.connect(_settingsClosedHandler)
        }
        _settingsDialog.open()
    }

    // SettingsDialog saves preferences 100 ms after it closes. Unload the
    // dialog after that work so the menu stays lightweight between uses.
    Timer {
        id: settingsUnloadTimer
        interval: VLCStyle.duration_veryLong
        repeat: false
        onTriggered: {
            if (root._settingsDialog && !root._settingsDialog.opened) {
                root._settingsDialog.closed.disconnect(root._settingsClosedHandler)
                root._settingsDialog.destroy()
                root._settingsDialog = null
                root._settingsClosedHandler = null
            }
        }
    }

    Component.onDestruction: {
        if (_settingsDialog) {
            _settingsDialog.closed.disconnect(_settingsClosedHandler)
            _settingsDialog.destroy()
            _settingsDialog = null
            _settingsClosedHandler = null
        }
    }
}
