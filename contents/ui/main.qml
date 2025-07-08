import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
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
    readonly property int iconTheme: plasmoid.configuration.iconTheme !== undefined ? plasmoid.configuration.iconTheme : 0
    readonly property bool showIconInTitle: plasmoid.configuration.showIconInTitle !== undefined ? plasmoid.configuration.showIconInTitle : true
    readonly property bool showProfileCard: plasmoid.configuration.showProfileCard !== undefined ? plasmoid.configuration.showProfileCard : true
    readonly property bool useProfileCarousel: plasmoid.configuration.useProfileCarousel !== undefined ? plasmoid.configuration.useProfileCarousel : false
    readonly property int commitGraphColor: plasmoid.configuration.commitGraphColor !== undefined ? plasmoid.configuration.commitGraphColor : 0
    readonly property int defaultReadmeViewMode: plasmoid.configuration.defaultReadmeViewMode !== undefined ? plasmoid.configuration.defaultReadmeViewMode : 2
    readonly property int defaultCommentViewMode: plasmoid.configuration.defaultCommentViewMode !== undefined ? plasmoid.configuration.defaultCommentViewMode : 1
    readonly property bool showUserAvatars: plasmoid.configuration.showUserAvatars !== undefined ? plasmoid.configuration.showUserAvatars : true
    readonly property bool showOrgAvatars: plasmoid.configuration.showOrgAvatars !== undefined ? plasmoid.configuration.showOrgAvatars : true
    readonly property bool showRepoAvatars: plasmoid.configuration.showRepoAvatars !== undefined ? plasmoid.configuration.showRepoAvatars : true
    readonly property bool showIssueAvatars: plasmoid.configuration.showIssueAvatars !== undefined ? plasmoid.configuration.showIssueAvatars : true
    readonly property bool showPRAvatars: plasmoid.configuration.showPRAvatars !== undefined ? plasmoid.configuration.showPRAvatars : true
    readonly property bool showProfileReadmeTab: plasmoid.configuration.showProfileReadmeTab !== undefined ? plasmoid.configuration.showProfileReadmeTab : true

    // Watch for configuration changes and rebuild tabs
    onShowProfileReadmeTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
        root.triggerWidthRecalculation();
    }

    // Navigation context modes
    property bool inRepositoryContext: false
    property bool inDetailContext: false
    property var currentRepository: null
    property var currentItem: null  // Current issue or PR being viewed
    property string previousTabId: ""
    property string previousGlobalTabId: "" // For repository → global navigation

    // Navigation history stack for search results
    property var navigationHistory: []

    // Dynamic tab management
    property var visibleTabs: []

    function buildVisibleTabsList() {
        var tabs = [];

        if (root.inDetailContext) {
            // In detail context, no tabs needed - single view
            return tabs;
        } else if (root.inRepositoryContext) {
            // In repository context, show README, Issues and PRs tabs
            // Always show README tab - data will be loaded lazily
            tabs.push({
                id: "repo-readme",
                name: "README",
                data: dataManager.repositoryReadmeData
            });
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
            // Global context - show all enabled tabs with Profile README first
            if (root.showProfileReadmeTab)
                tabs.push({
                    id: "profile-readme",
                    name: "README",
                    data: dataManager.profileReadmeData
                });
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

    function enterRepositoryContext(repository, skipHistoryUpdate = false) {
        // Save current global tab ID to return to later
        if (root.currentTabIndex < root.visibleTabs.length) {
            root.previousGlobalTabId = root.visibleTabs[root.currentTabIndex].id;
        }

        // Add current context to navigation history (unless we're navigating back)
        if (!skipHistoryUpdate) {
            var historyEntry = {
                type: "repository",
                repository: repository,
                timestamp: Date.now()
            };

            // Avoid duplicate entries
            var isDuplicate = false;
            if (navigationHistory.length > 0) {
                var lastEntry = navigationHistory[navigationHistory.length - 1];
                if (lastEntry.type === "repository" &&
                    lastEntry.repository &&
                    lastEntry.repository.full_name === repository.full_name) {
                    isDuplicate = true;
                }
            }

            if (!isDuplicate) {
                navigationHistory.push(historyEntry);
                // Keep history limited to last 10 items
                if (navigationHistory.length > 10) {
                    navigationHistory.shift();
                }
            }
        }

        // Clear previous repository data when switching to a different repository
        if (root.currentRepository && root.currentRepository.full_name !== repository.full_name) {
            dataManager.repositoryReadmeData = null;
            dataManager.repositoryIssuesData = [];
            dataManager.repositoryPRsData = [];

            // Clear the loaded cache for the previous repository
            var prevRepoName = root.currentRepository.full_name;
            delete dataManager.loadedRepoTabs[prevRepoName + "-readme"];
            delete dataManager.loadedRepoTabs[prevRepoName + "-issues"];
            delete dataManager.loadedRepoTabs[prevRepoName + "-prs"];
        }

        root.currentRepository = repository;
        root.inRepositoryContext = true;
        root.currentTabIndex = 0; // Reset to first tab in repo context

        // Update tab structure
        root.visibleTabs = buildVisibleTabsList();

        // Only fetch data for the first visible tab (lazy loading)
        if (root.visibleTabs.length > 0) {
            var firstTabId = root.visibleTabs[0].id;
            if (firstTabId === "repo-readme") {
                dataManager.ensureRepoTabDataLoaded(repository.full_name, "readme");
            } else if (firstTabId === "repo-issues") {
                dataManager.ensureRepoTabDataLoaded(repository.full_name, "issues");
            } else if (firstTabId === "repo-prs") {
                dataManager.ensureRepoTabDataLoaded(repository.full_name, "prs");
            }
        }

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
            if (newVisibleTabs[i].id === root.previousGlobalTabId) {
                targetIndex = i;
                break;
            }
        }

        // Update tabs and index together
        root.visibleTabs = newVisibleTabs;
        root.currentTabIndex = targetIndex;

        root.triggerWidthRecalculation();
    }

    function navigateBack() {
        if (root.inDetailContext) {
            root.exitDetailContext();
            return;
        }

        if (navigationHistory.length > 1) {
            // Remove current item
            navigationHistory.pop();

            // Get the previous item
            var previousEntry = navigationHistory[navigationHistory.length - 1];

            // Navigate to the previous item without adding to history
            if (previousEntry.type === "repo") {
                root.enterRepositoryContext(previousEntry.data, true);
            } else if (previousEntry.type === "issue" || previousEntry.type === "pr") {
                // Re-navigate to the previous issue/PR
                root.navigateToSearchResult(previousEntry.data);
                // Remove the duplicate entry we just added
                navigationHistory.pop();
            }
        } else {
            // No more history, go back to global view
            root.exitRepositoryContext();
            navigationHistory = [];
        }
    }

    function enterDetailContext(item) {

        // Save current tab ID to return to later (only if not already in detail context)
        if (!root.inDetailContext && root.currentTabIndex < root.visibleTabs.length) {
            root.previousTabId = root.visibleTabs[root.currentTabIndex].id;
        }

        // Clear previous detail data ALWAYS
        dataManager.currentIssueDetail = null;
        dataManager.currentPRDetail = null;
        dataManager.currentItemComments = [];


        root.currentItem = item;
        root.inDetailContext = true;
        root.visibleTabs = buildVisibleTabsList();

        // Force UI update after clearing data
        dataManager.dataUpdated();
        root.triggerWidthRecalculation();

        // Fetch detailed data for the item
        if (root.currentRepository && item) {
            if (item.pull_request || item.searchResultType === "pr") {
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

        root.triggerWidthRecalculation();
    }

    function navigateToSearchResult(item) {
        // Search field is already cleared by SearchComponent

        // Add this navigation to history FIRST
        var historyEntry = {
            type: item.searchResultType,
            data: item,
            timestamp: Date.now()
        };
        navigationHistory.push(historyEntry);
        if (navigationHistory.length > 10) {
            navigationHistory.shift();
        }

        switch (item.searchResultType) {
        case "repo":
            root.enterRepositoryContext(item, true); // Skip adding to history again
            break;
        case "issue":
        case "pr":
            // Extract repository info from search result
            var repoInfo = null;
            if (item.repository_url) {
                var parts = item.repository_url.split('/');
                repoInfo = {
                    full_name: parts[parts.length - 2] + "/" + parts[parts.length - 1],
                    name: parts[parts.length - 1],
                    owner: { login: parts[parts.length - 2] }
                };
            } else if (item.html_url) {
                var urlParts = item.html_url.split('/');
                repoInfo = {
                    full_name: urlParts[3] + "/" + urlParts[4],
                    name: urlParts[4],
                    owner: { login: urlParts[3] }
                };
            }

            if (repoInfo) {
                // Always clear previous data when switching repositories
                if (!root.currentRepository || root.currentRepository.full_name !== repoInfo.full_name) {
                    if (root.currentRepository) {
                        dataManager.repositoryReadmeData = null;
                        dataManager.repositoryIssuesData = [];
                        dataManager.repositoryPRsData = [];
                        var prevRepoName = root.currentRepository.full_name;
                        delete dataManager.loadedRepoTabs[prevRepoName + "-readme"];
                        delete dataManager.loadedRepoTabs[prevRepoName + "-issues"];
                        delete dataManager.loadedRepoTabs[prevRepoName + "-prs"];
                    }
                    root.currentRepository = repoInfo;
                    root.inRepositoryContext = true;
                }

                root.enterDetailContext(item);
            }
            break;
        default:
        }
    }

    // Data Manager - centralized data handling
    Components.DataManager {
        id: dataManager
        githubToken: root.githubToken
        githubUsername: root.githubUsername
        itemsPerPage: root.itemsPerPage

        onDataUpdated: {
            // Just trigger height recalculation - no need to rebuild tabs
            root.triggerWidthRecalculation();
        }

        onErrorOccurred: function (message) {
            root.triggerWidthRecalculation(); // This also triggers height recalculation
        }

        onWidthRecalculationNeeded: {
            // Rebuild tabs if we're in repository context (for README data changes)
            if (root.inRepositoryContext) {
                root.visibleTabs = buildVisibleTabsList();
            }
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
            source: dataManager.isLoading ? "" : Qt.resolvedUrl("../assets/icons/icons8-github" + (root.iconTheme === 1 ? "-light" : "") + ".svg")
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
        Layout.maximumHeight: optimalHeight

        property int optimalWidth: {
            // Make calculation reactive to data changes
            root.widthTrigger;

            // Base width calculation (scaled 1.5x)
            var baseWidth = Kirigami.Units.gridUnit * 42;
            var calculatedWidth = baseWidth;

            // User profile width (scaled 1.5x)
            if (dataManager.userData) {
                var profileWidth = 0;
                if (dataManager.userData.name) {
                    profileWidth = Math.max(profileWidth, dataManager.userData.name.length * 15);
                }
                if (dataManager.userData.login) {
                    profileWidth = Math.max(profileWidth, dataManager.userData.login.length * 15);
                }
                profileWidth += 300; // Avatar + stats + margins (scaled 1.5x)
                calculatedWidth = Math.max(calculatedWidth, profileWidth);
            }

            // Tab bar width (scaled 1.5x)
            var tabBarWidth = root.visibleTabs.length * 120 + 60;
            calculatedWidth = Math.max(calculatedWidth, tabBarWidth);

            // Content-based width (scaled 1.5x)
            calculatedWidth = Math.max(calculatedWidth, Kirigami.Units.gridUnit * 45);

            // Apply constraints (scaled 1.5x)
            var finalWidth = Math.max(baseWidth, calculatedWidth);
            return Math.min(finalWidth, Kirigami.Units.gridUnit * 75);
        }

        property int optimalHeight: {
            // Trigger recalculation when data changes or context changes
            root.widthTrigger;

            // Base component heights (scaled 1.5x)
            var headerHeight = 60;
            var profileCardHeight = (dataManager.userData && root.showProfileCard) ? (root.useProfileCarousel ? 200 : 126) : 0; // Taller for carousel
            var tabBarHeight = root.inDetailContext ? 0 : 48; // No tabs in detail view
            var margins = 30; // Top and bottom margins
            var errorHeight = dataManager.errorMessage !== "" ? 36 : 0;
            var componentSpacing = 18; // Kirigami.Units.smallSpacing between components (approximately 6px * 3 components)

            if (root.inDetailContext) {
                // Detail view: calculate based on actual timeline items
                var commentsLength = dataManager.currentItemComments ? dataManager.currentItemComments.length : 0;
                var actualTimelineItems = commentsLength + 1; // +1 for description
                var paginatedItems = Math.min(3, actualTimelineItems); // Items shown per page
                var timelineHeight = paginatedItems * 180 + Math.max(0, paginatedItems - 1) * 9; // 180px per card + 9px spacing between cards
                var issueHeaderHeight = 120; // Title + author + labels (scaled 1.5x)
                var paginationHeight = actualTimelineItems > 3 ? 60 : 0; // Only show if needed
                return Math.max(headerHeight + profileCardHeight + issueHeaderHeight + timelineHeight + paginationHeight + errorHeight + margins + componentSpacing, 200);
            } else {
                // Normal tab view: calculate based on current context and actual data
                var currentData = [];

                // Get data based on current context
                if (root.inRepositoryContext) {
                    // Repository context - get data based on actual tab ID
                    if (root.currentTabIndex < root.visibleTabs.length && root.visibleTabs[root.currentTabIndex]) {
                        var currentTabId = root.visibleTabs[root.currentTabIndex].id;
                        switch (currentTabId) {
                        case "repo-readme":
                            // Make README tab same height as a full page of items
                            var mockArray = [];
                            for (var i = 0; i < root.itemsPerPage; i++) {
                                mockArray.push(i);
                            }
                            currentData = mockArray;
                            break;
                        case "repo-issues":
                            currentData = dataManager.repositoryIssuesData || [];
                            break;
                        case "repo-prs":
                            currentData = dataManager.repositoryPRsData || [];
                            break;
                        default:
                            currentData = [];
                        }
                    } else {
                        currentData = [];
                    }
                } else {
                    // Global context - check current tab
                    if (root.currentTabIndex < root.visibleTabs.length && root.visibleTabs[root.currentTabIndex]) {
                        var tabId = root.visibleTabs[root.currentTabIndex].id;
                        switch (tabId) {
                        case "repos":
                            currentData = dataManager.repositoriesData || [];
                            break;
                        case "issues":
                            currentData = dataManager.issuesData || [];
                            break;
                        case "prs":
                            currentData = dataManager.pullRequestsData || [];
                            break;
                        case "orgs":
                            currentData = dataManager.organizationsData || [];
                            break;
                        case "starred":
                            currentData = dataManager.starredRepositoriesData || [];
                            break;
                        case "leaderboard":
                            currentData = [1, 2, 3, 4, 5]; // Mock 5 items for height calculation
                            break;
                        case "profile-readme":
                            // Make README tab same height as a full page of items
                            var mockArray = [];
                            for (var i = 0; i < root.itemsPerPage; i++) {
                                mockArray.push(i);
                            }
                            currentData = mockArray;
                            break;
                        default:
                            currentData = [];
                        }
                    }
                }

                var actualItems = Math.min(root.itemsPerPage, currentData.length);
                var contentHeight = actualItems * 90 + Math.max(0, actualItems - 1) * 3; // 90px per item + 3px spacing between items
                var paginationHeight = currentData.length > root.itemsPerPage ? 48 : 0;

                return Math.max(headerHeight + profileCardHeight + tabBarHeight + contentHeight + paginationHeight + errorHeight + margins + componentSpacing, 200);
            }
        }

        Component.onCompleted: {
            // Initialize visible tabs
            root.visibleTabs = buildVisibleTabsList();

            if (root.githubToken !== "" && root.githubUsername !== "") {
                if (!dataManager.userData) {
                    dataManager.refreshData();
                }

                // Lazy load data for the initial tab
                if (root.visibleTabs.length > 0) {
                    var initialTabId = root.visibleTabs[0].id;
                    if (initialTabId === "profile-readme")
                    // Profile README is already fetched with user data
                    {} else if (initialTabId === "repos") {
                        dataManager.ensureTabDataLoaded("repos");
                    } else if (initialTabId === "issues") {
                        dataManager.ensureTabDataLoaded("issues");
                    } else if (initialTabId === "prs") {
                        dataManager.ensureTabDataLoaded("prs");
                    } else if (initialTabId === "orgs") {
                        dataManager.ensureTabDataLoaded("orgs");
                    } else if (initialTabId === "starred") {
                        dataManager.ensureTabDataLoaded("starred");
                    }
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
                    flat: true
                    visible: root.inRepositoryContext || root.inDetailContext
                    onClicked: {
                        root.navigateBack();
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Image {
                        width: 20
                        height: 20
                        source: Qt.resolvedUrl("../assets/icons/icons8-github" + (root.iconTheme === 1 ? "-light" : "") + ".svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: {
                            if (!root.showIconInTitle) {
                                return false; // Hide if disabled in settings
                            }
                            if (root.inDetailContext && root.currentRepository && root.currentItem) {
                                return false; // Hide in detail context
                            } else if (root.inRepositoryContext && root.currentRepository) {
                                return false; // Hide in repository context
                            } else {
                                return true; // Show only in global context
                            }
                        }
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
                }

                // Search component - centered
                Item {
                    Layout.fillWidth: true
                }

                Components.SearchComponent {
                    id: searchComponent
                    dataManagerInstance: dataManager
                    showUserAvatars: root.showUserAvatars
                    showOrgAvatars: root.showOrgAvatars
                    showRepoAvatars: root.showRepoAvatars
                    showIssueAvatars: root.showIssueAvatars
                    showPRAvatars: root.showPRAvatars
                    onSearchResultClicked: function(item) {
                        navigateToSearchResult(item);
                    }
                    onOpenItem: function(item) {
                        console.log("Main: onOpenItem signal received for:", item);
                        navigateToSearchResult(item);
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Button {
                    icon.name: "view-refresh"
                    flat: true
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

            // User profile card or carousel
            Components.UserProfileCard {
                Layout.fillWidth: true
                Layout.bottomMargin: root.inDetailContext ? 8 : 0
                userData: dataManager.userData
                repositoryCount: dataManager.totalRepos
                totalStars: dataManager.totalStars
                showUserAvatars: root.showUserAvatars
                visible: root.showProfileCard && !root.useProfileCarousel
            }

            Components.ProfileCarousel {
                Layout.fillWidth: true
                Layout.bottomMargin: root.inDetailContext ? 8 : 0
                userData: dataManager.userData
                repositoryCount: dataManager.totalRepos
                totalStars: dataManager.totalStars
                showUserAvatars: root.showUserAvatars
                commitData: dataManager.commitActivityData
                commitGraphColor: root.commitGraphColor
                dataManagerInstance: dataManager
                visible: root.showProfileCard && root.useProfileCarousel
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

                    // Lazy load data for the newly selected tab
                    if (currentIndex >= 0 && currentIndex < root.visibleTabs.length && root.visibleTabs[currentIndex]) {
                        var tabData = root.visibleTabs[currentIndex];
                        var tabId = tabData && tabData.id ? tabData.id : "";

                        if (tabId && root.inRepositoryContext && root.currentRepository) {
                            // Repository context - load specific repo tab data
                            if (tabId === "repo-readme") {
                                dataManager.ensureRepoTabDataLoaded(root.currentRepository.full_name, "readme");
                            } else if (tabId === "repo-issues") {
                                dataManager.ensureRepoTabDataLoaded(root.currentRepository.full_name, "issues");
                            } else if (tabId === "repo-prs") {
                                dataManager.ensureRepoTabDataLoaded(root.currentRepository.full_name, "prs");
                            }
                        } else if (tabId) {
                            // Global context - load global tab data
                            if (tabId === "repos") {
                                dataManager.ensureTabDataLoaded("repos");
                            } else if (tabId === "issues") {
                                dataManager.ensureTabDataLoaded("issues");
                            } else if (tabId === "prs") {
                                dataManager.ensureTabDataLoaded("prs");
                            } else if (tabId === "orgs") {
                                dataManager.ensureTabDataLoaded("orgs");
                            } else if (tabId === "starred") {
                                dataManager.ensureTabDataLoaded("starred");
                            }
                        }
                    }

                    root.triggerWidthRecalculation(); // This also triggers height recalculation
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
                    repositoryInfo: root.currentRepository
                    showUserAvatars: root.showUserAvatars
                    showIssueAvatars: root.showIssueAvatars
                    showPRAvatars: root.showPRAvatars
                    dataManagerInstance: dataManager
                    defaultCommentViewMode: {
                        switch (root.defaultCommentViewMode) {
                        case 0:
                            return "raw";
                        case 1:
                            return "markdown";
                        default:
                            return "markdown";
                        }
                    }
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

                            // README view for repo-readme tab
                            Components.ReadmeView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readmeData: dataManager.repositoryReadmeData
                                repositoryInfo: root.currentRepository
                                visible: tabId === "repo-readme"
                                defaultViewMode: {
                                    switch (root.defaultReadmeViewMode) {
                                    case 0:
                                        return "raw";
                                    case 1:
                                        return "markdown";
                                    case 2:
                                        return "rich";
                                    default:
                                        return "rich";
                                    }
                                }
                            }

                            // README view for profile-readme tab
                            Components.ReadmeView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readmeData: dataManager.profileReadmeData
                                repositoryInfo: {
                                    return {
                                        full_name: root.githubUsername + "/" + root.githubUsername,
                                        name: root.githubUsername,
                                        owner: {
                                            login: root.githubUsername
                                        }
                                    };
                                }
                                visible: tabId === "profile-readme"
                                defaultViewMode: {
                                    switch (root.defaultReadmeViewMode) {
                                    case 0:
                                        return "raw";
                                    case 1:
                                        return "markdown";
                                    case 2:
                                        return "rich";
                                    default:
                                        return "rich";
                                    }
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: tabId !== "repo-readme" && tabId !== "profile-readme"

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
                                    id: listView
                                    boundsBehavior: Flickable.StopAtBounds
                                    spacing: 3
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
                                        showUserAvatars: root.showUserAvatars
                                        showOrgAvatars: root.showOrgAvatars
                                        showRepoAvatars: root.showRepoAvatars
                                        showIssueAvatars: root.showIssueAvatars
                                        showPRAvatars: root.showPRAvatars
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
                                        width: parent ? parent.width : 400
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
                                visible: tabId !== "repo-readme" && tabId !== "profile-readme"
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
        root.triggerWidthRecalculation();
    }
    onShowIssuesTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
        root.triggerWidthRecalculation();
    }
    onShowPullRequestsTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
        root.triggerWidthRecalculation();
    }
    onShowOrganizationsTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
        root.triggerWidthRecalculation();
    }
    onShowStarredTabChanged: {
        root.visibleTabs = buildVisibleTabsList();
        root.triggerWidthRecalculation();
    }
}
