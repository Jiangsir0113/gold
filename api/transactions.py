import csv
import io
import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session
from database import get_db
from models import Transaction, DailySnapshot
from auth import require_api_key
from redis_client import get_current_price
from api.pnl import calculate_summary

router = APIRouter(dependencies=[Depends(require_api_key)])


class TransactionIn(BaseModel):
    date: datetime.date
    type: str
    grams: float
    price_per_g: float
    fee: float = 0.0
    note: str | None = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v):
        if v not in ("buy", "sell"):
            raise ValueError("type must be 'buy' or 'sell'")
        return v

    @field_validator("grams", "price_per_g")
    @classmethod
    def validate_positive(cls, v):
        if v <= 0:
            raise ValueError("must be positive")
        return v


def _tx_to_dict(tx: Transaction) -> dict:
    return {
        "id": tx.id,
        "date": tx.date.isoformat(),
        "type": tx.type,
        "grams": tx.grams,
        "price_per_g": tx.price_per_g,
        "fee": tx.fee,
        "note": tx.note,
        "created_at": tx.created_at.isoformat() if tx.created_at else None,
    }


@router.get("/api/transactions")
def list_transactions(db: Session = Depends(get_db)):
    txs = db.query(Transaction).order_by(Transaction.date.desc(), Transaction.id.desc()).all()
    return [_tx_to_dict(t) for t in txs]


@router.post("/api/transactions", status_code=status.HTTP_201_CREATED)
def create_transaction(body: TransactionIn, db: Session = Depends(get_db)):
    tx = Transaction(**body.model_dump())
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return _tx_to_dict(tx)


# 注意：/export 必须在 /{tx_id} 之前注册，否则 FastAPI 会将 "export" 当作 int 参数解析导致 422
@router.get("/api/transactions/export")
def export_csv(db: Session = Depends(get_db)):
    txs = db.query(Transaction).order_by(Transaction.date.asc()).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "date", "type", "grams", "price_per_g", "fee", "note"])
    for tx in txs:
        writer.writerow([tx.id, tx.date, tx.type, tx.grams, tx.price_per_g, tx.fee, tx.note or ""])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=transactions.csv"},
    )


@router.put("/api/transactions/{tx_id}")
def update_transaction(tx_id: int, body: TransactionIn, db: Session = Depends(get_db)):
    tx = db.get(Transaction, tx_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    for k, v in body.model_dump().items():
        setattr(tx, k, v)
    db.commit()
    db.refresh(tx)
    return _tx_to_dict(tx)


@router.delete("/api/transactions/{tx_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(tx_id: int, db: Session = Depends(get_db)):
    tx = db.get(Transaction, tx_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    db.delete(tx)
    db.commit()


@router.get("/api/summary")
async def get_summary(db: Session = Depends(get_db)):
    txs = db.query(Transaction).all()
    tx_dicts = [_tx_to_dict(t) for t in txs]
    for t in tx_dicts:
        t["date"] = datetime.date.fromisoformat(t["date"])

    price_data = await get_current_price("au9999")
    current_price = price_data["price"] if price_data else 0.0
    return calculate_summary(tx_dicts, current_price)


@router.get("/api/summary/history")
def get_summary_history(db: Session = Depends(get_db)):
    snapshots = db.query(DailySnapshot).order_by(DailySnapshot.date.asc()).all()
    return [
        {"date": s.date.isoformat(), "grams": s.grams,
         "price_per_g": s.price_per_g, "market_value": s.market_value}
        for s in snapshots
    ]
