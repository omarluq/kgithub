import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

RowLayout {
    id: reactionBar

    property var reactions: []
    property int maxReactions: 5

    spacing: 6
    visible: reactions && reactions.length > 0

    Repeater {
        model: Math.min(reactions ? reactions.length : 0, maxReactions)

        Rectangle {
            property var reaction: reactions && index < reactions.length ? reactions[index] : null

            Layout.preferredHeight: 24
            Layout.preferredWidth: reactionLayout.implicitWidth + 12
            color: Qt.rgba(0, 0, 0, 0.05)
            border.color: Qt.rgba(0, 0, 0, 0.15)
            border.width: 1
            radius: 12
            visible: reaction && reaction.count > 0

            RowLayout {
                id: reactionLayout

                anchors.centerIn: parent
                spacing: 4

                PlasmaComponents3.Label {
                    text: reaction ? reaction.emoji : ""
                    font.pixelSize: 14
                }

                PlasmaComponents3.Label {
                    text: reaction ? reaction.count : ""
                    font.pixelSize: 12
                    color: Kirigami.Theme.textColor
                    opacity: 0.8
                }

            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    parent.color = Qt.rgba(0, 0, 0, 0.08);
                    parent.border.color = Qt.rgba(0, 0, 0, 0.25);
                    if (reaction) {
                        var tooltip = reaction.emoji + " " + reaction.type;
                        if (reaction.count > 1)
                            tooltip += " (" + reaction.count + ")";

                        if (reaction.users && reaction.users.length > 0) {
                            tooltip += "\n";
                            if (reaction.users.length <= 10)
                                tooltip += reaction.users.join(", ");
                            else
                                tooltip += reaction.users.slice(0, 10).join(", ") + " and " + (reaction.users.length - 10) + " more";
                        }
                        reactionTooltip.text = tooltip;
                        reactionTooltip.visible = true;
                    }
                }
                onExited: {
                    parent.color = Qt.rgba(0, 0, 0, 0.05);
                    parent.border.color = Qt.rgba(0, 0, 0, 0.15);
                    reactionTooltip.visible = false;
                }
            }

        }

    }

    PlasmaComponents3.ToolTip {
        id: reactionTooltip

        visible: false
        delay: 500
    }

}
