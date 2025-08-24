# defi-audit/audit.py
from __future__ import annotations

from typing import Dict, Any, Optional, Tuple
from web3 import Web3

# -----------------------------
# Proxy storage slots
# -----------------------------
# EIP-1967 (transparent/upgradeable proxy)
EIP1967_IMPLEMENTATION_SLOT = Web3.to_bytes(
    hexstr="0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC"
)
EIP1967_ADMIN_SLOT = Web3.to_bytes(
    hexstr="0xb53127684a568b3173ae13b9f8a6016e01ffa2a6e4f9a9dcab0f3f1e1c6aab9c"
)

# Legacy ZeppelinOS / early OpenZeppelin slots (no "-1" offset variant)
ZOS_IMPLEMENTATION_SLOT = Web3.keccak(text="org.zeppelinos.proxy.implementation")
ZOS_ADMIN_SLOT          = Web3.keccak(text="org.zeppelinos.proxy.admin")

PROXY_IMPL_SLOTS = [
    ("eip1967_impl", EIP1967_IMPLEMENTATION_SLOT),
    ("zos_impl",     ZOS_IMPLEMENTATION_SLOT),
]
PROXY_ADMIN_SLOTS = [
    ("eip1967_admin", EIP1967_ADMIN_SLOT),
    ("zos_admin",     ZOS_ADMIN_SLOT),
]

# -----------------------------
# Heuristic risk weights (tweak to taste)
# -----------------------------
RISK_WEIGHTS = {
    "proxy_detected": 1,
    "likely_proxy": 1,
    "owner_is_eoa": 1,
    "admin_is_eoa": 1,
    "paused_true": 1,
    "very_small_code": 1,
    "has_delegatecall": 1,
}

# -----------------------------
# Function selectors (owner(), paused())
# -----------------------------
SEL_OWNER  = Web3.to_bytes(hexstr="0x8da5cb5b")  # owner()
SEL_PAUSED = Web3.to_bytes(hexstr="0x5c975abb")  # paused()

# -----------------------------
# Low-level helpers
# -----------------------------
def _read_storage_at(w3: Web3, address: str, slot_bytes: bytes) -> str:
    """Read a storage slot (bytes32) and return hex string."""
    slot_int = int.from_bytes(slot_bytes, byteorder="big")
    val = w3.eth.get_storage_at(address, slot_int)
    return Web3.to_hex(val)

def _extract_address_from_slot(slot_hex: str) -> Optional[str]:
    """
    EIP-1967 / legacy slots are 32 bytes. The address usually sits in
    the last 20 bytes (right-aligned). Return checksum address if non-zero.
    """
    if not slot_hex or slot_hex == "0x":
        return None
    raw = Web3.to_bytes(hexstr=slot_hex)
    if len(raw) < 32:
        raw = raw.rjust(32, b"\x00")
    last20 = raw[-20:]
    if last20 == b"\x00" * 20:
        return None
    return Web3.to_checksum_address(Web3.to_hex(last20))

def _low_level_call(w3: Web3, to_addr: str, data: bytes) -> Optional[bytes]:
    """Perform an eth_call with raw data; return bytes or None on failure."""
    try:
        return w3.eth.call({"to": to_addr, "data": Web3.to_hex(data)})
    except Exception:
        return None

def _decode_owner(ret: bytes) -> Optional[str]:
    """Decode owner() return (address encoded in last 20 bytes of 32-byte ABI word)."""
    if not ret or len(ret) < 32:
        return None
    return Web3.to_checksum_address(Web3.to_hex(ret[-20:]))

def _decode_paused(ret: bytes) -> Optional[bool]:
    """Decode paused() return (bool in 32-byte ABI word)."""
    if not ret or len(ret) < 32:
        return None
    return int.from_bytes(ret[-32:], byteorder="big") == 1

def _is_contract(w3: Web3, address: str) -> Tuple[bool, bytes]:
    """Return (is_contract, runtime_bytecode)."""
    code = w3.eth.get_code(address)
    return (len(code) > 0, code)

def _is_eoa(w3: Web3, address: str) -> bool:
    """EOA has no runtime code."""
    code = w3.eth.get_code(address)
    return len(code) == 0

def _opcode_stats(bytecode: bytes) -> Dict[str, Any]:
    """
    Decode EVM bytecode sequentially. When encountering PUSH1..PUSH32 (0x60..0x7F),
    skip the next N bytes of immediate data so they won't be miscounted as opcodes.
    Counts a few risky/interesting opcodes.
    """
    i = 0
    b = bytearray(bytecode)

    counts = {
        "CALL": 0,
        "CALLCODE": 0,
        "DELEGATECALL": 0,
        "STATICCALL": 0,
        "SELFDESTRUCT": 0,  # a.k.a. SUICIDE
        "CREATE": 0,
        "CREATE2": 0,
    }

    OP = {
        0xF1: "CALL",
        0xF2: "CALLCODE",
        0xF4: "DELEGATECALL",
        0xFA: "STATICCALL",
        0xFF: "SELFDESTRUCT",
        0xF0: "CREATE",
        0xF5: "CREATE2",
    }

    while i < len(b):
        op = b[i]
        i += 1

        # PUSH1..PUSH32 → skip immediate bytes
        if 0x60 <= op <= 0x7F:
            push_len = op - 0x60 + 1
            i += push_len
            continue

        name = OP.get(op)
        if name:
            counts[name] += 1

    return counts

# -----------------------------
# Main audit routine
# -----------------------------
def run_audit(w3: Web3, contract_address: str, chain: str = "ethereum") -> Dict[str, Any]:
    """
    Heuristic on-chain checks against a contract.
    Returns a dict ready to be serialized as JSON.
    """
    # Normalize address
    try:
        addr = Web3.to_checksum_address(contract_address)
    except Exception:
        raise ValueError("Invalid contract address")

    # 1) Contract sanity: code and size
    is_contract, code = _is_contract(w3, addr)
    if not is_contract:
        raise ValueError("Address has no code (not a contract)")
    code_size = len(code)

    # 2) Proxy detection across multiple slots (EIP-1967 + ZOS legacy)
    impl_addr: Optional[str] = None
    admin_addr: Optional[str] = None
    impl_slot_hits: Dict[str, str] = {}
    admin_slot_hits: Dict[str, str] = {}

    for label, slot in PROXY_IMPL_SLOTS:
        slot_hex = _read_storage_at(w3, addr, slot)
        impl_slot_hits[label] = slot_hex
        cand = _extract_address_from_slot(slot_hex)
        if cand:
            impl_addr = cand
            break  # stop at first non-zero hit

    for label, slot in PROXY_ADMIN_SLOTS:
        slot_hex = _read_storage_at(w3, addr, slot)
        admin_slot_hits[label] = slot_hex
        cand = _extract_address_from_slot(slot_hex)
        if cand:
            admin_addr = cand
            break

    is_proxy = impl_addr is not None

    # 3) Privileged functions probing
    owner_addr: Optional[str] = None
    paused_val: Optional[bool] = None

    ret_owner = _low_level_call(w3, addr, SEL_OWNER)
    if ret_owner:
        try:
            owner_addr = _decode_owner(ret_owner)
        except Exception:
            owner_addr = None

    ret_paused = _low_level_call(w3, addr, SEL_PAUSED)
    if ret_paused:
        try:
            paused_val = _decode_paused(ret_paused)
        except Exception:
            paused_val = None

    # 4) Opcode stats (with PUSH skipping)
    op = _opcode_stats(code)
    has_delegatecall = op["DELEGATECALL"] > 0

    # Heuristic: looks like a proxy even if slots are empty
    likely_proxy = False
    if not is_proxy:
        if has_delegatecall and (code_size < 4000) and (owner_addr is not None or paused_val is not None):
            likely_proxy = True

    # 5) Owner/Admin surface (EOA vs contract)
    owner_is_eoa = _is_eoa(w3, owner_addr) if owner_addr else None
    admin_is_eoa = _is_eoa(w3, admin_addr) if admin_addr else None

    # 6) Risk scoring & notes
    risk_score = 0
    notes = []

    if is_proxy:
        risk_score += RISK_WEIGHTS["proxy_detected"]
        notes.append("Proxy detected (slot hit). Review implementation & admin controls.")
    elif likely_proxy:
        risk_score += RISK_WEIGHTS["likely_proxy"]
        notes.append("Likely proxy (heuristic): delegatecall + small code + implementation-like functions.")

    if owner_is_eoa:
        risk_score += RISK_WEIGHTS["owner_is_eoa"]
        notes.append("Owner is an EOA: consider multisig/timelock.")

    if admin_is_eoa:
        risk_score += RISK_WEIGHTS["admin_is_eoa"]
        notes.append("Proxy admin is an EOA: upgrade power centralized.")

    if paused_val is True:
        risk_score += RISK_WEIGHTS["paused_true"]
        notes.append("Contract is paused: verify reason and workflow.")

    if code_size < 1000:
        risk_score += RISK_WEIGHTS["very_small_code"]
        notes.append("Very small runtime bytecode: thin proxy shell or minimal logic.")

    if has_delegatecall:
        risk_score += RISK_WEIGHTS["has_delegatecall"]
        notes.append("DELEGATECALL present: review storage layout and upgrade safety.")

    findings: Dict[str, Any] = {
        "proxy_detected": is_proxy,
        "likely_proxy": likely_proxy,
        "implementation_address": impl_addr,
        "admin_address": admin_addr,
        "impl_slots": impl_slot_hits,
        "admin_slots": admin_slot_hits,
        "owner_function_present": owner_addr is not None,
        "owner": owner_addr,
        "owner_is_eoa": owner_is_eoa,
        "pausable_function_present": paused_val is not None,
        "paused": paused_val,
        "opcode_stats": op,
        "notes": notes,
    }

    result: Dict[str, Any] = {
        "chain": chain,
        "contract": addr,
        "is_contract": True,
        "code_size": code_size,
        "proxy": is_proxy,
        "implementation": impl_addr,
        "admin": admin_addr,
        "owner": owner_addr,
        "paused": paused_val,
        "risk_score": risk_score,
        "findings": findings,
    }
    return result

# -----------------------------
# Optional: tiny self-test helper
# -----------------------------
if __name__ == "__main__":
    """
    Example manual run (requires INFURA_KEY in env and a Web3 provider created here).
    This block intentionally avoids creating a provider to keep the module import-safe.
    """
    print("This module provides run_audit(w3, address). Import and call from your FastAPI app.")
