# API - Health Check

## Health check

Returns the health status of the server.

### API details

> **GET/HEAD** `/api/health`

### Query parameters

| Param | Type | Description |
|-------|------|-------------|
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

**200**
```json
{
  "status": 200,
  "message": "API is healthy.",
  "data": {
    "canBackup": false
  }
}
```
