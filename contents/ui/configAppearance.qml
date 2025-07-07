import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

ScrollView {
    id: appearanceConfigForm

    property string title: i18n("Appearance")

    // Configuration properties - MUST be at root level for KDE config system
    property alias cfg_iconTheme: iconThemeComboBox.currentIndex
    property alias cfg_showIconInTitle: showIconInTitleCheckBox.checked
    property alias cfg_showProfileCard: showProfileCardCheckBox.checked
    property alias cfg_itemsPerPage: itemsPerPageSpinBox.value
    property alias cfg_showRepositoriesTab: showRepositoriesCheckBox.checked
    property alias cfg_showIssuesTab: showIssuesCheckBox.checked
    property alias cfg_showPullRequestsTab: showPullRequestsCheckBox.checked
    property alias cfg_showOrganizationsTab: showOrganizationsCheckBox.checked
    property alias cfg_showStarredTab: showStarredCheckBox.checked
    property alias cfg_defaultReadmeViewMode: defaultReadmeViewModeComboBox.currentIndex
    property alias cfg_defaultCommentViewMode: defaultCommentViewModeComboBox.currentIndex
    property alias cfg_showUserAvatars: showUserAvatarsCheckBox.checked
    property alias cfg_showOrgAvatars: showOrgAvatarsCheckBox.checked
    property alias cfg_showRepoAvatars: showRepoAvatarsCheckBox.checked
    property alias cfg_showIssueAvatars: showIssueAvatarsCheckBox.checked
    property alias cfg_showPRAvatars: showPRAvatarsCheckBox.checked

    property int cfg_iconThemeDefault: 0
    property bool cfg_showIconInTitleDefault: true
    property bool cfg_showProfileCardDefault: true
    property int cfg_itemsPerPageDefault: 5
    property bool cfg_showRepositoriesTabDefault: true
    property bool cfg_showIssuesTabDefault: true
    property bool cfg_showPullRequestsTabDefault: true
    property bool cfg_showOrganizationsTabDefault: true
    property bool cfg_showStarredTabDefault: true
    property int cfg_defaultReadmeViewModeDefault: 2
    property int cfg_defaultCommentViewModeDefault: 1
    property bool cfg_showUserAvatarsDefault: true
    property bool cfg_showOrgAvatarsDefault: true
    property bool cfg_showRepoAvatarsDefault: true
    property bool cfg_showIssueAvatarsDefault: true
    property bool cfg_showPRAvatarsDefault: true

    // Fix scrolling behavior
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    // Ensure the ScrollView takes the full available space
    anchors.fill: parent

    ColumnLayout {
        width: appearanceConfigForm.availableWidth
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

        RowLayout {
            Kirigami.FormData.label: "GitHub Icon Theme:"
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ComboBox {
                id: iconThemeComboBox
                model: ["Dark", "Light"]
                currentIndex: 0
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            }

            // Icon preview
            Rectangle {
                width: Kirigami.Units.iconSizes.medium
                height: Kirigami.Units.iconSizes.medium
                radius: Kirigami.Units.smallSpacing / 2
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Qt.rgba(0.5, 0.5, 0.5, 0.3)

                Image {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing / 2
                    source: {
                        var themeSuffix = iconThemeComboBox.currentIndex === 1 ? "-light" : "";
                        return Qt.resolvedUrl("../assets/icons/icons8-github" + themeSuffix + ".svg");
                    }
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }
            }

            PlasmaComponents3.Label {
                text: iconThemeComboBox.currentIndex === 0 ? "Dark theme" : "Light theme"
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }

        PlasmaComponents3.CheckBox {
            id: showIconInTitleCheckBox
            Kirigami.FormData.label: "Show icon next to title:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showProfileCardCheckBox
            Kirigami.FormData.label: "Show profile card:"
            checked: true
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Avatar Settings"
        }

        PlasmaComponents3.CheckBox {
            id: showUserAvatarsCheckBox
            Kirigami.FormData.label: "Show user avatars:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showOrgAvatarsCheckBox
            Kirigami.FormData.label: "Show organization avatars:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showRepoAvatarsCheckBox
            Kirigami.FormData.label: "Show repository owner avatars:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showIssueAvatarsCheckBox
            Kirigami.FormData.label: "Show issue author avatars:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showPRAvatarsCheckBox
            Kirigami.FormData.label: "Show PR author avatars:"
            checked: true
        }

        PlasmaComponents3.SpinBox {
            id: itemsPerPageSpinBox
            Kirigami.FormData.label: "Items per page:"
            from: 3
            to: 20
            value: 5
        }

        PlasmaComponents3.ComboBox {
            id: defaultReadmeViewModeComboBox
            Kirigami.FormData.label: "Default README view mode:"
            model: ["Raw", "Markdown", "Rich"]
            currentIndex: 2
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }

        PlasmaComponents3.ComboBox {
            id: defaultCommentViewModeComboBox
            Kirigami.FormData.label: "Default comment view mode:"
            model: ["Raw", "Markdown"]
            currentIndex: 1
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Visible Tabs"
        }

        PlasmaComponents3.CheckBox {
            id: showRepositoriesCheckBox
            Kirigami.FormData.label: "Show Repositories tab:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showIssuesCheckBox
            Kirigami.FormData.label: "Show Issues tab:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showPullRequestsCheckBox
            Kirigami.FormData.label: "Show Pull Requests tab:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showOrganizationsCheckBox
            Kirigami.FormData.label: "Show Organizations tab:"
            checked: true
        }

        PlasmaComponents3.CheckBox {
            id: showStarredCheckBox
            Kirigami.FormData.label: "Show Starred Repositories tab:"
            checked: true
        }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Theme Information"
        }

        PlasmaComponents3.Label {
            text: "• Dark theme: Use dark GitHub icons (suitable for light system themes)\n• Light theme: Use light GitHub icons (suitable for dark system themes)\n\nThe icon theme affects the GitHub logo displayed in the compact representation and other GitHub-specific icons throughout the widget."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.8
        }
    }
}
