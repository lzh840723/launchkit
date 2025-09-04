"use client";
import { PropsWithChildren, useState } from "react";
import { WagmiProvider, createConfig, http } from "wagmi";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { sepolia } from "wagmi/chains";
import "@rainbow-me/rainbowkit/styles.css";

const config = createConfig({
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(), // 如需自定义 RPC，可换成 http(process.env.NEXT_PUBLIC_RPC_URL!)
  },
});

export default function Providers({ children }: PropsWithChildren) {
  // 用 useState 确保只创建一次 QueryClient（避免热更新时多实例）
  const [queryClient] = useState(() => new QueryClient());

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
