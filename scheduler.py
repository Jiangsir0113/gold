import json
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from config import SCRAPE_INTERVAL_SECONDS
from scrapers.au9999 import get_au9999
from scrapers.xauusd import get_xauusd
from scrapers.usdcny import get_usdcny
from redis_client import save_current_price, append_price_history, get_current_price

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

# 所有连接的 WebSocket 客户端
connected_clients: set = set()


async def scrape_and_broadcast() -> None:
    """爬取所有数据，存入 Redis，广播到 WebSocket 客户端"""
    results = {}
    try:
        results["au9999"] = await get_au9999()
    except Exception as e:
        logger.error(f"AU9999 scrape failed: {e}")

    try:
        results["xauusd"] = await get_xauusd()
    except Exception as e:
        logger.error(f"XAU/USD scrape failed: {e}")

    try:
        results["usdcny"] = await get_usdcny()
    except Exception as e:
        logger.error(f"USD/CNY scrape failed: {e}")

    # 写入 Redis
    for symbol, data in results.items():
        await save_current_price(symbol, data)

    # 追加历史（仅价格品种，不含汇率）
    for symbol in ("au9999", "xauusd"):
        if symbol in results:
            await append_price_history(symbol, results[symbol]["price"])

    # 广播到所有 WebSocket 客户端
    if connected_clients and results:
        message = json.dumps({"type": "price_update", "data": results})
        dead = set()
        for ws in connected_clients:
            try:
                await ws.send_text(message)
            except Exception as e:
                logger.debug("WebSocket send failed, removing client: %s", e)
                dead.add(ws)
        connected_clients.difference_update(dead)


def start_scheduler() -> None:
    scheduler.add_job(
        scrape_and_broadcast,
        "interval",
        seconds=SCRAPE_INTERVAL_SECONDS,
        id="price_scrape",
        max_instances=1,
    )
    scheduler.add_job(
        save_daily_snapshot,
        "cron",
        hour=15, minute=30,
        timezone="Asia/Shanghai",
        id="daily_snapshot",
        max_instances=1,
    )
    scheduler.start()


async def save_daily_snapshot() -> None:
    """每日 15:30（上海黄金交易所收盘）记录当天持仓快照"""
    import datetime
    from database import SessionLocal
    from models import Transaction, DailySnapshot
    from api.pnl import calculate_summary

    db = SessionLocal()
    try:
        txs = db.query(Transaction).all()
        tx_dicts = [
            {"id": t.id, "date": t.date, "type": t.type,
             "grams": t.grams, "price_per_g": t.price_per_g, "fee": t.fee}
            for t in txs
        ]
        price_data = await get_current_price("au9999")
        if not price_data:
            logger.warning("save_daily_snapshot: no AU9999 price in Redis, skipping snapshot")
            return
        current_price = price_data["price"]
        summary = calculate_summary(tx_dicts, current_price)

        today = datetime.datetime.now(tz=datetime.timezone(datetime.timedelta(hours=8))).date()
        existing = db.query(DailySnapshot).filter(DailySnapshot.date == today).first()
        if existing:
            existing.grams = summary["total_grams"]
            existing.price_per_g = current_price
            existing.market_value = summary["market_value"]
        else:
            snapshot = DailySnapshot(
                date=today,
                grams=summary["total_grams"],
                price_per_g=current_price,
                market_value=summary["market_value"],
            )
            db.add(snapshot)
        db.commit()
    finally:
        db.close()


def stop_scheduler() -> None:
    scheduler.shutdown(wait=False)
