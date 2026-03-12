# API Crons

## List cron jobs

Returns list with all registered app level cron jobs.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const jobs = await pb.crons.getFullList();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final jobs = await pb.crons.getFullList();
```

### API details

> **GET** `/api/crons`

### Query parameters

| Param  | Type   | Description                                                                                                                              |
| ------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` |

### Responses

**200:**

```json
[
  {
    "id": "__pbDBOptimize__",
    "expression": "0 0 * * *"
  },
  {
    "id": "__pbMFACleanup__",
    "expression": "0 * * * *"
  },
  {
    "id": "__pbOTPCleanup__",
    "expression": "0 * * * *"
  },
  {
    "id": "__pbLogsCleanup__",
    "expression": "0 */6 * * *"
  }
]
```

**400:**

```json
{
  "status": 400,
  "message": "Failed to load backups filesystem.",
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
  "message": "Only superusers can perform this action.",
  "data": {}
}
```

---

## Run cron job

Triggers a single cron job by its id.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.crons.run('__pbLogsCleanup__');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.crons.run('__pbLogsCleanup__');
```

### API details

> **POST** `/api/crons/jobId`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type   | Description                               |
| ----- | ------ | ----------------------------------------- |
| jobId | String | The identifier of the cron job to run.    |

### Responses

**204:**

```
null
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
  "message": "Missing or invalid cron job.",
  "data": {}
}
```
