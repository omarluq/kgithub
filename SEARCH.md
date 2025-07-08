# KGitHub Search System Documentation

## Overview

The KGitHub plasmoid features a comprehensive search system that allows users to quickly find and navigate GitHub content including repositories, issues, and pull requests. The search system is built with both basic global search and advanced type-specific search capabilities.

## Architecture

### Components

1. **SearchComponent.qml** - The main search UI component
2. **DataManager.qml** - Handles search API calls and data management
3. **GitHub Client** - Makes actual API requests to GitHub
4. **Navigation System** - Integrates search results with widget navigation

### Search Flow

```
User Input → SearchComponent → DataManager → GitHub API → Results → Navigation
```

## Search Types

### 1. Global Search (Default)

When users type without prefixes, the system performs a comprehensive search across all content types.

**Example**: `javascript`

**Behavior**:
- Searches repositories, issues, and pull requests simultaneously
- Returns up to 5 results per type (15 total)
- Results are sorted by last updated date
- Displays mixed content types in unified results

**API Calls**:
```javascript
// Three parallel API calls
GET /search/repositories?q=javascript&per_page=5&sort=updated
GET /search/issues?q=javascript is:issue&per_page=5&sort=updated
GET /search/issues?q=javascript is:pr&per_page=5&sort=updated
```

### 2. Advanced Search (Type-Specific)

Users can target specific content types using prefixes.

#### Repository Search: `repo:`

**Examples**:
- `repo:react` → Searches for repositories with "react" in name/description
- `repo:rails/rails` → Searches for the specific Rails repository

**Query Processing**:
```javascript
// Input: "repo:react"
// Generated: "react in:name,description"

// Input: "repo:rails/rails"
// Generated: "repo:rails/rails"
```

**API Call**:
```javascript
GET /search/repositories?q={processed_query}&per_page=15&sort=updated
```

#### Issue Search: `issue:`

**Examples**:
- `issue:memory leak`
- `issue:authentication error`

**API Call**:
```javascript
GET /search/issues?q={query} is:issue&per_page=15&sort=updated
```

#### Pull Request Search: `pr:`

**Examples**:
- `pr:security patch`
- `pr:feature update`

**API Call**:
```javascript
GET /search/issues?q={query} is:pr&per_page=15&sort=updated
```

## Implementation Details

### Search Query Parsing

```javascript
function parseSearchQuery(query) {
    var trimmed = query.trim();
    var lowerTrimmed = trimmed.toLowerCase();

    if (lowerTrimmed.startsWith("repo:")) {
        var repoQuery = trimmed.substring(5).trim();
        if (repoQuery.includes("/")) {
            // Specific repo: "repo:owner/name"
            repoQuery = "repo:" + repoQuery;
        } else {
            // General search: "repo:keyword"
            repoQuery = repoQuery + " in:name,description";
        }
        return { type: "repo", query: repoQuery };
    }
    // ... similar for issue: and pr:
}
```

### Advanced Search Function

```javascript
function performAdvancedSearch(searchType, query) {
    // Single API call to specific endpoint
    switch (searchType) {
        case "repo":
            githubClient.searchRepositories(query, 1, 15, callback);
            break;
        case "issue":
            githubClient.globalSearchIssues(query, 1, 15, callback);
            break;
        case "pr":
            githubClient.globalSearchPullRequests(query, 1, 15, callback);
            break;
    }
}
```

### Result Processing

Each search result gets a `searchResultType` property:
- `"repo"` for repositories
- `"issue"` for issues
- `"pr"` for pull requests

Results are sorted by `updated_at` in descending order.

## User Interface

### Search Input
- **Trigger**: 3+ characters typed
- **Delay**: 500ms debounce timer
- **Visual Feedback**: Loading spinner during search

### Search Results Popup
- **Display**: Opens immediately when user starts typing
- **States**:
  - Hint text for 1-2 characters
  - Loading spinner during search
  - Results list with animations
- **Interactions**: Click to navigate, hamburger menu for actions

### Result Actions

Each search result provides:

1. **Click to Open** - Navigates within the widget
2. **Hamburger Menu**:
   - **Open** - Navigate to content in widget
   - **Copy URL** - Copy GitHub URL to clipboard
   - **Open in GitHub** - Launch external browser

## Navigation Integration

### Context Management

The search results integrate with the widget's navigation system:

```javascript
function navigateToSearchResult(item) {
    switch (item.searchResultType) {
        case "repo":
            root.enterRepositoryContext(item);
            break;
        case "issue":
        case "pr":
            // Extract repository info and set context
            root.currentRepository = extractedRepoInfo;
            root.inRepositoryContext = true;
            root.enterDetailContext(item);
            break;
    }
}
```

### Back Navigation

Users can navigate back through:
- **Back Button** - Returns to previous context
- **Breadcrumb Navigation** - Shows current location
- **Context Awareness** - Maintains navigation state

## Performance Optimizations

### Debouncing
- 500ms delay before triggering search
- Prevents excessive API calls during typing

### Caching
- Results cached in DataManager
- Prevents duplicate requests for same query

### Rate Limiting
- Respects GitHub API rate limits
- Intelligent request throttling

### Result Limits
- Global search: 5 results per type (15 total)
- Advanced search: 15 results (focused)

## Error Handling

### Configuration Validation
```javascript
if (!isConfigured()) {
    errorMessage = "Please configure GitHub token and username";
    errorOccurred(errorMessage);
    return;
}
```

### API Error Handling
- Individual search failures don't stop other searches
- Graceful degradation for network issues
- User feedback for configuration problems

### Query Validation
- Minimum 2 characters required
- Empty queries clear results
- Invalid prefixes fall back to global search

## GitHub API Compliance

### Endpoints Used
- `/search/repositories` - Repository search
- `/search/issues` - Issues and pull requests search

### Parameters
- `q` - Search query with GitHub syntax
- `per_page` - Results per page (5 or 15)
- `page` - Page number (always 1)
- `sort` - Sort by "updated"

### GitHub Search Syntax
- `repo:owner/name` - Specific repository
- `in:name,description` - Search in specific fields
- `is:issue` / `is:pr` - Content type filters

## Future Improvements

### Planned Features
1. **Search History** - Recent searches dropdown
2. **Saved Searches** - Bookmark frequent queries
3. **Advanced Filters** - Date ranges, languages, etc.
4. **Search Suggestions** - Auto-complete functionality
5. **Result Previews** - Rich content previews
6. **Keyboard Navigation** - Arrow key navigation

### Performance Enhancements
1. **Virtual Scrolling** - Handle large result sets
2. **Incremental Loading** - Load more results on scroll
3. **Background Refresh** - Update results periodically
4. **Smarter Caching** - LRU cache with expiration

### User Experience
1. **Search Scopes** - Limit to user's repos/orgs
2. **Result Grouping** - Group by repository/type
3. **Quick Actions** - One-click common operations
4. **Mobile-Friendly** - Touch-optimized interface

## Debugging

### Console Logging
Enable debug logging by uncommenting log statements in:
- `SearchComponent.performSearch()`
- `DataManager.performAdvancedSearch()`

### Testing Queries
```javascript
// Test basic search
"javascript"

// Test repository search
"repo:react"
"repo:facebook/react"

// Test issue search
"issue:memory leak"

// Test PR search
"pr:security"
```

### Common Issues
1. **No Results**: Check GitHub token configuration
2. **Slow Search**: Network connectivity or rate limiting
3. **Wrong Results**: GitHub's search algorithm ranking
4. **Navigation Issues**: Repository context extraction

---

*This document reflects the current v1.0 implementation. Features and behavior may evolve in future versions.*
