# defi-audit/app.py
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from web3 import Web3
from audit import run_audit  # use the centralized audit logic
import os

# -----------------------------
# Environment & Web3 Initialization
# -----------------------------
load_dotenv()
INFURA_KEY = os.getenv("INFURA_KEY")
if not INFURA_KEY:
    raise RuntimeError("INFURA_KEY is required. Put it in .env or environment variables.")

CHAINS = {
    "ethereum": f"https://mainnet.infura.io/v3/{INFURA_KEY}",
    "polygon": f"https://polygon-mainnet.infura.io/v3/{INFURA_KEY}",
}

def get_w3(chain_name: str) -> Web3:
    if chain_name not in CHAINS:
        raise HTTPException(status_code=400, detail=f"Unsupported chain: {chain_name}")
    w3 = Web3(Web3.HTTPProvider(CHAINS[chain_name]))
    if not w3.is_connected():
        raise HTTPException(status_code=502, detail=f"RPC not connected: {chain_name}")
    return w3

# -----------------------------
# FastAPI Setup
# -----------------------------
app = FastAPI(
    title="DeFi Audit API",
    version="1.0.0",
    description="Minimal on-chain static checks without ABI (proxy/owner/paused/opcodes heuristics).",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# Health
# -----------------------------
@app.get("/health")
def health(chain: str = Query("ethereum", description="ethereum | polygon")):
    w3 = get_w3(chain)
    return {"ok": True, "chain": chain, "chain_id": w3.eth.chain_id}

# -----------------------------
# Audit (single source of truth -> audit.run_audit)
# -----------------------------
@app.get("/audit")
def audit(contract: str = Query(..., description="contract address to audit"),
          chain: str = Query("ethereum", description="ethereum | polygon")):
    w3 = get_w3(chain)
    try:
        result = run_audit(w3, contract, chain=chain)
        return result  # already a JSON-serializable dict
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
