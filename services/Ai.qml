pragma Singleton
import qs.config
import Quickshell
import QtQuick

Singleton {
    id: root

    // API Configuration
    property string apiKey: Config.services.geminiApiKey
    property string apiUrl: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    property bool hasApiKey: apiKey !== ""

    // Model information
    property var models: ({
            "gemini": {
                name: "Gemini 2.5 Flash",
                id: "gemini",
                provider: "google"
            }
        })
    property string currentModelId: "gemini"
    property bool currentModelHasApiKey: hasApiKey

    // Message management
    property var messageIDs: []
    property var messageByID: ({})
    property int nextMessageId: 1

    // Status
    property bool isGenerating: false

    // Configuration
    property var generationConfig: ({
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048
        })

    property bool enableConversationHistory: true
    property int maxHistoryMessages: 10

    // Signals
    signal messageUpdated(string messageId)
    signal messagesChanged
    signal errorOccurred(string error)

    Component.onCompleted: {
        if (hasApiKey) {
            console.log("Gemini API initialized successfully");
        } else {
            console.warn("Gemini API key not set. Add to shell.json: services.geminiApiKey");
        }
    }

    // Public API
    function sendUserMessage(content) {
        if (!_validateMessage(content))
            return;

        const userMsgId = _createUserMessage(content);
        const assistantMsgId = _createAssistantMessage();

        _triggerReactivity();
        _emitSignals([userMsgId, assistantMsgId]);

        _sendToGemini(assistantMsgId);
    }

    function clearMessages() {
        messageIDs = [];
        messageByID = {};
        nextMessageId = 1;
        messagesChanged();
    }

    function deleteMessage(messageId) {
        if (!messageByID[messageId])
            return;

        delete messageByID[messageId];
        const index = messageIDs.indexOf(messageId);
        if (index > -1) {
            messageIDs = messageIDs.filter((_, i) => i !== index);
        }

        messageByID = Object.assign({}, messageByID);
        messagesChanged();
    }

    function retryMessage(messageId) {
        const message = messageByID[messageId];
        if (!message || message.role !== "assistant")
            return;

        updateMessage(messageId, {
            content: "",
            thinking: true,
            done: false,
            error: false
        });

        _sendToGemini(messageId);
    }

    function updateMessage(messageId, updates) {
        if (!messageByID[messageId])
            return;

        const message = messageByID[messageId];
        Object.assign(message, updates);

        messageByID = Object.assign({}, messageByID);
        messageUpdated(messageId);
        messagesChanged();
    }

    function exportConversation() {
        return messageIDs.map(id => ({
                    role: messageByID[id].role,
                    content: messageByID[id].content,
                    timestamp: messageByID[id].timestamp
                }));
    }

    // Private functions
    function _validateMessage(content) {
        if (!content || content.trim() === "") {
            console.warn("Empty message not sent");
            return false;
        }
        return true;
    }

    function _createUserMessage(content) {
        const msgId = "msg_" + nextMessageId++;
        const message = {
            id: msgId,
            role: "user",
            content: content.trim(),
            timestamp: new Date(),
            done: true
        };

        messageByID[msgId] = message;
        messageIDs = [...messageIDs, msgId];

        return msgId;
    }

    function _createAssistantMessage() {
        const msgId = "msg_" + nextMessageId++;
        const message = {
            id: msgId,
            role: "assistant",
            content: "",
            timestamp: new Date(),
            thinking: true,
            done: false
        };

        messageByID[msgId] = message;
        messageIDs = [...messageIDs, msgId];

        return msgId;
    }

    function _triggerReactivity() {
        messageByID = Object.assign({}, messageByID);
    }

    function _emitSignals(messageIds) {
        messagesChanged();
        messageIds.forEach(id => messageUpdated(id));
    }

    function _buildConversationHistory() {
        if (!enableConversationHistory) {
            return [];
        }

        const recentMessages = messageIDs.slice(-maxHistoryMessages).filter(id => {
            const msg = messageByID[id];
            return msg && msg.done && !msg.error;
        }).map(id => {
            const msg = messageByID[id];
            return {
                role: msg.role === "user" ? "user" : "model",
                parts: [
                    {
                        text: msg.content
                    }
                ]
            };
        });

        return recentMessages;
    }

    function _sendToGemini(messageId) {
        if (!hasApiKey) {
            _handleError(messageId, "Gemini API key not configured. Add to shell.json: services.geminiApiKey");
            return;
        }

        isGenerating = true;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", apiUrl + "?key=" + apiKey);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isGenerating = false;
                _handleResponse(xhr, messageId);
            }
        };

        xhr.onerror = function () {
            isGenerating = false;
            _handleError(messageId, "Network error occurred");
        };

        xhr.ontimeout = function () {
            isGenerating = false;
            _handleError(messageId, "Request timed out");
        };

        xhr.timeout = 30000; // 30 second timeout

        const requestBody = _buildRequestBody();
        xhr.send(JSON.stringify(requestBody));
    }

    function _buildRequestBody() {
        const history = _buildConversationHistory();

        return {
            contents: history,
            generationConfig: generationConfig,
            safetySettings: [
                {
                    category: "HARM_CATEGORY_HARASSMENT",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                    category: "HARM_CATEGORY_HATE_SPEECH",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                    category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                    category: "HARM_CATEGORY_DANGEROUS_CONTENT",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                }
            ]
        };
    }

    function _handleResponse(xhr, messageId) {
        if (xhr.status === 200) {
            _handleSuccess(xhr.responseText, messageId);
        } else {
            _handleHttpError(xhr, messageId);
        }
    }

    function _handleSuccess(responseText, messageId) {
        try {
            const response = JSON.parse(responseText);
            const content = _extractContent(response);

            updateMessage(messageId, {
                content: content,
                thinking: false,
                done: true
            });
        } catch (e) {
            _handleError(messageId, "Failed to parse response: " + e.message);
        }
    }

    function _extractContent(response) {
        if (!response.candidates || !response.candidates[0]) {
            return "No response received from API";
        }

        const candidate = response.candidates[0];

        // Check for blocked content
        if (candidate.finishReason === "SAFETY") {
            return "Response blocked by safety filters";
        }

        if (!candidate.content || !candidate.content.parts || !candidate.content.parts[0]) {
            return "Empty response received";
        }

        return candidate.content.parts[0].text || "No text in response";
    }

    function _handleHttpError(xhr, messageId) {
        let errorMessage = `HTTP ${xhr.status}: `;

        try {
            const errorResponse = JSON.parse(xhr.responseText);
            errorMessage += errorResponse.error?.message || xhr.statusText || "Unknown error";
        } catch (e) {
            errorMessage += xhr.statusText || "Request failed";
        }

        _handleError(messageId, errorMessage);
    }

    function _handleError(messageId, errorMessage) {
        console.error("Gemini API error:", errorMessage);

        updateMessage(messageId, {
            content: errorMessage,
            thinking: false,
            done: true,
            error: true
        });

        errorOccurred(errorMessage);
    }
}
