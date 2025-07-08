import "../../github" as GitHub
import QtQuick

Item {
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
    property var commitActivityData: null
    property var profileReadmeData: null
    // Repository-specific data
    property var repositoryIssuesData: []
    property var repositoryPRsData: []
    property var repositoryReadmeData: null
    // Detailed view data
    property var currentIssueDetail: null
    property var currentPRDetail: null
    property var currentItemComments: []
    // Search data
    property var searchResults: []
    property bool isSearching: false
    property string currentSearchQuery: ""
    // State properties
    property bool isLoading: false
    property string errorMessage: ""
    property int totalStars: 0
    property bool calculatingStars: false
    // Track which tabs have been loaded
    property var loadedTabs: ({
    })
    property var loadedRepoTabs: ({
    })
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
    signal searchCompleted(var results)

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
        // If force refresh, invalidate all caches and loaded tabs
        if (forceRefresh) {
            userDataCache.timestamp = 0;
            totalStarsCache.timestamp = 0;
            organizationsCache.timestamp = 0;
            loadedTabs = {
            };
            loadedRepoTabs = {
            };
        }
        // Check if user data is cached and valid
        if (!forceRefresh && isCacheValid(userDataCache)) {
            userData = userDataCache.data;
            totalRepos = userData.public_repos || 0;
            widthRecalculationNeeded();
            isLoading = false;
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
            // Calculate total stars, fetch commit activity, and profile README
            calculateTotalStars();
            fetchCommitActivity();
            fetchProfileReadme();
            isLoading = false;
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
            loadedTabs["repos"] = true;
            widthRecalculationNeeded();
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
            loadedTabs["issues"] = true;
            widthRecalculationNeeded();
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
            loadedTabs["prs"] = true;
            widthRecalculationNeeded();
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
                loadedTabs["orgs"] = true;
                widthRecalculationNeeded();
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
            loadedTabs["starred"] = true;
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

    function fetchCommitActivity() {
        if (!githubUsername) {
            console.log("No GitHub username configured for commit activity");
            return ;
        }
        console.log("Fetching commit activity for:", githubUsername);
        githubClient.getUserCommitActivity(githubUsername, function(data, error) {
            if (error) {
                console.log("Failed to fetch commit activity:", error.message);
                errorMessage = "Failed to fetch commit activity: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            commitActivityData = data;
            console.log("Commit activity loaded:", data ? data.totalCommits + " commits" : "no data");
            widthRecalculationNeeded();
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

    // Lazy loading function - only fetch if not already loaded
    function ensureTabDataLoaded(tabType) {
        if (!loadedTabs[tabType])
            fetchDataForTab(tabType, 1);

    }

    // Check if tab data is loaded
    function isTabDataLoaded(tabType) {
        return loadedTabs[tabType] === true;
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
            loadedRepoTabs[repoFullName + "-issues"] = true;
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
            loadedRepoTabs[repoFullName + "-prs"] = true;
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

    function fetchRepositoryReadme(repoFullName) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        console.log("Fetching README for:", repoFullName);
        githubClient.getRepositoryReadme(owner, repo, function(data, error) {
            if (error) {
                console.log("README fetch error:", error.message);
                // Don't show error for missing README - just set to null
                repositoryReadmeData = null;
            } else {
                console.log("README fetched successfully:", data.name || "README");
                repositoryReadmeData = data;
            }
            loadedRepoTabs[repoFullName + "-readme"] = true;
            dataUpdated();
            widthRecalculationNeeded(); // Trigger tab rebuilding
        });
    }

    // Repository tab lazy loading functions
    function ensureRepoTabDataLoaded(repoFullName, tabType) {
        var tabKey = repoFullName + "-" + tabType;
        if (!loadedRepoTabs[tabKey]) {
            switch (tabType) {
            case "readme":
                fetchRepositoryReadme(repoFullName);
                break;
            case "issues":
                fetchRepositoryIssues(repoFullName, 1);
                break;
            case "prs":
                fetchRepositoryPRs(repoFullName, 1);
                break;
            }
        }
    }

    function isRepoTabDataLoaded(repoFullName, tabType) {
        var tabKey = repoFullName + "-" + tabType;
        return loadedRepoTabs[tabKey] === true;
    }

    // Detailed data fetching
    function fetchIssueDetails(repoFullName, issueNumber) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        // Clear previous comments when fetching new issue
        currentItemComments = [];
        githubClient.getIssueDetails(owner, repo, issueNumber, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch issue details: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            currentIssueDetail = data;
            dataUpdated();
            // Only fetch first page of comments initially (lazy loading)
            fetchItemComments(repoFullName, issueNumber, false, 1);
        });
    }

    function fetchPullRequestDetails(repoFullName, prNumber) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        // Clear previous comments when fetching new PR
        currentItemComments = [];
        githubClient.getPullRequestDetails(owner, repo, prNumber, function(data, error) {
            if (error) {
                errorMessage = "Failed to fetch PR details: " + error.message;
                errorOccurred(errorMessage);
                return ;
            }
            currentPRDetail = data;
            dataUpdated();
            // Only fetch first page of comments initially (lazy loading)
            fetchItemComments(repoFullName, prNumber, true, 1);
        });
    }

    function fetchItemComments(repoFullName, itemNumber, isPR, page = 1) {
        var repoPath = repoFullName.split('/');
        var owner = repoPath[0];
        var repo = repoPath[1];
        var commentCallback = function commentCallback(data, error) {
            if (error) {
                errorMessage = "Failed to fetch comments: " + error.message;
                errorOccurred(errorMessage);
                // Comment fetch error logged
                return ;
            }
            // For paginated loading, append new comments to existing ones
            if (page === 1) {
                currentItemComments = data || [];
            } else {
                var existingComments = currentItemComments || [];
                currentItemComments = existingComments.concat(data || []);
            }
            dataUpdated();
        };
        if (isPR)
            githubClient.getPullRequestComments(owner, repo, itemNumber, commentCallback, page, 30);
        else
            githubClient.getIssueComments(owner, repo, itemNumber, commentCallback, page, 30);
    }

    // Function to load more comments for timeline pagination
    function loadMoreComments(repoFullName, itemNumber, isPR, nextPage) {
        fetchItemComments(repoFullName, itemNumber, isPR, nextPage);
    }

    function fetchProfileReadme() {
        if (!githubUsername) {
            console.log("No GitHub username configured for profile README");
            return ;
        }
        console.log("Fetching profile README for:", githubUsername);
        githubClient.getUserProfileReadme(githubUsername, function(data, error) {
            if (error) {
                console.log("Profile README not found or error:", error.message);
                // Don't show error for missing profile README - just set to null
                profileReadmeData = null;
            } else {
                console.log("Profile README fetched successfully:", data.name || "README");
                profileReadmeData = data;
            }
            dataUpdated();
        });
    }

    // Global search functionality
    function performGlobalSearch(query) {
        function onSearchComplete() {
            completedRequests++;
            if (completedRequests >= totalRequests) {
                // Sort all results by updated_at descending
                allResults.sort(function(a, b) {
                    var dateA = new Date(a.updated_at || a.created_at || 0);
                    var dateB = new Date(b.updated_at || b.created_at || 0);
                    return dateB.getTime() - dateA.getTime();
                });
                searchResults = allResults;
                isSearching = false;
                searchCompleted(allResults);
                dataUpdated();
            }
        }

        if (!query || query.length < 2) {
            searchResults = [];
            isSearching = false;
            currentSearchQuery = "";
            searchCompleted([]);
            return ;
        }
        if (!isConfigured()) {
            errorMessage = "Please configure GitHub token and username in settings";
            errorOccurred(errorMessage);
            return ;
        }
        isSearching = true;
        currentSearchQuery = query;
        var allResults = [];
        var completedRequests = 0;
        var totalRequests = 3; // repos, issues, PRs
        // Search repositories
        githubClient.searchRepositories(query, 1, 5, function(data, error) {
            if (!error && data && data.items) {
                for (var i = 0; i < data.items.length; i++) {
                    var repo = data.items[i];
                    repo.searchResultType = "repo";
                    allResults.push(repo);
                }
            }
            onSearchComplete();
        });
        // Search issues
        githubClient.globalSearchIssues(query, 1, 5, function(data, error) {
            if (!error && data && data.items) {
                for (var i = 0; i < data.items.length; i++) {
                    var issue = data.items[i];
                    issue.searchResultType = "issue";
                    allResults.push(issue);
                }
            }
            onSearchComplete();
        });
        // Search pull requests
        githubClient.globalSearchPullRequests(query, 1, 5, function(data, error) {
            if (!error && data && data.items) {
                for (var i = 0; i < data.items.length; i++) {
                    var pr = data.items[i];
                    pr.searchResultType = "pr";
                    allResults.push(pr);
                }
            }
            onSearchComplete();
        });
    }

    // Advanced search functionality with type-specific searching
    function performAdvancedSearch(searchType, query) {
        function onSearchComplete(data, error, resultType) {
            isSearching = false;
            if (!error && data && data.items) {
                for (var i = 0; i < data.items.length; i++) {
                    var item = data.items[i];
                    item.searchResultType = resultType;
                    results.push(item);
                }
                // Sort results by updated_at descending
                results.sort(function(a, b) {
                    var dateA = new Date(a.updated_at || a.created_at || 0);
                    var dateB = new Date(b.updated_at || b.created_at || 0);
                    return dateB.getTime() - dateA.getTime();
                });
            }
            searchResults = results;
            searchCompleted(results);
            dataUpdated();
        }

        if (!query || query.length < 2) {
            searchResults = [];
            isSearching = false;
            currentSearchQuery = "";
            searchCompleted([]);
            return ;
        }
        if (!isConfigured()) {
            errorMessage = "Please configure GitHub token and username in settings";
            errorOccurred(errorMessage);
            return ;
        }
        isSearching = true;
        currentSearchQuery = searchType + ":" + query;
        var results = [];
        // Perform type-specific search with higher limits since we're only searching one type
        switch (searchType) {
        case "repo":
            githubClient.searchRepositories(query, 1, 15, function(data, error) {
                onSearchComplete(data, error, "repo");
            });
            break;
        case "issue":
            githubClient.globalSearchIssues(query, 1, 15, function(data, error) {
                onSearchComplete(data, error, "issue");
            });
            break;
        case "pr":
            githubClient.globalSearchPullRequests(query, 1, 15, function(data, error) {
                onSearchComplete(data, error, "pr");
            });
            break;
        default:
            // Fallback to global search for unknown types
            performGlobalSearch(query);
            return ;
        }
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
