import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import "components" as Components

PlasmoidItem {
    id: root

    readonly property string githubToken: plasmoid.configuration.githubToken || ""
    readonly property string githubUsername: plasmoid.configuration.githubUsername || ""
    readonly property int refreshInterval: (plasmoid.configuration.refreshInterval || 5) * 60000
    readonly property bool showRepositoriesTab: plasmoid.configuration.showRepositoriesTab !== undefined ? plasmoid.configuration.showRepositoriesTab : true
    readonly property bool showIssuesTab: plasmoid.configuration.showIssuesTab !== undefined ? plasmoid.configuration.showIssuesTab : true
    readonly property bool showPullRequestsTab: plasmoid.configuration.showPullRequestsTab !== undefined ? plasmoid.configuration.showPullRequestsTab : true
    readonly property bool showOrganizationsTab: plasmoid.configuration.showOrganizationsTab !== undefined ? plasmoid.configuration.showOrganizationsTab : true
    readonly property bool showStarredTab: plasmoid.configuration.showStarredTab !== undefined ? plasmoid.configuration.showStarredTab : true

    property var userData: null
    property var repositoriesData: []
    property var issuesData: []
    property var pullRequestsData: []
    property var organizationsData: []
    property var starredRepositoriesData: []
    property bool isLoading: false
    property string errorMessage: ""
    property int totalStars: 0
    property bool totalStarsCached: false

    // Cache metadata with timestamps
    property var userDataCache: ({ data: null, timestamp: 0, ttl: 30 * 60 * 1000 }) // 30 minutes
    property var totalStarsCache: ({ count: 0, timestamp: 0, ttl: 2 * 60 * 60 * 1000 }) // 2 hours
    property var organizationsCache: ({ data: [], timestamp: 0, ttl: 2 * 60 * 60 * 1000 }) // 2 hours
    property bool calculatingStars: false

    // Dynamic tab management
    property var visibleTabs: buildVisibleTabsList()

    function buildVisibleTabsList() {
        var tabs = [];
        if (root.showRepositoriesTab) tabs.push({id: "repos", name: "Repos", data: root.repositoriesData});
        if (root.showIssuesTab) tabs.push({id: "issues", name: "Issues", data: root.issuesData});
        if (root.showPullRequestsTab) tabs.push({id: "prs", name: "PRs", data: root.pullRequestsData});
        if (root.showOrganizationsTab) tabs.push({id: "orgs", name: "Orgs", data: root.organizationsData});
        if (root.showStarredTab) tabs.push({id: "starred", name: "Starred", data: root.starredRepositoriesData});
        return tabs;
    }

    // Separate pagination properties for each tab
    property int currentRepoPage: 1
    property int currentIssuePage: 1
    property int currentPRPage: 1
    property int currentOrgPage: 1
    property int currentStarredPage: 1
    property int itemsPerPage: 5
    property bool hasMoreRepos: true
    property bool hasMoreIssues: true
    property bool hasMorePRs: true
    property bool hasMoreOrgs: true
    property bool hasMoreStarred: true
    property int totalRepos: 0
    property int totalIssues: 0
    property int totalPRs: 0
    property int totalOrgs: 0
    property int totalStarredRepos: 0

    preferredRepresentation: compactRepresentation

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
            source: root.isLoading ? "" : Qt.resolvedUrl("../assets/icons/icons8-github.svg")
            fillMode: Image.PreserveAspectFit
            smooth: true

            Kirigami.Icon {
                anchors.fill: parent
                source: "view-refresh"
                visible: root.isLoading

                RotationAnimation on rotation {
                    running: root.isLoading
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }

    }

    fullRepresentation: Item {
        id: fullRepresentation

        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: optimalHeight
        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
        Layout.preferredHeight: optimalHeight

        property int optimalHeight: {
            var currentItems = 0;
            if (tabBar && tabBar.currentIndex !== undefined) {
                // Map visible tab index to actual data
                var visibleTabIndex = 0;
                var actualTabIndex = 0;

                if (root.showRepositoriesTab && actualTabIndex++ == tabBar.currentIndex) {
                    currentItems = Math.min(root.repositoriesData.length, root.itemsPerPage);
                } else if (root.showIssuesTab && actualTabIndex++ == tabBar.currentIndex) {
                    currentItems = Math.min(root.issuesData.length, root.itemsPerPage);
                } else if (root.showPullRequestsTab && actualTabIndex++ == tabBar.currentIndex) {
                    currentItems = Math.min(root.pullRequestsData.length, root.itemsPerPage);
                } else if (root.showOrganizationsTab && actualTabIndex++ == tabBar.currentIndex) {
                    currentItems = Math.min(root.organizationsData.length, root.itemsPerPage);
                } else if (root.showStarredTab && actualTabIndex++ == tabBar.currentIndex) {
                    currentItems = Math.min(root.starredRepositoriesData.length, root.itemsPerPage);
                } else {
                    currentItems = root.itemsPerPage;
                }
            } else {
                currentItems = root.itemsPerPage;
            }

            var headerHeight = 40;          // Title + refresh button
            var profileCardHeight = 84;     // User profile card
            var tabBarHeight = 32;          // Tab bar
            var itemHeight = 60;            // Per list item
            var itemSpacing = 2;            // Between items
            var paginationHeight = 32;      // Pagination controls
            var margins = 20;               // Various margins/spacing

            var contentHeight = (currentItems * itemHeight) + ((currentItems - 1) * itemSpacing) + paginationHeight;
            var totalHeight = headerHeight + profileCardHeight + tabBarHeight + contentHeight + margins;

            return Math.max(totalHeight, Kirigami.Units.gridUnit * 15); // Minimum fallback
        }

        Component.onCompleted: {
            if ((root.githubToken !== "" || getEffectiveToken() !== "") && root.githubUsername !== "") {
                if (!root.userData) {
                    root.refreshData();
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
                    onClicked: root.refreshData(true) // Force refresh all data including cached items
                    enabled: !root.isLoading
                }
            }

            // User profile card
            Components.UserProfileCard {
                Layout.fillWidth: true
                userData: root.userData
                repositoryCount: root.totalRepos
                totalStars: root.totalStars
            }

            // Tab bar
            PlasmaComponents3.TabBar {
                id: tabBar
                Layout.fillWidth: true

                Repeater {
                    model: root.visibleTabs
                    PlasmaComponents3.TabButton {
                        text: getTabDisplayText(modelData.id)
                    }
                }
            }

            // Content area
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // Repositories tab
                ColumnLayout {
                    visible: root.showRepositoriesTab
                    spacing: Kirigami.Units.smallSpacing

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: root.repositoriesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: reposList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(root.repositoriesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: root.repositoriesData[index]
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
                        currentPage: root.currentRepoPage
                        hasMore: root.hasMoreRepos
                        totalItems: root.totalRepos > 0 ? root.totalRepos : root.repositoriesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            root.currentRepoPage = page;
                            root.fetchRepositories(page);
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
                        ScrollBar.vertical.policy: root.issuesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: issuesList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(root.issuesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: root.issuesData[index]
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
                        currentPage: root.currentIssuePage
                        hasMore: root.hasMoreIssues
                        totalItems: root.totalIssues > 0 ? root.totalIssues : root.issuesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            root.currentIssuePage = page;
                            root.fetchIssues(page);
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
                        ScrollBar.vertical.policy: root.pullRequestsData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: prsList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(root.pullRequestsData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: root.pullRequestsData[index]
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
                        currentPage: root.currentPRPage
                        hasMore: root.hasMorePRs
                        totalItems: root.totalPRs > 0 ? root.totalPRs : root.pullRequestsData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            root.currentPRPage = page;
                            root.fetchPullRequests(page);
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
                        ScrollBar.vertical.policy: root.organizationsData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: orgsList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(root.organizationsData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: root.organizationsData[index]
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
                        currentPage: root.currentOrgPage
                        hasMore: root.hasMoreOrgs
                        totalItems: root.totalOrgs > 0 ? root.totalOrgs : root.organizationsData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            root.currentOrgPage = page;
                            root.fetchOrganizations(page);
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
                        ScrollBar.vertical.policy: root.starredRepositoriesData.length === 0 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        ListView {
                            id: starredList
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 2
                            model: Math.min(root.starredRepositoriesData.length, root.itemsPerPage)

                            delegate: Components.UnifiedListItem {
                                itemData: root.starredRepositoriesData[index]
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
                        currentPage: root.currentStarredPage
                        hasMore: root.hasMoreStarred
                        totalItems: root.totalStarredRepos > 0 ? root.totalStarredRepos : root.starredRepositoriesData.length
                        itemsPerPage: root.itemsPerPage
                        onGoToPage: function (page) {
                            root.currentStarredPage = page;
                            root.fetchStarredRepositories(page);
                        }
                    }
                }
            }

            // Error message
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.errorMessage
                color: "red"
                visible: root.errorMessage !== ""
                wrapMode: Text.WordWrap
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshInterval
        running: (root.githubToken !== "" || getEffectiveToken() !== "") && root.githubUsername !== ""
        repeat: true
        onTriggered: root.refreshData()
    }

    function getEffectiveToken() {
        return root.githubToken;
    }

    function isCacheValid(cache) {
        return cache.timestamp > 0 && (Date.now() - cache.timestamp) < cache.ttl;
    }

    function updateCache(cache, data) {
        cache.data = data;
        cache.timestamp = Date.now();
        return cache;
    }

    function buildVisibleTabs() {
        var tabs = [];
        var mapping = {};
        var visibleIndex = 0;

        if (root.showRepositoriesTab) {
            tabs.push("repositories");
            mapping["repositories"] = visibleIndex++;
        }
        if (root.showIssuesTab) {
            tabs.push("issues");
            mapping["issues"] = visibleIndex++;
        }
        if (root.showPullRequestsTab) {
            tabs.push("pullRequests");
            mapping["pullRequests"] = visibleIndex++;
        }
        if (root.showOrganizationsTab) {
            tabs.push("organizations");
            mapping["organizations"] = visibleIndex++;
        }
        if (root.showStarredTab) {
            tabs.push("starred");
            mapping["starred"] = visibleIndex++;
        }

        root.visibleTabs = tabs;
        root.tabIndexMapping = mapping;
    }

    function getDataForVisibleTab(visibleIndex) {
        if (visibleIndex >= 0 && visibleIndex < root.visibleTabs.length) {
            var tabType = root.visibleTabs[visibleIndex];
            switch(tabType) {
                case "repositories": return root.repositoriesData;
                case "issues": return root.issuesData;
                case "pullRequests": return root.pullRequestsData;
                case "organizations": return root.organizationsData;
                case "starred": return root.starredRepositoriesData;
                default: return [];
            }
        }
        return [];
    }

    function getTabDisplayText(tabId) {
        switch(tabId) {
            case "repos": return "Repos (" + Math.min(root.repositoriesData.length, root.itemsPerPage) + ")";
            case "issues": return "Issues (" + Math.min(root.issuesData.length, root.itemsPerPage) + ")";
            case "prs": return "PRs (" + Math.min(root.pullRequestsData.length, root.itemsPerPage) + ")";
            case "orgs": return "Orgs (" + Math.min(root.organizationsData.length, root.itemsPerPage) + ")";
            case "starred": return "Starred (" + Math.min(root.starredRepositoriesData.length, root.itemsPerPage) + ")";
            default: return "Tab";
        }
    }

    function getItemType(tabType) {
        switch(tabType) {
            case "repositories": return "repo";
            case "issues": return "issue";
            case "pullRequests": return "pr";
            case "organizations": return "org";
            case "starred": return "repo";
            default: return "repo";
        }
    }

    function getCurrentPage(tabType) {
        switch(tabType) {
            case "repositories": return root.currentRepoPage;
            case "issues": return root.currentIssuePage;
            case "pullRequests": return root.currentPRPage;
            case "organizations": return root.currentOrgPage;
            case "starred": return root.currentStarredPage;
            default: return 1;
        }
    }

    function getHasMore(tabType) {
        switch(tabType) {
            case "repositories": return root.hasMoreRepos;
            case "issues": return root.hasMoreIssues;
            case "pullRequests": return root.hasMorePRs;
            case "organizations": return root.hasMoreOrgs;
            case "starred": return root.hasMoreStarred;
            default: return false;
        }
    }

    function getTotalItems(tabType) {
        switch(tabType) {
            case "repositories": return root.totalRepos > 0 ? root.totalRepos : root.repositoriesData.length;
            case "issues": return root.totalIssues > 0 ? root.totalIssues : root.issuesData.length;
            case "pullRequests": return root.totalPRs > 0 ? root.totalPRs : root.pullRequestsData.length;
            case "organizations": return root.totalOrgs > 0 ? root.totalOrgs : root.organizationsData.length;
            case "starred": return root.totalStarredRepos > 0 ? root.totalStarredRepos : root.starredRepositoriesData.length;
            default: return 0;
        }
    }

    function setCurrentPage(tabType, page) {
        switch(tabType) {
            case "repositories": root.currentRepoPage = page; break;
            case "issues": root.currentIssuePage = page; break;
            case "pullRequests": root.currentPRPage = page; break;
            case "organizations": root.currentOrgPage = page; break;
            case "starred": root.currentStarredPage = page; break;
        }
    }

    function fetchDataForTab(tabType, page) {
        switch(tabType) {
            case "repositories": root.fetchRepositories(page); break;
            case "issues": root.fetchIssues(page); break;
            case "pullRequests": root.fetchPullRequests(page); break;
            case "organizations": root.fetchOrganizations(page); break;
            case "starred": root.fetchStarredRepositories(page); break;
        }
    }

    // New helper functions for dynamic tab system
    function getDataForTab(tabId) {
        switch(tabId) {
            case "repos": return root.repositoriesData;
            case "issues": return root.issuesData;
            case "prs": return root.pullRequestsData;
            case "orgs": return root.organizationsData;
            case "starred": return root.starredRepositoriesData;
            default: return [];
        }
    }

    function getItemTypeForTab(tabId) {
        switch(tabId) {
            case "repos": return "repo";
            case "issues": return "issue";
            case "prs": return "pr";
            case "orgs": return "org";
            case "starred": return "repo";
            default: return "repo";
        }
    }

    function getCurrentPageForTab(tabId) {
        switch(tabId) {
            case "repos": return root.currentRepoPage;
            case "issues": return root.currentIssuePage;
            case "prs": return root.currentPRPage;
            case "orgs": return root.currentOrgPage;
            case "starred": return root.currentStarredPage;
            default: return 1;
        }
    }

    function getHasMoreForTab(tabId) {
        switch(tabId) {
            case "repos": return root.hasMoreRepos;
            case "issues": return root.hasMoreIssues;
            case "prs": return root.hasMorePRs;
            case "orgs": return root.hasMoreOrgs;
            case "starred": return root.hasMoreStarred;
            default: return false;
        }
    }

    function getTotalItemsForTab(tabId) {
        var result;
        switch(tabId) {
            case "repos": result = root.totalRepos > 0 ? root.totalRepos : root.repositoriesData.length; break;
            case "issues": result = root.totalIssues > 0 ? root.totalIssues : root.issuesData.length; break;
            case "prs": result = root.totalPRs > 0 ? root.totalPRs : root.pullRequestsData.length; break;
            case "orgs": result = root.totalOrgs > 0 ? root.totalOrgs : root.organizationsData.length; break;
            case "starred":
                result = root.totalStarredRepos > 0 ? root.totalStarredRepos : root.starredRepositoriesData.length;
                break;
            default: result = 0; break;
        }
        return result;
    }

    function setCurrentPageForTab(tabId, page) {
        switch(tabId) {
            case "repos": root.currentRepoPage = page; break;
            case "issues": root.currentIssuePage = page; break;
            case "prs": root.currentPRPage = page; break;
            case "orgs": root.currentOrgPage = page; break;
            case "starred": root.currentStarredPage = page; break;
        }
    }

    function fetchDataForTabById(tabId, page) {
        switch(tabId) {
            case "repos": root.fetchRepositories(page); break;
            case "issues": root.fetchIssues(page); break;
            case "prs": root.fetchPullRequests(page); break;
            case "orgs": root.fetchOrganizations(page); break;
            case "starred": root.fetchStarredRepositories(page); break;
        }
    }

    function refreshData(forceRefresh = false) {
        var effectiveToken = getEffectiveToken();

        if (effectiveToken === "" || root.githubUsername === "") {
            root.errorMessage = "Please configure GitHub token and username in settings";
            return;
        }

        root.isLoading = true;
        root.errorMessage = "";

        // If force refresh, invalidate all caches
        if (forceRefresh) {
            root.userDataCache.timestamp = 0;
            root.totalStarsCache.timestamp = 0;
            root.organizationsCache.timestamp = 0;
        }

        // Check if user data is cached and valid (unless force refresh)
        if (!forceRefresh && isCacheValid(root.userDataCache)) {
            root.userData = root.userDataCache.data;
            root.totalRepos = root.userData.public_repos || 0;
            root.fetchRepositories(1);
            return;
        }

        // Fetch user data
        var userRequest = new XMLHttpRequest();
        var userUrl = "https://api.github.com/users/" + root.githubUsername;
        userRequest.open("GET", userUrl);
        userRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        userRequest.setRequestHeader("Accept", "application/vnd.github+json");
        userRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        userRequest.onreadystatechange = function () {
            if (userRequest.readyState === XMLHttpRequest.DONE) {
                if (userRequest.status === 200) {
                    root.userData = JSON.parse(userRequest.responseText);
                    root.totalRepos = root.userData.public_repos || 0;

                    // Cache the user data
                    updateCache(root.userDataCache, root.userData);

                    // Calculate total stars only on fresh user data fetch
                    root.calculateTotalStars();
                    root.fetchRepositories(1);
                } else {
                    if (userRequest.status === 401) {
                        root.errorMessage = "Invalid GitHub token. Please check your token in settings.";
                    } else {
                        root.errorMessage = "Failed to fetch user data: " + userRequest.status + " - " + userRequest.responseText;
                    }
                    root.isLoading = false;
                }
            }
        };

        userRequest.send();
    }

    function fetchRepositories(page = 1) {
        var effectiveToken = getEffectiveToken();
        var reposRequest = new XMLHttpRequest();
        var reposUrl = "https://api.github.com/users/" + root.githubUsername + "/repos?sort=updated&per_page=" + root.itemsPerPage + "&page=" + page + "&type=all";
        reposRequest.open("GET", reposUrl);
        reposRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        reposRequest.setRequestHeader("Accept", "application/vnd.github+json");
        reposRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        reposRequest.onreadystatechange = function () {
            if (reposRequest.readyState === XMLHttpRequest.DONE) {
                if (reposRequest.status === 200) {
                    var repos = JSON.parse(reposRequest.responseText);

                    root.repositoriesData = repos;
                    root.hasMoreRepos = repos.length === root.itemsPerPage;
                    root.currentRepoPage = page;

                    // Only calculate total stars and fetch other data on page 1
                    if (page === 1) {
                        root.fetchIssues(1);
                    }
                } else {
                    root.errorMessage = "Failed to fetch repositories: " + reposRequest.status + " - " + reposRequest.responseText;
                }
            }
        };

        reposRequest.send();
    }

    function calculateTotalStars() {
        // Prevent concurrent calculations
        if (root.calculatingStars) {
            return;
        }

        // Check time-based cache first
        if (isCacheValid(root.totalStarsCache)) {
            root.totalStars = root.totalStarsCache.count;
            return;
        }

        root.calculatingStars = true;
        testBothStarredEndpoints();

        root.totalStars = 0;
        calculateTotalStarsRecursive(1);
    }

    function testBothStarredEndpoints() {
        var effectiveToken = getEffectiveToken();

        // Test authenticated endpoint
        var authRequest = new XMLHttpRequest();
        authRequest.open("GET", "https://api.github.com/user/starred?per_page=5");
        authRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        authRequest.setRequestHeader("Accept", "application/vnd.github+json");
        authRequest.onreadystatechange = function() {
            if (authRequest.readyState === XMLHttpRequest.DONE) {
                if (authRequest.status === 200) {
                    var authData = JSON.parse(authRequest.responseText);
                }
            }
        };
        authRequest.send();

        // Test public endpoint
        var publicRequest = new XMLHttpRequest();
        publicRequest.open("GET", "https://api.github.com/users/" + root.githubUsername + "/starred?per_page=5");
        publicRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        publicRequest.setRequestHeader("Accept", "application/vnd.github+json");
        publicRequest.onreadystatechange = function() {
            if (publicRequest.readyState === XMLHttpRequest.DONE) {
                if (publicRequest.status === 200) {
                    var publicData = JSON.parse(publicRequest.responseText);
                }
            }
        };
        publicRequest.send();

        // Test token scopes
        var scopeRequest = new XMLHttpRequest();
        scopeRequest.open("GET", "https://api.github.com/user");
        scopeRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        scopeRequest.setRequestHeader("Accept", "application/vnd.github+json");
        scopeRequest.onreadystatechange = function() {
            if (scopeRequest.readyState === XMLHttpRequest.DONE) {
            }
        };
        scopeRequest.send();
    }

    function calculateTotalStarsRecursive(page) {
        var effectiveToken = getEffectiveToken();
        var starsRequest = new XMLHttpRequest();
        var starsUrl = "https://api.github.com/users/" + root.githubUsername + "/starred?per_page=100&page=" + page;
        starsRequest.open("GET", starsUrl);
        starsRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        starsRequest.setRequestHeader("Accept", "application/vnd.github+json");
        starsRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        starsRequest.onreadystatechange = function () {
            if (starsRequest.readyState === XMLHttpRequest.DONE) {
                if (starsRequest.status === 200) {
                    var starredRepos = JSON.parse(starsRequest.responseText);
                    root.totalStars += starredRepos.length;

                    // Check response headers for API rate limiting info
                    var rateLimitRemaining = starsRequest.getResponseHeader('X-RateLimit-Remaining');
                    var rateLimitReset = starsRequest.getResponseHeader('X-RateLimit-Reset');

                    // If we got a full page (100 repos), there might be more pages
                    if (starredRepos.length === 100) {
                        calculateTotalStarsRecursive(page + 1);
                    } else {
                        // Cache the result for 2 hours
                        root.totalStarsCache.count = root.totalStars;
                        root.totalStarsCache.timestamp = Date.now();

                        // Update the totalStarredRepos for pagination
                        root.totalStarredRepos = root.totalStars;

                        // Reset the calculation flag
                        root.calculatingStars = false;
                    }
                } else {
                    // Reset flag on error
                    root.calculatingStars = false;
                }
            }
        };

        starsRequest.send();
    }

    function fetchIssues(page = 1) {
        var effectiveToken = getEffectiveToken();
        var issuesRequest = new XMLHttpRequest();
        var issuesUrl = "https://api.github.com/search/issues?q=involves:" + root.githubUsername + "+state:open+-is:pr&per_page=" + root.itemsPerPage + "&page=" + page + "&sort=updated";
        issuesRequest.open("GET", issuesUrl);
        issuesRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        issuesRequest.setRequestHeader("Accept", "application/vnd.github+json");
        issuesRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        issuesRequest.onreadystatechange = function () {
            if (issuesRequest.readyState === XMLHttpRequest.DONE) {
                if (issuesRequest.status === 200) {
                    var searchResults = JSON.parse(issuesRequest.responseText);
                    var issues = searchResults.items || [];
                    root.totalIssues = searchResults.total_count || 0;

                    root.issuesData = issues;
                    root.hasMoreIssues = issues.length === root.itemsPerPage;
                    root.currentIssuePage = page;

                    if (page === 1) {
                        root.fetchPullRequests(1);
                    }
                } else {
                    root.errorMessage = "Failed to fetch issues: " + issuesRequest.status + " - " + issuesRequest.responseText;
                }
            }
        };

        issuesRequest.send();
    }

    function fetchPullRequests(page = 1) {
        var effectiveToken = getEffectiveToken();
        var prsRequest = new XMLHttpRequest();
        var prsUrl = "https://api.github.com/search/issues?q=involves:" + root.githubUsername + "+state:open+is:pr&per_page=" + root.itemsPerPage + "&page=" + page + "&sort=updated";
        prsRequest.open("GET", prsUrl);
        prsRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        prsRequest.setRequestHeader("Accept", "application/vnd.github+json");
        prsRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        prsRequest.onreadystatechange = function () {
            if (prsRequest.readyState === XMLHttpRequest.DONE) {
                if (prsRequest.status === 200) {
                    var searchResults = JSON.parse(prsRequest.responseText);
                    var prs = searchResults.items || [];
                    root.totalPRs = searchResults.total_count || 0;

                    root.pullRequestsData = prs;
                    root.hasMorePRs = prs.length === root.itemsPerPage;
                    root.currentPRPage = page;

                    if (page === 1) {
                        root.fetchOrganizations(1);
                    }
                } else {
                    root.errorMessage = "Failed to fetch PRs: " + prsRequest.status + " - " + prsRequest.responseText;
                }
            }
        };

        prsRequest.send();
    }

    function fetchOrganizations(page = 1) {
        var effectiveToken = getEffectiveToken();
        var orgsRequest = new XMLHttpRequest();
        var orgsUrl = "https://api.github.com/users/" + root.githubUsername + "/orgs?per_page=" + root.itemsPerPage + "&page=" + page;
        orgsRequest.open("GET", orgsUrl);
        orgsRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        orgsRequest.setRequestHeader("Accept", "application/vnd.github+json");
        orgsRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        orgsRequest.onreadystatechange = function () {
            if (orgsRequest.readyState === XMLHttpRequest.DONE) {
                if (orgsRequest.status === 200) {
                    var orgs = JSON.parse(orgsRequest.responseText);

                    root.organizationsData = orgs;
                    root.hasMoreOrgs = orgs.length === root.itemsPerPage;
                    root.currentOrgPage = page;
                } else {
                    if (orgsRequest.status === 403) {
                        // Don't show error for 403 on orgs, just log it
                    } else {
                        root.errorMessage = "Failed to fetch organizations: " + orgsRequest.status + " - " + orgsRequest.responseText;
                    }
                }
                if (page === 1) {
                    root.fetchStarredRepositories(1);
                    root.isLoading = false;
                }
            }
        };

        orgsRequest.send();
    }

    function fetchStarredRepositories(page = 1) {
        var effectiveToken = getEffectiveToken();
        var starredRequest = new XMLHttpRequest();
        var starredUrl = "https://api.github.com/users/" + root.githubUsername + "/starred?per_page=" + root.itemsPerPage + "&page=" + page;
        starredRequest.open("GET", starredUrl);
        starredRequest.setRequestHeader("Authorization", "Bearer " + effectiveToken);
        starredRequest.setRequestHeader("Accept", "application/vnd.github+json");
        starredRequest.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        starredRequest.onreadystatechange = function () {
            if (starredRequest.readyState === XMLHttpRequest.DONE) {
                if (starredRequest.status === 200) {
                    var starred = JSON.parse(starredRequest.responseText);

                    root.starredRepositoriesData = starred;
                    // Use the total count to determine if there are more pages, not just current page size
                    var totalPages = Math.ceil(root.totalStarredRepos / root.itemsPerPage);

                    // If total count is not available yet (still calculating), use fallback logic
                    if (root.totalStarredRepos > 0) {
                        root.hasMoreStarred = page < totalPages;
                    } else {
                        // Fallback: if we got a full page, assume there are more pages
                        root.hasMoreStarred = starred.length === root.itemsPerPage;
                    }
                    root.currentStarredPage = page;
                    if (root.totalStarredRepos > 0) {
                    } else {
                    }

                    // For starred repos, we use the cached total count from calculateTotalStars
                    // But only set it on the first page to avoid overwriting
                    if (page === 1) {
                        // If we don't have a total yet, use the count from the profile
                        if (root.totalStars > 0) {
                            root.totalStarredRepos = root.totalStars;
                        } else {
                            // Fallback: if total count calculation is still running, use a reasonable estimate
                            // The pagination will update once the total count is available
                            root.totalStarredRepos = starred.length === root.itemsPerPage ? 1000 : starred.length;
                        }
                    }
                } else {
                    root.errorMessage = "Failed to fetch starred repositories: " + starredRequest.status + " - " + starredRequest.responseText;
                }
            }
        };

        starredRequest.send();
    }

    Component.onCompleted: {
        if ((root.githubToken !== "" || getEffectiveToken() !== "") && root.githubUsername !== "") {
            root.refreshData();
        }
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
