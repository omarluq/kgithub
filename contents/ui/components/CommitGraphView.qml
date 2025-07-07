import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

ColumnLayout {
    id: commitGraph

    property var commitData: null
    property int commitGraphColor: 0
    property var dataManagerInstance: null

    function refreshCommitData() {
        if (dataManagerInstance)
            dataManagerInstance.fetchCommitActivity();

    }

    function getCommitDataForDay(dayIndex) {
        if (!commitData || !commitData.data || dayIndex >= commitData.data.length)
            return {
            "activity": 0,
            "commits": 0,
            "date": ""
        };

        return commitData.data[dayIndex];
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

    // Commit graph grid
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        GridLayout {
            width: commitGraph.width
            columns: 53 // 53 weeks in a year
            columnSpacing: 2
            rowSpacing: 2

            // Real commit graph data
            Repeater {
                model: commitData && commitData.data ? commitData.data.length : 371

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2
                    color: {
                        var dayData = getCommitDataForDay(index);
                        return getCommitColor(dayData.activity, commitGraphColor);
                    }
                    border.width: 1
                    border.color: Qt.rgba(0.8, 0.8, 0.8, 0.5)
                }

            }

        }

    }

    // Legend
    RowLayout {
        Layout.fillWidth: true
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
                    width: 8
                    height: 8
                    radius: 2
                    color: getLegendColor(index, commitGraphColor)
                    border.width: 1
                    border.color: Qt.rgba(0.8, 0.8, 0.8, 0.5)
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
