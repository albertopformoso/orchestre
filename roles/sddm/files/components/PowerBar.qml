import QtQuick
import QtQuick.Controls

Row {
    id: powerBarRoot
    spacing: 8
    height: 32

    property color textColor: "#9398a1"
    property color activeTextColor: "#ffffff"
    readonly property string barFontFamily: "Symbols Nerd Font Mono"

    Repeater {
        model: [
            { action: "layout", label: "Keyboard layout", icon: "" },
            { action: "suspend", label: "Suspend", icon: "󰤄" },
            { action: "reboot", label: "Restart", icon: "󰜉" },
            { action: "powerOff", label: "Power off", icon: "󰐥" }
        ]

        Button {
            id: control
            required property var modelData
            width: modelData.action === "layout" ? Math.max(40, contentItem.implicitWidth + 16) : 36
            height: powerBarRoot.height
            visible: modelData.action !== "layout" || (typeof keyboard !== "undefined" && keyboard.layouts.length > 1)
            hoverEnabled: true
            focusPolicy: Qt.TabFocus
            Accessible.name: modelData.label

            ToolTip {
                id: tooltip
                visible: control.hovered
                text: control.modelData.label
                delay: 500
                x: (control.width - width) / 2
                y: control.height + 8
                margins: 8
                padding: 8

                background: Rectangle {
                    color: Qt.rgba(0.08, 0.08, 0.09, 0.9)
                    radius: 3
                    border.width: 0
                }

                contentItem: Text {
                    text: tooltip.text
                    font: tooltip.font
                    color: "#f5f6f8"
                }
            }

            background: Item {}

            contentItem: Text {
                text: control.modelData.action === "layout"
                    ? ((typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout]) ? keyboard.layouts[keyboard.currentLayout].shortName : "US")
                    : control.modelData.icon
                color: control.hovered || control.activeFocus ? powerBarRoot.activeTextColor : powerBarRoot.textColor
                Behavior on color { ColorAnimation { duration: 150 } }
                font.pixelSize: 20
                // The layout label keeps its existing default font.
                font.family: control.modelData.action === "layout" ? Qt.application.font.family : powerBarRoot.barFontFamily
                font.capitalization: Font.AllUppercase
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                switch (modelData.action) {
                case "layout": keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; break;
                case "suspend": sddm.suspend(); break;
                case "reboot": sddm.reboot(); break;
                case "powerOff": sddm.powerOff(); break;
                }
            }
        }
    }
}
