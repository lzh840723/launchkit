from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from web3 import Web3
import os, jwt, time
from dotenv import load_dotenv

# --- Config ---
load_dotenv()
INFURA_KEY = os.getenv("INFURA_KEY")
SECRET_KEY = os.getenv("SECRET_KEY", "change_me")

if not INFURA_KEY:
    raise RuntimeError("INFURA_KEY is required (see .env.example)")

RPC = f"https://mainnet.infura.io/v3/{INFURA_KEY}"
w3 = Web3(Web3.HTTPProvider(RPC))

# Minimal ERC20 ABI
ERC20_ABI = [
    {"constant": True, "inputs": [{"name": "owner", "type": "address"}],
     "name": "balanceOf", "outputs": [{"name": "", "type": "uint256"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "decimals",
     "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "symbol",
     "outputs": [{"name": "", "type": "string"}], "type": "function"},
]

app = FastAPI(title="Token API", version="1.0.0")

# --- CORS (允许本地调试或你的前端域名) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产可改为具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        # 允许后续读取用户信息：payload.get("user")
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=403, detail="Invalid token")

def to_checksum(addr: str) -> str:
    if not w3.is_address(addr):
        raise HTTPException(status_code=400, detail="Invalid address")
    return w3.to_checksum_address(addr)

@app.get("/health")
def health():
    ok = w3.is_connected()
    chain_id = w3.eth.chain_id if ok else None
    return {"ok": ok, "chain_id": chain_id, "rpc": "infura-mainnet"}

@app.get("/balance")
def balance(contract: str, owner: str, user=Depends(verify_token)):
    caddr = to_checksum(contract)
    oaddr = to_checksum(owner)
    c = w3.eth.contract(address=caddr, abi=ERC20_ABI)

    try:
        raw = c.functions.balanceOf(oaddr).call()
        try:
            decimals = c.functions.decimals().call()
        except Exception:
            decimals = 18
        try:
            symbol = c.functions.symbol().call()
        except Exception:
            symbol = "TOKEN"
        human = float(raw) / (10 ** decimals)
        return {
            "contract": caddr,
            "owner": oaddr,
            "balance_raw": str(raw),
            "balance": human,
            "decimals": decimals,
            "symbol": symbol,
            "user": user.get("user"),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
