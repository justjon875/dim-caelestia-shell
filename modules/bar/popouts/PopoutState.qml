import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    property var dockModel: null
    property string selectedClientAddress: ""

    signal detachRequested(mode: string)
}
