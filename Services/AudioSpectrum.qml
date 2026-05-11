pragma Singleton

import QtQuick
import Quickshell
import Clavis.Audio 1.0

Singleton {
    id: root

    property int bars: 45
    property var _owners: ({})

    readonly property int refCount: Object.keys(_owners).length
    readonly property bool active: refCount > 0
    readonly property bool available: cava.available
    readonly property var values: cava.values

    function acquire(token) {
        if (!token || root._owners[token])
            return;

        const next = Object.assign({}, root._owners);
        next[token] = true;
        root._owners = next;
    }

    function release(token) {
        if (!token || !root._owners[token])
            return;

        const next = Object.assign({}, root._owners);
        delete next[token];
        root._owners = next;
    }

    CavaProvider {
        id: cava

        active: root.active
        bars: root.bars
    }
}
