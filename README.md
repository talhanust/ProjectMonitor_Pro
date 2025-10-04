# MMR Queue System

Complete MMR processing queue with Excel support, built with Bull, Redis, and TypeScript.

## 🚀 Quick Start

```bash
# 1. Install dependencies
make install

# 2. Start Redis
make start

# 3. Start the service (in a new terminal)
make dev

# 4. Test it (in another terminal)
make test
curl http://localhost:3001/health
```

## 📁 Project Structure

```
mmr-queue-system/
├── backend/services/
│   ├── shared/          # Shared components
│   │   ├── redis/       # Redis client
│   │   ├── queue/       # Bull queue config
│   │   ├── logger/      # Winston logger
│   │   └── middleware/  # Express middleware
│   └── mmr-service/
│       └── src/
│           ├── queues/      # MMR queue
│           ├── workers/     # Processing workers
│           ├── controllers/ # API controllers
│           ├── services/    # Business logic
│           ├── routes/      # Express routes
│           └── utils/       # Job tracker
├── scripts/
│   ├── generate-test-mmr.js  # Test file generator
│   └── quick-test.sh          # Quick test script
├── docker-compose.yml
├── Makefile
└── .env

```

## 🎯 Features

✅ Excel MMR processing (primary format)
✅ Automatic field detection
✅ Up to 10 concurrent jobs
✅ Automatic retry with exponential backoff
✅ Real-time progress tracking
✅ Batch processing support
✅ RESTful API
✅ Complete TypeScript implementation

## 🔌 API Endpoints

### Process File
```bash
curl -X POST http://localhost:3001/api/mmr/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "fileName": "doc.xlsx",
    "filePath": "/path/to/file.xlsx",
    "fileSize": 1024000,
    "uploadId": "upload-123"
  }'
```

### Get Job Status
```bash
curl http://localhost:3001/api/mmr/jobs/{jobId} \
  -H "Authorization: Bearer test-token"
```

### List User Jobs
```bash
curl http://localhost:3001/api/mmr/jobs \
  -H "Authorization: Bearer test-token"
```

## 🧪 Testing

```bash
# Generate test Excel file
node scripts/generate-test-mmr.js 100 test.xlsx

# Run quick test
./scripts/quick-test.sh

# Check health
curl http://localhost:3001/health | jq
```

## 📊 Excel MMR Format

The system automatically detects these fields:
- Title/Document
- Description/Content  
- Category/Type
- Reference/ID
- Date/Created
- Tags/Keywords
- Source/URL

## 🛠️ Development

```bash
# Install dependencies
make install

# Start Redis
make start

# Start in dev mode (auto-reload)
make dev

# Stop services
make stop
```

## 📝 Environment Variables

Edit `.env` file:
- `MMR_SERVICE_PORT` - Service port (default: 3001)
- `REDIS_HOST` - Redis host (default: localhost)
- `REDIS_PORT` - Redis port (default: 6379)
- `JWT_SECRET` - JWT secret key
- `LOG_LEVEL` - Logging level (default: info)

## 🎉 Success!

Your MMR Queue System is ready! Start developing and processing Excel MMR files.
