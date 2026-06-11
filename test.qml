import QtQuick
import Quickshell
import Caelestia.Config

ShellRoot {
    Component.onCompleted: {
        console.log("Config leftSidebar:", Config.leftSidebar);
        if (Config.leftSidebar) {
            console.log("enabled:", Config.leftSidebar.enabled);
        }
        Qt.quit();
    }
}
