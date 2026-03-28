import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from api.transactions import router as transactions_router
from database import engine, Base

# Create a test app without the Redis/scheduler lifespan
test_app = FastAPI()
test_app.include_router(transactions_router)

Base.metadata.create_all(bind=engine)
client = TestClient(test_app)
HEADERS = {"X-API-Key": "test-key"}
BUY_PAYLOAD = {"date": "2026-03-28", "type": "buy", "grams": 10.0, "price_per_g": 700.0, "fee": 5.0, "note": "首次买入"}


@pytest.fixture(autouse=True)
def clean_db():
    """每个测试前清空相关表"""
    from sqlalchemy import text
    from database import engine
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM transactions"))
        conn.execute(text("DELETE FROM daily_snapshots"))
        conn.commit()
    yield


def _create_tx(payload=None):
    with patch("auth.API_KEY", "test-key"):
        resp = client.post("/api/transactions", json=payload or BUY_PAYLOAD, headers=HEADERS)
    assert resp.status_code == 201
    return resp.json()


def test_create_transaction():
    data = _create_tx()
    assert data["grams"] == 10.0
    assert data["type"] == "buy"
    assert data["fee"] == 5.0


def test_list_transactions():
    _create_tx()
    with patch("auth.API_KEY", "test-key"):
        resp = client.get("/api/transactions", headers=HEADERS)
    assert resp.status_code == 200
    assert len(resp.json()) == 1


def test_update_transaction():
    tx = _create_tx()
    updated = {**BUY_PAYLOAD, "grams": 20.0, "note": "修改后"}
    with patch("auth.API_KEY", "test-key"):
        resp = client.put(f"/api/transactions/{tx['id']}", json=updated, headers=HEADERS)
    assert resp.status_code == 200
    assert resp.json()["grams"] == 20.0
    assert resp.json()["note"] == "修改后"


def test_delete_transaction():
    tx = _create_tx()
    with patch("auth.API_KEY", "test-key"):
        resp = client.delete(f"/api/transactions/{tx['id']}", headers=HEADERS)
    assert resp.status_code == 204


def test_export_csv_returns_csv_content():
    _create_tx()
    with patch("auth.API_KEY", "test-key"):
        resp = client.get("/api/transactions/export", headers=HEADERS)
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    lines = resp.text.strip().split("\n")
    assert lines[0].startswith("id,date,type")  # CSV 表头
    assert len(lines) == 2  # 表头 + 1条记录


def test_get_summary_empty():
    # get_current_price 是 async 函数，必须用 AsyncMock
    with patch("auth.API_KEY", "test-key"):
        with patch("api.transactions.get_current_price", new=AsyncMock(return_value={"price": 750.0})):
            resp = client.get("/api/summary", headers=HEADERS)
    assert resp.status_code == 200
    assert resp.json()["total_grams"] == 0.0
    assert resp.json()["unrealized_pnl"] == 0.0
