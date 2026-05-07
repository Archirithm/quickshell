.pragma library

function getRelativeTime(timestampMs) {
    if (!timestampMs) return "刚刚";

    var now = Date.now();
    var diffSeconds = Math.floor((now - timestampMs) / 1000);

    if (diffSeconds < 60) {
        return "刚刚";
    }

    var diffMinutes = Math.floor(diffSeconds / 60);
    if (diffMinutes < 60) {
        return diffMinutes + "分钟以前";
    }

    var diffHours = Math.floor(diffMinutes / 60);
    if (diffHours < 24) {
        return diffHours + "小时之前";
    }

    return "超过一天";
}
