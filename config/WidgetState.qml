pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool qsOpen: false
    property string qsView: "network"

    property bool leftSidebarOpen: false
    property string leftSidebarView: "info"

    function closeAllPopups() {
        qsOpen = false;
        leftSidebarOpen = false;
    }
}
