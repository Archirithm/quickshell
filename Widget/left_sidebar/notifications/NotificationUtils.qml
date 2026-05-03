import QtQuick

QtObject {
    function findSuitableMaterialSymbol(summary = "") {
        const lowerSummary = summary.toLowerCase();
        const keywordsToTypes = {
            "reboot": "restart_alt",
            "record": "screen_record",
            "battery": "power",
            "power": "power_settings_new",
            "screenshot": "screenshot_monitor",
            "welcome": "waving_hand",
            "time": "schedule",
            "installed": "download",
            "configuration reloaded": "reset_wrench",
            "unable": "question_mark",
            "couldn't": "question_mark",
            "config": "reset_wrench",
            "update": "update",
            "ai response": "neurology",
            "control": "settings",
            "music": "queue_music",
            "install": "deployed_code_update",
            "input": "keyboard_alt",
            "preedit": "keyboard_alt",
            "file": "folder_copy"
        };

        for (const [keyword, icon] of Object.entries(keywordsToTypes)) {
            if (lowerSummary.includes(keyword))
                return icon;
        }
        return "chat";
    }

    function getFriendlyNotifTimeString(timestamp) {
        if (!timestamp)
            return "";

        const messageTime = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - messageTime.getTime();
        if (diffMs < 60000)
            return "Now";

        if (messageTime.toDateString() === now.toDateString()) {
            const diffMinutes = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);
            return diffHours > 0 ? `${diffHours}h` : `${diffMinutes}m`;
        }

        if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
            return "Yesterday";

        return Qt.formatDateTime(messageTime, "MMMM dd");
    }

    function processNotificationBody(body, appName) {
        let processedBody = body || "";
        if (appName) {
            const lowerApp = appName.toLowerCase();
            const chromiumBrowsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"];
            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = processedBody.split("\n\n");
                if (lines.length > 1 && lines[0].startsWith("<a"))
                    processedBody = lines.slice(1).join("\n\n");
            }
        }
        return processedBody.replace(/<img/gi, "\n\n<img");
    }
}
