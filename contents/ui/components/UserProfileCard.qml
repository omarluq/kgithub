import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: userCard

    property var userData: null
    property int repositoryCount: 0
    property int totalStars: 0
    property bool showUserAvatars: true
    property bool hideCardBorder: false

    Layout.fillWidth: true
    Layout.preferredHeight: userInfo.implicitHeight + 30
    color: "transparent"
    border.width: hideCardBorder ? 0 : 1
    border.color: hideCardBorder ? "transparent" : Qt.rgba(0.5, 0.5, 0.5, 0.3)
    radius: hideCardBorder ? 0 : 9
    visible: userData !== null

    RowLayout {
        id: userInfo

        anchors.fill: parent
        anchors.margins: 15
        spacing: 22

        // Profile image
        Rectangle {
            width: 96
            height: 96
            radius: 48
            color: "transparent"
            border.width: 0

            CachedImage {
                anchors.fill: parent
                originalSource: showUserAvatars && userData ? userData.avatar_url : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: showUserAvatars && userData && userData.avatar_url

                Rectangle {
                    anchors.fill: parent
                    radius: 48
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.1)
                }

            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 48
                height: 48
                source: "user-identity"
                visible: !showUserAvatars || !userData || !userData.avatar_url
                opacity: 0.5
            }

        }

        // User details
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            PlasmaComponents3.Label {
                text: userData ? userData.login : ""
                font.bold: true
                font.pixelSize: 24
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: userData ? (userData.name || "No name set") : ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.8
                font.pixelSize: 18
            }

        }

        // Statistics grid
        GridLayout {
            columns: 2
            rowSpacing: 8
            columnSpacing: 22

            RowLayout {
                spacing: 6

                Kirigami.Icon {
                    source: "folder-code"
                    width: 5
                    height: 5
                }

                PlasmaComponents3.Label {
                    text: repositoryCount + " repos"
                    font.pixelSize: 16
                }

            }

            RowLayout {
                spacing: 6

                Kirigami.Icon {
                    source: "rating"
                    width: 5
                    height: 5
                }

                PlasmaComponents3.Label {
                    text: totalStars + " stars"
                    font.pixelSize: 16
                }

            }

            RowLayout {
                spacing: 6

                Kirigami.Icon {
                    source: "group"
                    width: 5
                    height: 5
                }

                PlasmaComponents3.Label {
                    text: (userData ? userData.followers : 0) + " followers"
                    font.pixelSize: 16
                }

            }

            RowLayout {
                spacing: 6

                Kirigami.Icon {
                    source: "user"
                    width: 5
                    height: 5
                }

                PlasmaComponents3.Label {
                    text: (userData ? userData.following : 0) + " following"
                    font.pixelSize: 16
                }

            }

        }

    }

}
