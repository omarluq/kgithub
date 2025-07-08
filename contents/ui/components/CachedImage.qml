import "../utils/ImageCache.js" as ImageCacheJS
import QtQuick

Image {
    id: cachedImage

    // Custom properties for cache management
    property string originalSource: ""
    property bool enableCustomCache: true

    // Enhanced caching properties
    cache: true
    asynchronous: true
    // Override source property to add caching logic
    onOriginalSourceChanged: {
        if (originalSource && enableCustomCache) {
            // Check if image is in our custom cache
            if (ImageCacheJS.ImageCache.isCached(originalSource)) {
                // Image is cached, set source directly
                source = originalSource;
                // Update cache timestamp (mark as recently used)
                ImageCacheJS.ImageCache.addToCache(originalSource);
            } else {
                // Image not cached, load and add to cache
                source = originalSource;
            }
        } else {
            // Use normal loading if caching disabled
            source = originalSource;
        }
    }
    // When image loads successfully, add to cache
    onStatusChanged: {
        if (status === Image.Ready && originalSource && enableCustomCache)
            ImageCacheJS.ImageCache.addToCache(originalSource);

    }

    // Clean up expired cache entries periodically
    Timer {
        interval: 5 * 60 * 1000 // 5 minutes
        running: enableCustomCache
        repeat: true
        onTriggered: ImageCacheJS.ImageCache.cleanExpired()
    }

}
