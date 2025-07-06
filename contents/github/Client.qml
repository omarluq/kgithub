import QtQuick 2.15

QtObject {
    id: client

    property string token: ""
    property string username: ""
    property string baseUrl: "https://api.github.com"
    property int rateLimitRemaining: -1
    property int rateLimitReset: -1

    // Error types
    readonly property int errorNone: 0
    readonly property int errorNetwork: 1
    readonly property int errorAuth: 2
    readonly property int errorRateLimit: 3
    readonly property int errorNotFound: 4
    readonly property int errorParse: 5
    readonly property int errorUnknown: 6

    signal rateLimitChanged(int remaining, int reset)
    signal errorOccurred(int errorType, string message)

    function makeRequest(url, callback, options = {}) {
        var retryCount = options.retryCount || 0;
        var maxRetries = options.maxRetries || 2;
        var timeout = options.timeout || 10000;
        var useAuth = options.useAuth !== false;

        var request = new XMLHttpRequest();
        request.timeout = timeout;
        request.open("GET", url);

        // Set headers
        if (useAuth && token !== "") {
            request.setRequestHeader("Authorization", "Bearer " + token);
        }
        request.setRequestHeader("Accept", "application/vnd.github+json");
        request.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");
        request.setRequestHeader("User-Agent", "KGitHub-Plasmoid/1.0.0");

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                handleResponse(request, callback, url, options, retryCount, maxRetries);
            }
        };

        request.ontimeout = function() {
            if (retryCount < maxRetries) {
                var delay = Math.pow(2, retryCount) * 1000; // Exponential backoff
                Qt.callLater(function() {
                        var newOptions = {};
                    for (var key in options) {
                        newOptions[key] = options[key];
                    }
                    newOptions.retryCount = retryCount + 1;
                    makeRequest(url, callback, newOptions);
                });
            } else {
                callback(null, createError(errorNetwork, "Request timeout after " + maxRetries + " retries"));
            }
        };

        request.send();
    }

    function handleResponse(request, callback, url, options, retryCount, maxRetries) {
        // Update rate limit info
        var remaining = request.getResponseHeader('X-RateLimit-Remaining');
        var reset = request.getResponseHeader('X-RateLimit-Reset');
        if (remaining !== null) {
            rateLimitRemaining = parseInt(remaining);
            rateLimitReset = parseInt(reset);
            rateLimitChanged(rateLimitRemaining, rateLimitReset);
        }

        if (request.status === 200) {
            try {
                var data = JSON.parse(request.responseText);
                callback(data, null);
            } catch (e) {
                var error = createError(errorParse, "Failed to parse response: " + e.message);
                callback(null, error);
                errorOccurred(error.type, error.message);
            }
        } else {
            var error = handleHttpError(request.status, request.responseText);

            // Retry for certain error types
            if (shouldRetry(request.status) && retryCount < maxRetries) {
                var delay = Math.pow(2, retryCount) * 1000;
                Qt.callLater(function() {
                        var newOptions = {};
                    for (var key in options) {
                        newOptions[key] = options[key];
                    }
                    newOptions.retryCount = retryCount + 1;
                    makeRequest(url, callback, newOptions);
                });
            } else {
                callback(null, error);
                errorOccurred(error.type, error.message);
            }
        }
    }

    function shouldRetry(status) {
        // Retry on server errors and rate limits (but not auth or not found)
        return status >= 500 || status === 429;
    }

    function handleHttpError(status, responseText) {
        switch (status) {
            case 401:
                return createError(errorAuth, "Invalid or expired GitHub token");
            case 403:
                var message = "Access forbidden";
                try {
                    var response = JSON.parse(responseText);
                    if (response.message && response.message.includes("rate limit")) {
                        message = "Rate limit exceeded. Try again later.";
                        return createError(errorRateLimit, message);
                    }
                } catch (e) {}
                return createError(errorAuth, message);
            case 404:
                return createError(errorNotFound, "Resource not found");
            case 422:
                return createError(errorUnknown, "Validation failed");
            case 429:
                return createError(errorRateLimit, "Rate limit exceeded");
            default:
                return createError(errorNetwork, "HTTP " + status + ": " + responseText);
        }
    }

    function createError(type, message) {
        return {
            type: type,
            message: message,
            timestamp: Date.now()
        };
    }

    // High-level API methods
    function getUser(username, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username);
        makeRequest(url, callback);
    }

    function getUserRepositories(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/repos";
        url += "?sort=updated&per_page=" + perPage + "&page=" + page + "&type=all";
        makeRequest(url, callback);
    }

    function searchIssues(query, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query);
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function searchPullRequests(query, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query + " is:pr");
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function getUserOrganizations(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/orgs";
        url += "?per_page=" + perPage + "&page=" + page;
        makeRequest(url, callback);
    }

    function getUserStarredRepositories(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/starred";
        url += "?per_page=" + perPage + "&page=" + page;
        makeRequest(url, callback);
    }

    function getUserStarredCount(username, callback) {
        var totalCount = 0;
        var currentPage = 1;

        function fetchPage() {
            getUserStarredRepositories(username, currentPage, 100, function(data, error) {
                if (error) {
                    callback(null, error);
                    return;
                }

                totalCount += data.length;

                if (data.length === 100) {
                    currentPage++;
                    fetchPage();
                } else {
                    callback(totalCount, null);
                }
            });
        }

        fetchPage();
    }

    // Validation helpers
    function isValidToken() {
        return token && token.length > 0;
    }

    function isValidUsername() {
        return username && username.length > 0;
    }

    function isConfigured() {
        return isValidToken() && isValidUsername();
    }

    // Rate limit helpers
    function getRateLimitStatus() {
        return {
            remaining: rateLimitRemaining,
            reset: rateLimitReset,
            resetDate: rateLimitReset > 0 ? new Date(rateLimitReset * 1000) : null
        };
    }

    function isRateLimited() {
        return rateLimitRemaining !== -1 && rateLimitRemaining <= 0;
    }
}
