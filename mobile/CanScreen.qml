/*
    Copyright 2021 Benjamin Vedder	benjamin@vedder.se

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

/*
GroupBox {
    id: canFwdBox
    Layout.preferredHeight: isHorizontal ? wizardBox.height : -1
    title: qsTr("CAN Forwarding")
    Layout.fillWidth: true

    ColumnLayout {
        anchors.topMargin: -5
        anchors.bottomMargin: -5
        anchors.fill: parent
        spacing: -10

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: isHorizontal ? 5 : 0

            ComboBox {
                id: canIdBox
                Layout.fillWidth: true

                textRole: "key"
                model: ListModel {
                    id: canItems
                }

                onCurrentIndexChanged: {
                    if (fwdCanBox.checked && canItems.rowCount() > 0) {
                        mCommands.setCanSendId(canItems.get(canIdBox.currentIndex).value)
                    }
                }
            }

            CheckBox {
                id: fwdCanBox
                text: qsTr("Activate")
                enabled: canIdBox.currentIndex >= 0 && canIdBox.count > 0

                onClicked: {
                    mCommands.setSendCan(fwdCanBox.checked, canItems.get(canIdBox.currentIndex).value)
                    canScanButton.enabled = !checked
                    canAllButton.enabled = !checked
                }
            }
        }

        ProgressBar {
            id: canScanBar
            visible: false
            Layout.fillWidth: true
            indeterminate: true
            Layout.preferredHeight: canAllButton.height
        }

        RowLayout {
            id: canButtonLayout
            Layout.fillWidth: true

            Button {
                id: canAllButton
                text: "List All (no Scan)"
                Layout.fillWidth: true
                Layout.preferredWidth: 500

                onClicked: {
                    canItems.clear()
                    for (var i = 0;i < 255;i++) {
                        var name = "VESC " + i
                        canItems.append({ key: name, value: i })
                    }
                    canIdBox.currentIndex = 0
                }
            }

            Button {
                id: canScanButton
                text: "Scan CAN Bus"
                Layout.fillWidth: true
                Layout.preferredWidth: 500

                onClicked: {
                    canScanBar.indeterminate = true
                    canButtonLayout.visible = false
                    canScanBar.visible = true
                    canItems.clear()
                    enabled = false
                    canAllButton.enabled = false
                    mCommands.pingCan()
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: isHorizontal
        }
    }
}
*/


import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.bleuart 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.utility 1.0

Item {
    id: rootItem

    property BleUart mBle: VescIf.bleDevice()
    property Commands mCommands: VescIf.commands()
    property int notchTop: 0
    property int animationSpeed: 500

    Timer {
        repeat: true
        interval: 1000
        running: true

        onTriggered: {
            if (!VescIf.isPortConnected()) {
                //canModel.clear()
                mCommands.setSendCan(false, -1)
                canList.currentIndex = 0;
                scanButton.enabled = true
            }
        }
    }


    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10

        Text {
            id: text
            Layout.fillWidth: true
            color: Utility.getAppHexColor("lightText")
            text: qsTr("CAN Devices")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true


            Button {
                id: scanButton
                text: qsTr("CAN Scan")
                enabled: false
                Layout.fillWidth: true
                flat: true
                onClicked: {
                    scanButton.enabled = false
                    canModel.clear()
                    scanDialog.open()
                    mCommands.pingCan()
                }
            }
        }

        ListModel {
            id: canModel
        }

        ListView {
            // transitions for insertion/deletation of elements
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 200 }
                NumberAnimation { property: "scale"; easing.type: Easing.OutBack; from: 0; to: 1.0; duration: 800 }
            }

            addDisplaced: Transition {
                NumberAnimation { properties: "y"; duration: 600; easing.type: Easing.InBack }
            }

            remove: Transition {
                NumberAnimation { property: "scale"; from: 1.0; to: 0; duration: 200 }
                NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: 200 }
            }

            removeDisplaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 500; easing.type: Easing.OutExpo }
            }

            id: canList
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            clip: true
            spacing: 5

            Component {
                id: canDelegate
                Rectangle {
                    Component.onCompleted: showAnim.start();
                    transform: Rotation { id:rt; origin.x: 0; origin.y: height; axis { x: 0.3; y: 1; z: 0 } angle: 0}//     <--- I like this one more!
                    SequentialAnimation {
                        id: showAnim
                        running: false
                        RotationAnimation { target: rt; from: 180; to: 0; duration: 800; easing.type: Easing.OutExpo; property: "angle" }
                    }
                    width: canList.width
                    height: 40
                    color: canList.currentIndex == index ? Utility.getAppHexColor("darkAccent") : Utility.getAppHexColor("normalBackground")
                    radius: 10
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            canList.currentIndex = index
                            if(index == 0){
                                mCommands.setSendCan(false,0)
                            }else{
                                mCommands.setSendCan(true,ID)
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Image {
                            id: image
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            source: deviceIconPath
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            text: name
                            horizontalAlignment: Text.AlignHCenter
                            color: Utility.getAppHexColor("lightText")
                            wrapMode: Text.WordWrap
                        }
                        Rectangle{
                            color: "#00000000"
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: idText.implicitHeight*1.5
                            border.color: Utility.getAppHexColor("lightText")
                            border.width: 2
                            radius: 2
                            Text {
                                id:idText
                                textFormat: Text.RichText
                                anchors.centerIn: parent
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                text: ID
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                color: Utility.getAppHexColor("lightText")
                                wrapMode: Text.WordWrap
                            }
                        }



                    }
                }
            }
            model: canModel
            delegate: canDelegate
        }
    }

    Connections {
        target: mBle


        onBleError: {
            VescIf.emitMessageDialog("BLE Error", info, false, false)
            enableDialog()
        }
    }

    function disableDialog() {
        commDialog.open()
        column.enabled = false
    }

    function enableDialog() {
        commDialog.close()
        column.enabled = true
    }

    Dialog {
        id: commDialog
        title: "Connecting..."
        closePolicy: Popup.NoAutoClose
        modal: true
        focus: true


        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        x: 10
        y: parent.height / 2 - height / 2
        parent: ApplicationWindow.overlay

        ProgressBar {
            anchors.fill: parent
            indeterminate: visible
        }
    }

    Dialog {
        id: scanDialog
        title: "Scanning CAN Bus..."
        closePolicy: Popup.NoAutoClose
        modal: true
        focus: true

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        x: 10
        y: parent.height / 2 - height / 2
        parent: ApplicationWindow.overlay

        ProgressBar {
            anchors.fill: parent
            indeterminate: visible
        }
    }

    Connections {
        target: mCommands

        onPingCanRx: {
            scanButton.enabled = true
            scanButton.text = qsTr("Scan")
            if (VescIf.isPortConnected()) {
                canModel.clear()
                mCommands.setSendCan(0,0);
                var params = Utility.getFwVersionBlocking(VescIf)
                var name = params.hw
                var theme ="qrc"  + Utility.getThemePath()
                var devicePath
                var logoPath = " "
                if (params.major === -1){
                    devicePath = theme + "icons/Help-96.png"
                    name = "Unknown"
                } else if (params.hwTypeStr() === "VESC") { //is a motor
                    devicePath = theme + "icons/motor_side.png"
                    name = params.hw
                } else if (params.hwTypeStr() === "VESC BMS") { //is a bms
                    devicePath = theme + "icons/icons8-battery-100.png"
                    name = "BMS (" + params.hw + "):"
                } else {
                    devicePath = theme + "icons/Electronics-96.png"
                    name = "BMS (" + params.hw + "):"
                }

                canModel.append({"name": name,
                                    "ID": "LOCAL",
                                    "deviceIconPath": devicePath,
                                    "logoIconPath": logoPath})
                for (var i = 0;i < devs.length;i++) {
                    params = Utility.getFwVersionBlockingCan(VescIf, devs[i])
                    name = params.hw
                    if (params.hwTypeStr() === "VESC") { //is a motor
                        devicePath = theme + "icons/motor_side.png"
                        name = params.hw;
                    } else if (params.hwTypeStr() === "VESC BMS") { //is a bms
                        devicePath = theme + "icons/icons8-battery-100.png"
                        name = "BMS (" + params.hw + "):";
                    } else {
                        devicePath = theme + "icons/Electronics-96.png"
                        name = params.hw;
                    }
                    canModel.append({"name": name,
                                        "ID": devs[i].toString(),
                                        "deviceIconPath": devicePath,
                                        "logoIconPath": logoPath})
                }
                canList.currentIndex = 0
                if(!isTimeout){
                    scanDialog.close()
                    scanButton.enabled = true
                    VescIf.emitStatusMessage("CAN Scan Finished", true)
                }else{
                    scanDialog.close()
                    scanButton.enabled = true
                    VescIf.emitStatusMessage("CAN Scan Timed Out", false)
                }
            }else{
                scanDialog.close()
                scanButton.enabled = true
                VescIf.emitStatusMessage("Device not connected", false)
            }
        }

    }
}


