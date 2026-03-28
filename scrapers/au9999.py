"""
AU9999 国内现货金价爬虫
主源：东方财富 行情接口（JSON）
备用：新浪财经
"""
import json
import re
import datetime
import logging
from scrapers.base import fetch

logger = logging.getLogger(__name__)

PRIMARY_URL = "https://push2.eastmoney.com/api/qt/stock/get?secid=0.Au9999&fields=f43,f169,f170"
BACKUP_URL = "https://hq.sinajs.cn/list=Au9999"


async def get_au9999() -> dict:
    """返回 {price, change, change_pct, updated_at}，失败时抛出异常"""
    try:
        return await _from_eastmoney()
    except Exception as exc:
        logger.warning("au9999 primary source failed (%s), trying backup", exc)
        return await _from_sina()


async def _from_eastmoney() -> dict:
    text = await fetch(PRIMARY_URL, headers={"Referer": "https://www.eastmoney.com/"})
    data = json.loads(text)
    d = data["data"]
    price = d["f43"] / 100        # 东方财富价格放大了100倍
    change = d["f169"] / 100
    change_pct = d["f170"] / 100
    return {
        "price": price,
        "change": change,
        "change_pct": change_pct,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }


async def _from_sina() -> dict:
    text = await fetch(BACKUP_URL, headers={"Referer": "https://finance.sina.com.cn/"})
    # 新浪格式：var hq_str_Au9999="Au9999,价格,涨跌,...";
    match = re.search(r'"([^"]+)"', text)
    if not match:
        raise ValueError("Sina Au9999 parse error")
    parts = match.group(1).split(",")
    price = float(parts[1])
    change = float(parts[2])
    change_pct = float(parts[3].rstrip("%"))
    return {
        "price": price,
        "change": change,
        "change_pct": change_pct,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
