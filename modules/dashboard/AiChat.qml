pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    implicitWidth: 700
    implicitHeight: 600

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 56

            color: Colours.palette.m3surface
            
            layer.enabled: true
            layer.effect: DropShadow {
                verticalOffset: 1
                radius: 3
                samples: 7
                color: Qt.rgba(0, 0, 0, 0.1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "auto_awesome"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    text: "Gemini"
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.DemiBold
                    color: Colours.palette.m3onSurface
                }

                Item { Layout.fillWidth: true }

                // Status badge
                StyledRect {
                    Layout.preferredWidth: statusRow.implicitWidth + 16
                    Layout.preferredHeight: 28
                    color: Ai.hasApiKey ? Colours.palette.m3secondaryContainer : Colours.palette.m3errorContainer
                    radius: 14

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Ai.hasApiKey ? Colours.palette.m3secondary : Colours.palette.m3error
                        }

                        StyledText {
                            text: Ai.hasApiKey ? "Connected" : "No API Key"
                            color: Ai.hasApiKey ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onErrorContainer
                            font.pointSize: Appearance.font.size.small
                            font.weight: Font.Medium
                        }
                    }
                }

                IconButton {
                    icon: "delete_sweep"
                    type: IconButton.Text
                    enabled: Ai.messageIDs.length > 0
                    onClicked: Ai.clearMessages()
                    ToolTip.text: "Clear chat"
                }
            }
        }

        // Messages area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: messageList

                anchors.fill: parent
                anchors.margins: Appearance.padding.large

                clip: true
                spacing: Appearance.spacing.normal

                model: Ai.messageIDs

                delegate: MessageBubble {
                    required property int index
                    required property var modelData

                    width: messageList.width
                    messageId: modelData
                }

                onCountChanged: Qt.callLater(() => messageList.positionViewAtEnd())
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: messageList.count === 0
                spacing: Appearance.spacing.large

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "forum"
                    color: Colours.palette.m3primary
                    font.pointSize: 64
                    opacity: 0.6
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Start chatting with Gemini"
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ask anything or get help with your tasks"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }

        // Input area
        StyledRect {
            Layout.fillWidth: true
            Layout.margins: Appearance.padding.large
            Layout.preferredHeight: inputArea.implicitHeight

            color: Colours.palette.m3surfaceContainerHighest
            radius: 28

            ColumnLayout {
                id: inputArea
                width: parent.width
                spacing: 0

                // Warning banner
                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.margins: Appearance.padding.small
                    
                    visible: !Ai.hasApiKey
                    color: Colours.palette.m3errorContainer
                    radius: Appearance.rounding.medium

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.padding.normal
                        anchors.rightMargin: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "info"
                            color: Colours.palette.m3error
                            font.pointSize: Appearance.font.size.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: "Add API key to shell.json: services.geminiApiKey"
                            color: Colours.palette.m3onErrorContainer
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // Input field
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(120, Math.max(40, inputField.contentHeight))

                        TextArea {
                            id: inputField

                            color: Colours.palette.m3onSurface
                            font.family: Appearance.font.family.sans
                            font.pointSize: Appearance.font.size.normal

                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            background: Item {}
                            placeholderText: "Message Gemini..."

                            Keys.onReturnPressed: event => {
                                if (!(event.modifiers & Qt.ShiftModifier)) {
                                    sendMessage();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    IconButton {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        icon: Ai.isGenerating ? "stop_circle" : "send"
                        type: IconButton.Filled
                        enabled: inputField.text.trim().length > 0 || Ai.isGenerating
                        onClicked: sendMessage()
                    }
                }
            }
        }
    }

    function sendMessage() {
        if (Ai.isGenerating) return;
        
        const text = inputField.text.trim();
        if (text.length === 0) return;

        Ai.sendUserMessage(text);
        inputField.text = "";
    }

    // Message component
    component MessageBubble: Item {
        id: bubble

        required property string messageId
        property int revision: 0

        readonly property var msg: { revision; return Ai.messageByID[messageId]; }
        readonly property string content: { revision; return msg?.content || ""; }
        readonly property string role: { revision; return msg?.role || ""; }
        readonly property bool thinking: { revision; return msg?.thinking || false; }
        readonly property bool done: { revision; return msg?.done || false; }
        readonly property bool error: { revision; return msg?.error || false; }
        readonly property bool isUser: role === "user"

        visible: msg !== undefined
        implicitHeight: visible ? bubbleRect.implicitHeight + Appearance.spacing.small : 0

        Connections {
            target: Ai
            function onMessageUpdated(id) { if (id === messageId) revision++; }
            function onMessagesChanged() { revision++; }
        }

        StyledRect {
            id: bubbleRect

            anchors.left: isUser ? undefined : parent.left
            anchors.right: isUser ? parent.right : undefined
            width: {
                const maxWidth = parent.width * 0.8;
                const minWidth = 200;
                const contentWidth = Math.min(maxWidth - Appearance.padding.large * 2, 600);
                return Math.min(maxWidth, Math.max(minWidth, contentWidth + Appearance.padding.large * 2));
            }

            implicitHeight: contentCol.implicitHeight + Appearance.padding.large * 2

            color: {
                if (error) return Colours.palette.m3errorContainer;
                if (isUser) return Colours.palette.m3primaryContainer;
                return Colours.palette.m3secondaryContainer;
            }
            radius: Appearance.rounding.large

            layer.enabled: true
            layer.effect: DropShadow {
                verticalOffset: 1
                radius: 4
                samples: 9
                color: Qt.rgba(0, 0, 0, 0.08)
            }

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.small

                // Thinking animation
                Row {
                    Layout.alignment: Qt.AlignLeft
                    visible: thinking
                    spacing: 6

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Colours.palette.m3onSecondaryContainer

                            SequentialAnimation on scale {
                                running: thinking
                                loops: Animation.Infinite
                                PauseAnimation { duration: Math.max(0, index * 150) }
                                NumberAnimation { from: 1; to: 1.3; duration: 400; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.3; to: 1; duration: 400; easing.type: Easing.InOutSine }
                                PauseAnimation { duration: Math.max(0, (2 - index) * 150) }
                            }
                        }
                    }
                }

                // Message text
                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: parent.width - Appearance.padding.large * 2
                    visible: !thinking
                    text: formatMessage(content)
                    textFormat: isUser ? Text.PlainText : Text.RichText
                    wrapMode: Text.Wrap
                    clip: true
                    color: {
                        if (error) return Colours.palette.m3onErrorContainer;
                        if (isUser) return Colours.palette.m3onPrimaryContainer;
                        return Colours.palette.m3onSecondaryContainer;
                    }
                    font.pointSize: Appearance.font.size.normal
                }

                // Actions
                RowLayout {
                    Layout.fillWidth: true
                    visible: !isUser && !thinking && done
                    spacing: Appearance.spacing.small

                    Item { Layout.fillWidth: true }

                    IconButton {
                        icon: "refresh"
                        type: IconButton.Text
                        onClicked: Ai.retryMessage(messageId)
                        ToolTip.text: "Retry"
                    }

                    IconButton {
                        icon: "content_copy"
                        type: IconButton.Text
                        onClicked: Quickshell.clipboardText = content
                        ToolTip.text: "Copy"
                    }
                }
            }
        }

        function formatMessage(text) {
            if (isUser) return text;

            let html = text
                // Code blocks
                .replace(/```([\s\S]*?)```/g, '<pre style="background: rgba(0,0,0,0.1); padding: 12px; border-radius: 8px; margin: 8px 0;"><code>$1</code></pre>')
                // Inline code
                .replace(/`([^`]+)`/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 6px; border-radius: 4px;">$1</code>')
                // Bold
                .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
                // Italic
                .replace(/\*(.+?)\*/g, '<em>$1</em>')
                // Line breaks
                .replace(/\n/g, '<br>');

            return html;
        }
    }
}