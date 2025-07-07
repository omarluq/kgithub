import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: readmeView

    property var readmeData: null

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
                        text: "View Raw"
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

            PlasmaComponents3.TextArea {
                id: contentText

                text: {
                    if (!readmeData || !readmeData.content)
                        return "No README content available";

                    try {
                        // Decode base64 content
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
                    color: Qt.rgba(0, 0, 0, 0.03)
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
