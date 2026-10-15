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
import QtQuick.Window

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

// Controls of the settings dialog (SettingsDialog.qml). Most of them take a
// ConfigOption and read and write it directly.
QtObject {

    // Colours of the design, for the dark and the light theme
    component Pal : QtObject {
        readonly property bool dark: VLCStyle.palette.isDark

        readonly property color window: dark ? "#0E0E0E" : "#E7E7E7"
        readonly property color header: dark ? "#000000" : "#DEDEDE"
        readonly property color panel: dark ? "#191919" : "#D5D5D5"
        readonly property color selected: dark ? "#222222" : "#E7E7E7"
        readonly property color box: dark ? "#090909" : "#DEDEDE"
        readonly property color boxInner: dark ? "#191919" : "#D5D5D5"
        readonly property color groupText: "#6B6B6B"
        readonly property color itemText: dark ? "#EAEAEA" : "#2E2E2E"
        readonly property color heading: dark ? "#C6C6C6" : "#2E2E2E"
        readonly property color label: dark ? "#8F8F8F" : "#3C3C3C"
        readonly property color title: dark ? "#969696" : "#3C3C3C"
        readonly property color dim: "#6B6B6B"
        readonly property color tick: dark ? "#1A1611" : "#C6AB89"

        // Background of the selected parts, from the accent colour
        // (Dark/BG/Accent Bright and Light/BG/Accent Bright of the design)
        function accentDim(c) {
            return dark ? Qt.rgba(c.r * 0.26, c.g * 0.26, c.b * 0.26, 1)
                        : Qt.rgba(c.r * 0.45 + 0.44, c.g * 0.45 + 0.44, c.b * 0.45 + 0.44, 1)
        }
    }

    component Icon : Image {
        id: icon

        property string name
        property color color: "#8F8F8F"
        property real size: VLCStyle.dp(24, VLCStyle.scale)

        width: size
        height: size

        property real _eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

        sourceSize: Qt.size(size * _eDPR, size * _eDPR)
        source: name === "" ? ""
                            : SVGColorImage.colorize("qrc:///redesign/" + name + ".svg")
                                           .any({ "#8F8F8F": Qt.rgba(color.r, color.g, color.b, 1.0),
                                                  "#D37918": Qt.rgba(color.r, color.g, color.b, 1.0) })
                                           .uri()

        Accessible.ignored: true
    }

    // Scrollable page. `filter` is the text of the search field.
    component Page : Flickable {
        id: page

        readonly property bool isSettingsPage: true

        property string filter: ""
        property bool showAdvanced: false

        // Whether a row of the page matches the search
        readonly property bool hasMatches: {
            void filter
            for (let i = 0; i < column.children.length; ++i) {
                const c = column.children[i]
                if (c.isSettingsSection && c.matchCount > 0)
                    return true
            }
            return false
        }

        default property alias content: column.data

        contentWidth: width
        contentHeight: column.implicitHeight + 2 * VLCStyle.dp(20, VLCStyle.scale)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        ColumnLayout {
            id: column

            x: VLCStyle.dp(24, VLCStyle.scale)
            y: VLCStyle.dp(20, VLCStyle.scale)
            width: page.width - 2 * VLCStyle.dp(24, VLCStyle.scale)

            spacing: VLCStyle.dp(20, VLCStyle.scale)
        }
    }

    // Group of rows with a heading. Hidden when none of its rows is shown.
    component Section : ColumnLayout {
        id: section

        readonly property bool isSettingsSection: true

        property string title
        // Rows that are only shown when the advanced options are open
        property bool advanced: false

        default property alias rows: rowColumn.data

        readonly property Item page: {
            let p = parent
            while (p && !p.isSettingsPage)
                p = p.parent
            return p
        }

        readonly property int matchCount: {
            let n = 0
            for (let i = 0; i < rowColumn.children.length; ++i) {
                const c = rowColumn.children[i]
                if (c.isSettingsRow ? c.matches : c.visible)
                    ++n
            }
            return n
        }

        Layout.fillWidth: true
        spacing: 0

        visible: matchCount > 0 && (!advanced || !page || page.showAdvanced || page.filter !== "")

        readonly property Pal pal: Pal { }

        Widgets.LabelExt {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(39, VLCStyle.scale)
            topPadding: VLCStyle.dp(10, VLCStyle.scale)

            text: section.title
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Medium
            color: section.pal.heading
            elide: Text.ElideRight
        }

        ColumnLayout {
            id: rowColumn
            Layout.fillWidth: true
            spacing: 0
        }
    }

    // One row: the label (and an information icon with the long description
    // of the option) on the left, the control on the right.
    component Row : RowLayout {
        id: row

        readonly property bool isSettingsRow: true

        property string text
        // Option of the control of the row, by default
        property ConfigOption option: (controlItem.children.length > 0 && controlItem.children[0].option !== undefined)
                                      ? controlItem.children[0].option : null
        // The row is hidden when its option does not exist
        property bool available: option ? option.available : true
        property string info: option ? option.longText : ""
        // Controls under the row, as wide as the page (sliders)
        property bool wide: false

        default property alias control: controlItem.data

        readonly property Item page: {
            let p = parent
            while (p && !p.isSettingsPage)
                p = p.parent
            return p
        }

        readonly property bool matches: available
            && (!page || page.filter === "" || row.text.toLowerCase().indexOf(page.filter.toLowerCase()) >= 0)

        visible: matches

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(46, VLCStyle.scale)
        spacing: VLCStyle.dp(10, VLCStyle.scale)

        readonly property Pal pal: Pal { }

        RowLayout {
            id: labelGroup
            Layout.preferredWidth: Math.min(implicitWidth, row.width - controlItem.implicitWidth - VLCStyle.dp(20, VLCStyle.scale))
            Layout.alignment: Qt.AlignVCenter
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.LabelExt {
                Layout.preferredWidth: Math.min(implicitWidth, labelGroup.width - (row.info !== "" ? VLCStyle.dp(28, VLCStyle.scale) : 0))
                text: row.text
                font.pixelSize: VLCStyle.fontSize_normal
                color: row.pal.label
                elide: Text.ElideRight
            }

            Icon {
                visible: row.info !== ""
                name: "info"
                size: VLCStyle.dp(18, VLCStyle.scale)
                color: row.pal.dim

                HoverHandler { id: infoHover }

                T.ToolTip.visible: infoHover.hovered
                T.ToolTip.delay: VLCStyle.delayToolTipAppear
                T.ToolTip.text: row.info
            }
        }

        Item { Layout.fillWidth: true }

        Item {
            id: controlItem

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.topMargin: VLCStyle.dp(5, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(5, VLCStyle.scale)

            implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
            implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
        }
    }

    // ON / OFF switch, 68x32
    component Switch : T.Switch {
        id: control

        property ConfigOption option: null
        property bool inverted: false

        implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        // When false, `checked` and `toggled` are handled by the user of the switch
        property bool bindOption: true

        checked: (bindOption && option) ? (!!option.value !== inverted) : false
        onToggled: if (bindOption && option) option.value = (checked !== inverted)


        readonly property ColorContext colorContext: ColorContext {
            id: switchTheme
            colorSet: ColorContext.ButtonAccent
            palette: VLCStyle.palette
            enabled: control.enabled
        }
        readonly property Pal pal: Pal { }

        readonly property real inset: VLCStyle.dp(3, VLCStyle.scale)

        indicator: Rectangle {
            anchors.fill: parent
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: control.pal.dark ? "#000000" : control.pal.box
            border.width: control.visualFocus ? VLCStyle.focus_border : 0
            border.color: switchTheme.visualFocus
            opacity: control.enabled ? 1 : 0.5

            Rectangle {
                x: control.checked ? control.inset : parent.width - width - control.inset
                y: control.inset
                width: parent.width - knob.width - 3 * control.inset
                height: parent.height - 2 * control.inset
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: control.checked ? control.pal.accentDim(switchTheme.bg.primary)
                                       : control.pal.boxInner

                Text {
                    anchors.centerIn: parent
                    text: control.checked ? qsTr("ON") : qsTr("OFF")
                    color: control.checked ? switchTheme.bg.primary : control.pal.dim
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                }
            }

            Rectangle {
                id: knob

                x: control.checked ? parent.width - width - control.inset : control.inset
                y: control.inset
                width: parent.height - 2 * control.inset
                height: width
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: control.checked ? Qt.darker(switchTheme.bg.primary, 1.23) : (control.pal.dark ? "#404040" : "#B3B3B3")

                Behavior on x {
                    NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.InOutSine }
                }
            }
        }

        contentItem: null
    }

    // Switch that adds a module to a list of modules ("audio-filter", ...).
    // `option` is an option of the module, it tells whether the module exists.
    component ModuleSwitch : Switch {
        id: moduleSwitch

        property string listName: "audio-filter"
        property string module

        readonly property ConfigOption list: ConfigOption { name: moduleSwitch.listName }

        function _modules() {
            const v = String(list.value ?? "")
            return v === "" ? [] : v.split(":")
        }

        bindOption: false
        checked: _modules().indexOf(module) >= 0
        onToggled: {
            let modules = _modules().filter((m) => m !== module)
            if (checked)
                modules.push(module)
            list.value = modules.join(":")
        }
    }

    // Drop-down list, 320x36. The entries are `option.choices` by default, or
    // any list of objects with `value` and `text`.
    component Dropdown : T.ComboBox {
        id: control

        property ConfigOption option: null
        // Without a list of choices, the values of a short integer range are listed
        property var entries: {
            if (!option)
                return []
            const list = option.choices
            if (list.length > 0 || option.type !== ConfigOption.Integer || option.maximum - option.minimum > 20)
                return list
            let range = []
            for (let v = option.minimum; v <= option.maximum; ++v)
                range.push({ value: v, text: String(v) })
            return range
        }
        // Value shown as selected, the value of the option by default
        property var selectedValue: option ? option.value : undefined
        signal picked(var value)

        implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

        model: entries
        textRole: "text"
        valueRole: "value"

        enabled: count > 0
        focusPolicy: Qt.StrongFocus

        function _index() {
            for (let i = 0; i < entries.length; ++i) {
                if (String(entries[i].value) === String(selectedValue))
                    return i
            }
            return -1
        }

        currentIndex: _index()
        displayText: currentIndex >= 0 ? entries[currentIndex].text
                                       : ((selectedValue === undefined || selectedValue === "" || Number(selectedValue) === 0) ? qsTr("Automatic") : String(selectedValue))

        onActivated: (index) => {
            const v = entries[index].value
            if (option)
                option.value = v
            picked(v)
        }

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: comboTheme
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: control.pal.dark ? "#000000" : control.pal.box
            border.width: control.visualFocus ? VLCStyle.focus_border : 0
            border.color: comboTheme.visualFocus
            opacity: control.enabled ? 1 : 0.5

            Rectangle {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: control.pal.boxInner
            }
        }

        contentItem: Widgets.LabelExt {
            leftPadding: VLCStyle.dp(16, VLCStyle.scale)
            rightPadding: VLCStyle.dp(36, VLCStyle.scale)
            text: control.displayText
            color: control.pal.label
            font.pixelSize: VLCStyle.fontSize_normal
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Icon {
            x: control.width - width - VLCStyle.dp(8, VLCStyle.scale)
            y: (control.height - height) / 2
            name: "chevron-down"
            color: control.pal.label
        }

        delegate: T.ItemDelegate {
            id: entry

            required property int index
            required property var modelData

            width: ListView.view.width
            implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
            highlighted: control.highlightedIndex === index

            contentItem: Widgets.LabelExt {
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                text: entry.modelData.text
                color: (entry.index === control.currentIndex) ? comboTheme.accent : control.pal.itemText
                font.pixelSize: VLCStyle.fontSize_normal
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: entry.highlighted ? control.pal.selected : "transparent"
            }
        }

        popup: T.Popup {
            y: control.height + VLCStyle.dp(4, VLCStyle.scale)
            width: control.width
            implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                                     VLCStyle.dp(320, VLCStyle.scale))
            padding: VLCStyle.dp(4, VLCStyle.scale)

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.delegateModel
                currentIndex: control.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: Widgets.ScrollBarExt { }
            }

            background: Rectangle {
                radius: VLCStyle.dp(10, VLCStyle.scale)
                color: control.pal.panel
            }
        }
    }

    // Buttons side by side, one of them selected (Light / Dark / System)
    component Segmented : Rectangle {
        id: seg

        property var entries: []        // texts
        property int currentIndex: -1
        signal picked(int index)

        implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: pal.box

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: segTheme
            colorSet: ColorContext.ButtonAccent
            palette: VLCStyle.palette
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
            spacing: VLCStyle.dp(2, VLCStyle.scale)

            Repeater {
                model: seg.entries

                delegate: T.Button {
                    id: segButton

                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    focusPolicy: Qt.StrongFocus
                    onClicked: seg.picked(index)

                    readonly property bool current: index === seg.currentIndex

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: segButton.current ? seg.pal.accentDim(segTheme.bg.primary)
                                                 : seg.pal.boxInner
                        border.width: segButton.visualFocus ? VLCStyle.focus_border : 0
                        border.color: segTheme.visualFocus
                    }

                    contentItem: Text {
                        text: segButton.modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: segButton.current ? segTheme.bg.primary : seg.pal.dim
                    }
                }
            }
        }
    }

    // Slider with labels under it, 320 wide
    component Slider : ColumnLayout {
        id: sliderRoot

        property ConfigOption option: null
        property real from: option ? option.minimum : 0
        property real to: option ? option.maximum : 1
        property real stepSize: 1
        property real factor: 1        // value of the option = value of the slider * factor
        property var labels: []       // texts under the slider, spread evenly
        property real value: option ? Number(option.value) / factor : 0
        signal moved(real value)

        implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: sliderTheme
            colorSet: ColorContext.ButtonAccent
            palette: VLCStyle.palette
        }

        T.Slider {
            id: slider

            Layout.fillWidth: true
            Layout.preferredWidth: VLCStyle.dp(320, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(16, VLCStyle.scale)

            from: sliderRoot.from
            to: sliderRoot.to
            stepSize: sliderRoot.stepSize
            value: sliderRoot.value
            focusPolicy: Qt.StrongFocus

            onMoved: {
                if (sliderRoot.option)
                    sliderRoot.option.value = (sliderRoot.option.type === ConfigOption.Integer)
                                              ? Math.round(value * sliderRoot.factor) : value * sliderRoot.factor
                sliderRoot.moved(value)
            }

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: sliderRoot.pal.box
                border.width: slider.visualFocus ? VLCStyle.focus_border : 0
                border.color: sliderTheme.visualFocus

                Rectangle {
                    x: VLCStyle.dp(2, VLCStyle.scale)
                    y: VLCStyle.dp(2, VLCStyle.scale)
                    height: parent.height - 2 * y
                    width: Math.max(slider.visualPosition * (parent.width - 2 * x), height)
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: sliderRoot.pal.accentDim(sliderTheme.bg.primary)
                }
            }

            handle: Rectangle {
                x: VLCStyle.dp(2, VLCStyle.scale) + slider.visualPosition * (slider.availableWidth - width - VLCStyle.dp(4, VLCStyle.scale))
                y: (slider.height - height) / 2
                width: VLCStyle.dp(4, VLCStyle.scale)
                height: VLCStyle.dp(12, VLCStyle.scale)
                radius: VLCStyle.dp(2, VLCStyle.scale)
                color: sliderTheme.bg.primary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: sliderRoot.labels.length > 0

            Repeater {
                model: sliderRoot.labels

                delegate: Text {
                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: index === 0 ? Text.AlignLeft
                                                     : (index === sliderRoot.labels.length - 1 ? Text.AlignRight : Text.AlignHCenter)
                    text: modelData
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: sliderRoot.pal.dim
                }
            }
        }
    }

    // Text field, 320x36. `suffix` is shown after the value (for numbers).
    component TextField : T.TextField {
        id: field

        property ConfigOption option: null
        property real factor: 1
        property bool numeric: option ? (option.type === ConfigOption.Integer || option.type === ConfigOption.Float) : false

        implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        verticalAlignment: Text.AlignVCenter

        font.pixelSize: VLCStyle.fontSize_normal
        color: pal.itemText
        placeholderTextColor: pal.dim
        selectByMouse: true

        text: (option && option.available) ? (numeric ? String(+(Number(option.value) / factor).toFixed(3)) : String(option.value ?? "")) : ""

        validator: numeric ? numberValidator : null
        DoubleValidator { id: numberValidator; notation: DoubleValidator.StandardNotation }

        onEditingFinished: {
            if (!option)
                return
            if (numeric) {
                const v = Number(text) * factor
                option.value = (option.type === ConfigOption.Integer) ? Math.round(v) : v
            } else {
                option.value = text
            }
        }

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: fieldTheme
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: field.pal.box
            border.width: VLCStyle.dp(field.activeFocus ? 1 : 2, VLCStyle.scale)
            border.color: field.activeFocus ? fieldTheme.accent : field.pal.boxInner
        }
    }

    // Button with a text, in the colour of the inputs (Browse, Reset, ...)
    component Button : T.Button {
        id: button

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), contentItem.implicitWidth + 2 * VLCStyle.dp(24, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: buttonTheme
            colorSet: ColorContext.ToolButton
            palette: VLCStyle.palette
            hovered: button.hovered
            pressed: button.down
            focused: button.visualFocus
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: button.hovered ? Qt.lighter(button.pal.boxInner, 1.3) : button.pal.boxInner
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: buttonTheme.visualFocus
        }

        contentItem: Text {
            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: VLCStyle.fontSize_normal
            font.weight: Font.DemiBold
            color: button.pal.label
        }
    }

    // Path with a Browse button
    component PathField : RowLayout {
        id: pathField

        property ConfigOption option: null

        implicitWidth: VLCStyle.dp(320, VLCStyle.scale)
        spacing: VLCStyle.dp(10, VLCStyle.scale)

        TextField {
            Layout.fillWidth: true
            implicitWidth: VLCStyle.dp(210, VLCStyle.scale)
            option: pathField.option
        }

        Button {
            text: qsTr("Browse")
            onClicked: pathField.option.browse()
        }
    }

    // Colour stored as an integer (0xRRGGBB), edited as "#RRGGBB"
    component ColorField : TextField {
        id: colorField

        numeric: false
        validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }

        text: (option && option.available) ? "#" + ("000000" + Number(option.value).toString(16).toUpperCase()).slice(-6) : ""

        leftPadding: VLCStyle.dp(40, VLCStyle.scale)

        Rectangle {
            x: VLCStyle.dp(10, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(20, VLCStyle.scale)
            height: width
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: colorField.text.length === 7 ? colorField.text : "transparent"
            border.width: 1
            border.color: colorField.pal.dim
        }

        onEditingFinished: {
            const v = parseInt(text.replace("#", ""), 16)
            if (option && !isNaN(v))
                option.value = v
        }
    }

    // Row that opens or closes the advanced options of the page
    component AdvancedToggle : T.Button {
        id: adv

        readonly property Item page: {
            let p = parent
            while (p && !p.isSettingsPage)
                p = p.parent
            return p
        }

        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(38, VLCStyle.scale)

        visible: !!page && page.filter === ""
        focusPolicy: Qt.StrongFocus
        onClicked: page.showAdvanced = !page.showAdvanced

        readonly property Pal pal: Pal { }
        readonly property ColorContext colorContext: ColorContext {
            id: advTheme
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
            focused: adv.visualFocus
        }

        background: Rectangle {
            radius: VLCStyle.dp(2, VLCStyle.scale)
            color: adv.hovered ? Qt.lighter(adv.pal.panel, 1.2) : adv.pal.panel
            border.width: adv.visualFocus ? VLCStyle.focus_border : 0
            border.color: advTheme.visualFocus
        }

        contentItem: Item {
            implicitHeight: advText.implicitHeight

            Text {
                id: advText
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -(advIcon.width + VLCStyle.dp(10, VLCStyle.scale)) / 2
                text: qsTr("Advanced Options")
                font.pixelSize: VLCStyle.fontSize_normal
                color: adv.pal.label
            }

            Icon {
                id: advIcon
                anchors.left: advText.right
                anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                name: "chevron-right"
                color: adv.pal.label
                rotation: (adv.page && adv.page.showAdvanced) ? 90 : 0
            }
        }
    }
}
