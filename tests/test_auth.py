import pytest
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient
from auth import require_api_key
from unittest.mock import patch

app = FastAPI()

@app.get("/test")
async def test_endpoint(key=Depends(require_api_key)):
    return {"ok": True}

client = TestClient(app)

def test_missing_api_key_returns_401():
    resp = client.get("/test")
    assert resp.status_code == 401

def test_wrong_api_key_returns_401():
    with patch("auth.API_KEY", "correct-key"):
        resp = client.get("/test", headers={"X-API-Key": "wrong-key"})
    assert resp.status_code == 401

def test_correct_api_key_passes():
    with patch("auth.API_KEY", "correct-key"):
        resp = client.get("/test", headers={"X-API-Key": "correct-key"})
    assert resp.status_code == 200

def test_empty_api_key_returns_401():
    with patch("auth.API_KEY", "correct-key"):
        resp = client.get("/test", headers={"X-API-Key": ""})
    assert resp.status_code == 401
