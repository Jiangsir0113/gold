import os
from dotenv import load_dotenv

load_dotenv()

API_KEY: str = os.environ["API_KEY"]
REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./gold.db")
SCRAPE_INTERVAL_SECONDS: int = int(os.getenv("SCRAPE_INTERVAL_SECONDS", "60"))
PRICE_TTL_SECONDS: int = 300        # 5 分钟，过期即视为数据陈旧
HISTORY_TTL_SECONDS: int = 90000    # 25 小时
