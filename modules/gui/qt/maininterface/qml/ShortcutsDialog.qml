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
import VLC.Util

// "Keyboard Shortcuts" of the design: the hotkeys of VLC in groups, with a
// search field. A key is changed by clicking its box and pressing the new
// key; Delete or Backspace removes it. The configuration file is written when
// the dialog is closed.
T.Popup {
    id: root

    modal: true
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

    anchors.centerIn: T.Overlay.overlay

    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.width : 1048) - 2 * VLCStyle.margin_large)
    height: Math.min(VLCStyle.dp(800, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.height : 800) - 2 * VLCStyle.margin_large)

    padding: 0

    readonly property SettingsWidgets.Pal pal: SettingsWidgets.Pal { }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    // Option whose key is being changed
    property string editing: ""

    // Fields searched: 0 all, 1 action, 2 hotkey, 3 global hotkey
    property int searchField: 0

    readonly property string filter: searchField_.searchPattern.toLowerCase()

    readonly property ConfigOption helper: ConfigOption { }

    // Groups of the design, from the names of the options
    readonly property var groups: [
        { title: qsTr("Basic"), match: /^key-(toggle-fullscreen|leave-fullscreen|position|intf-show|intf-boss|intf-popup-menu|quit|nav-.*|disc-menu)$/ },
        { title: qsTr("Playback"), match: /^key-(play-pause|pause|play|stop|next|prev|faster|slower|rate-.*|jump.*|frame-.*|random|loop|title-.*|chapter-.*|program-.*|record|clear-playlist)$/ },
        { title: qsTr("Audio"), match: /^key-(vol-.*|audio.*)$/ },
        { title: qsTr("Subtitles"), match: /^key-(sub.*)$/ },
        { title: qsTr("Video"), match: /^key-(aspect-ratio|crop.*|uncrop.*|toggle-autoscale|incr-scalefactor|decr-scalefactor|deinterlace.*|snapshot|zoom.*|unzoom|wallpaper|projection-toggle|viewpoint-.*)$/ },
        { title: qsTr("Bookmarks"), match: /^key-(set|play)-bookmark.*$/ },
        { title: qsTr("Other"), match: /./ }
    ]

    readonly property var sections: {
        const all = helper.hotkeys()
        let used = {}
        let out = []
        for (const g of groups) {
            let items = []
            for (const k of all) {
                if (used[k.name] || !g.match.test(k.name))
                    continue
                used[k.name] = true
                items.push(k)
            }
            if (items.length > 0)
                out.push({ title: g.title, items: items })
        }
        return out
    }

    // Whether a shortcut matches the search
    function matches(k) {
        if (filter === "")
            return true
        const action = k.text.toLowerCase()
        const key = helper.keysText(helper.stringValue(k.name)).toLowerCase()
        const global = k.global ? helper.keysText(helper.stringValue(k.global)).toLowerCase() : ""
        switch (searchField) {
        case 1: return action.indexOf(filter) >= 0
        case 2: return key.indexOf(filter) >= 0
        case 3: return global.indexOf(filter) >= 0
        default: return action.indexOf(filter) >= 0 || key.indexOf(filter) >= 0 || global.indexOf(filter) >= 0
        }
    }

    onClosed: {
        editing = ""
        helper.save(MainCtx)
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
    }

    background: Rectangle {
        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: theme.bg.primary

        Widgets.RoundedRectangleShadow {
            z: -1
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.46)
        }
    }

    component KeyBox : Rectangle {
        id: keyBox

        property string optionName
        readonly property ConfigOption option: ConfigOption { name: keyBox.optionName }
        readonly property bool active: root.editing !== "" && root.editing === optionName

        Layout.preferredWidth: VLCStyle.dp(270, VLCStyle.scale)
        Layout.preferredHeight: VLCStyle.dp(33, VLCStyle.scale)

        visible: optionName !== ""
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: root.pal.box
        border.width: active ? VLCStyle.dp(1, VLCStyle.scale) : 0
        border.color: theme.accent

        Text {
            anchors.centerIn: parent
            width: parent.width - 2 * VLCStyle.dp(44, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: keyBox.active ? qsTr("Press a key") : root.helper.keysText(String(keyBox.option.value ?? ""))
            font.pixelSize: VLCStyle.fontSize_normal
            color: keyBox.active ? theme.accent : root.pal.heading
        }

        SettingsWidgets.Icon {
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(5, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            name: "edit"
            color: keyBox.active ? theme.accent : root.pal.dim
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.editing = keyBox.active ? "" : keyBox.optionName
                keyCatcher.forceActiveFocus()
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: root.helper.keysText(String(option.value ?? ""))
    }

    // Receives the new key while a box is selected
    Item {
        id: keyCatcher

        Keys.onPressed: (event) => {
            if (root.editing === "")
                return
            event.accepted = true

            if (event.key === Qt.Key_Escape) {
                root.editing = ""
                return
            }

            // Wait for the key that goes with the modifiers
            if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control || event.key === Qt.Key_Alt
                    || event.key === Qt.Key_Meta || event.key === Qt.Key_AltGr)
                return

            const option = Qt.createQmlObject("import VLC.Util; ConfigOption { }", keyCatcher)
            option.name = root.editing
            if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)
                option.value = ""
            else
                option.value = root.helper.keyName(event.key, event.modifiers, event.text)
            option.destroy()

            // Refresh the boxes
            const name = root.editing
            root.editing = ""
            root.sectionsChanged()
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        readonly property ColorContext colorContext: ColorContext {
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
        }

        // Header with the title, the search field and the choice of the field
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(96, VLCStyle.scale)

            radius: VLCStyle.dp(14, VLCStyle.scale)
            color: root.pal.header

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(9, VLCStyle.scale)
                spacing: VLCStyle.dp(12, VLCStyle.scale)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                    Widgets.LabelExt {
                        Layout.fillWidth: true
                        leftPadding: VLCStyle.dp(10, VLCStyle.scale)
                        text: qsTr("Keyboard Shortcuts")
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: root.pal.label
                    }

                    Widgets.SvgToolButton {
                        Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
                        iconName: "close"
                        description: qsTr("Close")
                        onClicked: root.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(10, VLCStyle.scale)

                    Widgets.SearchField {
                        id: searchField_
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                        textField.placeholderText: qsTr("Search Keyboard Shortcuts...")
                        focus: true
                    }

                    SettingsWidgets.Dropdown {
                        Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                        entries: [{ value: 0, text: qsTr("All Fields") }, { value: 1, text: qsTr("Action") },
                                  { value: 2, text: qsTr("Hotkey") }, { value: 3, text: qsTr("Global Hotkey") }]
                        selectedValue: root.searchField
                        onPicked: (v) => root.searchField = v
                    }
                }
            }
        }

        // Column titles
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            spacing: VLCStyle.dp(20, VLCStyle.scale)

            Widgets.LabelExt { Layout.fillWidth: true; text: qsTr("Action"); color: root.pal.dim; font.pixelSize: VLCStyle.fontSize_normal }
            Widgets.LabelExt { Layout.preferredWidth: VLCStyle.dp(270, VLCStyle.scale); text: qsTr("Hotkey"); color: root.pal.dim; font.pixelSize: VLCStyle.fontSize_normal }
            Widgets.LabelExt { Layout.preferredWidth: VLCStyle.dp(270, VLCStyle.scale); text: qsTr("Global Hotkey"); color: root.pal.dim; font.pixelSize: VLCStyle.fontSize_normal }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)

            clip: true
            contentHeight: sectionColumn.implicitHeight + VLCStyle.dp(20, VLCStyle.scale)
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            ColumnLayout {
                id: sectionColumn

                x: VLCStyle.dp(20, VLCStyle.scale)
                width: parent.width - 2 * x
                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Repeater {
                    model: root.sections

                    delegate: ColumnLayout {
                        id: section

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(14, VLCStyle.scale)

                        visible: { void root.filter; void root.searchField; return section.modelData.items.some((k) => root.matches(k)) }

                        Widgets.LabelExt {
                            Layout.fillWidth: true
                            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)
                            text: section.modelData.title
                            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                            color: root.pal.title
                        }

                        ColumnLayout {
                            id: rows

                            Layout.fillWidth: true
                            spacing: VLCStyle.dp(14, VLCStyle.scale)

                            Repeater {
                                model: section.modelData.items

                                delegate: RowLayout {
                                    id: shortcut

                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: VLCStyle.dp(20, VLCStyle.scale)

                                    visible: root.matches(modelData)

                                    Widgets.LabelExt {
                                        Layout.fillWidth: true
                                        text: shortcut.modelData.text
                                        elide: Text.ElideRight
                                        font.pixelSize: VLCStyle.fontSize_normal
                                        color: root.pal.heading
                                    }

                                    KeyBox { id: hotkey; optionName: shortcut.modelData.name }

                                    KeyBox {
                                        id: globalKey
                                        optionName: shortcut.modelData.global
                                        visible: true
                                        opacity: optionName !== "" ? 1 : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)

            SettingsWidgets.Button {
                text: qsTr("Reset all shortcuts")
                onClicked: {
                    for (const s of root.sections)
                        for (const k of s.items) {
                            const o = Qt.createQmlObject("import VLC.Util; ConfigOption { }", root)
                            o.name = k.name
                            o.resetToDefault()
                            if (k.global) { o.name = k.global; o.resetToDefault() }
                            o.destroy()
                        }
                    root.sectionsChanged()
                }
            }

            Item { Layout.fillWidth: true }

            SettingsWidgets.Button {
                text: qsTr("Close")
                onClicked: root.close()
            }
        }
    }
}
