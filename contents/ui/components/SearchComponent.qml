import "." as Components
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

RowLayout {
    // Specific repo format: owner/repo - search by full name
    // Search in repository names and descriptions
    // Use GitHub's 'in:name' to search in repository names primarily

    id: searchComponent

    property bool isSearching: false
    property var searchResults: []
    property var dataManagerInstance: null
    property bool showUserAvatars: true
    property bool showOrgAvatars: true
    property bool showRepoAvatars: true
    property bool showIssueAvatars: true
    property bool showPRAvatars: true

    signal searchResultClicked(var item)
    signal openItem(var item)

    // Helper functions for menu actions
    function getItemUrl(item) {
        if (!item)
            return "";

        switch (item.searchResultType) {
        case "repo":
        case "issue":
        case "pr":
            return item.html_url || "";
        default:
            return "";
        }
    }

    // Advanced search query parsing
    function parseSearchQuery(query) {
        var trimmed = query.trim();
        var lowerTrimmed = trimmed.toLowerCase();
        // Check for advanced search prefixes (case-insensitive detection, preserve original case for query)
        if (lowerTrimmed.startsWith("repo:")) {
            var repoQuery = trimmed.substring(5).trim();
            // For repository search, we can enhance the query with GitHub search syntax
            if (repoQuery.includes("/"))
                repoQuery = "repo:" + repoQuery;
            else
                repoQuery = repoQuery + " in:name,description";
            return {
                "type": "repo",
                "query": repoQuery
            };
        } else if (lowerTrimmed.startsWith("issue:"))
            return {
            "type": "issue",
            "query": trimmed.substring(6).trim()
        };
        else if (lowerTrimmed.startsWith("pr:"))
            return {
            "type": "pr",
            "query": trimmed.substring(3).trim()
        };
        else
            return {
            "type": "global",
            "query": query
        };
    }

    // Helper functions for avatars and icons
    function getItemImageUrl(item) {
        if (!item)
            return "";

        switch (item.searchResultType) {
        case "repo":
            return item.owner && item.owner.avatar_url ? item.owner.avatar_url : "";
        case "issue":
        case "pr":
            return item.user && item.user.avatar_url ? item.user.avatar_url : "";
        default:
            return "";
        }
    }

    function shouldShowAvatar(item) {
        if (!item)
            return false;

        switch (item.searchResultType) {
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

    function getSystemIcon(item) {
        if (!item)
            return "document";

        switch (item.searchResultType) {
        case "repo":
            return "folder-code";
        case "issue":
            return "dialog-warning";
        case "pr":
            return "merge";
        default:
            return "document";
        }
    }

    // Function to handle search completion
    function onSearchCompleted(results) {
        searchComponent.isSearching = false;
        searchComponent.searchResults = results;
    }

    // Function to clear search
    function clearSearch() {
        searchField.text = "";
        performClearSearch();
    }

    function performSearch() {
        if (searchField.text.length === 0 || !dataManagerInstance)
            return ;

        searchComponent.isSearching = true;
        var parsedQuery = parseSearchQuery(searchField.text);
        // Use advanced search if available, otherwise fallback to global search
        if (dataManagerInstance.performAdvancedSearch)
            dataManagerInstance.performAdvancedSearch(parsedQuery.type, parsedQuery.query);
        else
            dataManagerInstance.performGlobalSearch(searchField.text);
    }

    function performClearSearch() {
        searchComponent.isSearching = false;
        searchComponent.searchResults = [];
        searchResultsPopup.close();
    }

    // Connect to DataManager's searchCompleted signal when dataManagerInstance is set
    onDataManagerInstanceChanged: {
        if (dataManagerInstance)
            dataManagerInstance.searchCompleted.connect(onSearchCompleted);

    }
    Layout.preferredWidth: 350
    Layout.maximumWidth: 400
    Layout.alignment: Qt.AlignHCenter
    spacing: 4

    PlasmaComponents3.TextField {
        id: searchField

        Layout.fillWidth: true
        placeholderText: "Search repos, issues, PRs..."
        onTextChanged: {
            if (text.length > 0) {
                if (!searchResultsPopup.opened)
                    searchResultsPopup.open();

                if (text.length > 2) {
                    searchTimer.restart();
                } else {
                    searchComponent.isSearching = false;
                    searchComponent.searchResults = [];
                }
            } else {
                searchComponent.performClearSearch();
            }
        }
        onAccepted: {
            if (text.length > 0)
                searchComponent.performSearch();

        }

        Timer {
            id: searchTimer

            interval: 500
            onTriggered: {
                if (searchField.text.length > 2)
                    searchComponent.performSearch();

            }
        }

    }

    // Search results popup
    PlasmaComponents3.Popup {
        id: searchResultsPopup

        width: 450
        height: Math.min(500, Math.max(100, searchComponent.searchResults.length * 70 + 60))
        // Position relative to search field
        parent: searchField
        x: 0
        y: searchField.height + 5
        clip: true

        // Clipboard helper using TextEdit workaround
        TextEdit {
            id: clipboardHelper

            function copyToClipboard(text) {
                clipboardHelper.text = text;
                clipboardHelper.selectAll();
                clipboardHelper.copy();
            }

            visible: false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Loading spinner
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: searchComponent.isSearching

                Item {
                    Layout.fillWidth: true
                }

                Kirigami.Icon {
                    id: spinnerIcon

                    source: "view-refresh"
                    width: 32
                    height: 32
                    Layout.alignment: Qt.AlignCenter

                    RotationAnimator {
                        target: spinnerIcon
                        running: searchComponent.isSearching
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

            }

            // Search hint for short queries
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Type at least 3 characters to search. Use prefixes: repo:, issue:, pr: for specific searches."
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.7
                visible: !searchComponent.isSearching && searchField.text.length <= 2 && searchField.text.length > 0

                Behavior on opacity {
                    PropertyAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                }

            }

            // Results list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                visible: !searchComponent.isSearching && searchField.text.length > 2
                clip: true

                ListView {
                    model: searchComponent.searchResults
                    spacing: 6
                    opacity: 1
                    clip: true

                    Behavior on opacity {
                        PropertyAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }

                    }

                    delegate: Components.UnifiedListItem {
                        property var rootComponent: searchComponent

                        itemData: modelData
                        showUserAvatars: rootComponent.showUserAvatars
                        showOrgAvatars: rootComponent.showOrgAvatars
                        showRepoAvatars: rootComponent.showRepoAvatars
                        showIssueAvatars: rootComponent.showIssueAvatars
                        showPRAvatars: rootComponent.showPRAvatars
                        itemType: modelData.searchResultType || "repo"
                        itemIndex: index
                        width: ListView.view.width
                        onClicked: function(item) {
                            searchResultsPopup.close();
                            searchField.text = "";
                            rootComponent.openItem(item);
                        }
                    }

                }

            }

        }

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            radius: 8
        }

    }

}
