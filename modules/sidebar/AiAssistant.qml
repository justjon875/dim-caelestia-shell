pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import Quickshell

Item {
    id: root

    property string activeProvider: GlobalConfig.ai.activeProvider
    onActiveProviderChanged: {
        if (GlobalConfig.ai.activeProvider !== activeProvider) {
            GlobalConfig.ai.activeProvider = activeProvider;
        }

        if (activeProvider === "ollama") {
            fetchOllamaModels();
        }

        // Snapping logic
        if (activeProvider === "gemini" && GlobalConfig.ai.snapToDefaultGemini) {
            activeGeminiModel = GlobalConfig.ai.defaultGeminiModel;
        } else if (activeProvider === "chatgpt" && GlobalConfig.ai.snapToDefaultChatgpt) {
            activeChatgptModel = GlobalConfig.ai.defaultChatgptModel;
        } else if (activeProvider === "ollama" && GlobalConfig.ai.snapToDefaultOllama) {
            activeOllamaModel = GlobalConfig.ai.defaultOllamaModel;
        }

        loadHistory();
    }

    property string activeGeminiModel: GlobalConfig.ai.activeGeminiModel
    onActiveGeminiModelChanged: {
        if (GlobalConfig.ai.activeGeminiModel !== activeGeminiModel) {
            GlobalConfig.ai.activeGeminiModel = activeGeminiModel;
        }
    }

    property string activeChatgptModel: GlobalConfig.ai.activeChatgptModel
    onActiveChatgptModelChanged: {
        if (GlobalConfig.ai.activeChatgptModel !== activeChatgptModel) {
            GlobalConfig.ai.activeChatgptModel = activeChatgptModel;
        }
    }

    property string activeOllamaModel: GlobalConfig.ai.activeOllamaModel
    onActiveOllamaModelChanged: {
        if (GlobalConfig.ai.activeOllamaModel !== activeOllamaModel) {
            GlobalConfig.ai.activeOllamaModel = activeOllamaModel;
        }
    }
    property var ollamaModelsList: []
    property bool isTyping: false

    readonly property string currentModel: {
        if (activeProvider === "gemini") return activeGeminiModel;
        if (activeProvider === "chatgpt") return activeChatgptModel;
        if (activeProvider === "ollama") return activeOllamaModel;
        return "";
    }

    function setCurrentModel(modelName) {
        if (activeProvider === "gemini") activeGeminiModel = modelName;
        else if (activeProvider === "chatgpt") activeChatgptModel = modelName;
        else if (activeProvider === "ollama") activeOllamaModel = modelName;
    }

    function fetchOllamaModels() {
        var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ollamaUrl + "/api/tags", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var list = [];
                        if (response.models) {
                            for (var i = 0; i < response.models.length; i++) {
                                list.push(response.models[i].name);
                            }
                        }
                        if (list.length > 0) {
                            ollamaModelsList = list;
                            if (list.indexOf(root.activeOllamaModel) === -1) {
                                root.activeOllamaModel = list[0];
                            }
                        } else {
                            ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                        }
                    } catch (e) {
                        console.log("Error parsing Ollama models: " + e.message);
                        ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                    }
                } else {
                    console.log("Ollama tags request failed (status " + xhr.status + ")");
                    ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                }
            }
        };
        xhr.send();
    }

    function saveHistory() {
        if (!GlobalConfig.ai.saveChatHistory) {
            GlobalConfig.ai.geminiHistoryJson = "[]";
            GlobalConfig.ai.chatgptHistoryJson = "[]";
            GlobalConfig.ai.ollamaHistoryJson = "[]";
            return;
        }

        var list = [];
        for (var i = 0; i < chatHistory.count; i++) {
            list.push({
                "isUser": chatHistory.get(i).isUser,
                "text": chatHistory.get(i).text
            });
        }
        var jsonStr = JSON.stringify(list);

        if (activeProvider === "gemini") GlobalConfig.ai.geminiHistoryJson = jsonStr;
        else if (activeProvider === "chatgpt") GlobalConfig.ai.chatgptHistoryJson = jsonStr;
        else if (activeProvider === "ollama") GlobalConfig.ai.ollamaHistoryJson = jsonStr;
    }

    function loadHistory() {
        chatHistory.clear();
        if (!GlobalConfig.ai.saveChatHistory) {
            chatHistory.append({
                "isUser": false,
                "text": "Hello! I am your AI Assistant. How can I help you today?"
            });
            return;
        }

        try {
            var jsonStr = "[]";
            if (activeProvider === "gemini") jsonStr = GlobalConfig.ai.geminiHistoryJson;
            else if (activeProvider === "chatgpt") jsonStr = GlobalConfig.ai.chatgptHistoryJson;
            else if (activeProvider === "ollama") jsonStr = GlobalConfig.ai.ollamaHistoryJson;

            var history = JSON.parse(jsonStr || "[]");
            if (history && history.length > 0) {
                for (var i = 0; i < history.length; i++) {
                    chatHistory.append(history[i]);
                }
            } else {
                chatHistory.append({
                    "isUser": false,
                    "text": "Hello! I am your AI Assistant. How can I help you today?"
                });
            }
        } catch (e) {
            console.log("Error loading chat history: " + e.message);
            chatHistory.append({
                "isUser": false,
                "text": "Hello! I am your AI Assistant. How can I help you today?"
            });
        }
    }

    Connections {
        target: GlobalConfig.ai
        function onSaveChatHistoryChanged() {
            loadHistory();
        }
        function onEnableGeminiChanged() { checkActiveProvider(); }
        function onEnableChatgptChanged() { checkActiveProvider(); }
        function onEnableOllamaChanged() { checkActiveProvider(); }
    }

    function checkActiveProvider() {
        if (activeProvider === "gemini" && !GlobalConfig.ai.enableGemini) {
            fallbackActiveProvider();
        } else if (activeProvider === "chatgpt" && !GlobalConfig.ai.enableChatgpt) {
            fallbackActiveProvider();
        } else if (activeProvider === "ollama" && !GlobalConfig.ai.enableOllama) {
            fallbackActiveProvider();
        }
    }

    function fallbackActiveProvider() {
        if (GlobalConfig.ai.enableGemini) activeProvider = "gemini";
        else if (GlobalConfig.ai.enableChatgpt) activeProvider = "chatgpt";
        else if (GlobalConfig.ai.enableOllama) activeProvider = "ollama";
    }

    Component.onCompleted: {
        checkActiveProvider();

        if (activeProvider === "ollama") {
            fetchOllamaModels();
        }

        // Snapping logic on startup
        if (activeProvider === "gemini" && GlobalConfig.ai.snapToDefaultGemini) {
            activeGeminiModel = GlobalConfig.ai.defaultGeminiModel;
        } else if (activeProvider === "chatgpt" && GlobalConfig.ai.snapToDefaultChatgpt) {
            activeChatgptModel = GlobalConfig.ai.defaultChatgptModel;
        } else if (activeProvider === "ollama" && GlobalConfig.ai.snapToDefaultOllama) {
            activeOllamaModel = GlobalConfig.ai.defaultOllamaModel;
        }

        loadHistory();
    }

    anchors.fill: parent
    anchors.margins: Tokens.padding.medium

    ListModel {
        id: chatHistory
    }

    function addAiMessage(message) {
        chatHistory.append({
            "isUser": false,
            "text": message
        });
        listView.positionViewAtEnd();
        saveHistory();
    }

    function sendPrompt(promptText) {
        if (!promptText.trim()) return;

        chatHistory.append({
            "isUser": true,
            "text": promptText
        });
        listView.positionViewAtEnd();
        saveHistory();

        isTyping = true;
        var provider = activeProvider;
        var xhr = new XMLHttpRequest();

        if (provider === "gemini") {
            var geminiKey = GlobalConfig.ai.geminiKey;
            if (!geminiKey) {
                addAiMessage("Error: Gemini API Key is missing. Please add it to ~/.config/caelestia/shell.json under \"ai\": { \"geminiKey\": \"your_key\" }");
                isTyping = false;
                return;
            }
            var url = "https://generativelanguage.googleapis.com/v1/models/" + activeGeminiModel + ":generateContent?key=" + geminiKey;
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    isTyping = false;
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.candidates[0].content.parts[0].text;
                            addAiMessage(reply);
                        } catch (e) {
                            addAiMessage("Error parsing Gemini response: " + e.message);
                        }
                    } else {
                        addAiMessage("Gemini request failed (status " + xhr.status + "): " + xhr.responseText);
                    }
                }
            };

            var contents = [];
            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                contents.push({
                    "role": msg.isUser ? "user" : "model",
                    "parts": [{"text": msg.text}]
                });
            }
            xhr.send(JSON.stringify({ "contents": contents }));

        } else if (provider === "chatgpt") {
            var openaiKey = GlobalConfig.ai.openaiKey;
            if (!openaiKey) {
                addAiMessage("Error: OpenAI API Key is missing. Please add it to ~/.config/caelestia/shell.json under \"ai\": { \"openaiKey\": \"your_key\" }");
                isTyping = false;
                return;
            }
            var url = "https://api.openai.com/v1/chat/completions";
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.setRequestHeader("Authorization", "Bearer " + openaiKey);

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    isTyping = false;
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.choices[0].message.content;
                            addAiMessage(reply);
                        } catch (e) {
                            addAiMessage("Error parsing ChatGPT response: " + e.message);
                        }
                    } else {
                        addAiMessage("ChatGPT request failed (status " + xhr.status + "): " + xhr.responseText);
                    }
                }
            };

            var messages = [];
            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                messages.push({
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                });
            }
            xhr.send(JSON.stringify({
                "model": activeChatgptModel,
                "messages": messages
            }));

        } else if (provider === "ollama") {
            var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
            var ollamaModel = GlobalConfig.ai.ollamaModel || "llama3";
            var url = ollamaUrl + "/api/chat";
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    isTyping = false;
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.message.content;
                            addAiMessage(reply);
                        } catch (e) {
                            addAiMessage("Error parsing Ollama response: " + e.message);
                        }
                    } else {
                        addAiMessage("Ollama request failed (status " + xhr.status + "). Make sure Ollama is running at " + ollamaUrl);
                    }
                }
            };

            var messages = [];
            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                messages.push({
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                });
            }
            xhr.send(JSON.stringify({
                "model": activeOllamaModel,
                "messages": messages,
                "stream": false
            }));
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Provider Switcher Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            visible: providerRepeater.count > 1

            Repeater {
                id: providerRepeater
                model: {
                    var list = [];
                    if (GlobalConfig.ai.enableGemini) list.push({ id: "gemini", label: "Gemini", icon: "auto_awesome" });
                    if (GlobalConfig.ai.enableChatgpt) list.push({ id: "chatgpt", label: "ChatGPT", icon: "chat" });
                    if (GlobalConfig.ai.enableOllama) list.push({ id: "ollama", label: "Ollama", icon: "terminal" });
                    return list;
                }

                delegate: StyledRect {
                    id: providerBtn

                    required property var modelData

                    readonly property bool active: root.activeProvider === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Tokens.rounding.medium
                    color: active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                    StateLayer {
                        radius: providerBtn.radius
                        color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        onClicked: root.activeProvider = providerBtn.modelData.id
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: providerBtn.modelData.icon
                            color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: providerBtn.modelData.label
                            color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.label.medium
                        }
                    }
                }
            }
        }

        // Model Selector Split Button Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            z: 10

            StyledText {
                text: qsTr("Model:")
                color: Colours.palette.m3onSurface
                font: Tokens.font.label.medium
                Layout.alignment: Qt.AlignVCenter
            }

            SplitButton {
                id: modelSelector
                Layout.fillWidth: true
                type: SplitButton.Tonal

                active: menuItems.find(m => m.modelData === root.currentModel) ?? menuItems[0] ?? null
                menu.onItemSelected: item => {
                    root.setCurrentModel(item.modelData);
                }

                menuItems: modelVariants.instances

                fallbackIcon: "smart_toy"
                fallbackText: qsTr("Select Model")
                stateLayer.disabled: true

                Variants {
                    id: modelVariants
                    model: {
                        if (root.activeProvider === "gemini") {
                            return ["gemini-1.5-flash-latest", "gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro"];
                        } else if (root.activeProvider === "chatgpt") {
                            return ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"];
                        } else if (root.activeProvider === "ollama") {
                            return root.ollamaModelsList.length > 0 ? root.ollamaModelsList : ["llama3", "mistral", "phi3", "gemma"];
                        }
                        return [];
                    }

                    delegate: MenuItem {
                        required property string modelData
                        text: modelData
                        icon: modelSelector.currentModel === modelData ? "check" : ""
                    }
                }
            }
        }

        // Messages List View
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerLow
            clip: true

            ListView {
                id: listView

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium
                model: chatHistory
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: StyledScrollBar {
                    flickable: listView
                }

                delegate: Item {
                    id: delegateItem

                    required property string text
                    required property bool isUser

                    width: listView.width - Tokens.padding.large
                    height: bubbleRect.height

                    StyledRect {
                        id: bubbleRect

                        anchors.right: delegateItem.isUser ? parent.right : undefined
                        anchors.left: delegateItem.isUser ? undefined : parent.left
                        width: Math.min(delegateItem.width * 0.85, messageText.implicitWidth + Tokens.padding.medium * 2)
                        height: messageText.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.large
                        color: delegateItem.isUser ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                        // Asymmetric corners
                        topLeftRadius: Tokens.rounding.large
                        topRightRadius: Tokens.rounding.large
                        bottomLeftRadius: delegateItem.isUser ? Tokens.rounding.large : 4
                        bottomRightRadius: delegateItem.isUser ? 4 : Tokens.rounding.large

                        TextEdit {
                            id: messageText

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            text: delegateItem.text
                            color: delegateItem.isUser ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                propagateComposedEvents: true
                                onPressed: mouse => mouse.accepted = false
                            }
                        }
                    }
                }
            }
        }

        // Loading/Typing status
        RowLayout {
            Layout.fillWidth: true
            visible: root.isTyping
            spacing: Tokens.spacing.small

            LoadingIndicator {
                implicitWidth: 16
                implicitHeight: 16
            }

            StyledText {
                text: qsTr("AI is thinking...")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }

        // Input Box Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: Math.max(38, inputArea.implicitHeight + Tokens.padding.small * 2)
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.large
                border.width: 1
                border.color: inputArea.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.2)

                ScrollView {
                    id: inputScroll

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    clip: true

                    TextArea {
                        id: inputArea

                        placeholderText: qsTr("Ask assistant...")
                        color: Colours.palette.m3onSurface
                        placeholderTextColor: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        wrapMode: Text.Wrap
                        selectByMouse: true
                        background: null

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.IBeamCursor
                            propagateComposedEvents: true
                            onPressed: mouse => mouse.accepted = false
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                event.accepted = true;
                                root.sendPrompt(inputArea.text);
                                inputArea.clear();
                            }
                        }
                    }
                }
            }

            IconButton {
                icon: "send"
                font: Tokens.font.icon.medium
                color: Colours.palette.m3primary
                onClicked: {
                    root.sendPrompt(inputArea.text);
                    inputArea.clear();
                }
            }

            IconButton {
                icon: "delete"
                font: Tokens.font.icon.medium
                color: Colours.palette.m3error
                onClicked: {
                    chatHistory.clear();
                    chatHistory.append({
                        "isUser": false,
                        "text": "Chat cleared. How can I help you today?"
                    });
                    saveHistory();
                }
            }
        }
    }
}
