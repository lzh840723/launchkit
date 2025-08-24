from fastapi import FastAPI, HTTPException
from web3 import Web3
import os
from dotenv import load_dotenv

load_dotenv()

INFURA_KEY = os.getenv("INFURA_KEY")
if not INFURA_KEY:
    raise RuntimeError("Please set INFURA_KEY in .env")

RPC = f"https://mainnet.infura.io/v3/{INFURA_KEY}"
w3 = Web3(Web3.HTTPProvider(RPC))

app = FastAPI(title="NFT Query API", version="1.0.0")

ERC721_ABI = [
    {
        "constant": True,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function",
    }
]

@app.get("/nft/{contract}/{owner}")
async def get_nft_balance(contract: str, owner: str):
    try:
        contract_instance = w3.eth.contract(address=w3.to_checksum_address(contract), abi=ERC721_ABI)
        balance = contract_instance.functions.balanceOf(w3.to_checksum_address(owner)).call()
        return {"contract": contract, "owner": owner, "balance": balance}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
