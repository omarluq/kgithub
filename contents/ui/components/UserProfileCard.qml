import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Rectangle {
    id: userCard

    property var userData: null
    property int repositoryCount: 0
    property int totalStars: 0

    Layout.fillWidth: true
    Layout.preferredHeight: userInfo.implicitHeight + 20
    color: Kirigami.Theme.alternateBackgroundColor
    radius: 5
    visible: userData !== null

    RowLayout {
        id: userInfo

        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Profile image
        Rectangle {
            width: 64
            height: 64
            radius: 32
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 2
            border.color: Kirigami.Theme.highlightColor

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: userData ? userData.avatar_url : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true

                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.1)
                }

            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: "user-identity"
                visible: !userData || !userData.avatar_url
                opacity: 0.5
            }

        }

        // User details
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            PlasmaComponents3.Label {
                text: userData ? userData.login : ""
                font.bold: true
                font.pixelSize: 16
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: userData ? (userData.name || "No name set") : ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.8
                font.pixelSize: 12
            }

        }

        // Statistics grid
        GridLayout {
            columns: 2
            rowSpacing: 5
            columnSpacing: 15

            PlasmaComponents3.Label {
                text: "📚 " + repositoryCount + " repos"
                font.pixelSize: 11
            }

            PlasmaComponents3.Label {
                text: "⭐ " + totalStars + " stars"
                font.pixelSize: 11
            }

            PlasmaComponents3.Label {
                text: "👥 " + (userData ? userData.followers : 0) + " followers"
                font.pixelSize: 11
            }

            PlasmaComponents3.Label {
                text: "👤 " + (userData ? userData.following : 0) + " following"
                font.pixelSize: 11
            }

        }

    }

}
