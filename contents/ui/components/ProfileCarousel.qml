import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    // Enhanced carousel with custom slide transitions

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

    // Content area with horizontal sliding animation
    Item {
        anchors.fill: parent
        anchors.margins: 15
        anchors.topMargin: 30
        clip: true

        // Sliding container
        Row {
            id: slidingContainer

            height: parent.height
            x: -carousel.currentIndex * parent.width

            // Profile Card View
            UserProfileCard {
                id: profileCard

                width: slidingContainer.parent.width
                height: slidingContainer.parent.height
                userData: carousel.userData
                repositoryCount: carousel.repositoryCount
                totalStars: carousel.totalStars
                showUserAvatars: carousel.showUserAvatars
                hideCardBorder: true
            }

            // Commit Graph View
            CommitGraphView {
                id: commitGraph

                width: slidingContainer.parent.width
                height: slidingContainer.parent.height
                commitData: carousel.commitData
                commitGraphColor: carousel.commitGraphColor
                dataManagerInstance: carousel.dataManagerInstance
            }

            Behavior on x {
                PropertyAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }

            }

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

                    // Glowing effect for active dot
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 4
                        height: parent.height + 4
                        radius: (parent.width + 4) / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Kirigami.Theme.highlightColor
                        opacity: index === carousel.currentIndex ? 0.3 : 0

                        Behavior on opacity {
                            PropertyAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Add a subtle haptic-like visual effect
                            scaleAnimation.restart();
                            carousel.currentIndex = index;
                        }
                        onEntered: parent.scale = 1.2
                        onExited: parent.scale = 1
                    }

                    SequentialAnimation {
                        id: scaleAnimation

                        PropertyAnimation {
                            target: parent
                            property: "scale"
                            to: 0.8
                            duration: 80
                            easing.type: Easing.OutCubic
                        }

                        PropertyAnimation {
                            target: parent
                            property: "scale"
                            to: 1.2
                            duration: 120
                            easing.type: Easing.OutBack
                        }

                    }

                    Behavior on scale {
                        PropertyAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        PropertyAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on border.color {
                        PropertyAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

        // Navigation arrows
        PlasmaComponents3.Button {
            id: leftArrow

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            icon.name: "go-previous"
            flat: true
            implicitWidth: 36
            implicitHeight: 36
            opacity: carousel.currentIndex > 0 ? 1 : 0.4
            onClicked: {
                pulseAnimation.target = leftArrow;
                pulseAnimation.restart();
                carousel.currentIndex = (carousel.currentIndex - 1 + 2) % 2;
            }

            background: Rectangle {
                color: parent.hovered ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.05)
                radius: 18
                border.width: 1
                border.color: parent.hovered ? Qt.rgba(0.5, 0.5, 0.5, 0.6) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                // Subtle glow effect on hover
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 2
                    height: parent.height + 2
                    radius: parent.radius + 1
                    color: "transparent"
                    border.width: 1
                    border.color: Kirigami.Theme.highlightColor
                    opacity: parent.parent.hovered ? 0.2 : 0

                    Behavior on opacity {
                        PropertyAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                Behavior on color {
                    PropertyAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on border.color {
                    PropertyAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on opacity {
                PropertyAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }

            }

        }

        PlasmaComponents3.Button {
            id: rightArrow

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            icon.name: "go-next"
            flat: true
            implicitWidth: 36
            implicitHeight: 36
            opacity: carousel.currentIndex < 1 ? 1 : 0.4
            onClicked: {
                pulseAnimation.target = rightArrow;
                pulseAnimation.restart();
                carousel.currentIndex = (carousel.currentIndex + 1) % 2;
            }

            background: Rectangle {
                color: parent.hovered ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.05)
                radius: 18
                border.width: 1
                border.color: parent.hovered ? Qt.rgba(0.5, 0.5, 0.5, 0.6) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                // Subtle glow effect on hover
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 2
                    height: parent.height + 2
                    radius: parent.radius + 1
                    color: "transparent"
                    border.width: 1
                    border.color: Kirigami.Theme.highlightColor
                    opacity: parent.parent.hovered ? 0.2 : 0

                    Behavior on opacity {
                        PropertyAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                Behavior on color {
                    PropertyAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on border.color {
                    PropertyAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on opacity {
                PropertyAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }

            }

        }

        // Shared pulse animation for buttons
        SequentialAnimation {
            id: pulseAnimation

            property Item target: null

            PropertyAnimation {
                target: pulseAnimation.target
                property: "scale"
                to: 0.9
                duration: 60
                easing.type: Easing.OutCubic
            }

            PropertyAnimation {
                target: pulseAnimation.target
                property: "scale"
                to: 1.1
                duration: 120
                easing.type: Easing.OutBack
            }

            PropertyAnimation {
                target: pulseAnimation.target
                property: "scale"
                to: 1
                duration: 100
                easing.type: Easing.OutCubic
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

}
