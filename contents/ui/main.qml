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

    // Navigation context modes
    property bool inRepositoryContext: false
    property bool inDetailContext: false
    property var currentRepository: null
    property var currentItem: null  // Current issue or PR being viewed
    property string previousTabId: ""

    // Dynamic tab management
    property var visibleTabs: buildVisibleTabsList()

    function buildVisibleTabsList() {
        var tabs = [];

        if (root.inDetailContext) {
            // In detail context, no tabs needed - single view
            return tabs;
        } else if (root.inRepositoryContext) {
            // In repository context, only show Issues and PRs tabs
            tabs.push({
                id: "repo-issues",
                name: "Issues",
                data: dataManager.repositoryIssuesData
            });
            tabs.push({
                id: "repo-prs",
                name: "PRs",
                data: dataManager.repositoryPRsData
            });
        } else {
            // Global context - show all enabled tabs
            if (root.showRepositoriesTab)
                tabs.push({
                    id: "repos",
                    name: "Repos",
                    data: dataManager.repositoriesData
                });
            if (root.showIssuesTab)
                tabs.push({
                    id: "issues",
                    name: "Issues",
                    data: dataManager.issuesData
                });
            if (root.showPullRequestsTab)
                tabs.push({
                    id: "prs",
                    name: "PRs",
                    data: dataManager.pullRequestsData
                });
            if (root.showOrganizationsTab)
                tabs.push({
                    id: "orgs",
                    name: "Orgs",
                    data: dataManager.organizationsData
                });
            if (root.showStarredTab)
                tabs.push({
                    id: "starred",
                    name: "Starred",
                    data: dataManager.starredRepositoriesData
                });
        }

        return tabs;
    }

    // Store current tab index to preserve across data updates
    property int currentTabIndex: 0

    // Width calculation trigger
    property int widthTrigger: 0

    function triggerWidthRecalculation() {
        widthTrigger++;
    }

    function enterRepositoryContext(repository) {
        // Save current tab ID to return to later
        if (root.currentTabIndex < root.visibleTabs.length) {
            root.previousTabId = root.visibleTabs[root.currentTabIndex].id;
        }

        root.currentRepository = repository;
        root.inRepositoryContext = true;
        root.currentTabIndex = 0; // Reset to first tab in repo context

        // Update tab structure
        root.visibleTabs = buildVisibleTabsList();

        // Fetch repository-specific data
        dataManager.fetchRepositoryIssues(repository.full_name, 1);
        dataManager.fetchRepositoryPRs(repository.full_name, 1);

        root.triggerWidthRecalculation();
    }

    function exitRepositoryContext() {
        root.inRepositoryContext = false;
        root.currentRepository = null;

        // Restore global tab structure first
        var newVisibleTabs = buildVisibleTabsList();

        // Find the correct tab index before updating visibleTabs
        var targetIndex = 0; // Default fallback
        for (var i = 0; i < newVisibleTabs.length; i++) {
            if (newVisibleTabs[i].id === root.previousTabId) {
                targetIndex = i;
                break;
            }
        }

        // Update tabs and index together
        root.visibleTabs = newVisibleTabs;
        root.currentTabIndex = targetIndex;
        // Force TabBar to sync its currentIndex
        if (tabBar && tabBar.currentIndex !== targetIndex) {
            tabBar.currentIndex = targetIndex;
        }

        root.triggerWidthRecalculation();
    }

    function enterDetailContext(item) {
        // Save current tab ID to return to later
        if (root.currentTabIndex < root.visibleTabs.length) {
            root.previousTabId = root.visibleTabs[root.currentTabIndex].id;
        }

        root.currentItem = item;
        root.inDetailContext = true;
        root.visibleTabs = buildVisibleTabsList();

        // Fetch detailed data for the item
        if (root.currentRepository && item) {
            if (item.pull_request) {
                // It's a PR
                dataManager.fetchPullRequestDetails(root.currentRepository.full_name, item.number);
            } else {
                // It's an issue
                dataManager.fetchIssueDetails(root.currentRepository.full_name, item.number);
            }
        }

        root.triggerWidthRecalculation();
    }

    function exitDetailContext() {
        root.inDetailContext = false;
        root.currentItem = null;

        // If we came from global context (not repository context), clear currentRepository
        if (!root.inRepositoryContext) {
            root.currentRepository = null;
        }

        // Restore tab structure first
        var newVisibleTabs = buildVisibleTabsList();

        // Find the correct tab index before updating visibleTabs
        var targetIndex = 0; // Default fallback
        for (var i = 0; i < newVisibleTabs.length; i++) {
            if (newVisibleTabs[i].id === root.previousTabId) {
                targetIndex = i;
                break;
            }
        }

        // Update tabs and index together
        root.visibleTabs = newVisibleTabs;
        root.currentTabIndex = targetIndex;
        // Force TabBar to sync its currentIndex
        if (tabBar && tabBar.currentIndex !== targetIndex) {
            tabBar.currentIndex = targetIndex;
        }

        root.triggerWidthRecalculation();
    }

    // Data Manager - centralized data handling
    Components.DataManager {
        id: dataManager
        githubToken: root.githubToken
        githubUsername: root.githubUsername
        itemsPerPage: root.itemsPerPage

        onDataUpdated: {
            // Trigger UI updates when data changes
            root.triggerWidthRecalculation();
        }

        onErrorOccurred: function (message) {}

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
            // Dynamic height calculation
            var headerHeight = 40;
            var profileCardHeight = 84;
            var tabBarHeight = 32;
            var margins = 20;

            if (root.inDetailContext) {
                // Detail view: calculate based on number of timeline items
                var timelineItems = Math.min(3, dataManager.currentItemComments.length + 1); // +1 for description
                var timelineHeight = timelineItems * 124 + (timelineItems - 1) * 4; // 120px per card + 4px spacing
                var issueHeaderHeight = 80; // Title + author + labels
                var totalHeight = headerHeight + profileCardHeight + issueHeaderHeight + timelineHeight + margins;
                return Math.max(totalHeight, Kirigami.Units.gridUnit * 20);
            } else {
                // Normal tab view
                var contentHeight = root.itemsPerPage * 60 + (root.itemsPerPage - 1) * 2;
                var paginationHeight = 32;
                var totalHeight = headerHeight + profileCardHeight + tabBarHeight + contentHeight + paginationHeight + margins;
                return Math.max(totalHeight, Kirigami.Units.gridUnit * 15);
            }
        }

        Component.onCompleted: {
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

                // Back button (visible in repository or detail context)
                PlasmaComponents3.Button {
                    icon.name: "go-previous"
                    visible: root.inRepositoryContext || root.inDetailContext
                    onClicked: {
                        if (root.inDetailContext) {
                            root.exitDetailContext();
                        } else {
                            root.exitRepositoryContext();
                        }
                    }
                    PlasmaComponents3.ToolTip.text: {
                        if (root.inDetailContext) {
                            return root.inRepositoryContext ? "Back to repository view" : "Back to global view";
                        } else {
                            return "Back to global view";
                        }
                    }
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                Kirigami.Heading {
                    text: {
                        if (root.inDetailContext && root.currentRepository && root.currentItem) {
                            return root.currentRepository.full_name + " #" + root.currentItem.number;
                        } else if (root.inRepositoryContext && root.currentRepository) {
                            return root.currentRepository.full_name;
                        } else {
                            return "KGithub";
                        }
                    }
                    level: 3
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Button {
                    icon.name: "view-refresh"
                    onClicked: {
                        if (root.inRepositoryContext && root.currentRepository) {
                            dataManager.fetchRepositoryIssues(root.currentRepository.full_name, 1);
                            dataManager.fetchRepositoryPRs(root.currentRepository.full_name, 1);
                        } else {
                            dataManager.refreshData(true);
                        }
                    }
                    enabled: !dataManager.isLoading
                }
            }

            // User profile card
            Components.UserProfileCard {
                Layout.fillWidth: true
                Layout.bottomMargin: root.inDetailContext ? 8 : 0
                userData: dataManager.userData
                repositoryCount: dataManager.totalRepos
                totalStars: dataManager.totalStars
            }

            // Tab bar
            PlasmaComponents3.TabBar {
                id: tabBar
                Layout.fillWidth: true
                Layout.topMargin: root.inDetailContext ? -12 : 0
                Layout.bottomMargin: root.inDetailContext ? -12 : 0
                currentIndex: root.currentTabIndex

                onCurrentIndexChanged: {
                    root.currentTabIndex = currentIndex;
                }

                Repeater {
                    model: root.visibleTabs
                    delegate: PlasmaComponents3.TabButton {
                        text: modelData.name
                        width: implicitWidth
                    }
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: root.inDetailContext ? 4 : 0

                // Detail view for issues/PRs
                Components.IssueDetailView {
                    anchors.fill: parent
                    anchors.margins: 0
                    visible: root.inDetailContext
                    itemData: root.currentItem
                    detailData: root.currentItem && root.currentItem.pull_request ? dataManager.currentPRDetail : dataManager.currentIssueDetail
                    commentsData: dataManager.currentItemComments
                    isLoading: dataManager.isLoading
                }

                // Tab-based view
                StackLayout {
                    anchors.fill: parent
                    visible: !root.inDetailContext
                    currentIndex: root.currentTabIndex

                    Repeater {
                        model: root.visibleTabs

                        ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing
                            property string tabId: modelData.id

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.policy: {
                                    var dataLength = 0;
                                    switch (tabId) {
                                    case "repos":
                                        dataLength = dataManager.repositoriesData.length;
                                        break;
                                    case "issues":
                                        dataLength = dataManager.issuesData.length;
                                        break;
                                    case "prs":
                                        dataLength = dataManager.pullRequestsData.length;
                                        break;
                                    case "orgs":
                                        dataLength = dataManager.organizationsData.length;
                                        break;
                                    case "starred":
                                        dataLength = dataManager.starredRepositoriesData.length;
                                        break;
                                    case "repo-issues":
                                        dataLength = dataManager.repositoryIssuesData.length;
                                        break;
                                    case "repo-prs":
                                        dataLength = dataManager.repositoryPRsData.length;
                                        break;
                                    }
                                    return dataLength === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded;
                                }

                                ListView {
                                    boundsBehavior: Flickable.StopAtBounds
                                    spacing: 2
                                    model: {
                                        switch (tabId) {
                                        case "repos":
                                            return dataManager.repositoriesData;
                                        case "issues":
                                            return dataManager.issuesData;
                                        case "prs":
                                            return dataManager.pullRequestsData;
                                        case "orgs":
                                            return dataManager.organizationsData;
                                        case "starred":
                                            return dataManager.starredRepositoriesData;
                                        case "repo-issues":
                                            return dataManager.repositoryIssuesData;
                                        case "repo-prs":
                                            return dataManager.repositoryPRsData;
                                        default:
                                            return [];
                                        }
                                    }

                                    delegate: Components.UnifiedListItem {
                                        itemData: modelData
                                        itemType: {
                                            switch (tabId) {
                                            case "repos":
                                                return "repo";
                                            case "issues":
                                            case "repo-issues":
                                                return "issue";
                                            case "prs":
                                            case "repo-prs":
                                                return "pr";
                                            case "orgs":
                                                return "org";
                                            case "starred":
                                                return "repo";
                                            default:
                                                return "repo";
                                            }
                                        }
                                        itemIndex: index
                                        width: parent.width
                                        onClicked: function (item) {
                                            if (tabId === "repos" || tabId === "starred") {
                                                // Repository clicked - enter repository context
                                                root.enterRepositoryContext(item);
                                            } else if (tabId === "issues" || tabId === "repo-issues" || tabId === "prs" || tabId === "repo-prs") {
                                                // Issue or PR clicked - enter detail context
                                                // For global issues/PRs, extract repository info from the item
                                                if (tabId === "issues" || tabId === "prs") {
                                                    // Extract repository info from global issue/PR
                                                    if (item.repository_url) {
                                                        var repoPath = item.repository_url.split('/').slice(-2);
                                                        root.currentRepository = {
                                                            full_name: repoPath.join('/'),
                                                            name: repoPath[1],
                                                            owner: {
                                                                login: repoPath[0]
                                                            }
                                                        };
                                                    }
                                                }
                                                root.enterDetailContext(item);
                                            }
                                        }
                                    }
                                }
                            }

                            Components.PaginationControls {
                                Layout.fillWidth: true
                                currentPage: {
                                    switch (tabId) {
                                    case "repos":
                                        return dataManager.getCurrentPageForTab("repos");
                                    case "issues":
                                        return dataManager.getCurrentPageForTab("issues");
                                    case "prs":
                                        return dataManager.getCurrentPageForTab("prs");
                                    case "orgs":
                                        return dataManager.getCurrentPageForTab("orgs");
                                    case "starred":
                                        return dataManager.getCurrentPageForTab("starred");
                                    case "repo-issues":
                                        return dataManager.currentRepoIssuesPage;
                                    case "repo-prs":
                                        return dataManager.currentRepoPRsPage;
                                    default:
                                        return 1;
                                    }
                                }
                                hasMore: {
                                    switch (tabId) {
                                    case "repos":
                                        return dataManager.getHasMoreForTab("repos");
                                    case "issues":
                                        return dataManager.getHasMoreForTab("issues");
                                    case "prs":
                                        return dataManager.getHasMoreForTab("prs");
                                    case "orgs":
                                        return dataManager.getHasMoreForTab("orgs");
                                    case "starred":
                                        return dataManager.getHasMoreForTab("starred");
                                    case "repo-issues":
                                        return dataManager.hasMoreRepoIssues;
                                    case "repo-prs":
                                        return dataManager.hasMoreRepoPRs;
                                    default:
                                        return false;
                                    }
                                }
                                totalItems: {
                                    switch (tabId) {
                                    case "repos":
                                        return dataManager.getTotalItemsForTab("repos");
                                    case "issues":
                                        return dataManager.getTotalItemsForTab("issues");
                                    case "prs":
                                        return dataManager.getTotalItemsForTab("prs");
                                    case "orgs":
                                        return dataManager.getTotalItemsForTab("orgs");
                                    case "starred":
                                        return dataManager.getTotalItemsForTab("starred");
                                    case "repo-issues":
                                        return dataManager.totalRepoIssues;
                                    case "repo-prs":
                                        return dataManager.totalRepoPRs;
                                    default:
                                        return 0;
                                    }
                                }
                                currentPageItems: {
                                    switch (tabId) {
                                    case "repos":
                                        return dataManager.repositoriesData.length;
                                    case "issues":
                                        return dataManager.issuesData.length;
                                    case "prs":
                                        return dataManager.pullRequestsData.length;
                                    case "orgs":
                                        return dataManager.organizationsData.length;
                                    case "starred":
                                        return dataManager.starredRepositoriesData.length;
                                    case "repo-issues":
                                        return dataManager.repositoryIssuesData.length;
                                    case "repo-prs":
                                        return dataManager.repositoryPRsData.length;
                                    default:
                                        return 0;
                                    }
                                }
                                itemsPerPage: root.itemsPerPage
                                onGoToPage: function (page) {
                                    switch (tabId) {
                                    case "repos":
                                    case "issues":
                                    case "prs":
                                    case "orgs":
                                    case "starred":
                                        dataManager.fetchDataForTab(tabId, page);
                                        break;
                                    case "repo-issues":
                                        dataManager.fetchRepositoryIssues(root.currentRepository.full_name, page);
                                        break;
                                    case "repo-prs":
                                        dataManager.fetchRepositoryPRs(root.currentRepository.full_name, page);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Error message
            RowLayout {
                Layout.fillWidth: true
                visible: dataManager.errorMessage !== ""
                spacing: 8

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: dataManager.errorMessage
                    color: "red"
                    wrapMode: Text.WordWrap
                }

                PlasmaComponents3.Button {
                    icon.name: "window-close"
                    flat: true
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: dataManager.clearError()
                    PlasmaComponents3.ToolTip.text: "Dismiss error"
                    PlasmaComponents3.ToolTip.visible: hovered
                }
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
