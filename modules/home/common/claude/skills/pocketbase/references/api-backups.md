# API Backups

## List backups

Returns list with all available backup files.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const backups = await pb.backups.getFullList();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final backups = await pb.backups.getFullList();
```

### API details

> **GET** `/api/backups`

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

**200:**

```json
[
  {
    "key": "pb_backup_20230519162514.zip",
    "modified": "2023-05-19 16:25:57.542Z",
    "size": 251316185
  },
  {
    "key": "pb_backup_20230518162514.zip",
    "modified": "2023-05-18 16:25:57.542Z",
    "size": 251314010
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

## Create backup

Creates a new app data backup.

This action will return an error if there is another backup/restore operation already in progress.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.create('new_backup.zip');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.create('new_backup.zip');
```

### API details

> **POST** `/api/backups`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| Optional - name | String | The base name of the backup file to create. Must be in the format `[a-z0-9_-].zip`. If not set, it will be auto generated. |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Responses

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "Try again later - another backup/restore process has already been started.",
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

## Upload backup

Uploads an existing backup zip file.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.upload({ file: new Blob([...]) });
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.upload(http.MultipartFile.fromBytes('file', ...));
```

### API details

> **POST** `/api/backups/upload`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| Required - file | File | The zip archive to upload. |

Uploading files is supported only via *multipart/form-data*.

### Responses

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "Something went wrong while processing your request.",
  "data": {
    "file": {
      "code": "validation_invalid_mime_type",
      "message": "\"test_backup.txt\" mime type must be one of: application/zip."
    }
  }
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

## Delete backup

Deletes a single backup by its name.

This action will return an error if the backup to delete is still being generated or part of a restore operation.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.delete('pb_data_backup.zip');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.delete('pb_data_backup.zip');
```

### API details

> **DELETE** `/api/backups/`**`key`**
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| key | String | The key of the backup file to delete. |

### Responses

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "Try again later - another backup/restore process has already been started.",
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

## Restore backup

Restore a single backup by its name and restarts the current running PocketBase process.

This action will return an error if there is another backup/restore operation already in progress.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.restore('pb_data_backup.zip');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.backups.restore('pb_data_backup.zip');
```

### API details

> **POST** `/api/backups/`**`key`**`/restore`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| key | String | The key of the backup file to restore. |

### Responses

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "Try again later - another backup/restore process has already been started.",
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

## Download backup

Downloads a single backup file.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const token = await pb.files.getToken();

const url = pb.backups.getDownloadUrl(token, 'pb_data_backup.zip');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final token = await pb.files.getToken();

final url = pb.backups.getDownloadUrl(token, 'pb_data_backup.zip');
```

### API details

> **GET** `/api/backups/`**`key`**

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| key | String | The key of the backup file to download. |

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| token | String | Superuser **file token** for granting access to the **backup file**. |

### Responses

**200:**

```
[file resource]
```

**400:**

```json
{
  "status": 400,
  "message": "Filesystem initialization failure.",
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
