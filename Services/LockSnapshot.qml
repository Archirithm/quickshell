pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property int generation: 0
    property int pendingCount: 0
    property bool ready: true
    property var urls: ({})
    property var results: ({})

    signal prepareRequested(int generation)
    signal prepared(int generation)

    function screenKey(screen) {
        return screen && screen.name ? screen.name : "__default";
    }

    function request(screenCount) {
        generation += 1;
        pendingCount = Math.max(0, screenCount);
        ready = pendingCount === 0;
        urls = {};
        results = {};

        prepareRequested(generation);

        if (ready)
            prepared(generation);

        return generation;
    }

    function setSnapshot(screenName, url, result, snapshotGeneration) {
        if (snapshotGeneration !== generation || ready)
            return;

        const key = screenName && screenName !== "" ? screenName : "__default";
        const nextUrls = {};
        const nextResults = {};

        for (const existingUrl in urls)
            nextUrls[existingUrl] = urls[existingUrl];

        for (const existingResult in results)
            nextResults[existingResult] = results[existingResult];

        if (url && url !== "") {
            nextUrls[key] = url;
            nextResults[key] = result;
        }

        urls = nextUrls;
        results = nextResults;
        pendingCount = Math.max(0, pendingCount - 1);

        if (pendingCount === 0) {
            ready = true;
            prepared(snapshotGeneration);
        }
    }

    function snapshotUrl(screen) {
        const key = screenKey(screen);
        return urls[key] || "";
    }
}
