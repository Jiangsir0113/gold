import datetime
import pytest
from api.pnl import calculate_summary


def make_tx(type_, grams, price, fee=0.0, date_offset=0, id_=1):
    return {
        "id": id_,
        "date": datetime.date(2026, 1, 1 + date_offset),
        "type": type_,
        "grams": grams,
        "price_per_g": price,
        "fee": fee,
    }


def test_single_buy_no_sell():
    txs = [make_tx("buy", 10.0, 700.0, fee=5.0)]
    result = calculate_summary(txs, current_price=750.0)
    # 均价 = (10*700 + 5) / 10 = 700.5
    assert abs(result["avg_cost_per_g"] - 700.5) < 0.01
    assert result["total_grams"] == 10.0
    # 浮动盈亏 = (750 - 700.5) * 10 = 495
    assert abs(result["unrealized_pnl"] - 495.0) < 0.01
    assert result["realized_pnl"] == 0.0
    # 浮动盈亏率 = (750 - 700.5) / 700.5 * 100 ≈ 7.07%
    assert abs(result["unrealized_pnl_pct"] - 7.07) < 0.1


def test_buy_then_partial_sell():
    txs = [
        make_tx("buy", 10.0, 700.0, fee=5.0, date_offset=0, id_=1),
        make_tx("sell", 5.0, 750.0, fee=3.0, date_offset=1, id_=2),
    ]
    result = calculate_summary(txs, current_price=760.0)
    avg = (10 * 700 + 5) / 10  # 700.5
    # 已实现盈亏 = 5 * (750 - 700.5) - 3 = 247.5 - 3 = 244.5
    assert abs(result["realized_pnl"] - 244.5) < 0.01
    # 剩余持仓 5 克，均价不变
    assert result["total_grams"] == 5.0
    assert abs(result["avg_cost_per_g"] - avg) < 0.01


def test_position_reset_then_rebuy():
    """持仓清零后再买入，均价重新计算"""
    txs = [
        make_tx("buy", 10.0, 700.0, date_offset=0, id_=1),
        make_tx("sell", 10.0, 720.0, date_offset=1, id_=2),   # 清零
        make_tx("buy", 5.0, 800.0, fee=4.0, date_offset=2, id_=3),  # 重新开仓
    ]
    result = calculate_summary(txs, current_price=850.0)
    # 新均价 = (5*800 + 4) / 5 = 800.8
    assert abs(result["avg_cost_per_g"] - 800.8) < 0.01
    assert result["total_grams"] == 5.0
    # 第一轮已实现盈亏 = 10 * (720 - 700) = 200
    assert abs(result["realized_pnl"] - 200.0) < 0.01


def test_empty_transactions():
    result = calculate_summary([], current_price=750.0)
    assert result["total_grams"] == 0.0
    assert result["unrealized_pnl"] == 0.0
    assert result["avg_cost_per_g"] == 0.0


def test_loss_scenario():
    """当前价低于均价时，浮动盈亏为负"""
    txs = [make_tx("buy", 10.0, 700.0, fee=5.0, id_=1)]
    result = calculate_summary(txs, current_price=680.0)
    avg = 700.5
    # 浮动亏损 = (680 - 700.5) * 10 = -205
    assert abs(result["unrealized_pnl"] - (-205.0)) < 0.01
    assert result["unrealized_pnl_pct"] < 0


def test_oversell_raises():
    """卖出超过持仓克数时应抛出 ValueError"""
    txs = [
        make_tx("buy", 3.0, 700.0, id_=1),
        make_tx("sell", 5.0, 750.0, id_=2, date_offset=1),
    ]
    with pytest.raises(ValueError, match="exceeds holding"):
        calculate_summary(txs, current_price=750.0)
