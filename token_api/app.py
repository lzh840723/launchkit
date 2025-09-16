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

# --- CORS (allow local debugging or your frontend domains) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Verify a JWT from the Authorization header (HTTP Bearer).
    Returns the decoded payload on success, otherwise raises HTTP 403.
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        # Payload can be accessed later, e.g., payload.get("user")
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=403, detail="Invalid token")

def to_checksum(addr: str) -> str:
    """
    Validate an Ethereum address and return its EIP-55 checksum format.
    Raises HTTP 400 if the address is invalid.
    """
    if not w3.is_address(addr):
        raise HTTPException(status_code=400, detail="Invalid address")
    return w3.to_checksum_address(addr)

@app.get("/health")
def health():
    """
    Simple health check for the RPC connection.
    Returns ok status, current chain_id (if connected), and RPC label.
    """
    ok = w3.is_connected()
    chain_id = w3.eth.chain_id if ok else None
    return {"ok": ok, "chain_id": chain_id, "rpc": "infura-mainnet"}

@app.get("/balance")
def balance(contract: str, owner: str, user=Depends(verify_token)):
    """
    Return the ERC-20 token balance for a given owner address.
    - Resolves contract and owner to checksum addresses
    - Calls balanceOf(owner)
    - Attempts to read decimals and symbol (with safe fallbacks)
    """
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
