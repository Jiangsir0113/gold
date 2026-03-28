from typing import Any


def calculate_summary(transactions: list[dict], current_price: float) -> dict:
    """
    按时间顺序（date + id 升序）遍历交易记录，使用加权均价法计算持仓汇总。
    卖出不改变加权均价；持仓归零后均价重置为 0。
    """
    total_grams = 0.0
    avg_cost = 0.0       # 加权均价（元/克，含买入手续费分摊）
    realized_pnl = 0.0

    sorted_txs = sorted(transactions, key=lambda t: (t["date"], t["id"]))

    for tx in sorted_txs:
        if tx["type"] == "buy":
            cost_new = tx["grams"] * tx["price_per_g"] + tx["fee"]
            cost_existing = total_grams * avg_cost
            total_grams += tx["grams"]
            avg_cost = (cost_existing + cost_new) / total_grams
        elif tx["type"] == "sell":
            pnl = tx["grams"] * (tx["price_per_g"] - avg_cost) - tx["fee"]
            realized_pnl += pnl
            total_grams -= tx["grams"]
            if total_grams <= 1e-9:   # 浮点保护：视为清零
                total_grams = 0.0
                avg_cost = 0.0

    market_value = total_grams * current_price
    unrealized_pnl = (current_price - avg_cost) * total_grams if total_grams > 0 else 0.0
    unrealized_pnl_pct = (unrealized_pnl / (avg_cost * total_grams) * 100) if total_grams > 0 and avg_cost > 0 else 0.0

    return {
        "total_grams": round(total_grams, 4),
        "avg_cost_per_g": round(avg_cost, 4),
        "current_price": current_price,
        "market_value": round(market_value, 2),
        "unrealized_pnl": round(unrealized_pnl, 2),
        "unrealized_pnl_pct": round(unrealized_pnl_pct, 4),
        "realized_pnl": round(realized_pnl, 2),
        "total_pnl": round(unrealized_pnl + realized_pnl, 2),
    }
