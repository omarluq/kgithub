.pragma library

function processRelativeUrls(content, repositoryInfo) {
    if (!repositoryInfo || !repositoryInfo.full_name) {
        return content;
    }

    var baseUrl = "https://github.com/" + repositoryInfo.full_name;
    var rawBaseUrl = "https://raw.githubusercontent.com/" + repositoryInfo.full_name + "/main";

    // Process markdown images: ![alt](./path) or ![alt](path)
    content = content.replace(/!\[([^\]]*)\]\((?!https?:\/\/)([^)]+)\)/g, function(match, alt, path) {
        var cleanPath = path.replace(/^\.\//, "");
        return "![" + alt + "](" + rawBaseUrl + "/" + cleanPath + ")";
    });

    // Process markdown links to files: [text](./path) or [text](path)
    content = content.replace(/\[([^\]]+)\]\((?!https?:\/\/)([^)#]+)(#[^)]*)?\)/g, function(match, text, path, anchor) {
        var cleanPath = path.replace(/^\.\//, "");
        anchor = anchor || "";

        // Check if it's likely a file (has extension) vs a section link
        if (cleanPath.includes('.') && !cleanPath.endsWith('/')) {
            // It's a file - use blob URL for GitHub
            return "[" + text + "](" + baseUrl + "/blob/main/" + cleanPath + anchor + ")";
        } else {
            // It's likely a directory or section - use tree URL
            return "[" + text + "](" + baseUrl + "/tree/main/" + cleanPath + anchor + ")";
        }
    });

    // Process HTML img tags: <img src="./path"> or <img src="path">
    content = content.replace(/<img([^>]*)\ssrc=["'](?!https?:\/\/)([^"']+)["']([^>]*)>/g, function(match, before, path, after) {
        var cleanPath = path.replace(/^\.\//, "");
        return "<img" + before + ' src="' + rawBaseUrl + "/" + cleanPath + '"' + after + ">";
    });

    return content;
}
