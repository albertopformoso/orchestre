import QtQuick

Item {
    id: clock

    // Kept for compatibility with Main.qml's external bindings —
    // not used for rendering below.
    property string backgroundSource: ""
    property color baseAccent: config.accentColor
    property string fontFamily: "Google Sans Flex"

    property color textColor: '#e8939497'
    property string clockFontFamily: "Google Sans Flex Medium Rounded"

    property string hourStr: ""
    property string minuteStr: ""

    function updateTime() {
        var date = new Date();
        var hours = date.getHours();
        var minutes = date.getMinutes();

        if (config.use24HourClock !== "true") {
            hours = hours % 12;
            if (hours === 0) hours = 12;
        }

        clock.hourStr = hours < 10 ? "0" + hours : "" + hours;
        clock.minuteStr = minutes < 10 ? "0" + minutes : "" + minutes;
    }

    Component.onCompleted: updateTime()

    Column {
        anchors.centerIn: parent
        spacing: -25

        Text {
            text: clock.hourStr
            color: clock.textColor
            font.pixelSize: 100
            font.family: clock.clockFontFamily
            anchors.horizontalCenter: parent.horizontalCenter
            antialiasing: true
        }

        Text {
            text: clock.minuteStr
            color: clock.textColor
            font.pixelSize: 100
            font.family: clock.clockFontFamily
            anchors.horizontalCenter: parent.horizontalCenter
            antialiasing: true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateTime()
    }
}
