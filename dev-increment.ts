const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

async function waitForServer(maxAttempts = 10, delay = 1000) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      console.log(`🔍 Checking if server is ready (attempt ${attempt}/${maxAttempts})...`);
      const healthRes = await fetch(`${BACKEND_URL}/health`);
      if (healthRes.ok) {
        console.log('✅ Server is ready!');
        return true;
      }
    } catch {
      console.log(`⏳ Server not ready yet, waiting ${delay}ms...`);
      if (attempt === maxAttempts) {
        console.error('❌ Server never became ready');
        return false;
      }
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}

async function incrementCounter() {
  try {
    console.log(`🔄 Sending increment request to: ${BACKEND_URL}/counter/increment`);

    // First, check if server is ready
    const isReady = await waitForServer();
    if (!isReady) {
      throw new Error('Server is not running. Please start the backend with: npm run dev:backend');
    }

    const res = await fetch(`${BACKEND_URL}/counter/increment`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ increment: 1 }),
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`HTTP ${res.status}: ${errorText}`);
    }

    const data = await res.json();
    console.log(`✅ Counter incremented successfully: ${data.count}`);
    return data;
  } catch (err: unknown) {
    if (err instanceof Error) {
      const typedErr = err as Error & { code?: string };
      if (typedErr.code === 'ECONNREFUSED') {
        console.error(`
❌ Backend server is not running!

Please start the backend server first:
1. Open a new terminal
2. Run: npm run dev:backend
3. Wait for "Server running at http://localhost:8080"
4. Then run this script again
`);
      } else {
        console.error(`❌ Failed to increment counter:`, typedErr.message);
      }
    } else {
      console.error('❌ Unknown error occurred:', err);
    }
    throw err;
  }
}

// Test the function
incrementCounter()
  .then((data) => console.log('🎉 Final result:', data))
  .catch((err) => console.error('💥 Final error:', err instanceof Error ? err.message : err));
