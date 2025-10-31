pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.stopwatch

    // Header
    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Stopwatch")
        font.weight: 500
        color: Qt.rgba(1, 1, 1, 0.87) //Hardcoded: white with 87% opacity for header text
    }

    // Time Display
    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: timeDisplay.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        StyledText {
            id: timeDisplay
            anchors.centerIn: parent

            property int hours: Math.floor(StopwatchState.elapsedTime / 3600000)
            property int minutes: Math.floor((StopwatchState.elapsedTime % 3600000) / 60000)
            property int seconds: Math.floor((StopwatchState.elapsedTime % 60000) / 1000)
            property int milliseconds: Math.floor((StopwatchState.elapsedTime % 1000) / 10)

            text: {
                if (hours > 0) {
                    return String(hours).padStart(2, '0') + ":" + String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0');
                } else {
                    return String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0') + "." + String(milliseconds).padStart(2, '0');
                }
            }

            color: Qt.rgba(1, 1, 1, 0.87)
            font.pointSize: Appearance.font.size.large
            font.family: Appearance.font.family.mono
            font.weight: 500
        }
    }

    // Control Buttons
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        // Start/Stop Button
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: startStopBtn.implicitHeight + Appearance.padding.small * 2

            radius: Appearance.rounding.full
            color: StopwatchState.isRunning ? Colours.palette.m3errorContainer : Colours.palette.m3primary

            StateLayer {
                color: StopwatchState.isRunning ? Colours.palette.m3onErrorContainer : Colours.palette.m3primaryContainer

                function onClicked(): void {
                    StopwatchState.toggle();
                }
            }

            RowLayout {
                id: startStopBtn
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    animate: true
                    text: StopwatchState.isRunning ? "pause" : "play_arrow"
                    color: StopwatchState.isRunning ? Colours.palette.m3onErrorContainer : Colours.palette.m3primaryContainer
                }

                StyledText {
                    text: StopwatchState.isRunning ? qsTr("Pause") : qsTr("Start")
                    color: StopwatchState.isRunning ? Colours.palette.m3onErrorContainer : Colours.palette.m3primaryContainer
                    font.weight: 500
                }
            }
        }

        // Reset Button
        StyledRect {
            Layout.preferredWidth: resetBtn.implicitWidth + Appearance.padding.small * 2
            Layout.preferredHeight: resetBtn.implicitHeight + Appearance.padding.small * 2

            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainer

            StateLayer {
                color: Qt.rgba(1, 1, 1, 0.87)
                disabled: StopwatchState.elapsedTime === 0

                function onClicked(): void {
                    StopwatchState.reset();
                }
            }

            MaterialIcon {
                id: resetBtn
                anchors.centerIn: parent
                animate: true
                text: "restart_alt"
                color: StopwatchState.elapsedTime === 0 ? Colours.palette.m3onSurfaceVariant : Qt.rgba(1, 1, 1, 0.87)
                opacity: StopwatchState.elapsedTime === 0 ? 0.5 : 1

                Behavior on opacity {
                    Anim {}
                }
            }
        }
    }

    // Status
    StyledText {
        Layout.topMargin: Appearance.spacing.small
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Status: %1").arg(StopwatchState.isRunning ? qsTr("Running") : (StopwatchState.elapsedTime > 0 ? qsTr("Paused") : qsTr("Ready")))
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pointSize: Appearance.font.size.small
    }
}
