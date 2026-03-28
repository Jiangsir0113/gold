import datetime
from sqlalchemy import Integer, Float, Text, Date, DateTime, func, CheckConstraint, text
from sqlalchemy.orm import Mapped, mapped_column
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("type IN ('buy', 'sell')", name="ck_transactions_type"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    date: Mapped[datetime.date] = mapped_column(Date, nullable=False, index=True)
    type: Mapped[str] = mapped_column(Text, nullable=False)       # 'buy' | 'sell'
    grams: Mapped[float] = mapped_column(Float, nullable=False)
    price_per_g: Mapped[float] = mapped_column(Float, nullable=False)
    fee: Mapped[float] = mapped_column(Float, nullable=False, default=0.0, server_default=text("0.0"))
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, server_default=func.now()
    )


class DailySnapshot(Base):
    __tablename__ = "daily_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    date: Mapped[datetime.date] = mapped_column(Date, nullable=False, unique=True)
    grams: Mapped[float] = mapped_column(Float, nullable=False)
    price_per_g: Mapped[float] = mapped_column(Float, nullable=False)
    market_value: Mapped[float] = mapped_column(Float, nullable=False)
