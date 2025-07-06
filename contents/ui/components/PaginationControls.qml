import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    id: paginationControls

    property int currentPage: 1
    property bool hasMore: true
    property int totalItems: 0
    property int itemsPerPage: 5
    property int totalPages: Math.max(1, Math.ceil(totalItems / itemsPerPage))

    signal goToPage(int page)
    signal refresh()

    Layout.fillWidth: true
    spacing: 5

    PlasmaComponents3.Label {
        text: totalItems + " items (Page " + currentPage + "/" + totalPages + ")"
        opacity: 0.7
        font.pixelSize: 10
    }

    Item { Layout.fillWidth: true }

    // Previous button
    PlasmaComponents3.Button {
        icon.name: "go-previous"
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
        enabled: currentPage < totalPages && hasMore
        onClicked: {
            paginationControls.goToPage(currentPage + 1);
        }
    }

}
