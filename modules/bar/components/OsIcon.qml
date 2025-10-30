import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    implicitWidth: icon.implicitWidth + Appearance.padding.small * 2
    implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

    StateLayer {
        anchors.fill: parent
        radius: Appearance.rounding.full

        function onClicked(): void {
            root.visibilities.launcher = !root.visibilities.launcher;
        }
    }

    ColouredIcon {
        id: icon

        anchors.centerIn: parent
        source: SysInfo.osLogo
        implicitSize: Appearance.font.size.large * 1.2
        colour: Colours.palette.m3tertiary
    }
}
