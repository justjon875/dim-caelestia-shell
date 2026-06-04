import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts
    property var model: popouts.dockModel

    property bool isPinned: model ? model.isPinned : false

    implicitWidth: layout.implicitWidth + Tokens.padding.normal * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.normal * 2

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: layout

            anchors.centerIn: parent
            spacing: 0

            // Pin/Unpin action
            StateLayer {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.sizes.bar.trayMenuEntrySize
                radius: Tokens.rounding.small
                visible: model && model.entry != null

                onClicked: {
                    if (isPinned) {
                        const current = GlobalConfig.launcher.favouriteApps ? [...GlobalConfig.launcher.favouriteApps] : [];
                        const index = current.indexOf(model.id);
                        if (index !== -1) {
                            current.splice(index, 1);
                            GlobalConfig.launcher.favouriteApps = current;
                        }
                    } else {
                        const current = GlobalConfig.launcher.favouriteApps ? [...GlobalConfig.launcher.favouriteApps] : [];
                        if (!current.includes(model.id)) {
                            current.push(model.id);
                            GlobalConfig.launcher.favouriteApps = current;
                        }
                    }
                    root.popouts.hasCurrent = false;
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.normal
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: isPinned ? "push_pin" : "push_pin"
                        color: isPinned ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.normal
                    }

                    StyledText {
                        text: isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
                        Layout.fillWidth: true
                    }
                }
            }

            // New window action
            StateLayer {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.sizes.bar.trayMenuEntrySize
                radius: Tokens.rounding.small
                visible: model && model.entry != null

                onClicked: {
                    if (model.entry) {
                        if (model.entry.runInTerminal) {
                            Quickshell.execDetached({
                                command: ["app2unit", "--", ...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...model.entry.command],
                                workingDirectory: model.entry.workingDirectory
                            });
                        } else {
                            Quickshell.execDetached({
                                command: ["app2unit", "--", ...model.entry.command],
                                workingDirectory: model.entry.workingDirectory
                            });
                        }
                    }
                    root.popouts.hasCurrent = false;
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.normal
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: "add_to_photos"
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: qsTr("Open new window")
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colours.palette.m3outlineVariant
                visible: model && model.entry != null
                Layout.topMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.padding.small
            }

            // Close all windows
            StateLayer {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.sizes.bar.trayMenuEntrySize
                radius: Tokens.rounding.small
                visible: model && model.toplevels && model.toplevels.length > 0

                onClicked: {
                    for (const toplevel of model.toplevels) {
                        Hypr.dispatch(`closewindow address:${toplevel.address}`);
                    }
                    root.popouts.hasCurrent = false;
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.normal
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: "close"
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3error
                    }

                    StyledText {
                        text: qsTr("Close all windows")
                        Layout.fillWidth: true
                        color: Colours.palette.m3error
                    }
                }
            }
        }
    }
}
