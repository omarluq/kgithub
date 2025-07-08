import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: generalConfigForm

    property string title: i18n("General")

    property alias cfg_githubToken: githubTokenField.text
    property alias cfg_githubUsername: githubUsernameField.text
    property alias cfg_refreshInterval: refreshIntervalSpinBox.value

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
