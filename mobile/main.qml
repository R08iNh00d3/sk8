/*
    Copyright 2017 - 2019 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.10

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0
import Vedder.vesc.vesc3ditem 1.0

ApplicationWindow {
    id: appWindow
    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property ConfigParams mAppConf: VescIf.appConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()

    visible: true
    width: 500
    height: 850
    title: qsTr("VESC Tool")

    // Full screen iPhone X workaround:
    property int safeWidth
    property int notchTop
    property int notchLeft
    property int notchRight
    property int notchBot

    // https://github.com/ekke/c2gQtWS_x/blob/master/qml/main.qml
    flags: Qt.platform.os === "ios" ? (Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint) : Qt.Window

    function updateNotch() {
        notchTop   = Utility.getSafeAreaMargins(appWindow)["top"]
        notchLeft  = Utility.getSafeAreaMargins(appWindow)["left"]
        notchRight = Utility.getSafeAreaMargins(appWindow)["right"]
        notchBot = Utility.getSafeAreaMargins(appWindow)["bottom"]/2 //leaving too much room at the bottom
        safeWidth  = appWindow.width - Utility.getSafeAreaMargins(appWindow)["left"] - Utility.getSafeAreaMargins(appWindow)["right"]
        connScreen.notchTop = notchTop
    }

    Timer {
        id: oriTimer
        interval: 100; running: true; repeat: false
        onTriggered: {
            updateNotch()
        }
    }

    Screen.orientationUpdateMask: Qt.LandscapeOrientation | Qt.PortraitOrientation
    Screen.onPrimaryOrientationChanged: {
        oriTimer.start()
    }

    Component.onCompleted: {
        if (!VescIf.isIntroDone()) {
            introWizard.openDialog()
        }
        updateNotch()
        Utility.keepScreenOn(VescIf.keepScreenOn())
        Utility.allowScreenRotation(VescIf.getAllowScreenRotation())
        Utility.stopGnssForegroundService()
    }

    onHeightChanged: {
        connScreen.y =  (connScreen.y > 1) ? connScreen.height : 0.0
    }

    SetupWizardIntro {
        id: introWizard
    }

    Controls {
        id: controls
        parentWidth: appWindow.width
        parentHeight: appWindow.height - footer.height - tabBar.height
    }

    MultiSettings {
        id: multiSettings
    }

    Settings {
        id: settings
    }

    Drawer {
        id: canDrawer
        edge: Qt.RightEdge
        width: 0.60 * appWindow.width
        height: appWindow.height - footer.height - tabBar.height
        y: tabBar.height
        dragMargin: 20
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        CanScreen {
            anchors.fill: parent
        }
    }

    Drawer {
        id: drawer
        width: 0.5 * appWindow.width
        height: appWindow.height - footer.height - tabBar.height
        y: tabBar.height
        dragMargin: 20

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 0

            Image {
                id: image
                Layout.preferredWidth: Math.min(parent.width, parent.height)*0.8
                Layout.preferredHeight: (464 * Layout.preferredWidth) / 1550
                Layout.margins: Math.min(parent.width, parent.height)*0.1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                source: "qrc" + Utility.getThemePath() + "/logo.png"
                antialiasing: true

            }

            Button {
                id: reconnectButton

                Layout.fillWidth: true
                text: "Connect"
                flat: true

                onClicked: {
                    connScreen.y = 0
                    drawer.close()
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Disconnect"
                flat: true

                onClicked: {
                    VescIf.disconnectPort()
                    drawer.close()
                }
            }

            Item {
                // Spacer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Button {
                Layout.fillWidth: true
                text: "Settings"
                flat: true

                onClicked: {
                    drawer.close()
                    settings.openDialog()
                }
            }

            Button {
                Layout.fillWidth: true
                text: "About"
                flat: true

                onClicked: {
                    VescIf.emitMessageDialog(
                                "About",
                                Utility.aboutText(),
                                true, true)
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Changelog"
                flat: true

                onClicked: {
                    VescIf.emitMessageDialog(
                                "VESC Tool Changelog",
                                Utility.vescToolChangeLog(),
                                true, false)
                }
            }

            Button {
                Layout.fillWidth: true
                text: "License"
                flat: true

                onClicked: {
                    if(Qt.platform.os == "ios"){
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("ios_license_text"),
                                    mInfoConf.getDescription("ios_license_text"),
                                    true, true)
                    }else{
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("gpl_text"),
                                    mInfoConf.getDescription("gpl_text"),
                                    true, true)
                    }

                }
            }
        }
    }

    SwipeView {
        id: swipeView
        currentIndex: tabBar.currentIndex
        anchors.fill: parent
        anchors.left:parent.anchors.left
        anchors.leftMargin: notchLeft
        anchors.right:parent.anchors.left
        anchors.rightMargin: notchRight
        clip: true

        Page {
            StartPage {
                id: connBle
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                onRequestOpenControls: {
                    controls.openDialog()
                }

                onRequestConnect: {
                    connScreen.y = 0
                }

                onRequestOpenMultiSettings: {
                    multiSettings.openDialog()
                }
            }
        }

        Page {
            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    color: Utility.getAppHexColor("lightBackground")
                    width: 16
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter |  Qt.AlignVCenter

                    PageIndicator {
                        count: rtSwipeView.count
                        currentIndex: rtSwipeView.currentIndex
                        anchors.centerIn: parent
                        rotation: 90
                    }
                }

                SwipeView {
                    id: rtSwipeView
                    enabled: true
                    clip: true

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: Qt.Vertical

                    Page {
                        RtData {
                            anchors.fill: parent
                        }
                    }

                    Page {
                        RtDataSetup {
                            anchors.fill: parent
                        }
                    }

                    Page {
                        ColumnLayout {
                            anchors.fill: parent

                            RtDataIMU {
                                Layout.fillWidth: true
                            }

                            CheckBox {
                                Layout.fillWidth: true
                                id: useYawBox
                                text: "Use Yaw (will drift)"
                                checked: false
                            }

                            Vesc3dItem {
                                id: vesc3d
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }

        Page {
            Profiles {
                anchors.fill: parent
                anchors.topMargin: 5
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }

        Page {
            BMS {
                anchors.fill: parent
            }
        }

        Page {
            FwUpdate {
                anchors.fill: parent
            }
        }

        Page {
            ConfigPageMotor {
                id: confPageMotor
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }

        Page {
            ConfigPageApp {
                id: confPageApp
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }

        Page {
            Terminal {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 10
            }
        }
    }

    header: Rectangle {
        color: Utility.getAppHexColor("lightestBackground")
        height: tabBar.implicitHeight + notchTop // iPhone X Workaround
        anchors.left: parent.left // iPhoneX workaround
        anchors.leftMargin: Math.max(notchLeft, notchRight)/2 // iPhoneX workaround
        anchors.bottom: parent.bottom // iPhoneX workaround

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            TabBar {
                id: tabBar
                currentIndex: swipeView.currentIndex
                Layout.fillWidth: true
                implicitWidth: 0
                clip: true

                background: Rectangle {
                    opacity: 1
                    color: Utility.getAppHexColor("lightBackground")
                }

                property int buttonWidth: Math.max(120,
                                                   tabBar.width /
                                                   (rep.model.length +
                                                    (uiHwPage.visible ? 1 : 0) +
                                                    (uiAppPage.visible ? 1 : 0)))

                Repeater {
                    id: rep
                    model: ["Start", "RT Data", "Profiles", "BMS", "Firmware", "Motor Cfg",
                        "App Cfg", "Terminal"]

                    TabButton {
                        text: modelData
                        width: tabBar.buttonWidth

                    }
                }
            }
        }
    }

    TabButton {
        id: uiHwButton
        visible: uiHwPage.visible
        text: "HwUi"
        width: tabBar.buttonWidth
    }

    Page {
        id: uiHwPage
        visible: false

        Item {
            id: uiHw
            anchors.fill: parent
            property var tabBarItem: tabBar
        }
    }

    TabButton {
        id: uiAppButton
        visible: uiAppPage.visible
        text: "AppUi"
        width: tabBar.buttonWidth
    }

    Page {
        id: uiAppPage
        visible: false

        Item {
            id: uiApp
            anchors.fill: parent
            property var tabBarItem: tabBar
        }
    }

    Page {
        id: rtDataBalance
        visible: false
        RtDataBalance {
            anchors.fill: parent
        }
    }

    footer: Rectangle {
        id: connectedRect
        clip: true
        color: Utility.getAppHexColor("lightBackground")
        width: parent.width
        height: 35 + notchBot
        Behavior on color {
            ColorAnimation {
                duration: 200;
                easing.type: Easing.OutBounce
                easing.overshoot: 3
            }
        }

        RowLayout{
            enabled:true
            anchors.fill: parent
            spacing: 0
            ToolButton {
                id:settingsButton
                Layout.fillHeight: true
                Layout.preferredWidth: 70
                Image {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -notchBot/2
                    antialiasing: true
                    height: parent.width*0.35
                    width: height
                    source: "qrc" + Utility.getThemePath() + "icons/Settings-96.png"
                }
                onClicked: {
                    if (drawer.visible) {
                        drawer.close()
                    } else {
                        drawer.open()
                    }
                }

            }
            Rectangle{
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Utility.getAppHexColor("darkBackground")
            }
            Rectangle{
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Utility.getAppHexColor("disabledText")
            }
            ColumnLayout{
                spacing: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    id: connectedText
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Utility.getAppHexColor("lightText")
                    text: VescIf.getConnectedPortName()
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: notchBot
                    opacity: 0
                }
            }
            Rectangle{
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Utility.getAppHexColor("darkBackground")
            }
            Rectangle{
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Utility.getAppHexColor("disabledText")
            }
            ToolButton {
                Layout.fillHeight: true
                Layout.preferredWidth: 70
                Image {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -notchBot/2
                    antialiasing: true
                    height: parent.width*0.35
                    width: height
                    source: "qrc" + Utility.getThemePath() + "icons/can_off.png"
                }
                onClicked: {
                    if (canDrawer.visible) {
                        canDrawer.close()
                    } else {
                        canDrawer.open()
                    }
                }
            }
        }
    }

    ConnectScreen {
        id: connScreen
        parent: ApplicationWindow.overlay

        x: 0
        y: 0
        height: parent.height
        width: parent.width
    }

    Timer {
        id: statusTimer
        interval: 1600
        running: false
        repeat: false
        onTriggered: {
            connectedText.text = VescIf.getConnectedPortName()
            connectedRect.color = Utility.getAppHexColor("lightBackground")
        }
    }

    Timer {
        id: uiTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!statusTimer.running && connectedText.text !== VescIf.getConnectedPortName()) {
                connectedText.text = VescIf.getConnectedPortName()
            }
        }
    }

    Timer {
        id: confTimer
        interval: 1000
        running: true
        repeat: true

        property bool mcConfRx: false
        property bool appConfRx: false

        onTriggered: {
            if (VescIf.isPortConnected() && VescIf.getLastFwRxParams().hwTypeStr() === "VESC") {
                if (!mcConfRx) {
                    mCommands.getMcconf()
                }

                if (!appConfRx) {
                    mCommands.getAppConf()
                }
            }
        }
    }

    Timer {
        id: rtTimer
        interval: 50
        running: true
        repeat: true

        onTriggered: {
            if(mAppConf.getParamEnum("app_to_use") === 9 && rtSwipeView.count == 3){
                rtSwipeView.addItem(rtDataBalance)
                rtDataBalance.visible = true
            } else if(mAppConf.getParamEnum("app_to_use") !== 9 && rtSwipeView.count == 4){
                rtSwipeView.removeItem(3)
                rtDataBalance.visible = false
            }

            if (VescIf.isPortConnected()) {
                // Sample RT data when the corresponding page is selected, or when
                // RT logging is active.

                if (VescIf.isRtLogOpen()) {
                    interval = 50
                    mCommands.getValues()
                    mCommands.getValuesSetup()
                    mCommands.getImuData(0xFFFF)

                    if (tabBar.currentIndex == (3 + indexOffset())) {
                        mCommands.bmsGetValues()
                    }
                } else {
                    if ((tabBar.currentIndex == (1 + indexOffset()) && rtSwipeView.currentIndex == 0)) {
                        interval = 50
                        mCommands.getValues()
                    }

                    if (tabBar.currentIndex == (1 + indexOffset()) && rtSwipeView.currentIndex == 1) {
                        interval = 50
                        mCommands.getValuesSetup()
                    }

                    if (tabBar.currentIndex == (1 + indexOffset()) && rtSwipeView.currentIndex == 2) {
                        interval = 20
                        mCommands.getImuData(0x1FF)
                    }

                    if (tabBar.currentIndex == (1 + indexOffset()) && rtSwipeView.currentIndex == 3) {
                        interval = 50
                        mCommands.getValuesSetup()
                        mCommands.getDecodedBalance()
                    }

                    if (tabBar.currentIndex == (3 + indexOffset())) {
                        interval = 100
                        mCommands.bmsGetValues()
                    }
                }
            }
        }
    }

    Dialog {
        id: vescDialog
        standardButtons: Dialog.Ok
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        height: Math.min(implicitHeight, parent.height - 40)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: ApplicationWindow.overlay

        ScrollView {
            id: vescDialogScroll
            anchors.fill: parent
            clip: true
            contentWidth: parent.width - 20

            Text {
                id: vescDialogLabel
                color: Utility.getAppHexColor("lightText")
                linkColor: "lightblue"
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
        }
    }

    property var hwUiObj: 0

    function updateHwUi () {
        if (hwUiObj != 0) {
            hwUiObj.destroy()
            hwUiObj = 0
        }

        swipeView.interactive = true
        tabBar.visible = true
        tabBar.enabled = true

        if (VescIf.isPortConnected() && VescIf.qmlHwLoaded()) {
            if (VescIf.getLastFwRxParams().qmlHwFullscreen) {
                swipeView.interactive = false
                tabBar.visible = false
                tabBar.enabled = false
            }

            hwUiObj = Qt.createQmlObject(VescIf.qmlHw(), uiHw, "HwUi")
            swipeView.insertItem(1, uiHwPage)
            tabBar.insertItem(1, uiHwButton)
            uiHwPage.visible = true
            swipeView.setCurrentIndex(0)
            swipeView.setCurrentIndex(1)
        } else {
            uiHwPage.visible = false
            uiHwPage.parent = null
            uiHwButton.parent = null
        }
    }

    property var appUiObj: 0

    function updateAppUi () {
        if (appUiObj != 0) {
            appUiObj.destroy()
            appUiObj = 0
        }

        swipeView.interactive = true
        tabBar.visible = true
        tabBar.enabled = true

        if (VescIf.isPortConnected() && VescIf.qmlAppLoaded()) {
            if (VescIf.getLastFwRxParams().qmlAppFullscreen) {
                swipeView.interactive = false
                tabBar.visible = false
                tabBar.enabled = false
            }

            appUiObj = Qt.createQmlObject(VescIf.qmlApp(), uiApp, "AppUi")
            swipeView.insertItem(1, uiAppPage)
            tabBar.insertItem(1, uiAppButton)
            uiAppPage.visible = true
            swipeView.setCurrentIndex(0)
            swipeView.setCurrentIndex(1)
        } else {
            uiAppPage.visible = false
            uiAppPage.parent = null
            uiAppButton.parent = null
        }
    }

    function indexOffset() {
        var res = 0
        if (uiHwButton.visible) {
            res++
        }
        if (uiAppButton.visible) {
            res++
        }
        return res
    }

    Connections {
        target: VescIf
        onPortConnectedChanged: {
            connectedText.text = VescIf.getConnectedPortName()
            if (!VescIf.isPortConnected()) {
                confTimer.mcConfRx = false
                confTimer.appConfRx = false
            }

            if (VescIf.useWakeLock()) {
                VescIf.setWakeLock(VescIf.isPortConnected())
            }

            reconnectButton.enabled = !VescIf.isPortConnected()
            connScreen.y = VescIf.isPortConnected() ? connScreen.height : 0.0
        }

        onStatusMessage: {
            connectedText.text = msg
            connectedRect.color = isGood ? Utility.getAppHexColor("lightAccent") : Utility.getAppHexColor("red")
            statusTimer.restart()
        }

        onMessageDialog: {
            vescDialog.title = title
            vescDialogLabel.text = (richText ? "<style>a:link { color: lightblue; }</style>" : "") + msg
            vescDialogLabel.textFormat = richText ? Text.RichText : Text.AutoText
            vescDialogScroll.ScrollBar.vertical.position = 0
            vescDialog.open()
        }

        onFwRxChanged: {
            if (rx) {
                if (limited && !VescIf.getFwSupportsConfiguration()) {
                    confPageMotor.enabled = false
                    confPageApp.enabled = false
                    swipeView.setCurrentIndex(4 + indexOffset())
                } else {
                    confPageMotor.enabled = true
                    confPageApp.enabled = true
                    mCommands.getMcconf()
                    mCommands.getAppConf()
                }
            }

            updateHwUi()
            updateAppUi()
        }

        onQmlLoadDone: {
            qmlLoadDialog.open()
        }
    }

    Connections {
        target: mMcConf

        onUpdated: {
            confTimer.mcConfRx = true
        }
    }

    Connections {
        target: mAppConf

        onUpdated: {
            confTimer.appConfRx = true
        }
    }

    Connections {
        target: mCommands

        onValuesImuReceived: {
            vesc3d.setRotation(values.roll, values.pitch,
                               useYawBox.checked ? values.yaw : 0)
        }

        onDeserializeConfigFailed: {
            if (isMc) {
                confTimer.mcConfRx = true
            }

            if (isApp) {
                confTimer.appConfRx = true
            }
        }
    }

    Dialog {
        id: qmlLoadDialog
        standardButtons: Dialog.Yes | Dialog.Cancel
        modal: true
        focus: true
        rightMargin: 10
        leftMargin: 10
        closePolicy: Popup.CloseOnEscape
        title: "Load Custom User Interface"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        parent: ApplicationWindow.overlay
        y: parent.y + parent.height / 2 - height / 2

        Text {
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "The hardware you are connecting to contains code that will alter the " +
                "user interface of VESC Tool. This code has not been verified by the " +
                "authors of VESC Tool and could contain bugs and security problems. \n\n" +
                "Do you want to load this custom user interface?"
        }

        onAccepted: {
            updateHwUi()
            updateAppUi()
        }

        onRejected: {
            VescIf.disconnectPort()
        }
    }
}
