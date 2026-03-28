# api/prices.py
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from auth import require_api_key
from redis_client import get_current_price, get_price_history
from scheduler import connected_clients

router = APIRouter()


@router.websocket("/ws/prices")
async def ws_prices(websocket: WebSocket):
    """实时价格 WebSocket。握手时验证 X-API-Key query 参数"""
    api_key = websocket.query_params.get("api_key", "")
    from config import API_KEY
    if api_key != API_KEY:
        await websocket.close(code=1008)  # Policy Violation
        return

    await websocket.accept()
    connected_clients.add(websocket)

    # 连接后立即推送当前价格
    data = {}
    for symbol in ("au9999", "xauusd", "usdcny"):
        price = await get_current_price(symbol)
        if price:
            data[symbol] = price
    if data:
        await websocket.send_text(json.dumps({"type": "price_update", "data": data}))

    try:
        while True:
            await websocket.receive_text()  # 保持连接
    except WebSocketDisconnect:
        connected_clients.discard(websocket)


@router.get("/api/prices/latest", dependencies=[Depends(require_api_key)])
async def get_latest_prices():
    """HTTP fallback：获取最新价格"""
    result = {}
    for symbol in ("au9999", "xauusd", "usdcny"):
        data = await get_current_price(symbol)
        if data:
            result[symbol] = data
    return result


@router.get("/api/prices/history", dependencies=[Depends(require_api_key)])
async def get_history(symbol: str = "au9999"):
    """获取当日价格历史（用于走势图）"""
    if symbol not in ("au9999", "xauusd"):
        return {"error": "symbol must be au9999 or xauusd"}
    items = await get_price_history(symbol)
    return {"symbol": symbol, "history": items}
