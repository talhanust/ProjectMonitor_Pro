'use client';

import { useEffect, useState } from 'react';
import { register } from '@/lib/serviceWorker';

export function ServiceWorkerRegistration() {
  const [showReload, setShowReload] = useState(false);
  const [waitingWorker, setWaitingWorker] = useState<ServiceWorker | null>(null);

  useEffect(() => {
    // Register service worker
    register({
      onSuccess: (registration) => {
        console.log('Service Worker registered successfully:', registration);
      },
      onUpdate: (registration) => {
        console.log('New Service Worker update available');
        setShowReload(true);
        setWaitingWorker(registration.waiting);
      },
      onError: (error) => {
        console.error('Service Worker registration error:', error);
      },
    });

    // Listen for messages from the service worker
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data?.type === 'CACHE_UPDATED') {
          console.log('Cache updated:', event.data.updatedURL);
        }
      });
    }

    // Listen for controller change and reload
    let refreshing = false;
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (!refreshing) {
          window.location.reload();
          refreshing = true;
        }
      });
    }
  }, []);

  const handleReload = () => {
    if (waitingWorker) {
      // Tell the waiting service worker to activate
      waitingWorker.postMessage({ type: 'SKIP_WAITING' });
    }
    setShowReload(false);
  };

  if (!showReload) {
    return null;
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 animate-slide-in">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-4 max-w-sm border border-gray-200 dark:border-gray-700">
        <div className="flex items-start space-x-3">
          <div className="flex-shrink-0">
            <svg
              className="h-6 w-6 text-blue-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </div>
          <div className="flex-1">
            <p className="text-sm font-medium text-gray-900 dark:text-white">Update Available</p>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              A new version of the app is available. Reload to update.
            </p>
            <div className="mt-3 flex space-x-3">
              <button
                onClick={handleReload}
                className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Reload
              </button>
              <button
                onClick={() => setShowReload(false)}
                className="inline-flex items-center px-3 py-1.5 border border-gray-300 dark:border-gray-600 text-xs font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Later
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
