import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    // No activity data for future dates

    id: commitGraph

    property var commitData: null
    property int commitGraphColor: 0
    property var dataManagerInstance: null
    property string selectedDate: ""
    property int selectedCommits: 0
    // Build GitHub-style grid data (7 rows × 53 columns)
    property var gitHubGrid: buildGitHubStyleGrid()

    function refreshCommitData() {
        if (dataManagerInstance)
            dataManagerInstance.fetchCommitActivity();

    }

    function getCommitColor(activity, colorScheme) {
        if (activity <= 0)
            return Qt.rgba(0.95, 0.95, 0.95, 1);

        // Scale activity levels properly (0-1 scale)
        switch (colorScheme) {
        case 0:
            // Green (GitHub style)
            if (activity <= 0.25)
                return Qt.rgba(0.6, 0.9, 0.6, 1);
            else if (activity <= 0.5)
                return Qt.rgba(0.4, 0.8, 0.4, 1);
            else if (activity <= 0.75)
                return Qt.rgba(0.3, 0.7, 0.3, 1);
            else
                return Qt.rgba(0.1, 0.6, 0.1, 1);
        case 1:
            // Blue
            if (activity <= 0.25)
                return Qt.rgba(0.4, 0.7, 0.9, 1);
            else if (activity <= 0.5)
                return Qt.rgba(0.3, 0.6, 0.8, 1);
            else if (activity <= 0.75)
                return Qt.rgba(0.2, 0.5, 0.7, 1);
            else
                return Qt.rgba(0.1, 0.3, 0.6, 1);
        case 2:
            // Purple
            if (activity <= 0.25)
                return Qt.rgba(0.8, 0.5, 0.9, 1);
            else if (activity <= 0.5)
                return Qt.rgba(0.7, 0.4, 0.8, 1);
            else if (activity <= 0.75)
                return Qt.rgba(0.6, 0.3, 0.7, 1);
            else
                return Qt.rgba(0.4, 0.1, 0.6, 1);
        case 3:
            // Orange
            if (activity <= 0.25)
                return Qt.rgba(1, 0.7, 0.4, 1);
            else if (activity <= 0.5)
                return Qt.rgba(0.9, 0.6, 0.3, 1);
            else if (activity <= 0.75)
                return Qt.rgba(0.8, 0.5, 0.2, 1);
            else
                return Qt.rgba(0.7, 0.3, 0.1, 1);
        case 4:
            // Red
            if (activity <= 0.25)
                return Qt.rgba(0.9, 0.5, 0.5, 1);
            else if (activity <= 0.5)
                return Qt.rgba(0.8, 0.4, 0.4, 1);
            else if (activity <= 0.75)
                return Qt.rgba(0.7, 0.3, 0.3, 1);
            else
                return Qt.rgba(0.6, 0.1, 0.1, 1);
        default:
            return Qt.rgba(0.6, 0.9, 0.6, 1);
        }
    }

    function getLegendColor(index, colorScheme) {
        switch (colorScheme) {
        case 0:
            // Green
            switch (index) {
            case 0:
                return Qt.rgba(0.95, 0.95, 0.95, 1);
            case 1:
                return Qt.rgba(0.6, 0.9, 0.6, 1);
            case 2:
                return Qt.rgba(0.3, 0.8, 0.3, 1);
            case 3:
                return Qt.rgba(0.2, 0.7, 0.2, 1);
            case 4:
                return Qt.rgba(0.1, 0.6, 0.1, 1);
            }
            break;
        case 1:
            // Blue
            switch (index) {
            case 0:
                return Qt.rgba(0.95, 0.95, 0.95, 1);
            case 1:
                return Qt.rgba(0.4, 0.7, 0.9, 1);
            case 2:
                return Qt.rgba(0.2, 0.5, 0.8, 1);
            case 3:
                return Qt.rgba(0.15, 0.4, 0.75, 1);
            case 4:
                return Qt.rgba(0.1, 0.3, 0.7, 1);
            }
            break;
        case 2:
            // Purple
            switch (index) {
            case 0:
                return Qt.rgba(0.95, 0.95, 0.95, 1);
            case 1:
                return Qt.rgba(0.8, 0.5, 0.9, 1);
            case 2:
                return Qt.rgba(0.6, 0.3, 0.8, 1);
            case 3:
                return Qt.rgba(0.5, 0.2, 0.7, 1);
            case 4:
                return Qt.rgba(0.4, 0.1, 0.6, 1);
            }
            break;
        case 3:
            // Orange
            switch (index) {
            case 0:
                return Qt.rgba(0.95, 0.95, 0.95, 1);
            case 1:
                return Qt.rgba(1, 0.7, 0.4, 1);
            case 2:
                return Qt.rgba(0.9, 0.5, 0.2, 1);
            case 3:
                return Qt.rgba(0.85, 0.4, 0.15, 1);
            case 4:
                return Qt.rgba(0.8, 0.3, 0.1, 1);
            }
            break;
        case 4:
            // Red
            switch (index) {
            case 0:
                return Qt.rgba(0.95, 0.95, 0.95, 1);
            case 1:
                return Qt.rgba(0.9, 0.5, 0.5, 1);
            case 2:
                return Qt.rgba(0.8, 0.3, 0.3, 1);
            case 3:
                return Qt.rgba(0.75, 0.2, 0.2, 1);
            case 4:
                return Qt.rgba(0.7, 0.1, 0.1, 1);
            }
            break;
        }
        return Qt.rgba(0.95, 0.95, 0.95, 1);
    }

    function buildGitHubStyleGrid() {
        if (!commitData || !commitData.data) {
            console.log("CommitGraphView: No commit data available");
            return [];
        }
        console.log("CommitGraphView: Building grid with", commitData.data.length, "data points");
        var grid = [];
        // Initialize 7 rows for days of the week
        for (var row = 0; row < 7; row++) {
            grid[row] = [];
            for (var col = 0; col < 53; col++) {
                grid[row][col] = {
                    "activity": 0,
                    "commits": 0,
                    "date": ""
                };
            }
        }
        // Fill grid with actual data + generate today and rest of current week
        var dataPointsUsed = 0;
        var today = new Date();
        today.setHours(0, 0, 0, 0); // Normalize to start of day
        var todayDayOfWeek = today.getDay();
        // First, create entries for today through end of current week
        for (var futureDay = 0; futureDay <= (6 - todayDayOfWeek); futureDay++) {
            var futureDate = new Date(today);
            futureDate.setDate(today.getDate() + futureDay);
            var futureDayOfWeek = futureDate.getDay();
            // Place in current week (rightmost column = 52)
            grid[futureDayOfWeek][52] = {
                "activity": 0,
                "commits": 0,
                "date": futureDate.toISOString().split('T')[0]
            };
        }
        // Then fill with actual commit data
        for (var i = 0; i < commitData.data.length; i++) {
            var dayData = commitData.data[i];
            if (dayData.date) {
                // Parse date in local timezone to avoid UTC conversion issues
                var dateParts = dayData.date.split('-');
                var date = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));
                var dayOfWeek = date.getDay(); // 0 = Sunday, 1 = Monday, etc.
                // Calculate days difference from today
                var daysDiff = Math.floor((today.getTime() - date.getTime()) / (24 * 60 * 60 * 1000));
                // Skip future dates beyond this week
                if (daysDiff < 0)
                    continue;

                // Calculate which week column this belongs to
                // Find the Sunday that starts the week containing this date
                var dateWeekStart = new Date(date);
                dateWeekStart.setDate(date.getDate() - dayOfWeek);
                var todayWeekStart = new Date(today);
                todayWeekStart.setDate(today.getDate() - todayDayOfWeek);
                var weeksDiff = Math.floor((todayWeekStart.getTime() - dateWeekStart.getTime()) / (7 * 24 * 60 * 60 * 1000));
                var col = 52 - weeksDiff;
                if (col >= 0 && col < 53 && dayOfWeek >= 0 && dayOfWeek < 7) {
                    grid[dayOfWeek][col] = {
                        "activity": dayData.activity || 0,
                        "commits": dayData.commits || 0,
                        "date": dayData.date
                    };
                    dataPointsUsed++;
                }
            }
        }
        console.log("CommitGraphView: Used", dataPointsUsed, "data points in grid");
        return grid;
    }

    function getWeekOfYear(date) {
        var d = new Date(date);
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
        var week1 = new Date(d.getFullYear(), 0, 4);
        return 1 + Math.round(((d.getTime() - week1.getTime()) / 8.64e+07 - 3 + (week1.getDay() + 6) % 7) / 7);
    }

    function getMonthLabels() {
        var labels = [];
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var todayDayOfWeek = today.getDay();
        // Calculate the start of this week (Sunday)
        var thisWeekStart = new Date(today);
        thisWeekStart.setDate(today.getDate() - todayDayOfWeek);
        var lastMonth = -1;
        var lastShownColumn = -1;
        for (var col = 0; col < 53; col++) {
            // Calculate the date for the start of this week column
            var weekOffset = 52 - col;
            var weekStartDate = new Date(thisWeekStart);
            weekStartDate.setDate(thisWeekStart.getDate() - (weekOffset * 7));
            var monthName = "";
            var currentMonth = weekStartDate.getMonth();
            // Only show month name when:
            // 1. It's a new month AND
            // 2. We have enough space since last shown month (at least 6 columns apart)
            if (currentMonth !== lastMonth && (lastShownColumn === -1 || (col - lastShownColumn) >= 6)) {
                var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                monthName = monthNames[currentMonth];
                lastShownColumn = col;
            }
            lastMonth = currentMonth;
            labels.push(monthName);
        }
        return labels;
    }

    function initializeTodayAsDefault() {
        var today = new Date();
        var todayString = today.toISOString().split('T')[0]; // YYYY-MM-DD format
        // Find today's data in the grid
        var todayCommits = 0;
        if (gitHubGrid && gitHubGrid.length > 0) {
            var todayDayOfWeek = today.getDay();
            if (gitHubGrid[todayDayOfWeek] && gitHubGrid[todayDayOfWeek][52]) {
                var todayData = gitHubGrid[todayDayOfWeek][52];
                if (todayData.date === todayString)
                    todayCommits = todayData.commits || 0;

            }
        }
        selectedDate = todayString;
        selectedCommits = todayCommits;
    }

    function getSelectedDateText() {
        if (selectedDate) {
            var dateParts = selectedDate.split('-');
            var date = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));
            return date.toLocaleDateString('en-US', {
                "weekday": 'long',
                "year": 'numeric',
                "month": 'long',
                "day": 'numeric'
            });
        }
        return "No date selected";
    }

    function getSelectedCommitsText() {
        if (selectedDate) {
            var commitText = selectedCommits === 1 ? "contribution" : "contributions";
            return selectedCommits + " " + commitText;
        }
        return "";
    }

    // Update grid when commit data changes
    onCommitDataChanged: {
        console.log("CommitGraphView: Commit data changed, rebuilding grid");
        gitHubGrid = buildGitHubStyleGrid();
        // Initialize today as default selection after grid is built
        Qt.callLater(initializeTodayAsDefault);
    }
    // Initialize today's date when component is ready
    Component.onCompleted: {
        Qt.callLater(initializeTodayAsDefault);
    }
    spacing: 12

    // Header
    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            source: "vcs-commit"
            width: 24
            height: 24
        }

        ColumnLayout {
            spacing: 2

            PlasmaComponents3.Label {
                text: "Commit Activity"
                font.bold: true
                font.pixelSize: 20
            }

            PlasmaComponents3.Label {
                text: commitData && commitData.totalCommits ? commitData.totalCommits + " contributions in the last year" : "Loading commit data..."
                opacity: 0.7
                font.pixelSize: 12
            }

        }

        Item {
            Layout.fillWidth: true
        }

        PlasmaComponents3.Button {
            icon.name: "view-refresh"
            flat: true
            implicitWidth: 24
            implicitHeight: 24
            onClicked: refreshCommitData()
        }

    }

    // GitHub-style commit graph
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        RowLayout {
            spacing: 4

            // Day labels (Sun, Mon, Tue, etc.)
            ColumnLayout {
                spacing: 2

                // Spacer for month labels
                Item {
                    height: 10
                }

                Repeater {
                    model: ["", "Mon", "", "Wed", "", "Fri", ""]

                    PlasmaComponents3.Label {
                        text: modelData
                        font.pixelSize: 10
                        opacity: 0.6
                        Layout.preferredHeight: 10
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignRight
                    }

                }

            }

            // Main grid
            ColumnLayout {
                spacing: 2

                // Month labels
                RowLayout {
                    spacing: 2
                    Layout.preferredHeight: 12

                    Repeater {
                        model: getMonthLabels()

                        Item {
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 12

                            PlasmaComponents3.Label {
                                text: modelData
                                font.pixelSize: 9
                                opacity: 0.7
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                visible: text !== ""
                            }

                        }

                    }

                }

                // Commit squares - organized as GitHub does it
                Repeater {
                    model: 7 // 7 days of the week

                    RowLayout {
                        property int dayIndex: index

                        spacing: 2

                        Repeater {
                            model: 53 // 53 weeks

                            Rectangle {
                                property int weekIndex: index
                                property var gridData: {
                                    var grid = commitGraph.gitHubGrid;
                                    if (grid && grid.length > parent.dayIndex && grid[parent.dayIndex] && grid[parent.dayIndex].length > weekIndex)
                                        return grid[parent.dayIndex][weekIndex];

                                    return {
                                        "activity": 0,
                                        "commits": 0,
                                        "date": ""
                                    };
                                }

                                width: 10
                                height: 10
                                radius: 2
                                color: getCommitColor(gridData.activity, commitGraphColor)
                                border.width: 1
                                border.color: Qt.rgba(0.8, 0.8, 0.8, 0.3)

                                MouseArea {
                                    id: mouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (gridData.date) {
                                            selectedDate = gridData.date;
                                            selectedCommits = gridData.commits || 0;
                                        }
                                    }
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    // Legend with selected date info
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Selected date metadata (left side)
        ColumnLayout {
            spacing: 3

            PlasmaComponents3.Label {
                text: getSelectedDateText()
                font.bold: true
                font.pixelSize: 14
                color: Kirigami.Theme.textColor
            }

            PlasmaComponents3.Label {
                text: getSelectedCommitsText()
                opacity: 0.8
                font.pixelSize: 12
                color: Kirigami.Theme.textColor
            }

        }

        Item {
            Layout.fillWidth: true
        }

        // Legend (right side)
        RowLayout {
            spacing: 8

            PlasmaComponents3.Label {
                text: "Less"
                opacity: 0.7
                font.pixelSize: 12
            }

            Row {
                spacing: 2

                Repeater {
                    model: 5

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 2
                        color: getLegendColor(index, commitGraphColor)
                        border.width: 1
                        border.color: Qt.rgba(0.8, 0.8, 0.8, 0.3)
                    }

                }

            }

            PlasmaComponents3.Label {
                text: "More"
                opacity: 0.7
                font.pixelSize: 12
            }

        }

    }

}
