import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts
    property var model: popouts.dockModel

    property MprisPlayer player: {
        if (!model) return null;
        return Players.list.find(p => p.identity.toLowerCase().includes(model.appClass.toLowerCase()) || (model.id && p.identity.toLowerCase().includes(model.id.toLowerCase().replace(".desktop", "")))) || null;
    }

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
            spacing: Tokens.spacing.normal

            // App details row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                IconImage {
                    id: icon
                    asynchronous: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: details.implicitHeight
                    source: model ? Icons.getAppIcon(model.iconName, "image-missing") : ""
                }

                ColumnLayout {
                    id: details
                    spacing: 0
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: model ? (model.entry ? model.entry.name : model.appClass) : ""
                        font.pointSize: Tokens.font.size.normal
                        elide: Text.ElideRight
                    }
                }

                Item {
                    implicitWidth: expandIcon.implicitHeight + Tokens.padding.small * 2
                    implicitHeight: expandIcon.implicitHeight + Tokens.padding.small * 2
                    Layout.alignment: Qt.AlignVCenter

                    StateLayer {
                        radius: Tokens.rounding.normal
                        onClicked: root.popouts.detachRequested("winfo")
                    }

                    MaterialIcon {
                        id: expandIcon
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: font.pointSize * 0.05
                        text: "chevron_right"
                        font.pointSize: Tokens.font.size.large
                    }
                }
            }

            // Previews Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal
                visible: model && model.toplevels && model.toplevels.length > 0

                Repeater {
                    model: root.model ? root.model.toplevels : []
                    
                    delegate: ColumnLayout {
                        spacing: Tokens.spacing.small

                        // Title and close button
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.maximumWidth: Tokens.sizes.bar.windowPreviewSize

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title || ""
                                font.pointSize: Tokens.font.size.smaller
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }

                            Item {
                                implicitWidth: closeIcon.implicitHeight + Tokens.padding.small * 2
                                implicitHeight: closeIcon.implicitHeight + Tokens.padding.small * 2

                                StateLayer {
                                    radius: Tokens.rounding.small
                                    onClicked: Hypr.dispatch(`closewindow address:${modelData.address}`)
                                }

                                MaterialIcon {
                                    id: closeIcon
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pointSize: Tokens.font.size.normal
                                }
                            }
                        }

                        // Preview
                        StateLayer {
                            Layout.preferredWidth: Tokens.sizes.bar.windowPreviewSize
                            Layout.preferredHeight: Tokens.sizes.bar.windowPreviewSize
                            radius: Tokens.rounding.small
                            color: "transparent"

                            onClicked: {
                                Hypr.dispatch(`focuswindow address:${modelData.address}`);
                                root.popouts.hasCurrent = false;
                            }

                            ClippingWrapperRectangle {
                                anchors.fill: parent
                                color: "transparent"
                                radius: Tokens.rounding.small

                                ScreencopyView {
                                    id: preview
                                    captureSource: modelData.wayland || null // qmllint disable unresolved-type
                                    live: visible
                                    constraintSize.width: Tokens.sizes.bar.windowPreviewSize
                                    constraintSize.height: Tokens.sizes.bar.windowPreviewSize
                                }
                            }
                        }
                    }
                }
            }

            // Media controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.normal
                visible: !!root.player

                Item {
                    implicitWidth: prevIcon.implicitHeight + Tokens.padding.small * 2
                    implicitHeight: prevIcon.implicitHeight + Tokens.padding.small * 2
                    visible: root.player ? root.player.canGoPrevious : false

                    StateLayer {
                        radius: Tokens.rounding.small
                        onClicked: root.player.previous()
                    }

                    MaterialIcon {
                        id: prevIcon
                        anchors.centerIn: parent
                        text: "skip_previous"
                        font.pointSize: Tokens.font.size.large
                    }
                }

                Item {
                    implicitWidth: playIcon.implicitHeight + Tokens.padding.small * 2
                    implicitHeight: playIcon.implicitHeight + Tokens.padding.small * 2
                    visible: root.player ? root.player.canTogglePlaying : false

                    StateLayer {
                        radius: Tokens.rounding.small
                        onClicked: root.player.togglePlaying()
                    }

                    MaterialIcon {
                        id: playIcon
                        anchors.centerIn: parent
                        text: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                        font.pointSize: Tokens.font.size.large
                    }
                }

                Item {
                    implicitWidth: nextIcon.implicitHeight + Tokens.padding.small * 2
                    implicitHeight: nextIcon.implicitHeight + Tokens.padding.small * 2
                    visible: root.player ? root.player.canGoNext : false

                    StateLayer {
                        radius: Tokens.rounding.small
                        onClicked: root.player.next()
                    }

                    MaterialIcon {
                        id: nextIcon
                        anchors.centerIn: parent
                        text: "skip_next"
                        font.pointSize: Tokens.font.size.large
                    }
                }
            }
        }
    }
}
