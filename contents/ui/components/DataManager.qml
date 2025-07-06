import "../../github" as GitHub
import QtQuick 2.15

Item {
    // Estimate higher number for first page if full
    // Estimate higher number for first page if full

    id: dataManager

    // Configuration properties
    property string githubToken: ""
    property string githubUsername: ""
    property int itemsPerPage: 5
    // Data properties
    property var userData: null
    property var repositoriesData: []
    property var issuesData: []
    property var pullRequestsData: []
    property var organizationsData: []
    property var starredRepositoriesData: []
    // Repository-specific data
    property var repositoryIssuesData: []
    property var repositoryPRsData: []
    // Detailed view data
    property var currentIssueDetail: null
    property var currentPRDetail: null
    property var currentItemComments: []
    // State properties
    property bool isLoading: false
    property string errorMessage: ""
    property int totalStars: 0
    property bool calculatingStars: false
    // Pagination properties
    property int currentRepoPage: 1
    property int currentIssuePage: 1
    property int currentPRPage: 1
    property int currentOrgPage: 1
    property int currentStarredPage: 1
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
    // Repository-specific pagination
    property int currentRepoIssuesPage: 1
    property int currentRepoPRsPage: 1
    property bool hasMoreRepoIssues: true
    property bool hasMoreRepoPRs: true
    property int totalRepoIssues: 0
    property int totalRepoPRs: 0
    // Cache properties
    property var userDataCache: ({
        "data": null,
        "timestamp": 0,
        "ttl": 30 * 60 * 1000
    })
    property var totalStarsCache: ({
        "count": 0,
        "timestamp": 0,
        "ttl": 2 * 60 * 60 * 1000
    })
    property var organizationsCache: ({
        "data": [],
        "timestamp": 0,
        "ttl": 2 * 60 * 60 * 1000
    })
    // GitHub client
    property alias githubClient: client

    // Signals
    signal dataUpdated()
    signal errorOccurred(string message)
    signal widthRecalculationNeeded()

    // Utility functions
    function isCacheValid(cache) {
        return cache.timestamp > 0 && (Date.now() - cache.timestamp) < cache.ttl;
    }

    function updateCache(cache, data) {
        cache.data = data;
        cache.timestamp = Date.now();
        return cache;
    }

    function isConfigured() {
        return githubClient.isConfigured();
    }

    function clearError() {
        errorMessage = "";
    }

    // Main data refresh function
    function refreshData(forceRefresh = false) {
        if (!isConfigured()) {
            errorMessage = "Please configure GitHub token and username in settings";
            errorOccurred(errorMessage);
            return ;
        }
        isLoading = true;
        errorMessage = "";
        // If force refresh, invalidate all caches
        if (forceRefresh) {
            userDataCache.timestamp = 0;
            totalStarsCache.timestamp = 0;
            organizationsCache.timestamp = 0;
        }
        // Check if user data is cached and valid
        if (!forceRefresh && isCacheValid(userDataCache)) {
            userData = userDataCache.data;
            totalRepos = userData.public_repos || 0;
            widthRecalculationNeeded();
            fetchRepositories(1);
            return ;
        }
        // Fetch user data
        githubClient.getUser(githubUsername, function(data, error) {
            if (error) {
                errorMessage = error.message;
                isLoading = false;
                errorOccurred(errorMessage);
                return ;
            }
            userData = data;
            totalRepos = data.public_repos || 0;
            widthRecalculationNeeded();
            // Cache the user data
            updateCache(userDataCache, data);
            // Calculate total stars and fetch repositories
            calculateTotalStars();
            fetchRepositories(1);
        });
    }

    // Data fetching functions
    function fetchRepositories(page = 1) {
        githubClient.getUserRepositories(githubUsername, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch repositories: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            repositoriesData = data;
            hasMoreRepos = data.length === itemsPerPage;
            currentRepoPage = page;
            widthRecalculationNeeded();
            if (page === 1)
                fetchIssues(1);

            dataUpdated();
        });
    }

    function fetchIssues(page = 1) {
        var query = "involves:" + githubUsername + " state:open -is:pr";
        githubClient.searchIssues(query, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch issues: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            var issues = data.items || [];
            totalIssues = data.total_count || 0;
            issuesData = issues;
            hasMoreIssues = issues.length === itemsPerPage;
            currentIssuePage = page;
            widthRecalculationNeeded();
            if (page === 1)
                fetchPullRequests(1);

            dataUpdated();
        });
    }

    function fetchPullRequests(page = 1) {
        var query = "involves:" + githubUsername + " state:open is:pr";
        githubClient.searchPullRequests(query, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch pull requests: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            var prs = data.items || [];
            totalPRs = data.total_count || 0;
            pullRequestsData = prs;
            hasMorePRs = prs.length === itemsPerPage;
            currentPRPage = page;
            widthRecalculationNeeded();
            if (page === 1)
                fetchOrganizations(1);

            dataUpdated();
        });
    }

    function fetchOrganizations(page = 1) {
        githubClient.getUserOrganizations(githubUsername, page, itemsPerPage, function(data, error) {
            if (error) {
                if (error.type !== githubClient.errorAuth) {
                    errorMessage = "Failed to fetch organizations: " + error.message;
                    errorOccurred(errorMessage);
                }
            } else {
                organizationsData = data;
                hasMoreOrgs = data.length === itemsPerPage;
                currentOrgPage = page;
                widthRecalculationNeeded();
            }
            if (page === 1) {
                fetchStarredRepositories(1);
                isLoading = false;
            }
            dataUpdated();
        });
    }

    function fetchStarredRepositories(page = 1) {
        githubClient.getUserStarredRepositories(githubUsername, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch starred repositories: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            starredRepositoriesData = data;
            hasMoreStarred = data.length === itemsPerPage;
            currentStarredPage = page;
            widthRecalculationNeeded();
            // For starred repos, use cached total count
            if (page === 1) {
                if (totalStars > 0)
                    totalStarredRepos = totalStars;
                else
                    totalStarredRepos = data.length === itemsPerPage ? 1000 : data.length;
            }
            dataUpdated();
        });
    }

    function calculateTotalStars() {
        if (calculatingStars)
            return ;

        // Check cache first
        if (isCacheValid(totalStarsCache)) {
            totalStars = totalStarsCache.count;
            return ;
        }
        calculatingStars = true;
        githubClient.getUserStarredCount(githubUsername, function(count, error) {
            calculatingStars = false;
            if (error)
                return ;

            totalStars = count;
            totalStarredRepos = count;
            // Cache the result
            totalStarsCache.count = count;
            totalStarsCache.timestamp = Date.now();
            dataUpdated();
        });
    }

    // Specific fetch functions for individual tabs
    function fetchDataForTab(tabType, page) {
        switch (tabType) {
        case "repos":
            fetchRepositories(page);
            break;
        case "issues":
            fetchIssues(page);
            break;
        case "prs":
            fetchPullRequests(page);
            break;
        case "orgs":
            fetchOrganizations(page);
            break;
        case "starred":
            fetchStarredRepositories(page);
            break;
        }
    }

    // Getters for tab data
    function getDataForTab(tabType) {
        switch (tabType) {
        case "repos":
            return repositoriesData;
        case "issues":
            return issuesData;
        case "prs":
            return pullRequestsData;
        case "orgs":
            return organizationsData;
        case "starred":
            return starredRepositoriesData;
        default:
            return [];
        }
    }

    function getCurrentPageForTab(tabType) {
        switch (tabType) {
        case "repos":
            return currentRepoPage;
        case "issues":
            return currentIssuePage;
        case "prs":
            return currentPRPage;
        case "orgs":
            return currentOrgPage;
        case "starred":
            return currentStarredPage;
        default:
            return 1;
        }
    }

    function getHasMoreForTab(tabType) {
        switch (tabType) {
        case "repos":
            return hasMoreRepos;
        case "issues":
            return hasMoreIssues;
        case "prs":
            return hasMorePRs;
        case "orgs":
            return hasMoreOrgs;
        case "starred":
            return hasMoreStarred;
        default:
            return false;
        }
    }

    function getTotalItemsForTab(tabType) {
        switch (tabType) {
        case "repos":
            return totalRepos > 0 ? totalRepos : repositoriesData.length;
        case "issues":
            return totalIssues > 0 ? totalIssues : issuesData.length;
        case "prs":
            return totalPRs > 0 ? totalPRs : pullRequestsData.length;
        case "orgs":
            return totalOrgs > 0 ? totalOrgs : organizationsData.length;
        case "starred":
            return totalStarredRepos > 0 ? totalStarredRepos : starredRepositoriesData.length;
        default:
            return 0;
        }
    }

    // Repository-specific data fetching
    function fetchRepositoryIssues(repoFullName, page = 1) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        githubClient.getRepositoryIssues(owner, repo, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch repository issues: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            repositoryIssuesData = data;
            hasMoreRepoIssues = data.length === itemsPerPage;
            currentRepoIssuesPage = page;
            // Estimate total count based on pagination
            if (page === 1) {
                if (data.length < itemsPerPage)
                    totalRepoIssues = data.length;
                else
                    totalRepoIssues = Math.max(data.length * 5, 100);
            } else {
                // Update estimate based on current page
                totalRepoIssues = Math.max(totalRepoIssues, (page - 1) * itemsPerPage + data.length);
            }
            dataUpdated();
        });
    }

    function fetchRepositoryPRs(repoFullName, page = 1) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        githubClient.getRepositoryPullRequests(owner, repo, page, itemsPerPage, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch repository pull requests: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            repositoryPRsData = data;
            hasMoreRepoPRs = data.length === itemsPerPage;
            currentRepoPRsPage = page;
            // Estimate total count based on pagination
            if (page === 1) {
                if (data.length < itemsPerPage)
                    totalRepoPRs = data.length;
                else
                    totalRepoPRs = Math.max(data.length * 5, 100);
            } else {
                // Update estimate based on current page
                totalRepoPRs = Math.max(totalRepoPRs, (page - 1) * itemsPerPage + data.length);
            }
            dataUpdated();
        });
    }

    // Detailed data fetching
    function fetchIssueDetails(repoFullName, issueNumber) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        githubClient.getIssueDetails(owner, repo, issueNumber, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch issue details: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            currentIssueDetail = data;
            dataUpdated();
            // Also fetch comments
            fetchItemComments(repoFullName, issueNumber, false);
        });
    }

    function fetchPullRequestDetails(repoFullName, prNumber) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        githubClient.getPullRequestDetails(owner, repo, prNumber, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch PR details: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            currentPRDetail = data;
            dataUpdated();
            // Also fetch comments
            fetchItemComments(repoFullName, prNumber, true);
        });
    }

    function fetchItemComments(repoFullName, itemNumber, isPR) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        var commentCallback = function commentCallback(data, error) {
            if (error) {
                errorMessage = "Failed to fetch comments: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            currentItemComments = data;
            dataUpdated();
        };
        if (isPR)
            githubClient.getPullRequestComments(owner, repo, itemNumber, commentCallback);
        else
            githubClient.getIssueComments(owner, repo, itemNumber, commentCallback);
    }

    Component.onCompleted: {
    }

    GitHub.Client {
        // Rate limit information available if needed

        id: client

        token: dataManager.githubToken
        username: dataManager.githubUsername
        onRateLimitChanged: function(remaining, reset) {
        }
        onErrorOccurred: function(errorType, message) {
            dataManager.errorMessage = message;
            dataManager.errorOccurred(message);
        }
    }

}
