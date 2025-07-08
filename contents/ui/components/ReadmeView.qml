import "../utils/MarkdownUtils.js" as MarkdownUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    // It's a file - use blob URL for GitHub
    // It's likely a directory or section - use tree URL

    id: readmeView

    property var readmeData: null
    property string defaultViewMode: "rich" // "raw", "markdown", "rich"
    property string viewMode: defaultViewMode
    property var repositoryInfo: null // Repository object with owner/name info

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // README header
        RowLayout {
            Layout.fillWidth: true

            Kirigami.Icon {
                source: "text-markdown"
                width: 18
                height: 18
            }

            Kirigami.Heading {
                text: readmeData ? readmeData.name : "README"
                level: 4
                Layout.fillWidth: true
            }

            // View mode selector
            PlasmaComponents3.Button {
                id: viewModeButton

                visible: readmeData
                icon.name: "view-visible"
                text: {
                    switch (viewMode) {
                    case "raw":
                        return "Raw";
                    case "markdown":
                        return "Markdown";
                    case "rich":
                        return "Rich";
                    default:
                        return "Rich";
                    }
                }
                flat: true
                onClicked: viewModeMenu.opened ? viewModeMenu.close() : viewModeMenu.popup(viewModeButton, 0, viewModeButton.height)

                PlasmaComponents3.Menu {
                    id: viewModeMenu

                    PlasmaComponents3.MenuItem {
                        text: "Raw"
                        icon.name: "text-plain"
                        checkable: true
                        checked: viewMode === "raw"
                        onTriggered: viewMode = "raw"
                    }

                    PlasmaComponents3.MenuItem {
                        text: "Markdown"
                        icon.name: "text-markdown"
                        checkable: true
                        checked: viewMode === "markdown"
                        onTriggered: viewMode = "markdown"
                    }

                    PlasmaComponents3.MenuItem {
                        text: "Rich"
                        icon.name: "text-enriched"
                        checkable: true
                        checked: viewMode === "rich"
                        onTriggered: viewMode = "rich"
                    }

                }

            }

            // Hamburger menu button
            PlasmaComponents3.Button {
                id: menuButton

                icon.name: "application-menu"
                flat: true
                implicitWidth: 24
                implicitHeight: 24
                visible: readmeData
                opacity: 1
                onClicked: contextMenu.opened ? contextMenu.close() : contextMenu.popup(menuButton, 0, menuButton.height)

                PlasmaComponents3.Menu {
                    id: contextMenu

                    PlasmaComponents3.MenuItem {
                        text: "View Raw on GitHub"
                        icon.name: "text-plain"
                        enabled: readmeData && readmeData.download_url
                        opacity: 1
                        onTriggered: {
                            if (readmeData && readmeData.download_url)
                                Qt.openUrlExternally(readmeData.download_url);

                        }
                    }

                    PlasmaComponents3.MenuItem {
                        text: "Copy Raw URL"
                        icon.name: "edit-copy"
                        enabled: readmeData && readmeData.download_url
                        opacity: 1
                        onTriggered: {
                            if (readmeData && readmeData.download_url)
                                clipboardHelper.copyToClipboard(readmeData.download_url);

                        }
                    }

                    PlasmaComponents3.MenuSeparator {
                    }

                    PlasmaComponents3.MenuItem {
                        text: "View on GitHub"
                        icon.name: "internet-services"
                        enabled: readmeData && readmeData.html_url
                        opacity: 1
                        onTriggered: {
                            if (readmeData && readmeData.html_url)
                                Qt.openUrlExternally(readmeData.html_url);

                        }
                    }

                    PlasmaComponents3.MenuItem {
                        text: "Copy GitHub URL"
                        icon.name: "edit-copy"
                        enabled: readmeData && readmeData.html_url
                        opacity: 1
                        onTriggered: {
                            if (readmeData && readmeData.html_url)
                                clipboardHelper.copyToClipboard(readmeData.html_url);

                        }
                    }

                }

            }

        }

        // Clipboard helper using TextEdit workaround
        TextEdit {
            id: clipboardHelper

            function copyToClipboard(text) {
                clipboardHelper.text = text;
                clipboardHelper.selectAll();
                clipboardHelper.copy();
                console.log("✓ Copied to clipboard:", text);
            }

            visible: false
        }

        // Separator line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(0.5, 0.5, 0.5, 0.3)
        }

        // README content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            // Raw view - pure text, no interpretation
            PlasmaComponents3.TextArea {
                id: rawContentText

                width: parent.width
                height: Math.max(parent.height, implicitHeight)
                visible: viewMode === "raw"
                text: {
                    if (!readmeData || !readmeData.content)
                        return "No README content available";

                    try {
                        // Return the exact raw content
                        return Qt.atob(readmeData.content);
                    } catch (e) {
                        return "Error decoding README content";
                    }
                }
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                selectByMouse: true
                readOnly: true
                font.family: "monospace"
                font.pixelSize: 11
                padding: 8

                background: Rectangle {
                    color: "transparent"
                    radius: 3
                }

            }

            // Markdown view
            PlasmaComponents3.TextArea {
                id: markdownContentText

                width: parent.width
                height: Math.max(parent.height, implicitHeight)
                visible: viewMode === "markdown"
                text: {
                    if (!readmeData || !readmeData.content)
                        return "No README content available";

                    try {
                        // Process relative URLs for markdown view
                        var rawContent = Qt.atob(readmeData.content);
                        return MarkdownUtils.processRelativeUrls(rawContent, repositoryInfo);
                    } catch (e) {
                        return "Error decoding README content";
                    }
                }
                wrapMode: Text.Wrap
                textFormat: Text.MarkdownText
                selectByMouse: true
                readOnly: true
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: 12
                padding: 8
                // Prevent local file resolution
                baseUrl: repositoryInfo ? "https://raw.githubusercontent.com/" + repositoryInfo.full_name + "/main/" : ""

                background: Rectangle {
                    color: "transparent"
                    radius: 3
                }

            }

            // Rich view - convert markdown to HTML
            PlasmaComponents3.TextArea {
                // Convert headers
                // Convert bold and italic
                // Convert inline code
                // Convert links
                // Convert line breaks
                // Convert headers
                // Convert bold and italic
                // Convert inline code
                // Convert images
                // Convert links
                // Convert line breaks

                id: richContentText

                width: parent.width
                height: Math.max(parent.height, implicitHeight)
                visible: viewMode === "rich"
                text: {
                    if (!readmeData || !readmeData.content)
                        return "No README content available";

                    try {
                        // Convert markdown to HTML for rich text display
                        var rawContent = Qt.atob(readmeData.content);
                        // Process relative URLs first
                        var processedContent = MarkdownUtils.processRelativeUrls(rawContent, repositoryInfo);
                        // Convert markdown to HTML
                        var htmlContent = processedContent.replace(/^### (.+)$/gm, "<h3>$1</h3>").replace(/^## (.+)$/gm, "<h2>$1</h2>").replace(/^# (.+)$/gm, "<h1>$1</h1>").replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(.+?)\*/g, "<i>$1</i>").replace(/`(.+?)`/g, "<code>$1</code>").replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">').replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>').replace(/\n/g, "<br>");
                        return htmlContent;
                    } catch (e) {
                        return "Error decoding README content";
                    }
                }
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                selectByMouse: true
                readOnly: true
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: 12
                padding: 8
                // Prevent local file resolution
                baseUrl: repositoryInfo ? "https://raw.githubusercontent.com/" + repositoryInfo.full_name + "/main/" : ""

                background: Rectangle {
                    color: "transparent"
                    radius: 3
                }

            }

        }

        // Footer metadata
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: readmeData

            // Separator line above footer
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(0.5, 0.5, 0.5, 0.2)
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            // Commit info row: SHA, size, and file type
            RowLayout {
                Layout.fillWidth: true

                // Left side: SHA and file info
                RowLayout {
                    spacing: 8

                    PlasmaComponents3.Label {
                        text: readmeData && readmeData.sha ? ("SHA: " + readmeData.sha.substring(0, 7)) : ""
                        opacity: 0.5
                        font.pixelSize: 9
                        font.family: "monospace"
                        visible: text !== ""
                    }

                    PlasmaComponents3.Label {
                        text: readmeData ? ("• " + Math.round(readmeData.size / 1024) + " KB") : ""
                        opacity: 0.5
                        font.pixelSize: 9
                        visible: text !== ""
                    }

                    PlasmaComponents3.Label {
                        text: readmeData && readmeData.type ? ("• " + readmeData.type) : ""
                        opacity: 0.4
                        font.pixelSize: 9
                        visible: text !== ""
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                // Right side: Encoding info
                PlasmaComponents3.Label {
                    text: readmeData && readmeData.encoding ? readmeData.encoding.toUpperCase() : ""
                    opacity: 0.4
                    font.pixelSize: 8
                    visible: text !== ""
                }

            }

            // File path info
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: readmeData && readmeData.path ? readmeData.path : "README.md"
                opacity: 0.4
                font.pixelSize: 8
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }

        }

    }

}
