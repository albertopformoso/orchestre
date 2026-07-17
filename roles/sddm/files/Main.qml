import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components"

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.backgroundColor
    focus: !loginState.visible

    // User & Session Logic (Root Level)
    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false

    // Glass palette
    property color glassFill: Qt.rgba(1, 1, 1, 0.08)
    property color glassFillHover: Qt.rgba(1, 1, 1, 0.14)
    property color glassBorder: Qt.rgba(1, 1, 1, 0.15)
    property color textPrimary: Qt.rgba(1, 1, 1, 0.92)
    property color textSecondary: Qt.rgba(1, 1, 1, 0.55)

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0) userIndex = userModel.lastIndex;
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) sessionIndex = sessionModel.lastIndex;
    }

    function cleanName(name) {
        if (!name) return "";
        var s = name.toString();
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        if (s.indexOf("/") !== -1) s = s.substring(s.lastIndexOf("/") + 1);
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"));
        s = s.replace(/[-_]/g, ' ');
        return s;
    }

    function doLogin() {
        if (!loginState.visible || isLoggingIn) return;

        var user = "";
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex;
            if (idx < 0 || idx >= userModel.count) idx = 0;

            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole);
            var nameRole = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1);
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole);

            user = edit ? edit.toString() : (nameRole ? nameRole.toString() : (display ? display.toString() : ""));
        }

        if (!user || user === "" || user === "User") {
            user = sddm.lastUser;
        }

        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var firstEdit = userModel.data(userModel.index(0, 0), Qt.EditRole);
            user = firstEdit ? firstEdit.toString() : "";
        }

        if (!user) return;

        container.isLoggingIn = true;
        var pass = passwordField.text;
        var sess = container.sessionIndex;

        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count) sess = 0;
        } else {
            sess = 0;
        }

        console.log("SDDM: Attempting login for user [" + user + "] session index [" + sess + "]");
        sddm.login(user.trim(), pass, sess);
        loginTimeout.start();
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: container.isLoggingIn = false
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            container.isLoggingIn = false
            loginTimeout.stop()
            loginState.isError = true
            shakeAnimation.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            loginTimeout.stop()
        }
    }

    FontLoader { id: fontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: fontMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: fontBold; source: "assets/fonts/FlexRounded-B.ttf" }

    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    // High-Quality Standalone Blur (Qt6 Native)
    MultiEffect {
        id: backgroundBlur
        anchors.fill: parent
        source: backgroundImage
        blurEnabled: true
        blur: loginState.visible ? 1.0 : 0.0
        opacity: loginState.visible ? 1.0 : 0.0
        autoPaddingEnabled: false

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        Behavior on blur { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginState.visible ? 0.6 : 0.4
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    PowerBar {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        z: 100
        opacity: 1
    }

    Shortcut {
        sequence: "Escape"
        enabled: loginState.visible
        onActivated: {
            loginState.visible = false;
            loginState.isError = false;
            passwordField.text = "";
            container.focus = true;
        }
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: loginState.visible
        onActivated: container.doLogin()
    }

    Text {
        id: dateText
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: container.textPrimary
        font.pixelSize: 20
        font.family: fontRegular.name
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 12
            leftMargin: 20
        }
        opacity: 1
    }

    Item {
        id: lockState
        anchors.fill: parent
        visible: !loginState.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Clock {
            id: mainClock
            anchors.centerIn: parent
            backgroundSource: config.background
            baseAccent: container.textPrimary
            fontFamily: fontRegular.name
            opacity: 1
        }

        Text {
            text: "Press any key to unlock"
            color: config.textColor
            font.pixelSize: 20
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 100
            }
            opacity: 0.5
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginState.visible = true;
                passwordField.forceActiveFocus();
            }
        }
    }

    Item {
        id: loginState
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 400 } }

        onVisibleChanged: {
            if (visible) passwordField.forceActiveFocus();
        }

        property bool isError: false
        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2; to: (parent.width - loginCard.width)/2 - 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2 - 10; to: (parent.width - loginCard.width)/2 + 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2 + 10; to: (parent.width - loginCard.width)/2; duration: 50; easing.type: Easing.InOutQuad }
            onStopped: isError = false
        }

        Rectangle {
            id: loginCard
            width: 380
            height: 480 + (numLockIndicator.visible ? 40 : 0)
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: loginState.isError ? Qt.rgba(0.25, 0.05, 0.05, 0.45) : container.glassFill
            opacity: 1.0
            border.color: container.glassBorder
            border.width: 1
            radius: 16

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                shadowBlur: 0.2
                shadowVerticalOffset: 3
                shadowHorizontalOffset: 0
                blurMax: 8
            }

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 15

                // Swapped directly to instant opacity shift
                opacity: (userPopup.opened || (typeof sessionPopup !== "undefined" && sessionPopup.opened)) ? 0.20 : 1.0

                Item {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: avatarFallback
                        anchors.fill: parent
                        color: container.glassFill
                        radius: width / 2
                        visible: avatar.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var n = "";
                                if (typeof userModel !== "undefined" && userModel.count > 0) {
                                    var d = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole);
                                    var nr = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 1);
                                    n = d ? d.toString() : (nr ? nr.toString() : "U");
                                } else {
                                    n = sddm.lastUser ? sddm.lastUser : "U";
                                }
                                return n.charAt(0);
                            }
                            color: container.textPrimary
                            font.pixelSize: 48
                            font.family: fontBold.name
                            font.weight: Font.Bold
                        }
                    }

                    Canvas {
                        id: avatarCanvas
                        anchors.fill: parent
                        visible: avatar.status === Image.Ready

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.beginPath();
                            ctx.arc(width/2, height/2, width/2, 0, 2 * Math.PI);
                            ctx.closePath();
                            ctx.clip();
                            ctx.drawImage(avatar, 0, 0, width, height);
                            console.log("SDDM: Canvas draw complete.");
                        }

                        Timer {
                            id: repaintTimer
                            interval: 500
                            onTriggered: avatarCanvas.requestPaint()
                        }

                        Image {
                            id: avatar
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: false

                            property var fallbackExtensions: ["jpg", "jpeg", "png", "webp", "bmp"]
                            property int fallbackIndex: 0
                            property bool usingBundledDefault: false

                            function tryNextFallback() {
                                if (fallbackIndex >= fallbackExtensions.length) {
                                    console.log("SDDM: No avatar file found with any known extension.");
                                    return;
                                }
                                var ext = fallbackExtensions[fallbackIndex];
                                fallbackIndex++;
                                source = Qt.resolvedUrl("assets/avatar." + ext);
                            }

                            Component.onCompleted: {
                                var s = "";
                                if (typeof userModel !== "undefined" && userModel.count > 0) {
                                    var icon = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 3);
                                    if (icon && icon.toString().match(/\.(jpg|jpeg|png|bmp|webp|svg)$/i)) {
                                        s = icon.toString();
                                    }
                                }
                                if (s !== "") {
                                    source = s;
                                } else {
                                    avatar.usingBundledDefault = true;
                                    avatar.tryNextFallback();
                                }
                            }

                            onStatusChanged: {
                                if (status === Image.Ready) {
                                    console.log("SDDM: Image ready, repainting Canvas.");
                                    repaintTimer.start();
                                } else if (status === Image.Error && avatar.usingBundledDefault) {
                                    avatar.tryNextFallback();
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: userNameLabel.width + 40
                    Layout.preferredHeight: userNameLabel.height + 20
                    Layout.topMargin: 10

                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: userClickArea.pressed ? 0.2 : 0
                        radius: 6
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    Text {
                        id: userNameLabel
                        anchors.centerIn: parent
                        text: {
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var idx = container.userIndex;
                                var modelIdx = userModel.index(idx, 0);
                                var display = userModel.data(modelIdx, Qt.DisplayRole);
                                var edit = userModel.data(modelIdx, Qt.EditRole);
                                var nr = userModel.data(modelIdx, Qt.UserRole + 1);
                                var realName = userModel.data(modelIdx, Qt.UserRole + 2);
                                var finalName = display ? display.toString() : (realName ? realName.toString() : (nr ? nr.toString() : (edit ? edit.toString() : "User")));
                                return cleanName(finalName) + (userModel.count > 1 ? " ▾" : "");
                            }
                            return cleanName(sddm.lastUser ? sddm.lastUser : "User");
                        }
                        color: container.textPrimary
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: fontRegular.name
                    }

                    MouseArea {
                        id: userClickArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: userPopup.open()
                    }

                    scale: userClickArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                Rectangle {
                    id: sessionPill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 36
                    color: (sessionClickArea.pressed || sessionPopup.opened) ? container.glassFillHover : container.glassFill
                    radius: 18
                    border.width: 1
                    border.color: (sessionClickArea.pressed || sessionPopup.opened) ? container.textPrimary : container.glassBorder

                    scale: sessionClickArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰟀"
                            color: container.textPrimary
                            font.pixelSize: 16
                        }
                        Text {
                            text: {
                                if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
                                    var idx = container.sessionIndex;
                                    var modelIdx = sessionModel.index(idx, 0);
                                    var n = sessionModel.data(modelIdx, Qt.UserRole + 4);
                                    var f = sessionModel.data(modelIdx, Qt.UserRole + 2);
                                    var d = sessionModel.data(modelIdx, Qt.DisplayRole);
                                    var finalName = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : "Session " + (idx + 1)));
                                    return cleanName(finalName) + (sessionModel.count > 1 ? " ▾" : "");
                                }
                                return "Hyprland";
                            }
                            color: container.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: sessionClickArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionPopup.open()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    Layout.preferredHeight: 40
                    spacing: 10

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        echoMode: TextInput.Password
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 18
                        color: container.textPrimary
                        focus: loginState.visible
                        enabled: !container.isLoggingIn

                        background: Rectangle {
                            color: parent.activeFocus ? container.glassFillHover : container.glassFill
                            radius: 8
                            border.width: 1
                            border.color: parent.activeFocus ? container.textPrimary : container.glassBorder
                            opacity: parent.enabled ? 1.0 : 0.5
                        }

                        Text {
                            text: "Enter Password"
                            color: container.textSecondary
                            font.pixelSize: 16
                            visible: !parent.text
                            anchors.centerIn: parent
                            opacity: 0.5
                        }

                        onAccepted: container.doLogin()
                    }
                }
                
                Text {
                    id: numLockIndicator
                    text: {
                        var capsOn = (typeof keyboard !== "undefined" && typeof keyboard.capsLock !== "undefined") ? keyboard.capsLock : false;
                        var numOn = (typeof keyboard !== "undefined" && typeof keyboard.numLock !== "undefined") ? keyboard.numLock : false;
                        if (capsOn && numOn) return "Caps Lock & Num Lock are on";
                        if (capsOn) return "Caps Lock is on";
                        if (numOn) return "Num Lock is on";
                        return "";
                    }
                    color: container.textPrimary
                    font.pixelSize: 14
                    font.family: fontRegular.name
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignLeft
                    visible: text !== ""
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        if (!loginState.visible) {
            loginState.visible = true;
            passwordField.forceActiveFocus();
            event.accepted = true;
        }
    }

    Popup {
        id: userPopup
        width: 260
        height: (typeof userModel !== "undefined") ? Math.min(300, userModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 - 50
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: userList.forceActiveFocus()
        background: Rectangle {
            color: Qt.rgba(0.12, 0.12, 0.12, 0.88)
            radius: 16
            opacity: 0.95
            border.color: container.glassBorder
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.15
                shadowVerticalOffset: 4
            }
        }
        // Removed enter/exit transitions for instant visibility changes
        ListView {
            id: userList
            anchors.fill: parent
            anchors.margins: 10
            model: (typeof userModel !== "undefined") ? userModel : null
            spacing: 5
            clip: true
            focus: true
            currentIndex: container.userIndex
            highlightFollowsCurrentItem: true
            delegate: ItemDelegate {
                width: parent.width
                height: 40
                property bool isCurrent: index === userList.currentIndex
                background: Rectangle {
                    color: isCurrent ? Qt.rgba(1, 1, 1, 0.15) : (hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    radius: 8
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: container.textPrimary
                        radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: isCurrent ? container.textPrimary : Qt.rgba(1, 1, 1, 0.1)
                        radius: 14
                        Text {
                            anchors.centerIn: parent
                            text: {
                                var mIdx = userModel.index(index, 0);
                                var d = userModel.data(mIdx, Qt.DisplayRole);
                                var n_r = userModel.data(mIdx, Qt.UserRole + 1);
                                var finalVal = d ? d.toString() : (n_r ? n_r.toString() : "U");
                                return finalVal.charAt(0);
                            }
                            color: isCurrent ? "black" : "white"
                            font.pixelSize: 12
                            font.family: fontBold.name
                            font.weight: Font.Bold
                        }
                    }
                    Item { Layout.preferredWidth: 12 }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var mIdx = userModel.index(index, 0);
                            var d = userModel.data(mIdx, Qt.DisplayRole);
                            var n_r = userModel.data(mIdx, Qt.UserRole + 1);
                            var r = userModel.data(mIdx, Qt.UserRole + 2);
                            var e = userModel.data(mIdx, Qt.EditRole);
                            return cleanName(d ? d : (r ? r : (n_r ? n_r : e)));
                        }
                        color: isCurrent ? "white" : (hovered ? "#FFFFFF" : "#DDDDDD")
                        font.pixelSize: 15
                        font.family: fontRegular.name
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60
                        elide: Text.ElideRight
                    }
                }
                onClicked: {
                    container.userIndex = index;
                    userPopup.close();
                }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.userIndex = currentIndex; userPopup.close(); }
            Keys.onEnterPressed: { container.userIndex = currentIndex; userPopup.close(); }
        }
    }

    Popup {
        id: sessionPopup
        width: 260
        height: (typeof sessionModel !== "undefined") ? Math.min(250, sessionModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + 80
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: sessionList.forceActiveFocus()
        background: Rectangle {
            color: Qt.rgba(0.12, 0.12, 0.12, 0.88)
            radius: 16
            opacity: 0.95
            border.color: container.glassBorder
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.15
                shadowVerticalOffset: 4
            }
        }
        // Removed enter/exit transitions for instant visibility changes
        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 10
            model: (typeof sessionModel !== "undefined") ? sessionModel : null
            spacing: 5
            clip: true
            focus: true
            currentIndex: container.sessionIndex
            highlightFollowsCurrentItem: true
            delegate: ItemDelegate {
                width: parent.width
                height: 40
                property bool isCurrent: index === sessionList.currentIndex
                background: Rectangle {
                    color: isCurrent ? Qt.rgba(1, 1, 1, 0.15) : (hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    radius: 8
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: container.textPrimary
                        radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Text {
                        Layout.preferredWidth: 40
                        text: "󰟀"
                        color: isCurrent ? container.textPrimary : "gray"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var n_val = sessionModel.data(sessionModel.index(index, 0), Qt.UserRole + 4);
                            var f_val = sessionModel.data(sessionModel.index(index, 0), Qt.UserRole + 2);
                            return cleanName(n_val ? n_val : f_val);
                        }
                        color: isCurrent ? "white" : "#AAAAAA"
                        font.pixelSize: 14
                        font.family: fontRegular.name
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60
                        elide: Text.ElideRight
                    }
                }
                onClicked: {
                    container.sessionIndex = index;
                    sessionPopup.close();
                }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.sessionIndex = currentIndex; sessionPopup.close(); }
            Keys.onEnterPressed: { container.sessionIndex = currentIndex; sessionPopup.close(); }
        }
    }
}
