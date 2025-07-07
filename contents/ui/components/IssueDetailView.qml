import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

ColumnLayout {
    id: detailView

    property var itemData: null
    property var detailData: null
    property var commentsData: []
    property bool isLoading: false
    property var timelineData: []
    property int currentPage: 1
    property int commentsPerPage: 3
    property var paginatedTimelineData: {
        var totalItems = timelineData.length;
        var totalPages = Math.ceil(totalItems / commentsPerPage);
        var startIndex = (currentPage - 1) * commentsPerPage;
        var endIndex = Math.min(startIndex + commentsPerPage, totalItems);
        return {
            "items": timelineData.slice(startIndex, endIndex),
            "currentPage": currentPage,
            "totalPages": totalPages,
            "totalItems": totalItems,
            "hasNext": currentPage < totalPages,
            "hasPrevious": currentPage > 1
        };
    }

    function getItemType() {
        if (!itemData)
            return "";

        return itemData.pull_request ? "pr" : "issue";
    }

    function getItemIcon() {
        return getItemType() === "pr" ? "merge" : "dialog-warning";
    }

    function getStatusColor() {
        if (!itemData)
            return Kirigami.Theme.textColor;

        if (getItemType() === "pr") {
            switch (itemData.state) {
            case "open":
                return "#238636"; // Green
            case "closed":
                return itemData.merged ? "#8250df" : "#da3633"; // Purple if merged, red if closed
            case "draft":
                return "#656d76"; // Gray
            default:
                return Kirigami.Theme.textColor;
            }
        } else {
            return itemData.state === "open" ? "#238636" : "#8250df";
        }
    }

    function getStatusText() {
        if (!itemData)
            return "";

        if (getItemType() === "pr") {
            if (itemData.draft)
                return "Draft";

            if (itemData.merged)
                return "Merged";

            return itemData.state === "open" ? "Open" : "Closed";
        } else {
            return itemData.state === "open" ? "Open" : "Closed";
        }
    }

    function updateTimelineData() {
        var timeline = [];
        // Add initial description as first item (always include, even if body is empty)
        if (itemData)
            timeline.push({
            "type": "description",
            "author": itemData.user,
            "created_at": itemData.created_at,
            "body": itemData.body || ""
        });

        // Add comments
        if (commentsData && commentsData.length > 0) {
            for (var i = 0; i < commentsData.length; i++) {
                timeline.push({
                    "type": "comment",
                    "author": commentsData[i].user,
                    "created_at": commentsData[i].created_at,
                    "body": commentsData[i].body
                });
            }
        }
        timelineData = timeline;
        currentPage = 1; // Reset to first page when data changes
    }

    function nextPage() {
        if (paginatedTimelineData.hasNext)
            currentPage++;

    }

    function previousPage() {
        if (paginatedTimelineData.hasPrevious)
            currentPage--;

    }

    spacing: 0
    onItemDataChanged: Qt.callLater(updateTimelineData)
    onCommentsDataChanged: Qt.callLater(updateTimelineData)

    // Single scrollable container with all content
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: contentColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: availableWidth

        ColumnLayout {
            id: contentColumn

            width: parent.width
            spacing: 9

            // Header with title and status
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 0
                Layout.bottomMargin: 0

                Kirigami.Icon {
                    source: getItemIcon()
                    width: 30
                    height: 30
                }

                PlasmaComponents3.Label {
                    text: itemData ? itemData.title : ""
                    font.bold: true
                    font.pixelSize: 22
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    Layout.preferredWidth: 300
                }

                // Status badge
                Rectangle {
                    color: getStatusColor()
                    radius: 18
                    implicitWidth: statusLabel.implicitWidth + 24
                    implicitHeight: statusLabel.implicitHeight + 12

                    PlasmaComponents3.Label {
                        id: statusLabel

                        anchors.centerIn: parent
                        text: getStatusText()
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                    }

                }

            }

            // Labels if any
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: itemData && itemData.labels && itemData.labels.length > 0

                Repeater {
                    model: itemData && itemData.labels ? itemData.labels : []

                    Rectangle {
                        color: "#" + modelData.color
                        radius: 12
                        implicitWidth: labelText.implicitWidth + 18
                        implicitHeight: labelText.implicitHeight + 9

                        PlasmaComponents3.Label {
                            id: labelText

                            anchors.centerIn: parent
                            text: modelData.name
                            color: "white"
                            font.pixelSize: 15
                        }

                    }

                }

            }

            // Separator line
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 18
                Layout.bottomMargin: 18
                height: 1
                color: Qt.rgba(0.5, 0.5, 0.5, 0.3)
            }

            // Timeline - properly integrated
            Repeater {
                model: paginatedTimelineData.items

                Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0.5, 0.5, 0.5, 0.2)
                    radius: 9

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 3

                        // Author and timestamp
                        RowLayout {
                            Layout.fillWidth: true

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: "transparent"

                                Image {
                                    anchors.fill: parent
                                    source: modelData.author ? modelData.author.avatar_url : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 15
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(0, 0, 0, 0.1)
                                    }

                                }

                            }

                            ColumnLayout {
                                spacing: 2

                                PlasmaComponents3.Label {
                                    text: {
                                        var author = modelData.author ? modelData.author.login : "Unknown";
                                        var action = modelData.type === "description" ? "opened this" : "commented";
                                        return author + " " + action;
                                    }
                                    font.bold: modelData.type === "description"
                                    opacity: 0.8
                                    font.pixelSize: 15
                                }

                                PlasmaComponents3.Label {
                                    text: {
                                        var date = new Date(modelData.created_at);
                                        return date.toLocaleDateString() + " " + date.toLocaleTimeString();
                                    }
                                    opacity: 0.6
                                    font.pixelSize: 12
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: modelData.author && itemData && itemData.user && modelData.author.login === itemData.user.login
                                color: "#0969da"
                                radius: 12
                                implicitWidth: 90
                                implicitHeight: 24

                                PlasmaComponents3.Label {
                                    anchors.centerIn: parent
                                    text: "Author"
                                    color: "white"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                            }

                        }

                        // Comment body
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            PlasmaComponents3.TextArea {
                                text: modelData.body || "No content"
                                wrapMode: Text.WordWrap
                                textFormat: Text.PlainText
                                selectByMouse: true
                                readOnly: true

                                background: Item {
                                }

                            }

                        }

                    }

                }

            }

            // Pagination controls
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                visible: timelineData.length > commentsPerPage

                PlasmaComponents3.Button {
                    text: "Previous"
                    flat: true
                    enabled: paginatedTimelineData.hasPrevious
                    onClicked: previousPage()
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: "Page " + paginatedTimelineData.currentPage + " of " + paginatedTimelineData.totalPages
                    opacity: 0.7
                    font.pixelSize: 15
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Button {
                    text: "Next"
                    flat: true
                    enabled: paginatedTimelineData.hasNext
                    onClicked: nextPage()
                }

            }

        }

    }

    // Loading indicator
    PlasmaComponents3.BusyIndicator {
        Layout.alignment: Qt.AlignHCenter
        visible: isLoading
    }

}
