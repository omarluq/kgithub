import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Rectangle {
    id: listItem

    property var itemData: null
    property string itemType: "repo" // "repo", "issue", "pr", "org"
    property int itemIndex: 0

    signal clicked(var item)

    function getTitle() {
        if (!itemData)
            return "";

        switch (itemType) {
        case "repo":
            return itemData.name || "";
        case "issue":
            return "#" + (itemData.number || "") + " " + (itemData.title || "");
        case "pr":
            return "#" + (itemData.number || "") + " " + (itemData.title || "");
        case "org":
            return itemData.login || "";
        default:
            return "";
        }
    }

    function getSubtitle() {
        if (!itemData)
            return "";

        switch (itemType) {
        case "repo":
            return itemData.description || "No description";
        case "issue":
        case "pr":
            var repo = itemData.repository_url ? itemData.repository_url.split('/').slice(-2).join('/') : "";
            return "by " + (itemData.user ? itemData.user.login : "") + " in " + repo;
        case "org":
            return itemData.description || "No description";
        default:
            return "";
        }
    }

    function getStatsText() {
        if (!itemData)
            return "";

        switch (itemType) {
        case "repo":
            var stars = itemData.stargazers_count || 0;
            var forks = itemData.forks_count || 0;
            return "⭐ " + stars + " 🍴 " + forks;
        case "issue":
        case "pr":
            var comments = itemData.comments || 0;
            return "💬 " + comments;
        case "org":
            var repos = itemData.public_repos || 0;
            return "📚 " + repos + " repos";
        default:
            return "";
        }
    }

    function getItemImageUrl() {
        if (!itemData)
            return "";

        switch (itemType) {
        case "org":
            return itemData.avatar_url || "";
        case "repo":
            return itemData.owner && itemData.owner.avatar_url ? itemData.owner.avatar_url : "";
        case "issue":
        case "pr":
            return itemData.user && itemData.user.avatar_url ? itemData.user.avatar_url : "";
        default:
            return "";
        }
    }

    Layout.fillWidth: true
    height: 60
    color: mouseArea.containsMouse ? Kirigami.Theme.highlightColor : "transparent"
    radius: 5

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            listItem.clicked(itemData);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Icon/Image based on item type
        Rectangle {
            width: 24
            height: 24
            radius: itemType === "org" ? 12 : 0
            color: "transparent"

            Image {
                id: itemImage

                anchors.fill: parent
                source: getItemImageUrl()
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: getItemImageUrl() !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: itemType === "org" ? 12 : 0
                    color: "transparent"
                    border.width: itemType === "org" ? 1 : 0
                    border.color: Qt.rgba(0, 0, 0, 0.1)
                }

            }

            Kirigami.Icon {
                anchors.fill: parent
                source: {
                    switch (itemType) {
                    case "repo":
                        return "folder-code";
                    case "issue":
                        return "dialog-warning";
                    case "pr":
                        return "merge";
                    case "org":
                        return "group";
                    default:
                        return "document";
                    }
                }
                visible: getItemImageUrl() === ""
            }

        }

        // Main content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            PlasmaComponents3.Label {
                text: getTitle()
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                text: getSubtitle()
                opacity: 0.7
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

        }

        // Stats for repos, orgs, issues, and PRs
        PlasmaComponents3.Label {
            text: getStatsText()
            opacity: 0.6
            font.pixelSize: 10
            visible: itemType === "repo" || itemType === "org" || itemType === "issue" || itemType === "pr"
        }

    }

}
