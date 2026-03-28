import json
import time
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from redis_client import save_current_price, get_current_price, append_price_history, get_price_history


def make_mock_redis():
    """创建完整的 async Redis mock"""
    mock = MagicMock()
    mock.set = AsyncMock()
    mock.get = AsyncMock(return_value=None)
    mock.zadd = AsyncMock()
    mock.expire = AsyncMock()
    mock.zrange = AsyncMock(return_value=[])
    return mock


@pytest.mark.asyncio
async def test_save_and_get_current_price():
    """save_current_price 写入后 get_current_price 能读回相同数据"""
    data = {"price": 765.50, "change": 2.30, "change_pct": 0.30, "updated_at": "2026-03-28T10:00:00"}
    mock_redis = make_mock_redis()
    mock_redis.get = AsyncMock(return_value=json.dumps(data))

    with patch("redis_client.get_redis", return_value=mock_redis):
        await save_current_price("au9999", data)
        result = await get_current_price("au9999")

    assert result["price"] == 765.50
    assert result["change_pct"] == 0.30
    mock_redis.set.assert_called_once()


@pytest.mark.asyncio
async def test_get_current_price_returns_none_when_missing():
    mock_redis = make_mock_redis()

    with patch("redis_client.get_redis", return_value=mock_redis):
        result = await get_current_price("au9999")

    assert result is None


@pytest.mark.asyncio
async def test_append_price_history_writes_sorted_set():
    mock_redis = make_mock_redis()

    with patch("redis_client.get_redis", return_value=mock_redis):
        await append_price_history("au9999", 765.50)

    mock_redis.zadd.assert_called_once()
    mock_redis.expire.assert_called_once()
    # 验证写入的 key 格式正确
    call_args = mock_redis.zadd.call_args
    assert "price_history:au9999:" in call_args[0][0]


@pytest.mark.asyncio
async def test_get_price_history_returns_parsed_list():
    entry = json.dumps({"price": 765.50, "ts": 1743120000})
    mock_redis = make_mock_redis()
    mock_redis.zrange = AsyncMock(return_value=[entry])

    with patch("redis_client.get_redis", return_value=mock_redis):
        result = await get_price_history("au9999")

    assert len(result) == 1
    assert result[0]["price"] == 765.50
