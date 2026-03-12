# API Settings

## List settings

Returns a list with all available application settings.

Secret/password fields are automatically redacted with *\*\*\*\*\*\** characters.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const settings = await pb.settings.getAll();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final settings = await pb.settings.getAll();
```

### API details

> **GET** `/api/settings`
>
> Requires `Authorization:TOKEN`

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. |

### Responses

**Response 200:**

```json
{
  "smtp": {
    "enabled": false,
    "port": 587,
    "host": "smtp.example.com",
    "username": "",
    "authMethod": "",
    "tls": true,
    "localName": ""
  },
  "backups": {
    "cron": "0 0 * * *",
    "cronMaxKeep": 3,
    "s3": {
      "enabled": false,
      "bucket": "",
      "region": "",
      "endpoint": "",
      "accessKey": "",
      "forcePathStyle": false
    }
  },
  "s3": {
    "enabled": false,
    "bucket": "",
    "region": "",
    "endpoint": "",
    "accessKey": "",
    "forcePathStyle": false
  },
  "meta": {
    "appName": "Acme",
    "appURL": "https://example.com",
    "senderName": "Support",
    "senderAddress": "support@example.com",
    "hideControls": false
  },
  "rateLimits": {
    "rules": [
      {
        "label": "*:auth",
        "audience": "",
        "duration": 3,
        "maxRequests": 2
      },
      {
        "label": "*:create",
        "audience": "",
        "duration": 5,
        "maxRequests": 20
      },
      {
        "label": "/api/batch",
        "audience": "",
        "duration": 1,
        "maxRequests": 3
      },
      {
        "label": "/api/",
        "audience": "",
        "duration": 10,
        "maxRequests": 300
      }
    ],
    "enabled": false
  },
  "trustedProxy": {
    "headers": [],
    "useLeftmostIP": false
  },
  "batch": {
    "enabled": true,
    "maxRequests": 50,
    "timeout": 3,
    "maxBodySize": 0
  },
  "logs": {
    "maxDays": 7,
    "minLevel": 0,
    "logIP": true,
    "logAuthId": false
  }
}
```

**Response 401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

**Response 403:**

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## Update settings

Bulk updates application settings and returns the updated settings list.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

const settings = await pb.settings.update({
    meta: {
      appName: 'YOUR_APP',
      appUrl: 'http://127.0.0.1:8090',
    },
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

final settings = await pb.settings.update(body: {
    'meta': {
      'appName': 'YOUR_APP',
      'appUrl': 'http://127.0.0.1:8090',
    },
});
```

### API details

> **PATCH** `/api/settings`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| **meta** | | Application meta data (name, url, support email, etc.). |
| `Required` appName | String | The app name. |
| `Required` appUrl | String | The app public absolute url. |
| `Optional` hideControls | Boolean | Hides the collection create and update controls from the Dashboard. Useful to prevent making accidental schema changes when in production environment. |
| `Required` senderName | String | Transactional mails sender name. |
| `Required` senderAddress | String | Transactional mails sender address. |
| **logs** | | App logger settings. |
| `Optional` maxDays | Number | Max retention period. Set to *0* for no logs. |
| `Optional` minLevel | Number | Specifies the minimum log persistent level. The default log levels are: -4: DEBUG, 0: INFO, 4: WARN, 8: ERROR |
| `Optional` logIP | Boolean | If enabled includes the client IP in the activity request logs. |
| `Optional` logAuthId | Boolean | If enabled includes the authenticated record id in the activity request logs. |
| **backups** | | App data backups settings. |
| `Optional` cron | String | Cron expression to schedule auto backups, e.g. `0 0 * * *`. |
| `Optional` cronMaxKeep | Number | The max number of cron generated backups to keep before removing older entries. |
| `Optional` s3 | Object | S3 configuration (the same fields as for the S3 file storage settings). |
| **smtp** | | SMTP mail server settings. |
| `Optional` enabled | Boolean | Enable the use of the SMTP mail server for sending emails. |
| `Required` host | String | Mail server host (required if SMTP is enabled). |
| `Required` port | Number | Mail server port (required if SMTP is enabled). |
| `Optional` username | String | Mail server username. |
| `Optional` password | String | Mail server password. |
| `Optional` tls | Boolean | Whether to enforce TLS connection encryption. When *false* *StartTLS* command is send, leaving the server to decide whether to upgrade the connection or not). |
| `Optional` authMethod | String | The SMTP AUTH method to use - *PLAIN* or *LOGIN* (used mainly by Microsoft). Default to *PLAIN* if empty. |
| `Optional` localName | String | Optional domain name or (IP address) to use for the initial EHLO/HELO exchange. If not explicitly set, `localhost` will be used. Note that some SMTP providers, such as Gmail SMTP-relay, requires a proper domain name and and will reject attempts to use localhost. |
| **s3** | | S3 compatible file storage settings. |
| `Optional` enabled | Boolean | Enable the use of a S3 compatible storage. |
| `Required` bucket | String | S3 storage bucket (required if enabled). |
| `Required` region | String | S3 storage region (required if enabled). |
| `Required` endpoint | String | S3 storage public endpoint (required if enabled). |
| `Required` accessKey | String | S3 storage access key (required if enabled). |
| `Required` secret | String | S3 storage secret (required if enabled). |
| `Optional` forcePathStyle | Boolean | Forces the S3 request to use path-style addressing, e.g. "https://s3.amazonaws.com/BUCKET/KEY" instead of the default "https://BUCKET.s3.amazonaws.com/KEY". |
| **batch** | | Batch logs settings. |
| `Optional` enabled | Boolean | Enable the batch Web APIs. |
| `Required` maxRequests | Number | The maximum allowed batch request to execute. |
| `Required` timeout | Number | The max duration in seconds to wait before cancelling the batch transaction. |
| `Optional` maxBodySize | Number | The maximum allowed batch request body size in bytes. If not set, fallbacks to max ~128MB. |
| **rateLimits** | | Rate limiter settings. |
| `Optional` enabled | Boolean | Enable the builtin rate limiter. |
| `Optional` rules | Array\<RateLimitRule\> | List of rate limit rules. Each rule have: `label` - the identifier of the rule. It could be a tag, complete path or path prerefix (when ends with `/`). `maxRequests` - the max allowed number of requests per duration. `duration` - specifies the interval (in seconds) per which to reset the counted/accumulated rate limiter tokens.. |
| **trustedProxy** | | Trusted proxy headers settings. |
| `Optional` headers | Array\<String\> | List of explicit trusted header(s) to check. |
| `Optional` useLeftmostIP | Boolean | Specifies to use the left-mostish IP from the trusted headers. |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. |

### Responses

**Response 200:**

```json
{
  "smtp": {
    "enabled": false,
    "port": 587,
    "host": "smtp.example.com",
    "username": "",
    "authMethod": "",
    "tls": true,
    "localName": ""
  },
  "backups": {
    "cron": "0 0 * * *",
    "cronMaxKeep": 3,
    "s3": {
      "enabled": false,
      "bucket": "",
      "region": "",
      "endpoint": "",
      "accessKey": "",
      "forcePathStyle": false
    }
  },
  "s3": {
    "enabled": false,
    "bucket": "",
    "region": "",
    "endpoint": "",
    "accessKey": "",
    "forcePathStyle": false
  },
  "meta": {
    "appName": "Acme",
    "appURL": "https://example.com",
    "senderName": "Support",
    "senderAddress": "support@example.com",
    "hideControls": false
  },
  "rateLimits": {
    "rules": [
      {
        "label": "*:auth",
        "audience": "",
        "duration": 3,
        "maxRequests": 2
      },
      {
        "label": "*:create",
        "audience": "",
        "duration": 5,
        "maxRequests": 20
      },
      {
        "label": "/api/batch",
        "audience": "",
        "duration": 1,
        "maxRequests": 3
      },
      {
        "label": "/api/",
        "audience": "",
        "duration": 10,
        "maxRequests": 300
      }
    ],
    "enabled": false
  },
  "trustedProxy": {
    "headers": [],
    "useLeftmostIP": false
  },
  "batch": {
    "enabled": true,
    "maxRequests": 50,
    "timeout": 3,
    "maxBodySize": 0
  },
  "logs": {
    "maxDays": 7,
    "minLevel": 0,
    "logIP": true,
    "logAuthId": false
  }
}
```

**Response 400:**

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "meta": {
      "appName": {
        "code": "validation_required",
        "message": "Missing required value."
      }
    }
  }
}
```

**Response 401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

**Response 403:**

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## Test S3 storage connection

Performs S3 storage connection test.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.testS3("backups");
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.testS3("backups");
```

### API details

> **POST** `/api/settings/test/s3`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| `Required` filesystem | String | The storage filesystem to test (`storage` or `backups`). |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Responses

**Response 204:**

```
null
```

**Response 400:**

```json
{
  "status": 400,
  "message": "Failed to initialize the S3 storage. Raw error:...",
  "data": {}
}
```

**Response 401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

---

## Send test email

Sends a test user email.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.testEmail("test@example.com", "verification");
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.testEmail("test@example.com", "verification");
```

### API details

> **POST** `/api/settings/test/email`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| `Optional` collection | String | The name or id of the auth collection. Fallbacks to *_superusers* if not set. |
| `Required` email | String | The receiver of the test email. |
| `Required` template | String | The test email template to send: `verification`, `password-reset` or `email-change`. |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Responses

**Response 204:**

```
null
```

**Response 400:**

```json
{
  "status": 400,
  "message": "Failed to send the test email.",
  "data": {
    "email": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

**Response 401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

---

## Generate Apple client secret

Generates a new Apple OAuth2 client secret key.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.generateAppleClientSecret(clientId, teamId, keyId, privateKey, duration)
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.settings.generateAppleClientSecret(clientId, teamId, keyId, privateKey, duration)
```

### API details

> **POST** `/api/settings/apple/generate-client-secret`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| `Required` clientId | String | The identifier of your app (aka. Service ID). |
| `Required` teamId | String | 10-character string associated with your developer account (usually could be found next to your name in the Apple Developer site). |
| `Required` keyId | String | 10-character key identifier generated for the "Sign in with Apple" private key associated with your developer account. |
| `Required` privateKey | String | PrivateKey is the private key associated to your app. |
| `Required` duration | Number | Duration specifies how long the generated JWT token should be considered valid. The specified value must be in seconds and max 15777000 (~6months). |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Responses

**Response 200:**

```json
{
    "secret": "..."
}
```

**Response 400:**

```json
{
  "status": 400,
  "message": "Failed to generate client secret. Raw error:...",
  "data": {}
}
```

**Response 401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```
