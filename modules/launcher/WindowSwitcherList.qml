pragma ComponentBehavior: Bound

import "items"
import "services"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services

PathView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property var panels
    required property var content

    readonly property int itemWidth: Tokens.sizes.launcher.windowSwitcherWidth * 0.8 + Tokens.padding.larger * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        const isBarHorizontal = Config.bar.position === "top" || Config.bar.position === "bottom";
        const barThickness = isBarHorizontal ? panels.bar.implicitHeight : panels.bar.implicitWidth;
        const barMargins = Math.max(Config.border.thickness, barThickness);

        // Subtract sidebar/utilities width when visible (they take horizontal space)
        let sidebarReduction = 0;
        if ((visibilities.sidebar || visibilities.utilities) && panels.utilities.implicitWidth > sidebarReduction) {
            if (!isBarHorizontal) {
                // Vertical bars: sidebar takes space from the side
                sidebarReduction = panels.utilities.implicitWidth;
            } else if (panels.sidebar.visible) {
                // Horizontal bars: sidebar takes space on the right side
                sidebarReduction = panels.sidebar.implicitWidth;
            }
        }

        // For horizontal bars with popouts, calculate how much horizontal space the popout takes
        let popoutReduction = 0;
        if (panels.popouts.hasCurrent && isBarHorizontal) {
            // Popout center position and width
            const popoutCenter = panels.popouts.currentCenter;
            const popoutHalfWidth = panels.popouts.nonAnimWidth / 2;
            const popoutRight = popoutCenter + popoutHalfWidth;
            const popoutLeft = popoutCenter - popoutHalfWidth;
            const screenCenter = screen.width / 2;

            // Calculate how far the popout extends from screen center in each direction
            const extendLeft = popoutLeft < screenCenter ? screenCenter - popoutLeft : 0;
            const extendRight = popoutRight > screenCenter ? popoutRight - screenCenter : 0;
            popoutReduction = Math.max(extendLeft, extendRight);
        }

        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + sidebarReduction) * 2 - popoutReduction;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, 10, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: Windows.query(search)
        onValuesChanged: root.currentIndex = 0
    }

    Component.onCompleted: Windows.reload()
    Component.onDestruction: {}

    onCurrentItemChanged: {
        if (currentItem) {}
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToPoint
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WindowSwitcherItem {
        list: root
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else
                root.incrementCurrentIndex();
            wheel.accepted = true;
        }
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }
}
