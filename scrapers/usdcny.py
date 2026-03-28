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
    price = float(parts[0])
    return {
        "price": price,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
