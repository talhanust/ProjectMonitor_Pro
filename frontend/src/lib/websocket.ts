import { useEffect } from 'react';

const WS_URL = process.env.NEXT_PUBLIC_MMR_WS_URL || 'ws://localhost:3001';

export const useWebSocket = (onMessage: (data: any) => void) => {
  // WebSocket is not supported by the MMR service
  // The service uses REST API for file upload and status polling
  
  useEffect(() => {
    console.log('ℹ️ MMR Service uses REST API (WebSocket not available)');
    console.log('📡 File uploads will use HTTP with progress callbacks');
  }, []);

  const sendMessage = (data: any) => {
    // No-op - WebSocket not available
  };

  return { sendMessage };
};
