"""
USD/CNY 汇率爬虫
主源：新浪财经外汇
"""
import re
import datetime
from scrapers.base import fetch

PRIMARY_URL = "https://hq.sinajs.cn/list=fx_susdcny"


async def get_usdcny() -> dict:
    text = await fetch(PRIMARY_URL, headers={"Referer": "https://finance.sina.com.cn/"})
    match = re.search(r'"([^"]+)"', text)
    if not match:
        raise ValueError("Sina USD/CNY parse error")
    parts = match.group(1).split(",")
    # 新浪汇率格式: 时间,买入价,卖出价,中间价,...
    if len(parts) < 4:
        raise ValueError(f"Sina USD/CNY unexpected format: {match.group(1)!r}")
    price = float(parts[3])
    return {
        "price": price,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
