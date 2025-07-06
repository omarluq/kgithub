import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import "components" as Components

PlasmoidItem {
    id: root

    // Configuration properties
    readonly property string githubToken: plasmoid.configuration.githubToken || ""
    readonly property string githubUsername: plasmoid.configuration.githubUsername || ""
    readonly property int refreshInterval: (plasmoid.configuration.refreshInterval || 5) * 60000
    readonly property bool showRepositoriesTab: plasmoid.configuration.showRepositoriesTab !== undefined ? plasmoid.configuration.showRepositoriesTab : true
    readonly property bool showIssuesTab: plasmoid.configuration.showIssuesTab !== undefined ? plasmoid.configuration.showIssuesTab : true
    readonly property bool showPullRequestsTab: plasmoid.configuration.showPullRequestsTab !== undefined ? plasmoid.configuration.showPullRequestsTab : true
    readonly property bool showOrganizationsTab: plasmoid.configuration.showOrganizationsTab !== undefined ? plasmoid.configuration.showOrganizationsTab : true
    readonly property bool showStarredTab: plasmoid.configuration.showStarredTab !== undefined ? plasmoid.configuration.showStarredTab : true
    readonly property int itemsPerPage: plasmoid.configuration.itemsPerPage || 5

    // Dynamic tab management
    property var visibleTabs: buildVisibleTabsList()

    function buildVisibleTabsList() {
        var tabs = [];
        if (root.showRepositoriesTab) tabs.push({id: "repos", name: "Repos", data: dataManager.repositoriesData});
        if (root.showIssuesTab) tabs.push({id: "issues", name: "Issues", data: dataManager.issuesData});
        if (root.showPullRequestsTab) tabs.push({id: "prs", name: "PRs", data: dataManager.pullRequestsData});
        if (root.showOrganizationsTab) tabs.push({id: "orgs", name: "Orgs", data: dataManager.organizationsData});
        if (root.showStarredTab) tabs.push({id: "starred", name: "Starred", data: dataManager.starredRepositoriesData});
        return tabs;
    }

    // Store tab display texts to avoid binding loops
    property var tabDisplayTexts: ({})

    // Store current tab index to preserve across data updates
    property int currentTabIndex: 0

    function updateTabDisplayTexts() {
        tabDisplayTexts = {
            "repos": "Repos",
            "issues": "Issues",
            "prs": "PRs",
            "orgs": "Orgs",
            "starred": "Starred"
        };
    }

    // Width calculation trigger
    property int widthTrigger: 0

    function triggerWidthRecalculation() {
        widthTrigger++;
    }

    // Data Manager - centralized data handling
    Components.DataManager {
        id: dataManager
        githubToken: root.githubToken
        githubUsername: root.githubUsername
        itemsPerPage: root.itemsPerPage

        onDataUpdated: {
            // Trigger UI updates when data changes
            root.updateTabDisplayTexts();
            root.triggerWidthRecalculation();
        }

        onErrorOccurred: function(message) {
            // Error handling can be added here if needed
        }

        onWidthRecalculationNeeded: {
            root.triggerWidthRecalculation();
        }
    }

    // Preferred representation
    preferredRepresentation: compactRepresentation

    // Compact representation (icon in panel/desktop)
    compactRepresentation: Item {
        id: compactRoot

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }

        Image {
            id: icon
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.8
            height: width
            source: dataManager.isLoading ? "" : Qt.resolvedUrl("../assets/icons/icons8-github.svg")
            fillMode: Image.PreserveAspectFit
            smooth: true

            Kirigami.Icon {
                anchors.fill: parent
                source: "view-refresh"
                visible: dataManager.isLoading

                RotationAnimation on rotation {
                    running: dataManager.isLoading
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }
    }

    // Full representation (expanded widget)
    fullRepresentation: Item {
        id: fullRepresentation

        Layout.minimumWidth: optimalWidth
        Layout.minimumHeight: optimalHeight
        Layout.preferredWidth: optimalWidth
        Layout.preferredHeight: optimalHeight
        Layout.maximumWidth: optimalWidth

        property int optimalWidth: {
            // Make calculation reactive to data changes
            root.widthTrigger;

            // Base width calculation
            var baseWidth = Kirigami.Units.gridUnit * 28;
            var calculatedWidth = baseWidth;

            // User profile width
            if (dataManager.userData) {
                var profileWidth = 0;
                if (dataManager.userData.name) {
                    profileWidth = Math.max(profileWidth, dataManager.userData.name.length * 10);
                }
                if (dataManager.userData.login) {
                    profileWidth = Math.max(profileWidth, dataManager.userData.login.length * 10);
                }
                profileWidth += 200; // Avatar + stats + margins
                calculatedWidth = Math.max(calculatedWidth, profileWidth);
            }

            // Tab bar width
            var tabBarWidth = root.visibleTabs.length * 80 + 40;
            calculatedWidth = Math.max(calculatedWidth, tabBarWidth);

            // Content-based width
            calculatedWidth = Math.max(calculatedWidth, Kirigami.Units.gridUnit * 30);

            // Apply constraints
            var finalWidth = Math.max(baseWidth, calculatedWidth);
            return Math.min(finalWidth, Kirigami.Units.gridUnit * 50);
        }

        property int optimalHeight: {
            // Simplified height calculation
            var headerHeight = 40;
            var profileCardHeight = 84;
            var tabBarHeight = 32;
            var contentHeight = root.itemsPerPage * 60 + (root.itemsPerPage - 1) * 2;
            var paginationHeight = 32;
            var margins = 20;

            var totalHeight = headerHeight + profileCardHeight + tabBarHeight + contentHeight + paginationHeight + margins;
            return Math.max(totalHeight, Kirigami.Units.gridUnit * 15);
        }

        Component.onCompleted: {
            // Initialize tab display texts
            root.updateTabDisplayTexts();
            if (root.githubToken !== "" && root.githubUsername !== "") {
                if (!dataManager.userData) {
                    dataManager.refreshData();
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // Header
            RowLayout {
                Layout.fillWidth: true

                Kirigami.Heading {
                    text: "KGithub"
                    level: 3
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Button {
                    icon.name: "view-refresh"
                    onClicked: dataManager.refreshData(true)
                    enabled: !dataManager.isLoading
                }
            }

            // User profile card
            Components.UserProfileCard {
                Layout.fillWidth: true
                userData: dataManager.userData
                repositoryCount: dataManager.totalRepos
                totalStars: dataManager.totalStars
            }

            // Tab bar
            PlasmaComponents3.TabBar {
                id: tabBar
                Layout.fillWidth: true
                currentIndex: root.currentTabIndex

                onCurrentIndexChanged: {
                    root.currentTabIndex = currentIndex;
                }

                Repeater {
                    model: root.visibleTabs
                    PlasmaComponents3.TabButton {
                        text: root.tabDisplayTexts[modelData.id] || modelData.name
                    }
                }
            }

            // Content area
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentTabIndex

                // Repositories tab
                ColumnLayout {
                    visible: root.showRepositoriesTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: dataManager.repositoriesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: reposList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(dataManager.repositoriesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: dataManager.repositoriesData[index]
                                itemType: "repo"
                                itemIndex: index
                                width: reposList.width
                                onClicked: function (item) {
                                }
                            }
                        }
                    }

                    Components.PaginationControls {
                        Layout.fillWidth: true
                        currentPage: dataManager.getCurrentPageForTab("repos")
                        hasMore: dataManager.getHasMoreForTab("repos")
                        totalItems: dataManager.getTotalItemsForTab("repos")
                        currentPageItems: dataManager.repositoriesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            dataManager.fetchDataForTab("repos", page);
                        }
                    }
                }

                // Issues tab
                ColumnLayout {
                    visible: root.showIssuesTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: dataManager.issuesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: issuesList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(dataManager.issuesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: dataManager.issuesData[index]
                                itemType: "issue"
                                itemIndex: index
                                width: issuesList.width
                                onClicked: function (item) {
                                }
                            }
                        }
                    }

                    Components.PaginationControls {
                        Layout.fillWidth: true
                        currentPage: dataManager.getCurrentPageForTab("issues")
                        hasMore: dataManager.getHasMoreForTab("issues")
                        totalItems: dataManager.getTotalItemsForTab("issues")
                        currentPageItems: dataManager.issuesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            dataManager.fetchDataForTab("issues", page);
                        }
                    }
                }

                // Pull Requests tab
                ColumnLayout {
                    visible: root.showPullRequestsTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: dataManager.pullRequestsData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: prsList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(dataManager.pullRequestsData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: dataManager.pullRequestsData[index]
                                itemType: "pr"
                                itemIndex: index
                                width: prsList.width
                                onClicked: function (item) {
                                }
                            }
                        }
                    }

                    Components.PaginationControls {
                        Layout.fillWidth: true
                        currentPage: dataManager.getCurrentPageForTab("prs")
                        hasMore: dataManager.getHasMoreForTab("prs")
                        totalItems: dataManager.getTotalItemsForTab("prs")
                        currentPageItems: dataManager.pullRequestsData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            dataManager.fetchDataForTab("prs", page);
                        }
                    }
                }

                // Organizations tab
                ColumnLayout {
                    visible: root.showOrganizationsTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: dataManager.organizationsData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: orgsList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(dataManager.organizationsData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: dataManager.organizationsData[index]
                                itemType: "org"
                                itemIndex: index
                                width: orgsList.width
                                onClicked: function (item) {
                                }
                            }
                        }
                    }

                    Components.PaginationControls {
                        Layout.fillWidth: true
                        currentPage: dataManager.getCurrentPageForTab("orgs")
                        hasMore: dataManager.getHasMoreForTab("orgs")
                        totalItems: dataManager.getTotalItemsForTab("orgs")
                        currentPageItems: dataManager.organizationsData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            dataManager.fetchDataForTab("orgs", page);
                        }
                    }
                }

                // Starred Repositories tab
                ColumnLayout {
                    visible: root.showStarredTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: dataManager.starredRepositoriesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: starredList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(dataManager.starredRepositoriesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: dataManager.starredRepositoriesData[index]
                                itemType: "repo"
                                itemIndex: index
                                width: starredList.width
                                onClicked: function (item) {
                                }
                            }
                        }
                    }

                    Components.PaginationControls {
                        Layout.fillWidth: true
                        currentPage: dataManager.getCurrentPageForTab("starred")
                        hasMore: dataManager.getHasMoreForTab("starred")
                        totalItems: dataManager.getTotalItemsForTab("starred")
                        currentPageItems: dataManager.starredRepositoriesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            dataManager.fetchDataForTab("starred", page);
                        }
                    }
                }
            }

            // Error message
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: dataManager.errorMessage
                color: "red"
                visible: dataManager.errorMessage !== ""
                wrapMode: Text.WordWrap
            }
        }
    }

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: root.refreshInterval
        running: root.githubToken !== "" && root.githubUsername !== ""
        repeat: true
        onTriggered: dataManager.refreshData()
    }

    // Initial width calculation timer
    Timer {
        id: initialWidthTimer
        interval: 100
        running: true
        onTriggered: {
            root.triggerWidthRecalculation();
        }
    }

    // Component initialization
    Component.onCompleted: {
        // Initialize tab display texts
        root.updateTabDisplayTexts();
        if (root.githubToken !== "" && root.githubUsername !== "") {
            dataManager.refreshData();
        }
    }

    // React to configuration changes
    onItemsPerPageChanged: {
        root.triggerWidthRecalculation();
    }

    // Watch for configuration changes and rebuild visible tabs
    onShowRepositoriesTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
    }
    onShowIssuesTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
    }
    onShowPullRequestsTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
    }
    onShowOrganizationsTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
    }
    onShowStarredTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
    }
}
