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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Menus
import VLC.Util

T.Page {
    id: root

    //path of the current page loader
    property var pagePrefix: []

    //note that T.Page introduce an intermediate Item, so to access our delegate,
    //we need to use contentChildren[0] rather than contentItem
    readonly property Item _firstChild: contentChildren[0] ?? null

    //indicates whether the subview support grid/list mode
    property bool hasGridListMode: _firstChild?.hasGridListMode ?? false

    property bool isSearchable: _firstChild?.isSearchable ?? false

    // Number shown at the right of the header. Pages with a nested view can
    // expose their count through itemCount.
    property int itemCount: _firstChild?.itemCount ?? _firstChild?.model?.count ?? -1

    property var sortModel: _firstChild?.sortModel ?? null

    //property is *not* readOnly, a PageLoader may define a localMenuDelegate common for its subviews (music, video)
    property SortMenu sortMenu: null

    // When set, a "+" button in the header calls this function (new playlist, ...)
    property var addAction: _firstChild?.addAction ?? null
    property string addDescription: _firstChild?.addDescription ?? qsTr("Add")

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    property bool enableBeginningFade: true
    property bool enableEndFade: true

    readonly property SearchCtx search: _searchCtx
    readonly property SortCtx sort: _sortCtx


    SearchCtx {
        id: _searchCtx
        available: root.isSearchable
    }

    SortCtx {
        id: _sortCtx

        readonly property string _sortCriteriaKey: ["sortCriteria", ...root.pagePrefix].join("/")
        readonly property string _sortOrderKey:  ["sortOrder", ...root.pagePrefix].join("/")

        available: Helpers.isArray(root.sortModel) && (root.sortModel).length > 0
        model: root.sortModel

        //save & restore setting of the page
        Component.onCompleted: {
            const criteria = MainCtx.settingValue(_sortCriteriaKey, undefined)
            if (criteria !== undefined)
                _sortCtx.criteria = criteria

            const order = MainCtx.settingValue(_sortOrderKey, undefined)
            if (order !== undefined)
                _sortCtx.order = parseInt(order)
        }

        Component.onDestruction: {
            MainCtx.setSettingValue(_sortCriteriaKey, _sortCtx.criteria)
            MainCtx.setSettingValue(_sortOrderKey, _sortCtx.order)
        }
    }

    Binding {
        target: MainCtx
        property: "hasGridListMode";
        value: root.hasGridListMode
    }

    on_FirstChildChanged: {
        if (!_firstChild)
            return
        _firstChild.Navigation.parentItem = root
        _firstChild.Navigation.upItem = root.header
    }

    function positionContentAtBeginning() {
        _firstChild?.positionContentAtBeginning?.()
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    header: DefaultPageHeader {
        text: root.title

        leftPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_left_margin + root.leftPadding
        rightPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_right_margin + root.rightPadding

        sortMenu: root.sortMenu

        search: _searchCtx
        sort: _sortCtx

        Navigation.parentItem: root
        Navigation.downAction: function() {
            if (typeof root.setCurrentItemFocus === "function")
                root.setCurrentItemFocus(Qt.TabFocusReason)
            else if (typeof root._firstChild?.setCurrentItemFocus === "function")
             root._firstChild.setCurrentItemFocus(Qt.TabFocusReason)
            else if (root._firstChild)
                root._firstChild.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    component DefaultPageHeader: T.ToolBar {
        id: defaultPageHeader

        // Properties
        property string text

        property alias sortMenu: gridSortFilter.sortMenu

        property alias search: gridSortFilter.search
        property alias sort: gridSortFilter.sort

        position: T.ToolBar.Header

        topPadding: VLCStyle.layoutTitle_top_padding
        bottomPadding: VLCStyle.layoutTitle_bottom_padding

        // FIXME: `GridItem`'s background extends beyond its
        //        bounding rect, violating the hypothetical
        //        clip test (see 7e6b23db).
        bottomInset: (MainCtx.hasGridListMode && MainCtx.gridView) ? VLCStyle.gridItemSelectedBorder : undefined

        // Settings

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        Navigation.navigable: true

        // Children

        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: ColorContext.View
        }

        // Number of items of the page, -1 when the page does not tell
        readonly property int itemCount: root.itemCount

        // Names of the pages, from the first element of the page path
        readonly property var _sectionNames: ({
            "home": qsTr("Home"),
            "video": qsTr("Videos"),
            "music": qsTr("Music"),
            "network": qsTr("Network"),
            "discover": qsTr("Discover")
        })

        readonly property var segments: {
            const section = (root.pagePrefix.length > 0) ? (_sectionNames[root.pagePrefix[0]] ?? "") : ""
            const title = root.title
            if (section === "")
                return title ? [title] : []
            if (title === "" || title === section)
                return [section]
            return [section, title]
        }

        background: Rectangle {
            color: theme.bg.primary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: VLCStyle.dp(1, VLCStyle.scale)
                color: theme.fg.primary
                opacity: 0.1
            }
        }

        RowLayout {
            id: row

            anchors.fill: parent

            spacing: VLCStyle.margin_small

            SvgToolButton {
                id: backButton

                iconName: "arrow-left"
                description: qsTr("Previous")
                enabled: !History.previousEmpty

                onClicked: History.previous()

                Navigation.parentItem: defaultPageHeader
                Navigation.rightItem: forwardButton
            }

            SvgToolButton {
                id: forwardButton

                iconName: "arrow-right"
                description: qsTr("Next")
                enabled: !History.nextEmpty

                onClicked: History.next()

                Navigation.parentItem: defaultPageHeader
                Navigation.leftItem: backButton
                Navigation.rightItem: gridSortFilter
            }

            Row {
                id: breadcrumb

                Layout.leftMargin: VLCStyle.margin_small
                Layout.fillWidth: true

                spacing: VLCStyle.margin_xsmall

                Repeater {
                    model: defaultPageHeader.segments

                    delegate: Row {
                        required property int index
                        required property string modelData

                        readonly property bool isLast: (index === defaultPageHeader.segments.length - 1)

                        spacing: VLCStyle.margin_xsmall

                        Text {
                            visible: index > 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: "\u25B8"
                            font.pixelSize: VLCStyle.fontSize_xsmall
                            color: theme.fg.secondary
                        }

                        LabelExt {
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, VLCStyle.dp(280, VLCStyle.scale))

                            font.pixelSize: VLCStyle.fontSize_large
                            font.weight: (isLast && defaultPageHeader.segments.length > 1) ? Font.DemiBold : Font.Normal
                            color: (isLast || defaultPageHeader.segments.length === 1) ? theme.fg.primary : theme.fg.secondary
                        }
                    }
                }
            }

            LabelExt {
                visible: defaultPageHeader.itemCount >= 0

                text: defaultPageHeader.itemCount + " " + (defaultPageHeader.itemCount === 1 ? qsTr("item") : qsTr("items"))
                color: theme.fg.secondary
                font.pixelSize: VLCStyle.fontSize_normal
            }

            SvgToolButton {
                visible: typeof root.addAction === "function"
                iconName: "nav-add"
                description: root.addDescription
                onClicked: root.addAction()
                Navigation.parentItem: defaultPageHeader
            }

            GridSortFilterControls {
                id: gridSortFilter
                focus: true
                sort: _sortCtx
                search: _searchCtx
                Navigation.parentItem: defaultPageHeader
                Navigation.leftItem: forwardButton
            }

            SvgToolButton {
                id: pageMenuButton

                iconName: "more"
                description: qsTr("Page menu")
                checked: pageMenu.shown
                onClicked: pageMenu.popup(mapToGlobal(0, height))
                Navigation.parentItem: defaultPageHeader

                QmlGlobalMenu {
                    id: pageMenu
                    ctx: MainCtx
                }
            }
        }
    }
}
