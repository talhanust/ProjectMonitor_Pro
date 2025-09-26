# API Documentation

## Base URL

- Development: http://localhost:8080
- Production: TBD

## Authentication

All authenticated endpoints require a JWT token in the Authorization header:
Authorization: Bearer <token>

## Endpoints

### Health Check

GET /health
Returns the health status of the API.

### Status

GET /api/v1/status
Returns API version and environment information.

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
Rate Limiting

100 requests per minute per IP
Headers included in response:

X-RateLimit-Limit
X-RateLimit-Remaining
X-RateLimit-Reset
```
