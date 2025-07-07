import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Rectangle {
    id: carousel

    property var userData: null
    property int repositoryCount: 0
    property int totalStars: 0
    property bool showUserAvatars: true
    property int currentIndex: 0
    property var commitData: null
    property int commitGraphColor: 0
    property bool showNavigation: hoverArea.containsMouse
    property var dataManagerInstance: null

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(profileCard.implicitHeight, commitGraph.implicitHeight) + 50
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(0.5, 0.5, 0.5, 0.3)
    radius: 9
    visible: userData !== null

    // Content area
    StackLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.topMargin: 30
        currentIndex: carousel.currentIndex

        // Profile Card View
        UserProfileCard {
            id: profileCard

            userData: carousel.userData
            repositoryCount: carousel.repositoryCount
            totalStars: carousel.totalStars
            showUserAvatars: carousel.showUserAvatars
            hideCardBorder: true
        }

        // Commit Graph View
        CommitGraphView {
            id: commitGraph

            commitData: carousel.commitData
            commitGraphColor: carousel.commitGraphColor
            dataManagerInstance: carousel.dataManagerInstance
        }

    }

    // Navigation overlay
    Item {
        anchors.fill: parent
        z: 1000
        opacity: carousel.showNavigation ? 1 : 0
        visible: opacity > 0

        // Navigation dots
        Row {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12
            spacing: 12

            Repeater {
                model: 2

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: index === carousel.currentIndex ? Kirigami.Theme.highlightColor : "transparent"
                    border.width: 2
                    border.color: index === carousel.currentIndex ? Kirigami.Theme.highlightColor : Qt.rgba(0.7, 0.7, 0.7, 0.8)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: carousel.currentIndex = index
                        onEntered: parent.scale = 1.3
                        onExited: parent.scale = 1
                    }

                    Behavior on scale {
                        PropertyAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

        // Navigation arrows
        PlasmaComponents3.Button {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            icon.name: "go-previous"
            flat: true
            implicitWidth: 36
            implicitHeight: 36
            onClicked: carousel.currentIndex = (carousel.currentIndex - 1 + 2) % 2

            background: Rectangle {
                color: parent.hovered ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.05)
                radius: 18
                border.width: 1
                border.color: parent.hovered ? Qt.rgba(0.5, 0.5, 0.5, 0.6) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                Behavior on color {
                    PropertyAnimation {
                        duration: 150
                    }

                }

                Behavior on border.color {
                    PropertyAnimation {
                        duration: 150
                    }

                }

            }

        }

        PlasmaComponents3.Button {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            icon.name: "go-next"
            flat: true
            implicitWidth: 36
            implicitHeight: 36
            onClicked: carousel.currentIndex = (carousel.currentIndex + 1) % 2

            background: Rectangle {
                color: parent.hovered ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.05)
                radius: 18
                border.width: 1
                border.color: parent.hovered ? Qt.rgba(0.5, 0.5, 0.5, 0.6) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                Behavior on color {
                    PropertyAnimation {
                        duration: 150
                    }

                }

                Behavior on border.color {
                    PropertyAnimation {
                        duration: 150
                    }

                }

            }

        }

        Behavior on opacity {
            PropertyAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }

        }

    }

    // Top-level hover detection (above everything)
    MouseArea {
        id: hoverArea

        anchors.fill: parent
        z: 2000 // Above navigation at z:1000
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton
    }

    // Smooth transition animation
    Behavior on currentIndex {
        PropertyAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }

    }

}
