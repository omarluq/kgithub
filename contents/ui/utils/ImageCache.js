.pragma library

// Global image cache manager
var ImageCache = {
    // Cache settings
    maxCacheSize: 50, // Maximum number of cached images
    cacheTimeout: 30 * 60 * 1000, // 30 minutes in milliseconds

    // Cache storage
    cache: {},
    cacheOrder: [], // Track insertion order for LRU eviction

    // Get cache key for an image URL
    getCacheKey: function(url) {
        return url;
    },

    // Check if image is cached and still valid
    isCached: function(url) {
        var key = this.getCacheKey(url);
        var entry = this.cache[key];

        if (!entry) {
            return false;
        }

        // Check if cache entry is still valid (not expired)
        var now = Date.now();
        if (now - entry.timestamp > this.cacheTimeout) {
            this.removeFromCache(key);
            return false;
        }

        return true;
    },

    // Add image to cache
    addToCache: function(url) {
        var key = this.getCacheKey(url);
        var now = Date.now();

        // If already cached, update timestamp and move to end
        if (this.cache[key]) {
            this.cache[key].timestamp = now;
            this.moveToEnd(key);
            return;
        }

        // Check cache size limit
        if (this.cacheOrder.length >= this.maxCacheSize) {
            // Remove oldest entry (LRU eviction)
            var oldestKey = this.cacheOrder.shift();
            delete this.cache[oldestKey];
        }

        // Add new entry
        this.cache[key] = {
            url: url,
            timestamp: now
        };
        this.cacheOrder.push(key);
    },

    // Remove image from cache
    removeFromCache: function(key) {
        if (this.cache[key]) {
            delete this.cache[key];
            var index = this.cacheOrder.indexOf(key);
            if (index > -1) {
                this.cacheOrder.splice(index, 1);
            }
        }
    },

    // Move cache entry to end (most recently used)
    moveToEnd: function(key) {
        var index = this.cacheOrder.indexOf(key);
        if (index > -1) {
            this.cacheOrder.splice(index, 1);
            this.cacheOrder.push(key);
        }
    },

    // Clear entire cache
    clearCache: function() {
        this.cache = {};
        this.cacheOrder = [];
    },

    // Get cache statistics
    getCacheStats: function() {
        return {
            size: this.cacheOrder.length,
            maxSize: this.maxCacheSize,
            entries: Object.keys(this.cache).length
        };
    },

    // Clean expired entries
    cleanExpired: function() {
        var now = Date.now();
        var expiredKeys = [];

        for (var key in this.cache) {
            if (now - this.cache[key].timestamp > this.cacheTimeout) {
                expiredKeys.push(key);
            }
        }

        for (var i = 0; i < expiredKeys.length; i++) {
            this.removeFromCache(expiredKeys[i]);
        }
    }
};
