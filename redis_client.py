import datetime
import json
import time
from typing import Optional
import redis.asyncio as aioredis
from config import REDIS_URL, PRICE_TTL_SECONDS, HISTORY_TTL_SECONDS

_redis: Optional[aioredis.Redis] = None


async def init_redis() -> None:
    global _redis
    _redis = aioredis.from_url(REDIS_URL, decode_responses=True)


async def close_redis() -> None:
    global _redis
    if _redis:
        await _redis.aclose()
        _redis = None


def get_redis() -> aioredis.Redis:
    if _redis is None:
        raise RuntimeError("Redis not initialized. Call init_redis() at startup.")
    return _redis


async def save_current_price(symbol: str, data: dict) -> None:
    r = get_redis()
    await r.set(f"price:current:{symbol}", json.dumps(data), ex=PRICE_TTL_SECONDS)


async def get_current_price(symbol: str) -> Optional[dict]:
    r = get_redis()
    raw = await r.get(f"price:current:{symbol}")
    return json.loads(raw) if raw else None


async def append_price_history(symbol: str, price: float) -> None:
    """将当前价格追加到当日历史 Sorted Set，score 为 Unix 时间戳"""
    r = get_redis()
    today = datetime.date.today().isoformat()
    key = f"price_history:{symbol}:{today}"
    ts = int(time.time())
    entry = json.dumps({"price": price, "ts": ts})
    async with r.pipeline() as pipe:
        await pipe.zadd(key, {entry: ts})
        await pipe.expire(key, HISTORY_TTL_SECONDS)
        await pipe.execute()


async def get_price_history(symbol: str) -> list[dict]:
    """获取当日价格历史，按时间升序"""
    r = get_redis()
    today = datetime.date.today().isoformat()
    key = f"price_history:{symbol}:{today}"
    items = await r.zrange(key, 0, -1)
    return [json.loads(item) for item in items]
