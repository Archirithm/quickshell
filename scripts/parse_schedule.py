#!/usr/bin/env python3
import json
import os

# 配置路径
OBSIDIAN_MD = "/home/archirithm/Documents/Obsidian Vault/kebiao.md"
CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "schedule.json")


def parse_markdown():
    if not os.path.exists(OBSIDIAN_MD):
        print(f"找不到 Obsidian 课表文件: {OBSIDIAN_MD}")
        return None

    with open(OBSIDIAN_MD, "r", encoding="utf-8") as f:
        lines = f.readlines()

    grid = []
    for line in lines:
        line = line.strip()
        if not line.startswith("|"):
            continue
        # 清理首尾的竖线并分割单元格，同时去掉 markdown 的粗体星号
        if line.startswith("|"):
            line = line[1:]
        if line.endswith("|"):
            line = line[:-1]
        cols = [col.strip().replace("**", "") for col in line.split("|")]
        grid.append(cols)

    # 至少要有：表头、分割线、至少一行数据
    if len(grid) < 3:
        return None

    body = grid[2:]
    rows = len(body)
    cols = len(body[0]) if rows > 0 else 0

    time_headers = []
    parsed_items = []

    # 记录是否已经被上方的合并单元格占据
    skip = [[False] * cols for _ in range(rows)]

    # 提取第 0 列作为左侧固定的时间段
    for r in range(rows):
        if len(body[r]) > 0:
            time_headers.append(body[r][0])

    # 遍历星期一到星期日的课程
    for c in range(1, cols):
        for r in range(rows):
            if skip[r][c]:
                continue

            text = body[r][c] if c < len(body[r]) else ""
            row_span = 1

            # 如果不是空课，检查下方是否有连上的课（同一列名称相同），进行合并
            if text != "":
                while (
                    r + row_span < rows
                    and c < len(body[r + row_span])
                    and body[r + row_span][c] == text
                ):
                    skip[r + row_span][c] = True
                    row_span += 1

            parsed_items.append(
                {
                    "row": r,
                    "col": c - 1,  # 将星期一变成第 0 列
                    "rowSpan": row_span,
                    "text": text,
                    "isEmpty": (text == ""),
                }
            )

    return {"timeHeaders": time_headers, "scheduleItems": parsed_items}


def main():
    os.makedirs(CACHE_DIR, exist_ok=True)
    data = parse_markdown()

    if data:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False)
        print(f"✅ 课表解析成功！JSON 已保存至: {CACHE_FILE}")
    else:
        print("❌ 解析失败，请检查 Markdown 格式。")


if __name__ == "__main__":
    main()
