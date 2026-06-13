pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit 0.1
import Caelestia.Config
import QtQuick.Effects
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import M3Shapes

StyledWindow {
    id: root

    required property PolkitAgent agent
    required property var screen

    property int activeScreenScale: 1
    readonly property real centerScale: Math.max(0.8, Math.min(1, root.height / 1440))
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale
    readonly property int passwordMaxWidth: centerWidth * 0.8
    property string buffer: ""
    readonly property list<int> shapeQueue: {
        const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow, MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided, MaterialShape.Ghostish, MaterialShape.SoftBurst];
        for (let i = shapes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shapes[i], shapes[j]] = [shapes[j], shapes[i]];
        }
        return shapes;
    }

    name: "polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool isActive: agent.isActive && agent.flow != null
    visible: isActive || closeAnim.running

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onIsActiveChanged: {
        if (isActive) {
            closeAnim.stop()
            openAnim.start()
        } else {
            openAnim.stop()
            closeAnim.start()
        }
    }

    ParallelAnimation {
        id: openAnim

        SequentialAnimation {
            ParallelAnimation {
                Anim { target: dialogContainer; property: "opacity"; to: 1; duration: Tokens.anim.durations.small }
                Anim { target: dialogContainer; property: "scale"; to: 1; type: Anim.FastSpatial }
                Anim { target: dialogContainer; property: "rotation"; to: 360; duration: Tokens.anim.durations.expressiveFastSpatial; easing: Tokens.anim.standardAccel }
            }
            ParallelAnimation {
                Anim { target: lockIcon; property: "rotation"; to: 360; easing: Tokens.anim.standardDecel }
                Anim { type: Anim.DefaultEffects; target: lockIcon; property: "opacity"; to: 0 }
                Anim { type: Anim.DefaultEffects; target: dialogContent; property: "opacity"; to: 1 }
                Anim { target: dialogContent; property: "scale"; to: 1 }
                Anim { target: dialogBg; property: "radius"; to: Tokens.rounding.large }
                Anim { target: dialogContainer; property: "implicitWidth"; to: dialogContainer.targetWidth }
                Anim { target: dialogContainer; property: "implicitHeight"; to: dialogContainer.targetHeight }
            }
        }
    }


    TextMetrics {
        id: nonAnimPlaceholder

        text: "Enter your password"
        font: Tokens.font.body.builders.medium.scale(centerScale).width(110).build()
    }

    SequentialAnimation {
        id: closeAnim

        ParallelAnimation {
            Anim { target: dialogContainer; property: "implicitWidth"; to: dialogContainer.iconSize }
            Anim { target: dialogContainer; property: "implicitHeight"; to: dialogContainer.iconSize }
            Anim { target: dialogBg; property: "radius"; to: dialogContainer.initialRadius }
            Anim { target: dialogContent; property: "scale"; to: 0 }
            Anim { target: dialogContent; property: "opacity"; to: 0; type: Anim.StandardSmall }
            Anim { target: lockIcon; property: "opacity"; to: 1; type: Anim.StandardLarge }
            
            SequentialAnimation {
                PauseAnimation { duration: Tokens.anim.durations.small }
                Anim { target: dialogContainer; property: "opacity"; to: 0; type: Anim.Standard }
                PropertyAction { target: dialogContainer; property: "rotation"; value: 180 }
                PropertyAction { target: dialogContainer; property: "scale"; value: 0 }
                PropertyAction { target: lockIcon; property: "rotation"; value: 180 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        // Prevent clicks from passing through
    }

    Item {
        id: dialogContainer

        readonly property int iconSize: lockIcon.implicitHeight + Tokens.padding.large * 4
        readonly property int initialRadius: iconSize / 4 * Tokens.rounding.scale

        property int targetWidth: Math.max(420, root.passwordMaxWidth + Tokens.padding.extraLarge * 2)
        property int targetHeight: dialogContent.implicitHeight + Tokens.padding.extraLarge * 2

        anchors.centerIn: parent
        implicitWidth: iconSize
        implicitHeight: iconSize
        rotation: 180
        scale: 0

        StyledRect {
            id: dialogBg

            anchors.fill: parent
            radius: dialogContainer.initialRadius
            color: Colours.layer(Colours.palette.m3surface, 0)
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
            color: Colours.palette.m3secondary
            rotation: 180
        }

        ColumnLayout {
            id: dialogContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.padding.large
            anchors.verticalCenter: parent.verticalCenter
            
            opacity: 0
            scale: 0
            spacing: Tokens.spacing.extraLarge

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: textContent.implicitHeight + Tokens.padding.large * 2
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.large
                
                ColumnLayout {
                    id: textContent

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: "Authentication Required"
                        font: Tokens.font.title.builders.large.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: agent.flow ? agent.flow.message : ""
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: agent.flow && agent.flow.supplementaryMessage ? agent.flow.supplementaryMessage : ""
                        font: Tokens.font.body.small
                        color: agent.flow && agent.flow.supplementaryIsError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        visible: text.length > 0
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            StyledRect {
                id: passwordRect
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: {
                    const emptyW = nonAnimPlaceholder.width + iconWrapper.implicitWidth + enterButton.implicitWidth + passwordInputLayout.spacing * 2 + Tokens.padding.medium * 2;
                    return root.buffer.length > 0 ? root.passwordMaxWidth : Math.min(root.passwordMaxWidth, emptyW);
                }
                implicitHeight: passwordInputLayout.implicitHeight + Tokens.padding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.full
                
                focus: true

                Behavior on implicitWidth { Anim {} }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: passwordRect.forceActiveFocus()
                    }
                    
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (agent.flow && root.buffer) {
                                agent.flow.submit(root.buffer)
                                root.buffer = ""
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backspace) {
                            if (root.buffer.length > 0) {
                                root.buffer = root.buffer.slice(0, -1);
                            }
                            if (root.buffer.length === 0) {
                                charList.implicitWidth = charList.implicitWidth;
                                placeholder.animate = true;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            if (agent.flow) {
                                agent.flow.cancelAuthenticationRequest()
                            }
                            root.buffer = ""
                            event.accepted = true;
                        } else if (event.text.length > 0) {
                            charList.bindImWidth();
                            root.buffer += event.text;
                            event.accepted = true;
                        }
                    }

                    Connections {
                        function onIsActiveChanged() {
                            if (agent.isActive) {
                                root.buffer = ""
                                passwordRect.forceActiveFocus()
                            }
                        }

                        target: agent
                    }

                    RowLayout {
                        id: passwordInputLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.extraSmall
                        spacing: Tokens.spacing.medium
                        
                        Item {
                            id: iconWrapper
                            Layout.fillHeight: true
                            implicitWidth: height
                            
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "lock"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.builders.medium.scale(centerScale).build()
                            }
                        }
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            StyledText {
                                id: placeholder

                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 1
                                text: nonAnimPlaceholder.text
                                animate: true
                                color: Colours.palette.m3outline
                                font: nonAnimPlaceholder.font
                                opacity: root.buffer ? 0 : 1

                                Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                            }

                            ListView {
                                id: charList

                                readonly property int fullWidth: {
                                    let w = (count - 1) * spacing;
                                    for (let i = 0; i < count; i++)
                                        w += ((itemAtIndex(i) as CharItem)?.nonAnimWidthScale ?? 1) * implicitHeight;
                                    return w + implicitHeight;
                                }

                                function bindImWidth(): void {
                                    imWidthBehavior.enabled = false;
                                    implicitWidth = Qt.binding(() => fullWidth);
                                    imWidthBehavior.enabled = true;
                                }

                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: implicitWidth > parent.width ? -(implicitWidth - parent.width) / 2 : 0

                                implicitWidth: fullWidth
                                implicitHeight: Tokens.font.body.medium.pointSize

                                orientation: Qt.Horizontal
                                spacing: Tokens.spacing.extraSmall
                                interactive: false

                                model: ScriptModel {
                                    values: root.buffer.split("")
                                }

                                delegate: CharItem {}

                                Behavior on implicitWidth {
                                    id: imWidthBehavior
                                    Anim {}
                                }
                            }
                        }
                        
                        Item {
                            id: enterButton

                            implicitWidth: implicitHeight
                            implicitHeight: {
                                const h = enterIcon.implicitHeight + Tokens.padding.extraSmall * 2;
                                return h % 2 === 0 ? h : h + 1;
                            }

                            MaterialShape {
                                anchors.fill: parent
                                color: root.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                                shape: root.buffer ? MaterialShape.Arrow : MaterialShape.Circle
                                scale: !root.buffer ? 1 : enterMouse.pressed ? 0.6 : enterMouse.containsMouse ? 0.8 : 0.7
                                rotation: 90
                                
                                Behavior on scale { Anim { type: Anim.FastSpatial } }
                                Behavior on color { CAnim {} }
                                
                                MouseArea {
                                    id: enterMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: root.buffer ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (agent.flow && root.buffer) {
                                            agent.flow.submit(root.buffer)
                                            root.buffer = ""
                                        }
                                    }
                                }
                            }

                            MaterialIcon {
                                id: enterIcon

                                anchors.centerIn: parent
                                text: "arrow_forward"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.builders.medium.scale(centerScale * 1.2).build()
                                opacity: root.buffer ? 0 : 1

                                Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                            }
                        }
                    }
                }
        }
    }

    component CharItem: Item {
        id: char

        required property int index
        property real nonAnimWidthScale: 1

        implicitHeight: charList.implicitHeight

        ListView.onRemove: {
            initAnim.stop();
            removeAnim.start();
        }

        MaterialShape {
            id: charShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: root.shapeQueue[char.index % root.shapeQueue.length] ?? MaterialShape.Circle
            color: Colours.palette.m3onSurface

            Behavior on color {
                CAnim {}
            }

            SequentialAnimation {
                id: initAnim

                running: true

                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "opacity"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        from: 0
                        to: 1
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        from: charList.implicitHeight
                        to: charList.implicitHeight * 1.3
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1.5
                    }
                }
                PauseAnimation {
                    duration: 180 * Tokens.anim.durations.scale
                }
                PropertyAction {
                    target: charShape
                    property: "shape"
                    value: MaterialShape.Circle
                }
                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 2 / 3
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        to: charList.implicitHeight
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1
                    }
                }
            }

            SequentialAnimation {
                id: removeAnim

                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        target: charShape
                        property: "opacity"
                        to: 0
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 0.5
                    }
                }
                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
}
