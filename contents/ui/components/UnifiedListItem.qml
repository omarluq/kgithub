import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: listItem

    property var itemData: null
    property string itemType: "repo" // "repo", "issue", "pr", "org"
    property int itemIndex: 0
    property bool showUserAvatars: true
    property bool showOrgAvatars: true
    property bool showRepoAvatars: true
    property bool showIssueAvatars: true
    property bool showPRAvatars: true

    signal clicked(var item)

    function getItemUrl() {
        if (!itemData)
            return "";

        switch (itemType) {
        case "repo":
            return itemData.html_url || "";
        case "issue":
        case "pr":
            return itemData.html_url || "";
        case "org":
            // Organizations use github.com/orgname format
            return itemData.login ? "https://github.com/" + itemData.login : "";
        default:
            return "";
        }
    }

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

    function shouldShowAvatar() {
        switch (itemType) {
        case "org":
            return showOrgAvatars;
        case "repo":
            return showRepoAvatars;
        case "issue":
            return showIssueAvatars;
        case "pr":
            return showPRAvatars;
        default:
            return false;
        }
    }

    Layout.fillWidth: true
    height: 90
    color: mouseArea.containsMouse ? Kirigami.Theme.highlightColor : "transparent"
    radius: 8

    // Clipboard helper using TextEdit workaround
    TextEdit {
        id: clipboardHelper

        function copyToClipboard(text) {
            clipboardHelper.text = text;
            clipboardHelper.selectAll();
            clipboardHelper.copy();
            console.log("✓ Copied to clipboard:", text);
        }

        visible: false
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        anchors.rightMargin: 30 // Leave space for hamburger menu
        hoverEnabled: true
        onClicked: {
            listItem.clicked(itemData);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // Icon/Image based on item type
        Rectangle {
            width: 36
            height: 36
            radius: itemType === "org" ? 18 : 0
            color: "transparent"

            CachedImage {
                id: itemImage

                anchors.fill: parent
                originalSource: shouldShowAvatar() ? getItemImageUrl() : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: shouldShowAvatar() && getItemImageUrl() !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: itemType === "org" ? 18 : 0
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
                visible: !shouldShowAvatar() || getItemImageUrl() === ""
            }

        }

        // Main content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            PlasmaComponents3.Label {
                text: getTitle()
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                text: getSubtitle()
                opacity: 0.7
                font.pixelSize: 16
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

        }

        // Stats for repos, orgs, issues, and PRs
        RowLayout {
            spacing: 9
            visible: itemType === "repo" || itemType === "org" || itemType === "issue" || itemType === "pr"

            // Stars and forks for repos
            RowLayout {
                spacing: 3
                visible: itemType === "repo"

                Kirigami.Icon {
                    source: "rating"
                    width: 2
                    height: 2
                }

                PlasmaComponents3.Label {
                    text: itemData ? (itemData.stargazers_count || 0) : 0
                    opacity: 0.6
                    font.pixelSize: 15
                }

                Kirigami.Icon {
                    source: "vcs-branch"
                    width: 2
                    height: 2
                }

                PlasmaComponents3.Label {
                    text: itemData ? (itemData.forks_count || 0) : 0
                    opacity: 0.6
                    font.pixelSize: 15
                }

            }

            // Comments for issues/PRs
            RowLayout {
                spacing: 3
                visible: itemType === "issue" || itemType === "pr"

                Kirigami.Icon {
                    source: "dialog-messages"
                    width: 2
                    height: 2
                }

                PlasmaComponents3.Label {
                    text: itemData ? (itemData.comments || 0) : 0
                    opacity: 0.6
                    font.pixelSize: 15
                }

            }

            // Repos for orgs
            RowLayout {
                spacing: 3
                visible: itemType === "org"

                Kirigami.Icon {
                    source: "folder-code"
                    width: 2
                    height: 2
                }

                PlasmaComponents3.Label {
                    text: (itemData ? (itemData.public_repos || 0) : 0) + " repos"
                    opacity: 0.6
                    font.pixelSize: 15
                }

            }

        }

        // Hamburger menu button
        PlasmaComponents3.Button {
            id: menuButton

            icon.name: "application-menu"
            flat: true
            implicitWidth: 24
            implicitHeight: 24
            onClicked: contextMenu.opened ? contextMenu.close() : contextMenu.popup(menuButton, 0, menuButton.height)

            PlasmaComponents3.Menu {
                id: contextMenu

                PlasmaComponents3.MenuItem {
                    text: "Copy URL"
                    icon.name: "edit-copy"
                    enabled: getItemUrl() !== ""
                    onTriggered: {
                        var url = getItemUrl();
                        if (url)
                            clipboardHelper.copyToClipboard(url);

                    }
                }

                PlasmaComponents3.MenuSeparator {
                }

                PlasmaComponents3.MenuItem {
                    text: "Open in GitHub"
                    icon.name: "internet-services"
                    enabled: getItemUrl() !== ""
                    onTriggered: {
                        var url = getItemUrl();
                        if (url)
                            Qt.openUrlExternally(url);

                    }
                }

            }

        }

    }

}
