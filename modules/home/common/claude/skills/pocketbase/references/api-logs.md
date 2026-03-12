# API Logs

## List logs

Returns a paginated logs list.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const pageResult = await pb.logs.getList(1, 20, {
    filter: 'data.status >= 400'
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final pageResult = await pb.logs.getList(
    page: 1,
    perPage: 20,
    filter: 'data.status >= 400',
);
```

### API details

> **GET** `/api/logs`
>
> Requires `Authorization:TOKEN`

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| page | Number | The page (aka. offset) of the paginated list (*default to 1*). |
| perPage | Number | The max returned logs per page (*default to 30*). |
| sort | String | Specify the *ORDER BY* fields. Add `-` / `+` (default) in front of the attribute for DESC / ASC order, e.g.: `?sort=-rowid,level` **Supported log sort fields:** `@random`, `rowid`, `id`, `created`, `updated`, `level`, `message` and any `data.*` attribute. |
| filter | String | Filter expression to filter/search the returned logs list, e.g.: `?filter=(data.url~'test.com' && level>0)` **Supported log filter fields:** `id`, `created`, `updated`, `level`, `message` and any `data.*` attribute. The supported filter operators are `=`, `!=`, `>`, `>=`, `<`, `<=`, `~`, `!~`, `?=`, `?!=`, `?>`, `?>=`, `?<`, `?<=`, `?~`, `?!~`. For more information about the available operators, check the [rules and filters documentation](api-rules-and-filters.md). |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

**200:**

```json
{
  "page": 1,
  "perPage": 20,
  "totalItems": 2,
  "items": [
    {
      "id": "ai5z3aoed6809au",
      "created": "2024-10-27 09:28:19.524Z",
      "data": {
        "auth": "_superusers",
        "execTime": 2.392327,
        "method": "GET",
        "referer": "http://localhost:8090/_/",
        "remoteIP": "127.0.0.1",
        "status": 200,
        "type": "request",
        "url": "/api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
        "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36",
        "userIP": "127.0.0.1"
      },
      "message": "GET /api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
      "level": 0
    },
    {
      "id": "26apis4s3sm9yqm",
      "created": "2024-10-27 09:28:19.524Z",
      "data": {
        "auth": "_superusers",
        "execTime": 2.392327,
        "method": "GET",
        "referer": "http://localhost:8090/_/",
        "remoteIP": "127.0.0.1",
        "status": 200,
        "type": "request",
        "url": "/api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
        "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36",
        "userIP": "127.0.0.1"
      },
      "message": "GET /api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
      "level": 0
    }
  ]
}
```

**400:**

```json
{
  "status": 400,
  "message": "Something went wrong while processing your request. Invalid filter.",
  "data": {}
}
```

**401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## View log

Returns a single log by its ID.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithEmail('test@example.com', '123456');

const log = await pb.logs.getOne('LOG_ID');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithEmail('test@example.com', '123456');

final log = await pb.logs.getOne('LOG_ID');
```

### API details

> **GET** `/api/logs/`{id}
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| id | String | ID of the log to view. |

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

**200:**

```json
{
  "id": "ai5z3aoed6809au",
  "created": "2024-10-27 09:28:19.524Z",
  "data": {
    "auth": "_superusers",
    "execTime": 2.392327,
    "method": "GET",
    "referer": "http://localhost:8090/_/",
    "remoteIP": "127.0.0.1",
    "status": 200,
    "type": "request",
    "url": "/api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
    "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36",
    "userIP": "127.0.0.1"
  },
  "message": "GET /api/collections/_pbc_2287844090/records?page=1&perPage=1&filter=&fields=id",
  "level": 0
}
```

**401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

**404:**

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

## Logs statistics

Returns hourly aggregated logs statistics.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

const stats = await pb.logs.getStats({
    filter: 'data.status >= 400'
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

final stats = await pb.logs.getStats(
    filter: 'data.status >= 400'
);
```

### API details

> **GET** `/api/logs/stats`
>
> Requires `Authorization:TOKEN`

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| filter | String | Filter expression to filter/search the logs, e.g.: `?filter=(data.url~'test.com' && level>0)` **Supported log filter fields:** `rowid`, `id`, `created`, `updated`, `level`, `message` and any `data.*` attribute. The supported filter operators are `=`, `!=`, `>`, `>=`, `<`, `<=`, `~`, `!~`, `?=`, `?!=`, `?>`, `?>=`, `?<`, `?<=`, `?~`, `?!~`. For more information about the available operators, check the [rules and filters documentation](api-rules-and-filters.md). |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

**200:**

```json
[
  {
    "total": 4,
    "date": "2022-06-01 19:00:00.000"
  },
  {
    "total": 1,
    "date": "2022-06-02 12:00:00.000"
  },
  {
    "total": 8,
    "date": "2022-06-02 13:00:00.000"
  }
]
```

**400:**

```json
{
  "status": 400,
  "message": "Something went wrong while processing your request. Invalid filter.",
  "data": {}
}
```

**401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```
