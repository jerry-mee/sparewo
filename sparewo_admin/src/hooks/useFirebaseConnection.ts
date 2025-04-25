import { useState, useEffect } from "react";
import { connectionManager } from "@/services/firebase.service";

/**
 * Hook to monitor Firebase connection status
 * @returns Object containing Firebase connection status and last reconnect attempt time
 */
export function useFirebaseConnection() {
  const [isConnected, setIsConnected] = useState(true);
  const [lastReconnectAttempt, setLastReconnectAttempt] = useState<Date | null>(null);

  useEffect(() => {
    // Use connection manager to track status
    const removeListener = connectionManager.addConnectionListener((connected: boolean) => {
      setIsConnected(connected);
      
      if (!connected) {
        setLastReconnectAttempt(new Date());
      }
    });
    
    // Clean up subscription
    return () => {
      removeListener();
    };
  }, []);

  return { isConnected, lastReconnectAttempt };
}