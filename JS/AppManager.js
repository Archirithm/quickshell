.pragma library

function fuzzySearch(inputText, appName) {
    let lowerInput = inputText.toLowerCase();
    let lowerName = appName.toLowerCase();
    let inputIndex = 0;

    for (let i = 0; i < lowerName.length; i++) {
        if (lowerName[i] === lowerInput[inputIndex]) {
            inputIndex++;
        }
        if (inputIndex === lowerInput.length) {
            return true;
        }
    }
    return false;
}

function updateFilter(inputText, DesktopEntries) {
    let lowerInput = (inputText || "").toLowerCase();
    // 获取原生异步列表
    const apps = DesktopEntries.applications.values;
    let filterApps = [];

    if (lowerInput === "") {
        filterApps = apps;
    } else {
        filterApps = apps.filter((app) => fuzzySearch(lowerInput, app.name));
    }

    // 1. 过滤掉不可见的后台挂件
    filterApps = filterApps.filter(app => !app.noDisplay);

    // 2. 【核心修复】：强制按首字母 A-Z 排序，彻底解决每次重启顺序不一样的问题！
    filterApps.sort((a, b) => {
        let nameA = a.name ? a.name.toLowerCase() : "";
        let nameB = b.name ? b.name.toLowerCase() : "";
        if (nameA < nameB) return -1;
        if (nameA > nameB) return 1;
        return 0;
    });

    let result = [];
    for (let i = 0; i < filterApps.length; i++) {
        let app = filterApps[i];
        
        result.push({
            name: app.name,
            icon: app.icon || "",
            appObj: app 
        });
        
        // 渲染性能保护：最多显示 50 个
        if (result.length >= 50) break;
    }

    return result;
}
