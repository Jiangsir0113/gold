import pytest
from unittest.mock import AsyncMock, patch
from scrapers.au9999 import _from_eastmoney, get_au9999
from scrapers.usdcny import get_usdcny
from scrapers.xauusd import _from_sina as xauusd_from_sina, get_xauusd


@pytest.mark.asyncio
async def test_au9999_eastmoney_success():
    """东方财富主源解析成功"""
    mock_response = '{"data":{"f43":76550,"f169":230,"f170":30}}'
    with patch("scrapers.au9999.fetch", new=AsyncMock(return_value=mock_response)):
        result = await _from_eastmoney()
    assert result["price"] == 765.50
    assert result["change"] == 2.30


@pytest.mark.asyncio
async def test_au9999_falls_back_to_sina():
    """东方财富失败时切换到新浪"""
    sina_result = {"price": 765.50, "change": 2.30, "change_pct": 0.30, "updated_at": "2026-03-28T10:00:00"}
    with patch("scrapers.au9999._from_eastmoney", side_effect=Exception("network error")):
        with patch("scrapers.au9999._from_sina", new=AsyncMock(return_value=sina_result)):
            result = await get_au9999()
    assert result["price"] == 765.50


@pytest.mark.asyncio
async def test_usdcny_parses_correctly():
    mock_response = 'var hq_str_fx_susdcny="7.2531,...";\n'
    with patch("scrapers.usdcny.fetch", new=AsyncMock(return_value=mock_response)):
        result = await get_usdcny()
    assert result["price"] == 7.2531


@pytest.mark.asyncio
async def test_xauusd_sina_success():
    """新浪主源 XAU/USD 解析成功"""
    # price=3012.50, close_prev=3013.70 → change = -1.20, change_pct = -0.0398...%
    mock_response = 'var hq_str_hf_XAU="3012.50,3013.70,...";\n'
    with patch("scrapers.xauusd.fetch", new=AsyncMock(return_value=mock_response)):
        result = await xauusd_from_sina()
    assert result["price"] == 3012.50
    assert abs(result["change"] - (-1.20)) < 0.01


@pytest.mark.asyncio
async def test_au9999_sina_parses_correctly():
    """新浪备用源 AU9999 解析成功"""
    mock_response = 'var hq_str_Au9999="Au9999,765.50,2.30,0.30%,...";\n'
    from scrapers.au9999 import _from_sina as au9999_from_sina
    with patch("scrapers.au9999.fetch", new=AsyncMock(return_value=mock_response)):
        result = await au9999_from_sina()
    assert result["price"] == 765.50
    assert result["change"] == 2.30
