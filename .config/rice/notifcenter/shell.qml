//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Центр уведомлений: плитки CPU/RAM/диск, быстрые кнопки, список уведомлений, всплывающие тосты.
// Управление: qs -c notifcenter ipc call center toggle | dnd | close
ShellRoot {
    id: root

    property bool open: false
    property bool dnd: false
    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: home + "/.local/bin/"
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int count: server.trackedNotifications.values.length

    // ---------- сервер уведомлений ----------
    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => { n.tracked = true }
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss()
    }

    // ---------- счётчик для waybar (custom/notify читает этот файл через tail -F) ----------
    FileView {
        id: stateFile
        path: root.home + "/.cache/rice/notify.json"
    }
    function publish() {
        const alt = (root.dnd ? "dnd-" : "") + (root.count > 0 ? "notification" : "none")
        stateFile.setText(JSON.stringify({ text: root.count > 0 ? String(root.count) : "", alt: alt }) + "\n")
    }
    onCountChanged: publish()
    onDndChanged: publish()
    Component.onCompleted: publish()

    IpcHandler {
        target: "center"
        function toggle(): void { root.open = !root.open }
        function close(): void { root.open = false }
        function dnd(): void { root.dnd = !root.dnd }
    }

    // ---------- статистика (опрашиваем только пока панель открыта) ----------
    property int cpu: 0
    property int temp: 0
    property int ram: 0
    property int disk: 0
    Process {
        id: statsProc
        command: ["sh", Quickshell.shellDir + "/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ").map(Number)
                if (p.length === 4 && !p.some(isNaN)) { root.cpu = p[0]; root.temp = p[1]; root.ram = p[2]; root.disk = p[3] }
            }
        }
    }

    // ---------- быстрые кнопки ----------
    property var states: ({})
    readonly property var buttons: [
        { id: "wifi",  icon: "", label: "Wi-Fi",      status: "rice-qs wifi-status", toggle: "rice-qs wifi-toggle" },
        { id: "lofi",  icon: "", label: "Lo-fi",      status: "rice-lofi status",    toggle: "rice-lofi toggle", close: true },
        { id: "vpn",   icon: "", label: "VPN",        status: "rice-happ status",    toggle: "rice-happ", close: true },
        { id: "bt",    icon: "", label: "Bluetooth",  status: "rice-qs bt-status",   toggle: "rice-qs bt-toggle" },
        { id: "mic",   icon: "", label: "Микрофон",   status: "rice-qs mic-status",  toggle: "rice-qs mic-toggle" },
        { id: "shot",  icon: "", label: "Скриншот",   toggle: "sleep 0.4; grim -g \"$(slurp)\" - | wl-copy", close: true }
    ]
    Process {
        id: statusProc
        command: ["sh", "-c", "export PATH=\"$HOME/.local/bin:$PATH\"; "
            + root.buttons.filter(b => b.status).map(b => "echo " + b.id + "=$(" + b.status + ")").join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) s[line.slice(0, i)] = line.slice(i + 1).trim() === "true"
                }
                root.states = s
            }
        }
    }
    function refreshStatus() { if (!statusProc.running) statusProc.running = true }
    function run(b) {
        Quickshell.execDetached(["sh", "-c", "export PATH=\"$HOME/.local/bin:$PATH\"; " + b.toggle])
        if (b.close) root.open = false
        else { refreshTimer.restart() }
    }
    Timer { id: refreshTimer; interval: 700; onTriggered: root.refreshStatus() }

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.open
        onTriggered: { if (!statsProc.running) statsProc.running = true; root.refreshStatus() }
    }

    // ---------- вспомогательные компоненты ----------
    component Glyph: Text {
        font.family: root.font
        color: Colors.on_surface
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component Tile: ClippingRectangle {
        id: tile
        property string icon
        property int value
        property string extra: ""
        property color tint: Colors.primary
        Layout.fillWidth: true
        Layout.preferredHeight: 92
        radius: 22
        color: Colors.surface_container_high
        // заливка снизу вверх по значению
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * Math.min(tile.value, 100) / 100
            color: Qt.alpha(tile.tint, 0.22)
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Glyph { text: tile.icon; color: tile.tint; font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter }
            Glyph { text: tile.value + "%"; font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        }
        Glyph {
            visible: tile.extra !== ""
            text: tile.extra
            font.pixelSize: 11
            color: Colors.on_surface_variant
            anchors { top: parent.top; right: parent.right; margins: 8 }
        }
    }

    // Карточка уведомления (в панели и в тостах)
    component Card: Rectangle {
        id: card
        required property var n
        property bool toast: false
        signal dismissed()
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 24
        radius: 18
        color: toast ? Qt.alpha(Colors.surface_container_highest, 0.95) : Colors.surface_container_high
        border.width: n.urgency === NotificationUrgency.Critical ? 2 : (toast ? 1 : 0)
        border.color: n.urgency === NotificationUrgency.Critical ? Colors.error : Colors.outline_variant

        RowLayout {
            id: cardCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 12
            property string icon: card.n.image !== "" ? card.n.image
                : card.n.appIcon === "" ? ""
                : card.n.appIcon.startsWith("/") ? "file://" + card.n.appIcon
                : Quickshell.iconPath(card.n.appIcon, true)

            ClippingRectangle {
                visible: cardCol.icon !== ""
                Layout.preferredWidth: 44; Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignTop
                radius: 12
                color: Colors.surface_container_highest
                Image {
                    anchors.fill: parent
                    anchors.margins: card.n.image !== "" ? 0 : 5
                    source: cardCol.icon
                    sourceSize: Qt.size(96, 96)
                    fillMode: card.n.image !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Glyph {
                        text: card.n.appName
                        font.pixelSize: 11
                        color: Colors.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        horizontalAlignment: Text.AlignLeft
                    }
                    Glyph {
                        text: ""
                        font.pixelSize: 13
                        color: closeArea.containsMouse ? Colors.error : Colors.on_surface_variant
                        MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true
                            onClicked: { card.n.dismiss(); card.dismissed() } }
                    }
                }
                Glyph {
                    text: card.n.summary
                    font.pixelSize: 13; font.bold: true
                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignLeft
                }
                Glyph {
                    visible: text !== ""
                    text: card.n.body
                    font.pixelSize: 12
                    color: Colors.on_surface_variant
                    wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignLeft
                }
                Flow {
                    visible: card.n.actions.length > 0
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: card.n.actions
                        delegate: Rectangle {
                            required property var modelData
                            height: 26; width: actText.implicitWidth + 20; radius: 13
                            color: actArea.containsMouse ? Colors.primary_container : Colors.secondary_container
                            Glyph { id: actText; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 12 }
                            MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { modelData.invoke(); card.dismissed() } }
                        }
                    }
                }
            }
        }
    }

    // ---------- тосты ----------
    PanelWindow {
        id: toasts
        visible: toastCol.implicitHeight > 0 && !root.open
        anchors { top: true; right: true }
        margins { top: 8; right: 8 }
        implicitWidth: 400
        implicitHeight: Math.max(toastCol.implicitHeight, 1)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notifcenter-toasts"

        ColumnLayout {
            id: toastCol
            width: parent.width
            spacing: 8
            Repeater {
                model: server.trackedNotifications
                delegate: Card {
                    id: toastCard
                    required property var modelData
                    n: modelData
                    toast: true
                    property bool shown: !root.dnd || modelData.urgency === NotificationUrgency.Critical
                    visible: shown
                    Layout.preferredHeight: shown ? implicitHeight : 0
                    onDismissed: shown = false
                    Timer {
                        running: toastCard.shown && toastCard.n.urgency !== NotificationUrgency.Critical
                                 && toastCard.n.expireTimeout !== 0
                        interval: toastCard.n.expireTimeout > 0 ? toastCard.n.expireTimeout * 1000 : 6000
                        onTriggered: toastCard.shown = false
                    }
                }
            }
        }
    }

    // ---------- панель ----------
    PanelWindow {
        id: panel
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        WlrLayershell.namespace: "notifcenter"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        MouseArea { anchors.fill: parent; onClicked: root.open = false }

        Rectangle {
            id: sheet
            width: 420
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right; margins: 8 }
            radius: 28
            color: Qt.alpha(Colors.surface, 0.94)
            border.width: 1
            border.color: Qt.alpha(Colors.outline_variant, 0.6)
            focus: true
            Keys.onEscapePressed: root.open = false
            MouseArea { anchors.fill: parent }   // клики внутри не закрывают

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Tile { icon: ""; value: root.cpu; extra: root.temp + "°C"; tint: Colors.primary }
                    Tile { icon: "󰍛"; value: root.ram; tint: Colors.tertiary }
                    Tile { icon: ""; value: root.disk; tint: Colors.secondary }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: root.buttons
                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            readonly property bool on: root.states[modelData.id] === true
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 20
                            color: on ? Colors.primary : (btnArea.containsMouse ? Colors.surface_container_highest : Colors.surface_container_high)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Glyph { text: btn.modelData.icon; font.pixelSize: 20; color: btn.on ? Colors.on_primary : Colors.on_surface; Layout.alignment: Qt.AlignHCenter }
                                Glyph { text: btn.modelData.label; font.pixelSize: 11; color: btn.on ? Colors.on_primary : Colors.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                            }
                            MouseArea { id: btnArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.run(btn.modelData) }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Glyph {
                        text: root.count > 0 ? "Уведомлений: " + root.count : "Уведомлений нет"
                        font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        horizontalAlignment: Text.AlignLeft
                    }
                    Rectangle {
                        width: dndText.implicitWidth + 20; height: 28; radius: 14
                        color: root.dnd ? Colors.tertiary : Colors.surface_container_high
                        Glyph { id: dndText; anchors.centerIn: parent; text: "Не беспокоить"; font.pixelSize: 12; color: root.dnd ? Colors.on_tertiary : Colors.on_surface }
                        MouseArea { anchors.fill: parent; onClicked: root.dnd = !root.dnd }
                    }
                    Rectangle {
                        visible: root.count > 0
                        width: clrText.implicitWidth + 20; height: 28; radius: 14
                        color: Colors.surface_container_high
                        Glyph { id: clrText; anchors.centerIn: parent; text: "Очистить"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: root.clearAll() }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: listCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: listCol
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: server.trackedNotifications
                            delegate: Card {
                                required property var modelData
                                n: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
