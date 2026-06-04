import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    property var dockModel

    signal detachRequested(mode: string)
}
