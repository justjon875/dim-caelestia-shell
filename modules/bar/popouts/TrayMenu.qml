pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

StackView {
    id: root

    required property PopoutState popouts
    required property QsMenuHandle trayItem

    implicitWidth: currentItem?.implicitWidth ?? 0
    implicitHeight: currentItem?.implicitHeight ?? 0

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    Component {
        id: subMenuComp

        SubMenu {}
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown

        padding: Tokens.padding.large
        spacing: Tokens.spacing.large

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: {
            shown = true;
            updateGroups();
        }
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener

            menu: menu.handle
        }

        property var entryGroups: []

        function updateGroups(): void {
            if (!menuOpener.children) {
                entryGroups = [];
                return;
            }
            let groups = [];
            let currentGroup = [];
            for (let i = 0; i < childrenTracker.count; i++) {
                let trackerItem = childrenTracker.itemAt(i);
                if (!trackerItem) {
                    Qt.callLater(updateGroups);
                    return;
                }
                let child = trackerItem.modelData;
                if (!child) continue;
                if (child.isSeparator) {
                    if (currentGroup.length > 0) {
                        groups.push(currentGroup);
                        currentGroup = [];
                    }
                } else {
                    currentGroup.push(child);
                }
            }
            if (currentGroup.length > 0) {
                groups.push(currentGroup);
            }
            entryGroups = groups;
        }

        Connections {
            target: menuOpener
            ignoreUnknownSignals: true
            function onChildrenChanged() { menu.updateGroups() }
        }

        Repeater {
            id: childrenTracker
            model: menuOpener.children
            delegate: Item {
                required property var modelData
                Component.onCompleted: menu.updateGroups()
                Component.onDestruction: menu.updateGroups()
            }
        }

        Repeater {
            model: menu.entryGroups

            StyledRect {
                id: container

                required property var modelData

                implicitWidth: Tokens.sizes.bar.trayMenuWidth + Tokens.padding.large * 2
                implicitHeight: groupColumn.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Column {
                    id: groupColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: container.modelData || []

                        StyledRect {
                            id: item

                            required property QsMenuEntry modelData

                            implicitWidth: Tokens.sizes.bar.trayMenuWidth
                            implicitHeight: children.implicitHeight

                            radius: Tokens.rounding.full
                            color: "transparent"

                            Loader {
                                id: children

                                asynchronous: true
                                anchors.left: parent.left
                                anchors.right: parent.right

                                sourceComponent: Item {
                                    implicitHeight: label.implicitHeight

                                    StateLayer {
                                        anchors.margins: -Tokens.padding.large / 2
                                        anchors.leftMargin: -Tokens.padding.large
                                        anchors.rightMargin: -Tokens.padding.large

                                        radius: item.radius
                                        disabled: !item.modelData.enabled

                                        onClicked: {
                                            const entry = item.modelData;
                                            if (entry.hasChildren)
                                                root.push(subMenuComp.createObject(null, {
                                                    handle: entry,
                                                    isSubMenu: true
                                                }));
                                            else {
                                                item.modelData.triggered();
                                                root.popouts.hasCurrent = false;
                                            }
                                        }
                                    }

                                    Loader {
                                        id: icon

                                        asynchronous: true
                                        anchors.left: parent.left

                                        active: item.modelData.icon !== ""

                                        sourceComponent: IconImage {
                                            asynchronous: true
                                            implicitSize: label.implicitHeight

                                            source: item.modelData.icon
                                        }
                                    }

                                    StyledText {
                                        id: label

                                        anchors.left: icon.right
                                        anchors.leftMargin: icon.active ? Tokens.spacing.smaller : 0

                                        text: labelMetrics.elidedText
                                        color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    }

                                    TextMetrics {
                                        id: labelMetrics

                                        text: item.modelData.text
                                        font.pointSize: label.font.pointSize
                                        font.family: label.font.family

                                        elide: Text.ElideRight
                                        elideWidth: Tokens.sizes.bar.trayMenuWidth - (icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0) - (expand.active ? expand.implicitWidth + Tokens.spacing.normal : 0)
                                    }

                                    Loader {
                                        id: expand

                                        asynchronous: true
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right

                                        active: item.modelData.hasChildren

                                        sourceComponent: MaterialIcon {
                                            text: "chevron_right"
                                            color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            asynchronous: true
            active: menu.isSubMenu

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Tokens.spacing.small / 2

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: -Tokens.padding.small / 2
                        anchors.leftMargin: -Tokens.padding.smaller
                        anchors.rightMargin: -Tokens.padding.smaller * 2

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSecondaryContainer
                            onClicked: root.pop()
                        }
                    }

                    Row {
                        id: back

                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_left"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Back")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
