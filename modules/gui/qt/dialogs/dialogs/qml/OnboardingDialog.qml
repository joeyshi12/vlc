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
import VLC.Dialogs
import VLC.Util

// Onboarding of the design, shown on the first start instead of the first run
// wizard: welcome and media folder, theme and accent colour, basic keyboard
// shortcuts.
T.Popup {
    id: root

    modal: true
    focus: true
    closePolicy: T.Popup.NoAutoClose

    anchors.centerIn: T.Overlay.overlay

    width: Math.min(VLCStyle.dp(1090, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.width : 1090) - 2 * VLCStyle.margin_large)
    height: Math.min(VLCStyle.dp(759, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.height : 759) - 2 * VLCStyle.margin_large)

    padding: 0

    property int step: 0
    readonly property int stepCount: 3

    // Folder added to the media library when the onboarding is finished
    property string folderUrl: ""

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    readonly property bool dark: VLCStyle.palette.isDark
    readonly property color pageColor: dark ? "#0E0E0E" : "#E7E7E7"
    readonly property color boxColor: dark ? "#090909" : "#DEDEDE"
    readonly property color keyColor: dark ? "#1B1B1B" : "#D5D5D5"
    readonly property color keyBorder: dark ? "#373737" : "#ACACAC"
    readonly property color strongText: dark ? "#EAEAEA" : "#2E2E2E"
    readonly property color text: dark ? "#969696" : "#3C3C3C"
    readonly property color dimText: "#6B6B6B"

    function finish() {
        if (folderUrl !== "" && MainCtx.mediaLibraryAvailable) {
            const model = Qt.createQmlObject("import VLC.MediaLibrary; MLFolderModel { }", root)
            model.ctx = MainCtx
            model.add(folderUrl)
        }
        DialogsProvider.finishOnboarding(networkSwitch.checked)
        close()
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    background: Rectangle {
        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: root.pageColor

        Widgets.RoundedRectangleShadow {
            z: -1
            blurRadius: VLCStyle.dp(11.8, VLCStyle.scale)
            yOffset: VLCStyle.dp(4, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.38)
        }
    }

    component AccentButton : T.Button {
        id: accentButton

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), implicitContentWidth + VLCStyle.dp(32, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: theme.accent
            border.width: accentButton.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: Text {
            text: accentButton.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.DemiBold
            color: "#161616"
        }
    }

    component PlainButton : T.Button {
        id: plainButton

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), implicitContentWidth + VLCStyle.dp(32, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: plainButton.hovered ? Qt.lighter(root.keyColor, 1.2) : root.keyColor
            border.width: plainButton.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: Text {
            text: plainButton.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            color: root.text
        }
    }

    component Key : Rectangle {
        property alias text: keyText.text

        implicitWidth: Math.max(VLCStyle.dp(57, VLCStyle.scale), keyText.implicitWidth + VLCStyle.dp(40, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
        radius: VLCStyle.dp(12, VLCStyle.scale)
        color: root.keyColor
        border.width: VLCStyle.dp(3, VLCStyle.scale)
        border.color: root.keyBorder

        Text {
            id: keyText
            anchors.centerIn: parent
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            color: root.text
        }
    }

    component Shortcut : RowLayout {
        property string action
        property var keys: []

        spacing: VLCStyle.dp(20, VLCStyle.scale)

        Text {
            Layout.preferredWidth: VLCStyle.dp(220, VLCStyle.scale)
            text: parent.action
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Light
            color: root.text
            elide: Text.ElideRight
        }

        Row {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Repeater {
                model: parent.parent.keys

                delegate: Row {
                    required property int index
                    required property string modelData
                    spacing: VLCStyle.dp(10, VLCStyle.scale)

                    Text {
                        visible: index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/"
                        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                        color: root.dimText
                    }

                    Key { text: modelData }
                }
            }
        }
    }

    contentItem: Item {
        StackLayout {
            anchors.fill: parent
            anchors.bottomMargin: VLCStyle.dp(88, VLCStyle.scale)
            currentIndex: root.step

            // Welcome
            Item {
                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: VLCStyle.dp(116, VLCStyle.scale)
                    width: Math.min(parent.width - 2 * VLCStyle.margin_large, VLCStyle.dp(595, VLCStyle.scale))
                    spacing: 0

                    Widgets.BannerCone {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: VLCStyle.dp(141, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(141, VLCStyle.scale)
                        sourceSize.width: VLCStyle.dp(141, VLCStyle.scale)
                        sourceSize.height: VLCStyle.dp(141, VLCStyle.scale)
                        color: theme.accent
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: VLCStyle.dp(29, VLCStyle.scale)
                        text: qsTr("Welcome to VLC!")
                        font.pixelSize: VLCStyle.dp(32, VLCStyle.scale)
                        font.weight: Font.Light
                        color: root.strongText
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: qsTr("VLC is a free and open source cross-platform multimedia player and framework that plays most multimedia files as well as DVDs, Audio CDs, VCDs, and various streaming protocols.")
                        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                        font.weight: Font.Light
                        color: root.text
                    }

                    Text {
                        Layout.topMargin: VLCStyle.dp(48, VLCStyle.scale)
                        visible: MainCtx.mediaLibraryAvailable
                        text: qsTr("Choose a Media Folder to get started with")
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: root.text
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
                        visible: MainCtx.mediaLibraryAvailable
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: VLCStyle.dp(36, VLCStyle.scale)
                            radius: VLCStyle.dp(6, VLCStyle.scale)
                            color: root.boxColor
                            border.width: VLCStyle.dp(2, VLCStyle.scale)
                            border.color: root.keyColor

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: VLCStyle.dp(14, VLCStyle.scale)
                                anchors.right: parent.right
                                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideMiddle
                                text: root.folderUrl !== "" ? decodeURIComponent(root.folderUrl.replace(/^file:\/\//, ""))
                                                            : qsTr("No folder")
                                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                                color: root.folderUrl !== "" ? root.strongText : root.dimText
                            }
                        }

                        PlainButton {
                            text: qsTr("Browse")
                            onClicked: {
                                const url = DialogsProvider.getFolderUrl()
                                if (url !== "")
                                    root.folderUrl = url
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.dp(24, VLCStyle.scale)
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Fetch titles and cover art from the internet")
                            font.pixelSize: VLCStyle.fontSize_normal
                            color: root.text
                            wrapMode: Text.WordWrap
                        }

                        SettingsWidgets.Switch {
                            id: networkSwitch
                            bindOption: false
                            checked: true
                        }
                    }
                }
            }

            // Theme and colour
            Item {
                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: VLCStyle.dp(173, VLCStyle.scale)
                    spacing: VLCStyle.dp(71, VLCStyle.scale)

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Select your preferred theme and color.")
                        font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
                        font.weight: Font.Light
                        color: root.text
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: VLCStyle.dp(40, VLCStyle.scale)

                        Repeater {
                            // The rows of the colour scheme model are System, Day, Night
                            model: [
                                { text: qsTr("Light"), row: 1, color: "#AFAFAF" },
                                { text: qsTr("Dark"), row: 2, color: "#222222" },
                                { text: qsTr("System"), row: 0, color: "" }
                            ]

                            delegate: Column {
                                id: schemeChoice

                                required property var modelData

                                readonly property bool current: MainCtx.colorScheme.data(MainCtx.colorScheme.index(modelData.row, 0), Qt.CheckStateRole) === Qt.Checked
                                                                && MainCtx.colorScheme.scheme !== undefined

                                spacing: VLCStyle.dp(22, VLCStyle.scale)

                                Rectangle {
                                    width: VLCStyle.dp(116, VLCStyle.scale)
                                    height: width
                                    radius: VLCStyle.dp(19, VLCStyle.scale)
                                    color: "transparent"
                                    border.width: VLCStyle.dp(4, VLCStyle.scale)
                                    border.color: schemeChoice.current ? theme.accent : "transparent"

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: VLCStyle.dp(100, VLCStyle.scale)
                                        height: width
                                        radius: VLCStyle.dp(12, VLCStyle.scale)
                                        color: schemeChoice.modelData.color !== "" ? schemeChoice.modelData.color : "#AFAFAF"
                                        gradient: schemeChoice.modelData.color !== "" ? null : systemGradient

                                        Gradient {
                                            id: systemGradient
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.5; color: "#AFAFAF" }
                                            GradientStop { position: 0.501; color: "#222222" }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: MainCtx.colorScheme.setData(MainCtx.colorScheme.index(schemeChoice.modelData.row, 0), true, Qt.CheckStateRole)
                                    }
                                }

                                Text {
                                    width: VLCStyle.dp(116, VLCStyle.scale)
                                    horizontalAlignment: Text.AlignHCenter
                                    text: schemeChoice.modelData.text
                                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                                    font.weight: Font.Light
                                    color: root.text
                                }
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: VLCStyle.dp(12, VLCStyle.scale)

                        readonly property ConfigOption accent: ConfigOption { name: "qt-accent-color" }

                        Repeater {
                            model: ["#D37918", "#E15032", "#C49E23", "#19A234", "#18AAD3", "#185DD3", "#8E42FF", "#F052B3", "#AFAFAF"]

                            delegate: Rectangle {
                                id: colorChoice

                                required property int index
                                required property string modelData

                                readonly property bool current: {
                                    const v = String(parent.accent.value).toUpperCase()
                                    return v === modelData || (index === 0 && v === "DEFAULT")
                                }

                                width: VLCStyle.dp(40, VLCStyle.scale)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: VLCStyle.dp(3, VLCStyle.scale)
                                border.color: current ? modelData : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: VLCStyle.dp(28, VLCStyle.scale)
                                    height: width
                                    radius: width / 2
                                    color: colorChoice.modelData
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: colorChoice.parent.accent.value = (colorChoice.index === 0) ? "default" : colorChoice.modelData
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("The accent color is used after VLC is started again.")
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: root.dimText
                    }
                }
            }

            // Keyboard shortcuts
            Item {
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: VLCStyle.dp(60, VLCStyle.scale)
                    text: qsTr("Learn the basic keyboard shortcuts.")
                    font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
                    color: root.text
                }

                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: VLCStyle.dp(154, VLCStyle.scale)
                    spacing: VLCStyle.dp(80, VLCStyle.scale)

                    ColumnLayout {
                        spacing: VLCStyle.dp(40, VLCStyle.scale)
                        Shortcut { action: qsTr("Play / Pause"); keys: [qsTr("Space")] }
                        Shortcut { action: qsTr("Seek Backward / Forward"); keys: ["\u2190", "\u2192"] }
                        Shortcut { action: qsTr("Previous / Next Item"); keys: ["P", "N"] }
                        Shortcut { action: qsTr("Previous / Next Frame"); keys: ["Shift+E", "E"] }
                        Shortcut { action: qsTr("Cycle Subtitle Track"); keys: ["V"] }
                        Shortcut { action: qsTr("Cycle Audio Track"); keys: ["B"] }
                    }

                    ColumnLayout {
                        spacing: VLCStyle.dp(40, VLCStyle.scale)
                        Shortcut { action: qsTr("Toggle Fullscreen"); keys: ["F"] }
                        Shortcut { action: qsTr("Increase / Decrease Volume"); keys: ["Ctrl+\u2191", "Ctrl+\u2193"] }
                        Shortcut { action: qsTr("Mute"); keys: ["M"] }
                        Shortcut { action: qsTr("Take a Snapshot"); keys: ["Shift+S"] }
                        Shortcut { action: qsTr("Record"); keys: ["Shift+R"] }
                        Shortcut { action: qsTr("Quit"); keys: ["Ctrl+Q"] }
                    }
                }
            }
        }

        // Footer: steps on the left, the buttons on the right
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: VLCStyle.dp(41, VLCStyle.scale)
            anchors.bottomMargin: VLCStyle.dp(56, VLCStyle.scale)
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Text {
                visible: root.step === root.stepCount - 1
                text: qsTr("Find the full list in the settings.")
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                color: root.dimText
            }

            Row {
                visible: root.step < root.stepCount - 1
                spacing: VLCStyle.dp(8, VLCStyle.scale)

                Repeater {
                    model: root.stepCount

                    delegate: Rectangle {
                        required property int index
                        width: index === root.step ? VLCStyle.dp(24, VLCStyle.scale) : VLCStyle.dp(8, VLCStyle.scale)
                        height: VLCStyle.dp(8, VLCStyle.scale)
                        radius: height / 2
                        color: index === root.step ? theme.accent : root.keyBorder
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlainButton {
                visible: root.step > 0
                text: qsTr("Back")
                onClicked: root.step--
            }

            AccentButton {
                focus: true
                text: root.step === root.stepCount - 1 ? qsTr("Finish") : qsTr("Next")
                onClicked: {
                    if (root.step === root.stepCount - 1)
                        root.finish()
                    else
                        root.step++
                }
            }
        }
    }
}
