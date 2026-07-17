import QtQuick

Row {
    id: powerBarRoot
    spacing: 20
    height: 20

    property color textColor: "#8CD8DEE9"
    readonly property string barFontFamily: "Symbols Nerd Font Mono"

    // Keyboard Layout
    Text {
        text: (typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout]) ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
        color: textColor
        font.pixelSize: 20
        font.capitalization: Font.AllUppercase
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    // Suspend
    Text {
        text: "󰤄"
        color: textColor
        font.pixelSize: 20
        font.family: barFontFamily
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.suspend()
        }
    }

    // Restart
    Text {
        text: "󰜉"
        color: textColor
        font.pixelSize: 20
        font.family: barFontFamily
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.reboot()
        }
    }

    // Power off
    Text {
        text: "󰐥"
        color: textColor
        font.pixelSize: 20
        font.family: barFontFamily
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.powerOff()
        }
    }
}
