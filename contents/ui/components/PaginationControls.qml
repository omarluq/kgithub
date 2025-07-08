import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

RowLayout {
    id: paginationControls

    property int currentPage: 1
    property bool hasMore: true
    property int totalItems: 0
    property int itemsPerPage: 5
    property int currentPageItems: 0
    property int totalPages: Math.max(1, Math.ceil(totalItems / itemsPerPage))

    signal goToPage(int page)
    signal refresh()

    Layout.fillWidth: true
    spacing: 5

    PlasmaComponents3.Label {
        text: "Showing " + currentPageItems + " of " + totalItems + " items (Page " + currentPage + "/" + totalPages + ")"
        opacity: 0.7
        font.pixelSize: 10
    }

    Item {
        Layout.fillWidth: true
    }

    // Previous button
    PlasmaComponents3.Button {
        icon.name: "go-previous"
        flat: true
        enabled: currentPage > 1
        onClicked: {
            paginationControls.goToPage(currentPage - 1);
        }
    }

    // Current page indicator
    PlasmaComponents3.Label {
        text: "Page " + currentPage
        font.bold: true
        opacity: 0.8
    }

    // Next button
    PlasmaComponents3.Button {
        icon.name: "go-next"
        flat: true
        enabled: currentPage < totalPages && hasMore
        onClicked: {
            paginationControls.goToPage(currentPage + 1);
        }
    }

}
