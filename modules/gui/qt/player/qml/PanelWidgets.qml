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

// Controls used in the pages of the player panels. Use them as
// PanelWidgets.Page, PanelWidgets.LabeledRow, PanelWidgets.Switch, and so on.
QtObject {

    // Colours shared by the controls.
    component Theme : ColorContext {
        colorSet: ColorContext.Window
    }

    component BoxTheme : ColorContext {
        // Slider bg.secondary is the colour of input boxes (black in the dark theme).
        colorSet: ColorContext.Slider
    }

    // Scrollable page with a column of rows.
    component Page : Flickable {
        id: page

        default property alias rows: column.data
        property alias spacing: column.spacing

        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight + VLCStyle.margin_normal
        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        ColumnLayout {
            id: column

            width: page.width
            spacing: 0
        }
    }

    // Grey caption above a group of rows, with optional buttons on the right.
    component Section : RowLayout {
        id: section

        property alias text: label.text
        default property alias actions: actionRow.data

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(60, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(28, VLCStyle.scale)

        readonly property ColorContext colorContext: Theme { id: sectionTheme }

        Widgets.ListLabel {
            font.weight: Font.Normal
            id: label
            Layout.fillWidth: true
            color: sectionTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        Row {
            id: actionRow
            spacing: VLCStyle.margin_normal
        }
    }

    // Horizontal line between groups of rows.
    component Separator : Rectangle {
        Layout.fillWidth: true
        implicitHeight: VLCStyle.border
        color: separatorTheme.separator

        readonly property ColorContext colorContext: Theme { id: separatorTheme }
    }

    // Small icon button used in section headers.
    component IconButton : Widgets.IconToolButton {
        font.pixelSize: VLCStyle.icon_normal
        width: VLCStyle.icon_normal + VLCStyle.margin_xxsmall
        height: width
    }

    // Row with a label on the left and a control on the right.
    component LabeledRow : RowLayout {
        id: row

        property alias text: rowLabel.text

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(52, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: VLCStyle.margin_small

        readonly property ColorContext colorContext: Theme { id: rowTheme }

        Widgets.ListLabel {
            font.weight: Font.Normal
            id: rowLabel
            Layout.fillWidth: true
            color: rowTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
    }

    // ON/OFF box with a sliding block, 68x32.
    component Switch : T.Switch {
        id: control

        implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        readonly property ColorContext colorContext: BoxTheme {
            id: switchTheme
            enabled: control.enabled
        }
        readonly property ColorContext accentContext: ColorContext {
            id: accentTheme
            colorSet: ColorContext.ButtonAccent
            enabled: control.enabled
        }

        readonly property real inset: VLCStyle.dp(3, VLCStyle.scale)

        indicator: Rectangle {
            anchors.fill: parent
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: switchTheme.bg.secondary
            border.width: control.visualFocus ? VLCStyle.focus_border : 0
            border.color: switchTheme.visualFocus

            opacity: control.enabled ? 1 : 0.5

            // Unused side, dim accent
            Rectangle {
                x: control.checked ? control.inset : parent.width - width - control.inset
                y: control.inset
                width: parent.width - knob.width - 3 * control.inset
                height: parent.height - 2 * control.inset
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: switchTheme.fg.secondary

                Widgets.ListLabel {
                    font.weight: Font.Normal
                    anchors.centerIn: parent
                    text: control.checked ? qsTr("ON") : qsTr("OFF")
                    color: switchTheme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_normal
                }
            }

            Rectangle {
                id: knob

                x: control.checked ? parent.width - width - control.inset : control.inset
                y: control.inset
                width: parent.height - 2 * control.inset
                height: width
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: control.checked ? accentTheme.bg.primary : Qt.darker(accentTheme.bg.primary, 1.25)

                Behavior on x {
                    NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.InOutSine }
                }
            }
        }

        contentItem: null
    }

    // Drop-down list in a black box, 220x48.
    // Use either `choices` (a VLCVarChoiceModel, TrackListModel or any model
    // with `display` and `checked` roles) or `model` with `currentIndex`.
    component ComboBox : T.ComboBox {
        id: control

        // Model that marks the current entry with the `checked` role.
        property var choices: null

        implicitWidth: VLCStyle.dp(220, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(48, VLCStyle.scale)

        model: choices
        textRole: choices ? "display" : ""

        enabled: count > 0

        readonly property ColorContext colorContext: BoxTheme {
            id: comboTheme
            enabled: control.enabled
        }
        readonly property ColorContext popupContext: Theme { id: popupTheme }

        // Follow the `checked` role of the choices model.
        function _checkedIndex() {
            if (!choices)
                return currentIndex
            for (let i = 0; i < count; ++i) {
                const checked = choices.data(choices.index(i, 0), Qt.CheckStateRole)
                if (checked)
                    return i
            }
            return -1
        }

        Connections {
            target: control.choices
            enabled: !!control.choices
            function onDataChanged() { control.currentIndex = control._checkedIndex() }
            function onModelReset() { control.currentIndex = control._checkedIndex() }
            function onRowsInserted() { control.currentIndex = control._checkedIndex() }
        }
        onCountChanged: if (choices) currentIndex = _checkedIndex()
        Component.onCompleted: if (choices) currentIndex = _checkedIndex()

        onActivated: (index) => {
            if (choices)
                choices.setData(choices.index(index, 0), true, Qt.CheckStateRole)
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: comboTheme.bg.secondary
            border.width: control.visualFocus ? VLCStyle.focus_border : 0
            border.color: comboTheme.visualFocus
            opacity: control.enabled ? 1 : 0.5
        }

        contentItem: Widgets.ListLabel {
            font.weight: Font.Normal
            leftPadding: VLCStyle.margin_normal
            rightPadding: control.indicator.width + VLCStyle.margin_xsmall
            text: control.displayText
            color: popupTheme.fg.primary
            font.pixelSize: VLCStyle.fontSize_large
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Widgets.IconLabel {
            x: control.width - width - VLCStyle.margin_small
            y: (control.height - height) / 2
            text: VLCIcons.chevron_down
            color: popupTheme.fg.secondary
            font.pixelSize: VLCStyle.icon_small
        }

        delegate: T.ItemDelegate {
            id: entry

            required property int index
            required property var model

            width: ListView.view.width
            implicitHeight: VLCStyle.dp(44, VLCStyle.scale)
            highlighted: control.highlightedIndex === index

            contentItem: Widgets.ListLabel {
                font.weight: Font.Normal
                leftPadding: VLCStyle.margin_small
                text: control.choices ? entry.model.display
                                      : (control.textRole ? entry.model[control.textRole] : entry.model.modelData)
                color: (entry.index === control.currentIndex) ? popupTheme.accent : popupTheme.fg.primary
                font.pixelSize: VLCStyle.fontSize_large
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: (entry.highlighted || entry.index === control.currentIndex)
                       ? comboTheme.bg.secondary : "transparent"
            }
        }

        popup: T.Popup {
            y: control.height + VLCStyle.margin_xxxsmall
            width: control.width
            implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                                     VLCStyle.dp(300, VLCStyle.scale))
            padding: VLCStyle.dp(2, VLCStyle.scale)

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.delegateModel
                currentIndex: control.highlightedIndex
                spacing: VLCStyle.dp(2, VLCStyle.scale)
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: Widgets.ScrollBarExt { }
            }

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: popupTheme.bg.primary
                border.width: VLCStyle.border
                border.color: popupTheme.border
            }
        }
    }

    // List of choices with a check mark on the selected ones. `model` needs
    // the `display` and `checked` roles (TrackListModel, AudioDeviceModel).
    component CheckList : ColumnLayout {
        id: list

        property alias model: repeater.model
        property string emptyText: ""

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: VLCStyle.margin_small

        readonly property ColorContext colorContext: Theme { id: listTheme }

        Widgets.ListLabel {
            font.weight: Font.Normal
            visible: repeater.count === 0 && list.emptyText !== ""
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.margin_xsmall
            text: list.emptyText
            color: listTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        Repeater {
            id: repeater

            delegate: T.ItemDelegate {
                id: item

                required property var model
                required property int index

                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                focusPolicy: Qt.StrongFocus

                Accessible.role: Accessible.CheckBox
                Accessible.checked: item.model.checked
                Accessible.name: item.model.display

                onClicked: item.model.checked = !item.model.checked

                readonly property ColorContext colorContext: ColorContext {
                    id: itemTheme
                    colorSet: ColorContext.Item
                    hovered: item.hovered
                    focused: item.visualFocus
                }

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: itemTheme.bg.primary
                    border.width: item.visualFocus ? VLCStyle.focus_border : 0
                    border.color: itemTheme.visualFocus
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.margin_xsmall

                    Widgets.IconLabel {
                        Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                        horizontalAlignment: Text.AlignHCenter
                        text: VLCIcons.check
                        font.pixelSize: VLCStyle.icon_normal * 0.8
                        color: item.model.checked ? listTheme.accent : listTheme.fg.secondary.alpha(0.35)
                    }

                    Widgets.ListLabel {
                        font.weight: Font.Normal
                        Layout.fillWidth: true
                        text: item.model.display
                        color: listTheme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // Value with "-" and "+" buttons, for delays.
    component Stepper : RowLayout {
        id: stepper

        property string valueText
        signal decrease()
        signal increase()
        signal reset()

        spacing: VLCStyle.margin_xxsmall

        readonly property ColorContext colorContext: BoxTheme { id: stepperTheme }

        IconButton {
            text: VLCIcons.remove
            description: qsTr("Decrease")
            onClicked: stepper.decrease()
        }

        Rectangle {
            implicitWidth: VLCStyle.dp(100, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: stepperTheme.bg.secondary

            Widgets.ListLabel {
                font.weight: Font.Normal
                anchors.centerIn: parent
                text: stepper.valueText
                color: popupTheme.fg.primary
                font.pixelSize: VLCStyle.fontSize_large
            }

            TapHandler {
                // Double click sets the value back to zero.
                onDoubleTapped: stepper.reset()
            }

            readonly property ColorContext textContext: Theme { id: popupTheme }
        }

        IconButton {
            text: VLCIcons.add
            description: qsTr("Increase")
            onClicked: stepper.increase()
        }
    }

    // Full width button at the bottom of a page.
    // Row with a text and a chevron, in the colour of the input boxes. It
    // opens a page or a dialog with more settings ("Expand Settings").
    component ExpandRow : T.Button {
        id: expandRow

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)

        implicitHeight: VLCStyle.dp(46, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        readonly property ColorContext colorContext: BoxTheme {
            id: expandTheme
            hovered: expandRow.hovered
            focused: expandRow.visualFocus
            pressed: expandRow.down
        }

        // The text uses the colours of the panel, not the ones of the boxes
        readonly property ColorContext textContext: Theme { id: expandTextTheme }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: expandTheme.bg.secondary
            border.width: expandRow.visualFocus ? VLCStyle.focus_border : 0
            border.color: expandTheme.visualFocus
        }

        contentItem: RowLayout {
            Widgets.ListLabel {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.margin_normal

                font.weight: Font.Normal
                text: expandRow.text
                color: expandTextTheme.fg.primary
                font.pixelSize: VLCStyle.fontSize_normal
            }

            Image {
                Layout.rightMargin: VLCStyle.margin_normal
                Layout.preferredWidth: VLCStyle.dp(20, VLCStyle.scale)
                Layout.preferredHeight: Layout.preferredWidth

                property real _eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

                sourceSize: Qt.size(width * _eDPR, height * _eDPR)
                source: SVGColorImage.colorize("qrc:///redesign/chevron-right.svg")
                                     .any({ "#8F8F8F": Qt.rgba(expandTextTheme.fg.secondary.r, expandTextTheme.fg.secondary.g, expandTextTheme.fg.secondary.b, 1.0) })
                                     .uri()

                Accessible.ignored: true
            }
        }
    }

    component WideButton : T.Button {
        id: button

        property string iconText: VLCIcons.settings

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(20, VLCStyle.scale)

        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        readonly property ColorContext colorContext: ColorContext {
            id: buttonTheme
            colorSet: ColorContext.ToolButton
            hovered: button.hovered
            focused: button.visualFocus
            pressed: button.down
        }

        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: buttonTheme.bg.primary
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: buttonTheme.visualFocus
        }

        contentItem: Item {
            implicitHeight: buttonRow.implicitHeight

            Row {
                id: buttonRow
                anchors.centerIn: parent
                spacing: VLCStyle.margin_xsmall

                Widgets.IconLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    text: button.iconText
                    color: buttonTheme.fg.primary
                    font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                }

                Widgets.ListLabel {
                    font.weight: Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                    text: button.text
                    color: buttonTheme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_large
                }
            }
        }
    }
}
