from contextlib import asynccontextmanager
from fastapi import FastAPI
from database import init_db
from redis_client import init_redis, close_redis
from scheduler import start_scheduler, stop_scheduler
from api.prices import router as prices_router
from api.transactions import router as transactions_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动
    init_db()
    await init_redis()
    start_scheduler()
    yield
    # 关闭
    stop_scheduler()
    await close_redis()


app = FastAPI(title="Gold Tracker API", lifespan=lifespan)
app.include_router(prices_router)
app.include_router(transactions_router)
