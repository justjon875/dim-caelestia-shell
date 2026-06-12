import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import Caelestia.Config

Item {
    id: root

    property bool isFetching: false
    property string errorMessage: ""

    ListModel {
        id: newsModel
    }

    function fetchNews() {
        if (isFetching) return;
        isFetching = true;
        errorMessage = "";
        
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "https://archlinux.org/feeds/news/");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isFetching = false;
                if (xhr.status === 200) {
                    parseNews(xhr.responseText);
                } else {
                    errorMessage = qsTr("Failed to fetch news (Status: %1)").arg(xhr.status);
                }
            }
        };
        xhr.send();
    }

    function parseNews(xmlString) {
        newsModel.clear();
        
        var itemRegex = /<item>([\s\S]*?)<\/item>/g;
        var titleRegex = /<title>(.*?)<\/title>/;
        var linkRegex = /<link>(.*?)<\/link>/;
        var dateRegex = /<pubDate>(.*?)<\/pubDate>/;
        
        var match;
        while ((match = itemRegex.exec(xmlString)) !== null) {
            var itemContent = match[1];
            
            var titleMatch = titleRegex.exec(itemContent);
            var linkMatch = linkRegex.exec(itemContent);
            var dateMatch = dateRegex.exec(itemContent);
            
            if (titleMatch && linkMatch && dateMatch) {
                // Remove CDATA if present or unescape basic HTML entities
                var title = titleMatch[1].replace(/<!\[CDATA\[(.*?)\]\]>/g, "$1").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#039;/g, "'");
                var dateStr = dateMatch[1];
                
                // Format date nicely
                var dateObj = new Date(dateStr);
                var formattedDate = dateObj.toLocaleDateString();
                if (formattedDate === "Invalid Date") formattedDate = dateStr;
                
                newsModel.append({
                    "title": title,
                    "link": linkMatch[1],
                    "date": formattedDate
                });
            }
        }
        
        if (newsModel.count === 0) {
            errorMessage = qsTr("No news articles found.");
        }
    }

    Component.onCompleted: fetchNews()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Arch Linux News")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }
            
            StyledIconButton {
                icon: "refresh"
                tooltip: qsTr("Refresh")
                onClicked: fetchNews()
            }
        }

        // Error message
        StyledText {
            Layout.fillWidth: true
            visible: root.errorMessage !== ""
            text: root.errorMessage
            color: Colours.palette.m3error
            wrapMode: Text.WordWrap
        }

        // Loading Indicator
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.isFetching && newsModel.count === 0

            StyledText {
                anchors.centerIn: parent
                text: qsTr("Fetching latest news...")
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: newsModel
            spacing: Tokens.spacing.small
            clip: true
            visible: !root.isFetching || newsModel.count > 0
            
            ScrollBar.vertical: StyledScrollBar {}

            delegate: StyledRect {
                width: ListView.view.width
                implicitHeight: col.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                
                color: ma.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh

                Behavior on color { Anim { type: Anim.DefaultColor } }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(model.link)
                }

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: model.title
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: model.date
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }
}
