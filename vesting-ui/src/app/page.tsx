"use client";
import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { parseAbi } from "viem";

const abi = parseAbi([
  "function releasable() view returns (uint256)",
  "function release(uint256 amount)"
]);

const VAULT = process.env.NEXT_PUBLIC_VAULT as `0x${string}`;

export default function Home() {
  const { address } = useAccount();
  const { data: releasable, refetch } = useReadContract({
    address: VAULT,
    abi,
    functionName: "releasable",
  });

  const { writeContract, isPending } = useWriteContract();

  return (
    <main style={{ padding: 24, fontFamily: "ui-sans-serif" }}>
      <ConnectButton />
      <h1>Vesting Demo</h1>
      <p>Vault: {VAULT}</p>
      <p>Releasable: {String(releasable ?? 0)} wei</p>
      <button
        disabled={!address || isPending}
        onClick={async () => {
          await writeContract({ address: VAULT, abi, functionName: "release", args: [BigInt(0)] });
          await refetch();
        }}
      >
        Claim
      </button>
    </main>
  );
}
