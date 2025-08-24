import os
import time
import json
import logging
from typing import Dict, Any
from contextlib import asynccontextmanager

import asyncio
import aiohttp
import asyncpg
import jwt
from dotenv import load_dotenv
from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from redis.asyncio import Redis
from web3 import AsyncWeb3, AsyncHTTPProvider

# -----------------------------
# 环境/日志
# -----------------------------
load_dotenv()
INFURA_KEY = os.getenv("INFURA_KEY")
SECRET_KEY = os.getenv("SECRET_KEY")
DATA_DIR = os.getenv("DATA_DIR", "/app/data")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")  # 在 docker-compose 网络中用服务名连接

db_user = os.getenv("POSTGRES_USER", "lzh")
db_pass = os.getenv("POSTGRES_PASSWORD", "")
db_name = os.getenv("POSTGRES_DB", "blockchain_db")
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "5432")

DATABASE_URL = os.getenv("DATABASE_URL", f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}")


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# -----------------------------
# 全局资源
# -----------------------------
db_pool: asyncpg.Pool | None = None
redis_client: Redis | None = None
web3_clients: dict[str, AsyncWeb3] = {}

# 正确的 Infura HTTP 入口
INFURA_HTTP = {
    "ethereum": f"https://mainnet.infura.io/v3/{INFURA_KEY}",            # 以太坊主网
    "polygon":  f"https://polygon-mainnet.infura.io/v3/{INFURA_KEY}",    # Polygon 主网
}

# 极简 ERC20 ABI（balanceOf）
ERC20_ABI: list[Dict[str, Any]] = [
    {
        "constant": True,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function",
    }
]

# 批量 RPC 的 HTTP session（长连接，降延迟）
http_session: aiohttp.ClientSession | None = None
RPC_TIMEOUT = aiohttp.ClientTimeout(total=1.2)

# SWR 缓存参数
FRESH_TTL = 10        # 新鲜缓存（直接返回）
STALE_TTL = 120       # 允许返回陈旧值的最长时间
CACHE_KEY_FMT = "web3:{chain}:{addr}"
CACHE_TS_FMT  = "web3ts:{chain}:{addr}"

# -----------------------------
# FastAPI app & lifespan
# -----------------------------
app = FastAPI()
security = HTTPBearer()

@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_pool, redis_client, web3_clients, http_session

    # DB 连接池
    db_pool = await asyncpg.create_pool(dsn=DATABASE_URL, min_size=1, max_size=10)

    # Redis（decode_responses 便于 JSON 处理）
    redis_client = Redis.from_url(REDIS_URL, decode_responses=True)
    try:
        await redis_client.ping()
        logger.info("Redis ping OK.")
    except Exception as e:
        logger.error(f"Redis connect failed: {e}")
        raise

    # fastapi-cache2 可留作你后续的接口级缓存需要
    FastAPICache.init(RedisBackend(redis_client), prefix="audit_cache")

    if not INFURA_KEY or not SECRET_KEY:
        raise ValueError("Missing INFURA_KEY or SECRET_KEY")

    # 全局 Web3（地址校验、get_logs 用）
    for chain, url in INFURA_HTTP.items():
        web3_clients[chain] = AsyncWeb3(AsyncHTTPProvider(url))
    logger.info("Web3 clients initialized.")

    # 长连接会显著降低 RPC 往返
    http_session = aiohttp.ClientSession(timeout=RPC_TIMEOUT, trust_env=False)

    yield

    await db_pool.close()
    await redis_client.aclose()
    if http_session:
        await http_session.close()

app.router.lifespan_context = lifespan

# -----------------------------
# 安全：JWT 校验
# -----------------------------
async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"], options={"require_exp": True})
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=403, detail="Invalid token")

# -----------------------------
# 工具
# -----------------------------
async def ensure_await(maybe_coro):
    if asyncio.iscoroutine(maybe_coro):
        return await maybe_coro
    return maybe_coro

async def rpc_batch(chain_name: str, requests: list[dict]) -> list[dict]:
    """对同一链一次性发 JSON-RPC 批量请求。"""
    url = INFURA_HTTP[chain_name]
    assert http_session is not None
    headers = {"Content-Type": "application/json"}
    async with http_session.post(url, json=requests, headers=headers) as resp:
        if resp.status != 200:
            text = await resp.text()
            raise HTTPException(status_code=502, detail=f"RPC {resp.status}: {text[:200]}")
        return await resp.json()

async def _store_cache(chain_name: str, checksum_addr: str, payload: dict):
    assert redis_client is not None
    key = CACHE_KEY_FMT.format(chain=chain_name, addr=checksum_addr)
    ts  = CACHE_TS_FMT.format(chain=chain_name, addr=checksum_addr)
    now = int(time.time())
    await redis_client.set(key, json.dumps(payload), ex=STALE_TTL)
    await redis_client.set(ts, str(now), ex=STALE_TTL)

async def _load_cache(chain_name: str, checksum_addr: str):
    assert redis_client is not None
    key = CACHE_KEY_FMT.format(chain=chain_name, addr=checksum_addr)
    ts  = CACHE_TS_FMT.format(chain=chain_name, addr=checksum_addr)
    data_s, ts_s = await asyncio.gather(redis_client.get(key), redis_client.get(ts))
    if not data_s:
        return None, None
    try:
        data = json.loads(data_s)
    except Exception:
        return None, None
    return data, (int(ts_s) if ts_s else None)

# -----------------------------
# SWR + 批量 RPC：<1s 返回
# -----------------------------
async def get_cached_web3_data(contract: str, chain_name: str) -> Dict:
    if redis_client is None:
        raise HTTPException(status_code=500, detail="Redis not initialized")
    if chain_name not in INFURA_HTTP:
        raise HTTPException(status_code=400, detail=f"Unsupported chain: {chain_name}")

    # 规范地址
    checksum_addr = web3_clients[chain_name].to_checksum_address(contract)

    # 1) 读缓存
    cached, ts = await _load_cache(chain_name, checksum_addr)
    now = int(time.time())
    fresh = cached and ts and (now - ts) <= FRESH_TTL
    if fresh:
        return cached  # 新鲜值，直接返回（命中时几十毫秒）

    # 2) 有陈旧值：先返回陈旧值，同时后台刷新
    if cached:
        asyncio.create_task(_refresh_live(chain_name, checksum_addr))
        return cached

    # 3) 无缓存：同步拉取一轮（批量 RPC 仅一次网络往返）
    return await _refresh_live(chain_name, checksum_addr)

async def _refresh_live(chain_name: str, checksum_addr: str) -> Dict:
    """
    批量 RPC：
      - eth_call(balanceOf(zero))
      - eth_gasPrice
      - eth_blockNumber
    """
    zero_addr = "0x0000000000000000000000000000000000000000"
    # keccak('balanceOf(address)') 前4字节：0x70a08231
    data_balanceOf = "0x70a08231" + "0"*24 + zero_addr[2:]
    call_obj = {"to": checksum_addr, "data": data_balanceOf}

    batch = [
        {"jsonrpc": "2.0", "id": 1, "method": "eth_call",       "params": [call_obj, "latest"]},
        {"jsonrpc": "2.0", "id": 2, "method": "eth_gasPrice",   "params": []},
        {"jsonrpc": "2.0", "id": 3, "method": "eth_blockNumber","params": []},
        # 如需更准小费，可再加一条 eth_maxPriorityFeePerGas：
        # {"jsonrpc":"2.0","id":4,"method":"eth_maxPriorityFeePerGas","params":[]},
    ]
    try:
        resp = await rpc_batch(chain_name, batch)
        by_id = {item["id"]: item for item in resp}

        bal_hex = by_id[1].get("result")
        gas_hex = by_id[2].get("result")
        blk_hex = by_id[3].get("result")

        balance = int(bal_hex, 16) if bal_hex else 0
        gas_price = int(gas_hex, 16) if gas_hex else 0
        block_number = int(blk_hex, 16) if blk_hex else 0

        # 采用 gasPrice 作为近似（更快）；需要更准可再加 tip 合并
        effective_gwei = gas_price / 10**9

        result = {
            "balance": balance,
            "current_price": f"{effective_gwei:.3f} Gwei",
            "chain": chain_name,
            "block_number": block_number
        }

        await _store_cache(chain_name, checksum_addr, result)
        return result

    except Exception as e:
        logger.exception(f"live refresh failed: {e}")
        # 失败时若有陈旧值，用陈旧值兜底
        cached, _ = await _load_cache(chain_name, checksum_addr)
        if cached:
            return cached
        raise HTTPException(status_code=502, detail="Upstream node error")

# -----------------------------
# 异步落库/落盘（不阻塞响应）
# -----------------------------
async def write_db_file(contract: str, user: str | None, web3_data: Dict):
    try:
        assert db_pool is not None
        result = web3_data.copy()
        result["user"] = user

        # DB
        async with db_pool.acquire() as conn:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS security_audits (
                    contract TEXT,
                    chain TEXT,
                    report JSONB
                );
            """)
            await conn.execute(
                "INSERT INTO security_audits (contract, chain, report) VALUES ($1, $2, $3);",
                contract, web3_data["chain"], json.dumps(result)
            )

        # 文件
        os.makedirs(DATA_DIR, exist_ok=True)
        log_path = os.path.join(DATA_DIR, "audit_report.json")

        try:
            if not os.path.exists(log_path) or os.path.getsize(log_path) == 0:
                with open(log_path, "w") as f:
                    json.dump([result], f, indent=4)
            else:
                with open(log_path, "r+") as f:
                    data = json.load(f)
                    data.append(result)
                    f.seek(0)
                    json.dump(data, f, indent=4)
                    f.truncate()
        except json.JSONDecodeError:
            with open(log_path, "w") as f:
                json.dump([result], f, indent=4)

    except Exception as e:
        logger.error(f"Background task (write_db_file) error: {e}")

# -----------------------------
# 后台增量抓日志（不阻塞响应）
# -----------------------------
def _jsonable_log(log: Dict[str, Any]) -> Dict[str, Any]:
    txh = log.get("transactionHash")
    topics = log.get("topics", [])
    return {
        "address": log.get("address"),
        "blockNumber": log.get("blockNumber"),
        "data": log.get("data"),
        "logIndex": log.get("logIndex"),
        "transactionHash": txh.hex() if hasattr(txh, "hex") else txh,
        "transactionIndex": log.get("transactionIndex"),
        "topics": [t.hex() if hasattr(t, "hex") else t for t in topics],
    }

async def update_logs(contract: str, chain_name: str):
    if redis_client is None:
        return
    try:
        w3 = web3_clients[chain_name]
        key = f"logs:{chain_name}:{contract}"

        last_block_s = await redis_client.get(f"{key}:last_block")
        if last_block_s:
            from_block = int(last_block_s) + 1
        else:
            current_block0 = await ensure_await(w3.eth.block_number)
            from_block = max(current_block0 - 100, 0)

        current_block = await ensure_await(w3.eth.block_number)
        if from_block > current_block:
            return

        logs = await w3.eth.get_logs({
            "address": contract,
            "fromBlock": from_block,
            "toBlock": current_block
        })
        jsonable = [_jsonable_log(l) for l in logs]
        await redis_client.set(key, json.dumps(jsonable), ex=300)
        await redis_client.set(f"{key}:last_block", str(current_block), ex=300)
    except Exception as e:
        logger.error(f"update_logs error: {e}")

# -----------------------------
# 路由
# -----------------------------
@app.get("/security_audit/{contract}")
async def security_audit(
    contract: str,
    chain_name: str = "ethereum",
    user: Dict = Depends(verify_token),
    background_tasks: BackgroundTasks = BackgroundTasks(),  # 确保不是 None
):
    # 热数据（<1s；命中缓存几十毫秒）
    web3_data = await get_cached_web3_data(contract, chain_name)

    # 后台写库/写盘
    background_tasks.add_task(write_db_file, contract, user.get("user"), web3_data)

    # 后台增量抓日志（不阻塞响应）
    try:
        checksum_address = web3_clients[chain_name].to_checksum_address(contract)
        background_tasks.add_task(update_logs, checksum_address, chain_name)
    except Exception as e:
        logger.error(f"schedule update_logs failed: {e}")

    return web3_data

@app.get("/health")
async def health():
    try:
        pong = await redis_client.ping() if redis_client else False
        db_ok = False
        if db_pool:
            async with db_pool.acquire() as conn:
                await conn.execute("SELECT 1;")
            db_ok = True
        return {"ok": True, "redis": bool(pong), "db": db_ok}
    except Exception as e:
        return {"ok": False, "error": str(e)}
