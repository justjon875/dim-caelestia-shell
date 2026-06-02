import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        Layout.leftMargin: Tokens.padding.small
        text: qsTr("Lock Status")
        font.weight: 500
    }

    StyledRect {
        Layout.fillWidth: true
        implicitWidth: cardLayout.implicitWidth + Tokens.padding.normal * 2
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.normal * 2
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: cardLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.normal
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
            }

            StyledText {
                text: qsTr("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
            }
        }
    }
}
