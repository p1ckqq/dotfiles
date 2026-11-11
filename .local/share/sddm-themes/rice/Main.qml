import QtQuick

// rice — SDDM: обои + дата + большие контурные часы + поле пароля
Rectangle {
    id: root
    width: 2560
    height: 1080
    color: "#101012"

    property color accent: config.stringValue("accent") || "#e6e6ea"
    property bool clock24: config.stringValue("clock24") !== "false"
    property int sessionIdx: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userModel.lastUser || config.stringValue("user") || ""
    property string fontName: "JetBrainsMono Nerd Font"

    // ---------- обои ----------
    Image {
        anchors.fill: parent
        source: config.stringValue("background") || "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.18 }

    // ---------- время ----------
    property string timeText: ""
    property string dateText: ""
    function tick() {
        var n = new Date()
        timeText = Qt.formatTime(n, clock24 ? "HH:mm" : "hh:mm")
        dateText = Qt.formatDate(n, "dddd, MMMM d")
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.tick() }

    Column {
        id: center
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: root.accent
            font.family: root.fontName
            font.pixelSize: 34
            font.weight: Font.Bold
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
        }

        // большие часы: полупрозрачная заливка + светлый контур
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: clock.width
            height: clock.height * 1.25
            Text {
                id: clock
                anchors.centerIn: parent
                text: root.timeText
                color: Qt.rgba(0.86, 0.86, 0.9, 0.92)
                style: Text.Outline
                styleColor: Qt.rgba(0.1, 0.1, 0.12, 0.85)
                font.family: root.fontName
                font.pixelSize: 170
                font.weight: Font.ExtraBold
                font.letterSpacing: -6
                transform: Scale { origin.x: clock.width / 2; origin.y: clock.height / 2; xScale: 0.82; yScale: 1.25 }
            }
        }

        Item { width: 1; height: 14 }

        // поле пароля
        Rectangle {
            id: pwBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: 46
            radius: 23
            color: Qt.rgba(1, 1, 1, pw.activeFocus ? 0.20 : 0.15)

            TextInput {
                id: pw
                anchors.fill: parent
                anchors.leftMargin: 20; anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.accent
                font.family: root.fontName
                font.pixelSize: 18
                focus: true
                clip: true
                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
            }
            Text {
                anchors.centerIn: parent
                visible: pw.text.length === 0
                text: "Enter Password"
                color: root.accent
                opacity: 0.85
                font.family: root.fontName
                font.pixelSize: 15
                font.italic: true
            }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: pwBox; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
                NumberAnimation { target: pwBox; property: "anchors.horizontalCenterOffset"; to: 12;  duration: 50 }
                NumberAnimation { target: pwBox; property: "anchors.horizontalCenterOffset"; to: -6;  duration: 50 }
                NumberAnimation { target: pwBox; property: "anchors.horizontalCenterOffset"; to: 0;   duration: 50 }
            }
        }
    }

    // кнопки питания в углу
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 22
        Repeater {
            model: [ { t: "\u{F0904}", a: "suspend" }, { t: "\u{F0709}", a: "reboot" }, { t: "\u{F0425}", a: "poweroff" } ]
            Text {
                text: modelData.t
                color: root.accent
                opacity: ma.containsMouse ? 1.0 : 0.5
                font.family: root.fontName
                font.pixelSize: 22
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: modelData.a === "suspend" ? sddm.suspend()
                             : modelData.a === "reboot" ? sddm.reboot() : sddm.powerOff()
                }
            }
        }
    }

    // запасной вариант имени: первый пользователь из списка
    Repeater {
        model: userModel
        delegate: Item { Component.onCompleted: if (index === 0 && root.userName === "") root.userName = model.name }
    }

    function doLogin() { sddm.login(root.userName, pw.text, root.sessionIdx) }

    Connections {
        target: sddm
        function onLoginFailed() { pw.text = ""; shake.start() }
    }

    Component.onCompleted: pw.forceActiveFocus()
}
