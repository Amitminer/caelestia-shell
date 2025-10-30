pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: stopwatchState

    property int elapsedTime: 0
    property bool isRunning: false
    property int startTime: 0

    function start() {
        if (!isRunning) {
            startTime = Date.now() - elapsedTime;
            isRunning = true;
        }
    }

    function stop() {
        if (isRunning) {
            isRunning = false;
        }
    }

    function reset() {
        stop();
        elapsedTime = 0;
        startTime = 0;
    }

    function toggle() {
        if (isRunning) {
            stop();
        } else {
            start();
        }
    }

    property Timer timer: Timer {
        interval: 10
        repeat: true
        running: stopwatchState.isRunning
        onTriggered: {
            if (stopwatchState.isRunning) {
                stopwatchState.elapsedTime = Date.now() - stopwatchState.startTime;
            }
        }
    }
}
