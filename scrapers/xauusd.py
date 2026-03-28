"""
XAU/USD 伦敦金爬虫
主源：新浪财经
备用：东方财富
"""
import re
import json
import datetime
from scrapers.base import fetch

PRIMARY_URL = "https://hq.sinajs.cn/list=hf_XAU"
BACKUP_URL = "https://push2.eastmoney.com/api/qt/stock/get?secid=0.GC00Y&fields=f43,f169,f170"


async def get_xauusd() -> dict:
    try:
        return await _from_sina()
    except Exception:
        return await _from_eastmoney()


async def _from_sina() -> dict:
    text = await fetch(PRIMARY_URL, headers={"Referer": "https://finance.sina.com.cn/"})
    match = re.search(r'"([^"]+)"', text)
    if not match:
        raise ValueError("Sina XAU parse error")
    parts = match.group(1).split(",")
    price = float(parts[0])
    close_prev = float(parts[1])
    change = round(price - close_prev, 2)
    change_pct = round(change / close_prev * 100, 4) if close_prev else 0.0
    return {
        "price": price,
        "change": change,
        "change_pct": change_pct,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }


async def _from_eastmoney() -> dict:
    text = await fetch(BACKUP_URL, headers={"Referer": "https://www.eastmoney.com/"})
    data = json.loads(text)
    d = data["data"]
    price = d["f43"] / 100
    change = d["f169"] / 100
    change_pct = d["f170"] / 100
    return {
        "price": price,
        "change": change,
        "change_pct": change_pct,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
