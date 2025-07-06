import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

ColumnLayout {
    id: generalConfigForm

    property string title: i18n("General")

    property alias cfg_githubToken: githubTokenField.text
    property alias cfg_githubUsername: githubUsernameField.text
    property alias cfg_refreshInterval: refreshIntervalSpinBox.value
    property alias cfg_itemsPerPage: itemsPerPageSpinBox.value
    property alias cfg_showRepositoriesTab: showRepositoriesCheckBox.checked
    property alias cfg_showIssuesTab: showIssuesCheckBox.checked
    property alias cfg_showPullRequestsTab: showPullRequestsCheckBox.checked
    property alias cfg_showOrganizationsTab: showOrganizationsCheckBox.checked
    property alias cfg_showStarredTab: showStarredCheckBox.checked

    property string cfg_githubTokenDefault: ""
    property string cfg_githubUsernameDefault: ""
    property int cfg_refreshIntervalDefault: 5
    property int cfg_itemsPerPageDefault: 5
    property bool cfg_showRepositoriesTabDefault: true
    property bool cfg_showIssuesTabDefault: true
    property bool cfg_showPullRequestsTabDefault: true
    property bool cfg_showOrganizationsTabDefault: true
    property bool cfg_showStarredTabDefault: true

    Kirigami.FormLayout {
        Layout.fillWidth: true

        PlasmaComponents3.TextField {
            id: githubTokenField
            Kirigami.FormData.label: "GitHub Personal Access Token:"
            placeholderText: "Enter your GitHub token"
            echoMode: TextInput.Password
        }

        PlasmaComponents3.TextField {
            id: githubUsernameField
            Kirigami.FormData.label: "GitHub Username:"
            placeholderText: "Enter your GitHub username (e.g., torvalds)"
        }

        PlasmaComponents3.SpinBox {
            id: refreshIntervalSpinBox
            Kirigami.FormData.label: "Refresh interval (minutes):"
            from: 1
            to: 60
            value: 5
        }

        PlasmaComponents3.SpinBox {
            id: itemsPerPageSpinBox
            Kirigami.FormData.label: "Items per page:"
            from: 3
            to: 20
            value: 5
        }
    }

    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Visible Tabs"
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

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
        Kirigami.FormData.label: "Instructions"
    }

    PlasmaComponents3.Label {
        text: "1. Create a GitHub Personal Access Token at:\n   https://github.com/settings/tokens\n\n2. Grant the following permissions:\n   • repo (for private repositories)\n   • public_repo (for public repositories)\n   • read:org (for organization access)\n\n3. Enter your GitHub username and token above\n\n4. KGithub will show your repositories, issues, PRs, and organizations"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        opacity: 0.8
    }
}
