# API Records

## CRUD actions

### List/Search records

Returns a paginated records list, supporting sorting and filtering.

Depending on the collection's `listRule` value, the access to this action may or may not have been restricted.

*You could find individual generated records API documentation in the "Dashboard > Collections > API Preview".*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

// fetch a paginated records list
const resultList = await pb.collection('posts').getList(1, 50, {
    filter: 'created >= "2022-01-01 00:00:00" && someField1 != someField2',
});

// you can also fetch all records at once via getFullList
const records = await pb.collection('posts').getFullList({
    sort: '-created',
});

// or fetch only the first record that matches the specified filter
const record = await pb.collection('posts').getFirstListItem('someField="test"', {
    expand: 'relField1,relField2.subRelField',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

// fetch a paginated records list
final resultList = await pb.collection('posts').getList(
  page: 1,
  perPage: 50,
  filter: 'created >= "2022-01-01 00:00:00" && someField1 != someField2',
);

// you can also fetch all records at once via getFullList
final records = await pb.collection('posts').getFullList(sort: '-created');

// or fetch only the first record that matches the specified filter
final record = await pb.collection('posts').getFirstListItem(
  'someField="test"',
  expand: 'relField1,relField2.subRelField',
);
```

#### API details

> **GET** `/api/collections/collectionIdOrName/records`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the records' collection. |

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| page | Number | The page (aka. offset) of the paginated list (*default to 1*). |
| perPage | Number | The max returned records per page (*default to 30*). |
| sort | String | Specify the *ORDER BY* fields. Add `-` / `+` (default) in front of the attribute for DESC / ASC order, eg.: `// DESC by created and ASC by id` `?sort=-created,id` **Supported record sort fields:** `@random`, `@rowid`, `id`, **and any other collection field**. |
| filter | String | Filter expression to filter/search the returned records list (in addition to the collection's `listRule`), e.g.: `?filter=(title~'abc' && created>'2022-01-01')` **Supported record filter fields:** `id`, **+ any field from the collection schema**. The filter syntax follows the PocketBase filter rules and supports operators like `=`, `!=`, `>`, `>=`, `<`, `<=`, `~`, `!~`, `?=`, `?!=`, `?>`, `?>=`, `?<`, `?<=`, `?~`, `?!~`. To group and combine the filters you can use parentheses `(...)`, `&&` (AND) and `\|\|` (OR) tokens. Single line comments are also supported via `//`. |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |
| skipTotal | Boolean | If it is set the total counts query will be skipped and the response fields `totalItems` and `totalPages` will have `-1` value. This could drastically speed up the search queries when the total counters are not needed. For optimization purposes, it is set by default for the `getFirstListItem` SDKs method. |

**Responses**

**200:**

```json
{
  "page": 1,
  "perPage": 100,
  "totalItems": 2,
  "totalPages": 1,
  "items": [
    {
      "id": "ae40239d2bc4477",
      "collectionId": "a98f514eb05f454",
      "collectionName": "posts",
      "updated": "2022-06-25 11:03:50.052",
      "created": "2022-06-25 11:03:35.163",
      "title": "test1"
    },
    {
      "id": "d08dfc4f4d84419",
      "collectionId": "a98f514eb05f454",
      "collectionName": "posts",
      "updated": "2022-06-25 11:03:45.876",
      "created": "2022-06-25 11:03:45.876",
      "title": "test2"
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

**403:**

```json
{
  "status": 403,
  "message": "Only superusers can filter by '@collection.*'",
  "data": {}
}
```

---

### View record

Returns a single collection record by its ID.

Depending on the collection's `viewRule` value, the access to this action may or may not have been restricted.

*You could find individual generated records API documentation in the "Dashboard > Collections > API Preview".*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const record1 = await pb.collection('posts').getOne('RECORD_ID', {
    expand: 'relField1,relField2.subRelField',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final record1 = await pb.collection('posts').getOne('RECORD_ID',
  expand: 'relField1,relField2.subRelField',
);
```

#### API details

> **GET** `/api/collections/collectionIdOrName/records/recordId`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the record's collection. |
| recordId | String | ID of the record to view. |

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "id": "ae40239d2bc4477",
  "collectionId": "a98f514eb05f454",
  "collectionName": "posts",
  "updated": "2022-06-25 11:03:50.052",
  "created": "2022-06-25 11:03:35.163",
  "title": "test1"
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

**404:**

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

### Create record

Creates a new collection *Record*.

Depending on the collection's `createRule` value, the access to this action may or may not have been restricted.

*You could find individual generated records API documentation from the Dashboard.*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const record = await pb.collection('demo').create({
    title: 'Lorem ipsum',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final record = await pb.collection('demo').create(body: {
    'title': 'Lorem ipsum',
});
```

#### API details

> **POST** `/api/collections/collectionIdOrName/records`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the record's collection. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Optional id | String | **15 characters string** to store as record ID. If not set, it will be auto generated. |
| | | *Schema fields* |
| | | **Any field from the collection's schema.** |
| | | *Additional auth record fields* |
| Required password | String | Auth record password. |
| Required passwordConfirm | String | Auth record password confirmation. |

Body parameters could be sent as *JSON* or *multipart/form-data*.
File upload is supported only through *multipart/form-data*.

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "collectionId": "a98f514eb05f454",
  "collectionName": "demo",
  "id": "ae40239d2bc4477",
  "updated": "2022-06-25 11:03:50.052",
  "created": "2022-06-25 11:03:35.163",
  "title": "Lorem ipsum"
}
```

**400:**

```json
{
  "status": 400,
  "message": "Failed to create record.",
  "data": {
    "title": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
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

**404:**

```json
{
  "status": 404,
  "message": "The requested resource wasn't found. Missing collection context.",
  "data": {}
}
```

---

### Update record

Updates an existing collection *Record*.

Depending on the collection's `updateRule` value, the access to this action may or may not have been restricted.

*You could find individual generated records API documentation from the Dashboard.*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const record = await pb.collection('demo').update('YOUR_RECORD_ID', {
    title: 'Lorem ipsum',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final record = await pb.collection('demo').update('YOUR_RECORD_ID', body: {
    'title': 'Lorem ipsum',
});
```

#### API details

> **PATCH** `/api/collections/collectionIdOrName/records/recordId`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the record's collection. |
| recordId | String | ID of the record to update. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| | | *Schema fields* |
| | | **Any field from the collection's schema.** |
| | | *Additional auth record fields* |
| Optional oldPassword | String | Old auth record password. This field is required only when changing the record password. Superusers and auth records with "Manage" access can skip this field. |
| Optional password | String | New auth record password. |
| Optional passwordConfirm | String | New auth record password confirmation. |

Body parameters could be sent as *JSON* or *multipart/form-data*.
File upload is supported only through *multipart/form-data*.

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "collectionId": "a98f514eb05f454",
  "collectionName": "demo",
  "id": "ae40239d2bc4477",
  "updated": "2022-06-25 11:03:50.052",
  "created": "2022-06-25 11:03:35.163",
  "title": "Lorem ipsum"
}
```

**400:**

```json
{
  "status": 400,
  "message": "Failed to create record.",
  "data": {
    "title": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
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

**404:**

```json
{
  "status": 404,
  "message": "The requested resource wasn't found. Missing collection context.",
  "data": {}
}
```

---

### Delete record

Deletes a single collection *Record* by its ID.

Depending on the collection's `deleteRule` value, the access to this action may or may not have been restricted.

*You could find individual generated records API documentation from the Dashboard.*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection('demo').delete('YOUR_RECORD_ID');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection('demo').delete('YOUR_RECORD_ID');
```

#### API details

> **DELETE** `/api/collections/collectionIdOrName/records/recordId`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the record's collection. |
| recordId | String | ID of the record to delete. |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "Failed to delete record. Make sure that the record is not part of a required relation reference.",
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

**404:**

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

### Batch create/update/upsert/delete records

Batch and transactional create/update/upsert/delete of multiple records in a single request.

> **Warning** The batch Web API need to be explicitly enabled and configured from the *Dashboard > Settings > Application*.
>
> Because this endpoint processes the requests in a single read&write transaction, other queries may queue up and it could degrade the performance of your application if not used with proper care and configuration *(some recommendations: prefer using the smallest possible max processing time and body size limits; avoid large file uploads over slow S3 networks and custom hooks that communicate with slow external APIs)*.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const batch = pb.createBatch();

batch.collection('example1').create({ ... });
batch.collection('example2').update('RECORD_ID', { ... });
batch.collection('example3').delete('RECORD_ID');
batch.collection('example4').upsert({ ... });

const result = await batch.send();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final batch = pb.createBatch();

batch.collection('example1').create(body: { ... });
batch.collection('example2').update('RECORD_ID', body: { ... });
batch.collection('example3').delete('RECORD_ID');
batch.collection('example4').upsert(body: { ... });

final result = await batch.send();
```

#### API details

> **POST** `/api/batch`

**Body Parameters**

Body parameters could be sent as *application/json* or *multipart/form-data*.
File upload is supported only via *multipart/form-data* (see below for more details).

| Param | Description |
| --- | --- |
| Required requests | `Array<Request>` - List of the requests to process. The supported batch request actions are: - record create - `POST /api/collections/{collection}/records` - record update - `PATCH /api/collections/{collection}/records/{id}` - record upsert - `PUT /api/collections/{collection}/records` (the body must have `id` field) - record delete - `DELETE /api/collections/{collection}/records/{id}` Each batch Request element have the following properties: - `url path` *(could include query parameters)* - `method` *(GET, POST, PUT, PATCH, DELETE)* - `headers` (custom per-request `Authorization` header is not supported at the moment, aka. all batch requests have the same auth state) - `body` **NB!** When the batch request is send as `multipart/form-data`, the regular batch action fields are expected to be submitted as serialized json under the `@jsonPayload` field and file keys need to follow the pattern `requests.N.fileField` or `requests[N].fileField` *(this is usually handled transparently by the SDKs when their specific object notation is used)*. If you don't use the SDKs or prefer manually to construct the `FormData` body, then it could look something like: |

```javascript
const formData = new FormData();

formData.append("@jsonPayload", JSON.stringify({
    requests: [
        {
            method: "POST",
            url: "/api/collections/example/records?expand=user",
            body: { title: "test1" },
        },
        {
            method: "PATCH",
            url: "/api/collections/example/records/RECORD_ID",
            body: { title: "test2" },
        },
        {
            method: "DELETE",
            url: "/api/collections/example/records/RECORD_ID",
        },
    ]
}))

// file for the first request
formData.append("requests.0.document", new File(...))

// file for the second request
formData.append("requests.1.document", new File(...))
```

**Responses**

**200:**

```json
[
  {
    "status": 200,
    "body": {
      "collectionId": "a98f514eb05f454",
      "collectionName": "demo",
      "id": "ae40239d2bc4477",
      "updated": "2022-06-25 11:03:50.052",
      "created": "2022-06-25 11:03:35.163",
      "title": "test1",
      "document": "file_a98f51.txt"
    }
  },
  {
    "status": 200,
    "body": {
      "collectionId": "a98f514eb05f454",
      "collectionName": "demo",
      "id": "31y1gc447bc9602",
      "updated": "2022-06-25 11:03:50.052",
      "created": "2022-06-25 11:03:35.163",
      "title": "test2",
      "document": "file_f514eb0.txt"
    }
  }
]
```

**400:**

```json
{
  "status": 400,
  "message": "Batch transaction failed.",
  "data": {
    "requests": {
      "1": {
        "code": "batch_request_failed",
        "message": "Batch request failed.",
        "response": {
          "status": 400,
          "message": "Failed to create record.",
          "data": {
            "title": {
              "code": "validation_min_text_constraint",
              "message": "Must be at least 3 character(s).",
              "params": { "min": 3 }
            }
          }
        }
      }
    }
  }
}
```

**403:**

```json
{
  "status": 403,
  "message": "Batch requests are not allowed.",
  "data": {}
}
```

---

## Auth record actions

### List auth methods

Returns a public list with the allowed collection authentication methods.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const result = await pb.collection('users').listAuthMethods();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final result = await pb.collection('users').listAuthMethods();
```

#### API details

> **GET** `/api/collections/collectionIdOrName/auth-methods`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "password": {
    "enabled": true,
    "identityFields": ["email"]
  },
  "oauth2": {
    "enabled": true,
    "providers": [
      {
        "name": "github",
        "displayName": "GitHub",
        "state": "nT7SLxzXKAVMeRQJtxSYj9kvnJAvGk",
        "authURL": "https://github.com/login/oauth/authorize?client_id=test&code_challenge=fcf8WAhNI6uCLJYgJubLyWXHvfs8xghoLe3zksBvxjE&code_challenge_method=S256&response_type=code&scope=read%3Auser+user%3Aemail&state=nT7SLxzXKAVMeRQJtxSYj9kvnJAvGk&redirect_uri=",
        "codeVerifier": "PwBG5OKR2IyQ7siLrrcgWHFwLLLAeUrz7PS1nY4AneG",
        "codeChallenge": "fcf8WAhNI6uCLJYgJubLyWXHvfs8xghoLe3zksBvxjE",
        "codeChallengeMethod": "S256"
      }
    ]
  },
  "mfa": {
    "enabled": false,
    "duration": 0
  },
  "otp": {
    "enabled": false,
    "duration": 0
  }
}
```

---

### Auth with password

Authenticate a single auth record by combination of a password and a unique identity field (e.g. email).

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const authData = await pb.collection('users').authWithPassword(
    'YOUR_USERNAME_OR_EMAIL',
    'YOUR_PASSWORD',
);

// after the above you can also access the auth data from the authStore
console.log(pb.authStore.isValid);
console.log(pb.authStore.token);
console.log(pb.authStore.record.id);

// "logout" the last authenticated record
pb.authStore.clear();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final authData = await pb.collection('users').authWithPassword(
  'YOUR_USERNAME_OR_EMAIL',
  'YOUR_PASSWORD',
);

// after the above you can also access the auth data from the authStore
print(pb.authStore.isValid);
print(pb.authStore.token);
print(pb.authStore.record.id);

// "logout" the last authenticated record
pb.authStore.clear();
```

#### API details

> **POST** `/api/collections/collectionIdOrName/auth-with-password`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required identity | String | Auth record username or email address. |
| Required password | String | Auth record password. |
| Optional identityField | String | A specific identity field to use (by default fallbacks to the first matching one). |

Body parameters could be sent as *JSON* or *multipart/form-data*.

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,record.expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,record.description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRxMXhsY2xtZmxva3UzMyIsInR5cGUiOiJhdXRoUmVjb3JkIiwiY29sbGVjdGlvbklkIjoiX3BiX3VzZXJzX2F1dGhfIiwiZXhwIjoyMjA4OTg1MjYxfQ.UwD8JvkbQtXpymT09d7J6fdA0aP9g4FJ1GPh_ggEkzc",
  "record": {
    "id": "8171022dc95a4ed",
    "collectionId": "d2972397d45614e",
    "collectionName": "users",
    "created": "2022-06-24 06:24:18.434Z",
    "updated": "2022-06-24 06:24:18.889Z",
    "username": "test@example.com",
    "email": "test@example.com",
    "verified": false,
    "emailVisibility": true,
    "someCustomField": "example 123"
  }
}
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "password": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Auth with OAuth2

Authenticate with an OAuth2 provider and returns a new auth token and record data.

This action usually should be called right after the provider login page redirect.

You could also check the [OAuth2 web integration example](/docs/authentication#web-oauth2-integration).

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const authData = await pb.collection('users').authWithOAuth2Code(
    'google',
    'CODE',
    'VERIFIER',
    'REDIRECT_URL',
    // optional data that will be used for the new account on OAuth2 sign-up
    {
      'name': 'test',
    },
);

// after the above you can also access the auth data from the authStore
console.log(pb.authStore.isValid);
console.log(pb.authStore.token);
console.log(pb.authStore.record.id);

// "logout" the last authenticated record
pb.authStore.clear();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final authData = await pb.collection('users').authWithOAuth2Code(
  'google',
  'CODE',
  'VERIFIER',
  'REDIRECT_URL',
  // optional data that will be used for the new account on OAuth2 sign-up
  createData: {
    'name': 'test',
  },
);

// after the above you can also access the auth data from the authStore
print(pb.authStore.isValid);
print(pb.authStore.token);
print(pb.authStore.record.id);

// "logout" the last authenticated record
pb.authStore.clear();
```

#### API details

> **POST** `/api/collections/collectionIdOrName/auth-with-oauth2`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required provider | String | The name of the OAuth2 client provider (e.g. "google"). |
| Required code | String | The authorization code returned from the initial request. |
| Required codeVerifier | String | The code verifier sent with the initial request as part of the code_challenge. |
| Required redirectUrl | String | The redirect url sent with the initial request. |
| Optional createData | Object | Optional data that will be used when creating the auth record on OAuth2 sign-up. The created auth record must comply with the same requirements and validations in the regular **create** action. *The data can only be in `json`, aka. `multipart/form-data` and files upload currently are not supported during OAuth2 sign-ups.* |

Body parameters could be sent as *JSON* or *multipart/form-data*.

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,record.expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,record.description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRxMXhsY2xtZmxva3UzMyIsInR5cGUiOiJhdXRoUmVjb3JkIiwiY29sbGVjdGlvbklkIjoiX3BiX3VzZXJzX2F1dGhfIiwiZXhwIjoyMjA4OTg1MjYxfQ.UwD8JvkbQtXpymT09d7J6fdA0aP9g4FJ1GPh_ggEkzc",
  "record": {
    "id": "8171022dc95a4ed",
    "collectionId": "d2972397d45614e",
    "collectionName": "users",
    "created": "2022-06-24 06:24:18.434Z",
    "updated": "2022-06-24 06:24:18.889Z",
    "username": "test@example.com",
    "email": "test@example.com",
    "verified": true,
    "emailVisibility": false,
    "someCustomField": "example 123"
  },
  "meta": {
    "id": "abc123",
    "name": "John Doe",
    "username": "john.doe",
    "email": "test@example.com",
    "isNew": false,
    "avatarURL": "https://example.com/avatar.png",
    "rawUser": {...},
    "accessToken": "...",
    "refreshToken": "...",
    "expiry": "..."
  }
}
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "provider": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Auth with OTP

Authenticate a single auth record with an one-time password (OTP).

Note that when requesting an OTP we return an `otpId` even if a user with the provided email doesn't exist as a very basic enumeration protection.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

// send OTP email to the provided auth record
const req = await pb.collection('users').requestOTP('test@example.com');

// ... show a screen/popup to enter the password from the email ...

// authenticate with the requested OTP id and the email password
const authData = await pb.collection('users').authWithOTP(req.otpId, "YOUR_OTP");

// after the above you can also access the auth data from the authStore
console.log(pb.authStore.isValid);
console.log(pb.authStore.token);
console.log(pb.authStore.record.id);

// "logout"
pb.authStore.clear();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

// send OTP email to the provided auth record
final req = await pb.collection('users').requestOTP('test@example.com');

// ... show a screen/popup to enter the password from the email ...

// authenticate with the requested OTP id and the email password
final authData = await pb.collection('users').authWithOTP(req.otpId, "YOUR_OTP");

// after the above you can also access the auth data from the authStore
print(pb.authStore.isValid);
print(pb.authStore.token);
print(pb.authStore.record.id);

// "logout"
pb.authStore.clear();
```

#### API details

##### OTP Request

> **POST** `/api/collections/collectionIdOrName/request-otp`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required email | String | The auth record email address to send the OTP request (if exists). |

**Responses**

**200:**

```json
{
  "otpId": "RANDOM_OTP_ID"
}
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "email": {
      "code": "validation_is_email",
      "message": "Must be a valid email address."
    }
  }
}
```

**429:**

```json
{
  "status": 429,
  "message": "You've send too many OTP requests, please try again later.",
  "data": {}
}
```

##### OTP Auth

> **POST** `/api/collections/collectionIdOrName/auth-with-otp`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required otpId | String | The id of the OTP request. |
| Required password | String | The one-time password. |

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,record.expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,record.description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRxMXhsY2xtZmxva3UzMyIsInR5cGUiOiJhdXRoUmVjb3JkIiwiY29sbGVjdGlvbklkIjoiX3BiX3VzZXJzX2F1dGhfIiwiZXhwIjoyMjA4OTg1MjYxfQ.UwD8JvkbQtXpymT09d7J6fdA0aP9g4FJ1GPh_ggEkzc",
  "record": {
    "id": "8171022dc95a4ed",
    "collectionId": "d2972397d45614e",
    "collectionName": "users",
    "created": "2022-06-24 06:24:18.434Z",
    "updated": "2022-06-24 06:24:18.889Z",
    "username": "test@example.com",
    "email": "test@example.com",
    "verified": false,
    "emailVisibility": true,
    "someCustomField": "example 123"
  }
}
```

**400:**

```json
{
  "status": 400,
  "message": "Failed to authenticate.",
  "data": {
    "otpId": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Auth refresh

Returns a new auth response (token and user data) for already authenticated auth record.

*This method is usually called by users on page/screen reload to ensure that the previously stored data in `pb.authStore` is still valid and up-to-date.*

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const authData = await pb.collection('users').authRefresh();

// after the above you can also access the refreshed auth data from the authStore
console.log(pb.authStore.isValid);
console.log(pb.authStore.token);
console.log(pb.authStore.record.id);
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final authData = await pb.collection('users').authRefresh();

// after the above you can also access the refreshed auth data from the authStore
print(pb.authStore.isValid);
print(pb.authStore.token);
print(pb.authStore.record.id);
```

#### API details

> **POST** `/api/collections/collectionIdOrName/auth-refresh`
>
> Requires `Authorization:TOKEN`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,record.expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,record.description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRxMXhsY2xtZmxva3UzMyIsInR5cGUiOiJhdXRoUmVjb3JkIiwiY29sbGVjdGlvbklkIjoiX3BiX3VzZXJzX2F1dGhfIiwiZXhwIjoyMjA4OTg1MjYxfQ.UwD8JvkbQtXpymT09d7J6fdA0aP9g4FJ1GPh_ggEkzc",
  "record": {
    "id": "8171022dc95a4ed",
    "collectionId": "d2972397d45614e",
    "collectionName": "users",
    "created": "2022-06-24 06:24:18.434Z",
    "updated": "2022-06-24 06:24:18.889Z",
    "username": "test@example.com",
    "email": "test@example.com",
    "verified": false,
    "emailVisibility": true,
    "someCustomField": "example 123"
  }
}
```

**401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token to be set.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record model is not allowed to perform this action.",
  "data": {}
}
```

**404:**

```json
{
  "status": 404,
  "message": "Missing auth record context.",
  "data": {}
}
```

---

### Verification

Sends auth record email verification request.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').requestVerification('test@example.com');

// ---
// (optional) in your custom confirmation page:
// ---

await pb.collection('users').confirmVerification('VERIFICATION_TOKEN');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').requestVerification('test@example.com');

// ---
// (optional) in your custom confirmation page:
// ---

await pb.collection('users').confirmVerification('VERIFICATION_TOKEN');
```

#### API details

##### Request verification

> **POST** `/api/collections/collectionIdOrName/request-verification`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required email | String | The auth record email address to send the verification request (if exists). |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "email": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

##### Confirm verification

> **POST** `/api/collections/collectionIdOrName/confirm-verification`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required token | String | The token from the verification request email. |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "token": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Password reset

Sends auth record password reset email request.

On successful password reset all previously issued auth tokens for the specific record will be automatically invalidated.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').requestPasswordReset('test@example.com');

// ---
// (optional) in your custom confirmation page:
// ---

// note: after this call all previously issued auth tokens are invalidated
await pb.collection('users').confirmPasswordReset(
    'RESET_TOKEN',
    'NEW_PASSWORD',
    'NEW_PASSWORD_CONFIRM',
);
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').requestPasswordReset('test@example.com');

// ---
// (optional) in your custom confirmation page:
// ---

// note: after this call all previously issued auth tokens are invalidated
await pb.collection('users').confirmPasswordReset(
  'RESET_TOKEN',
  'NEW_PASSWORD',
  'NEW_PASSWORD_CONFIRM',
);
```

#### API details

##### Request password reset

> **POST** `/api/collections/collectionIdOrName/request-password-reset`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required email | String | The auth record email address to send the password reset request (if exists). |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "email": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

##### Confirm password reset

> **POST** `/api/collections/collectionIdOrName/confirm-password-reset`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required token | String | The token from the password reset request email. |
| Required password | String | The new password to set. |
| Required passwordConfirm | String | The new password confirmation. |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "token": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Email change

Sends auth record email change request.

On successful email change all previously issued auth tokens for the specific record will be automatically invalidated.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').authWithPassword('test@example.com', '1234567890');

await pb.collection('users').requestEmailChange('new@example.com');

// ---
// (optional) in your custom confirmation page:
// ---

// note: after this call all previously issued auth tokens are invalidated
await pb.collection('users').confirmEmailChange('EMAIL_CHANGE_TOKEN', 'YOUR_PASSWORD');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection('users').authWithPassword('test@example.com', '1234567890');

await pb.collection('users').requestEmailChange('new@example.com');

...

// ---
// (optional) in your custom confirmation page:
// ---

// note: after this call all previously issued auth tokens are invalidated
await pb.collection('users').confirmEmailChange('EMAIL_CHANGE_TOKEN', 'YOUR_PASSWORD');
```

#### API details

##### Request email change

> **POST** `/api/collections/collectionIdOrName/request-email-change`
>
> Requires `Authorization:TOKEN`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required newEmail | String | The new email address to send the change email request. |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "newEmail": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

**401:**

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token to be set.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record model is not allowed to perform this action.",
  "data": {}
}
```

##### Confirm email change

> **POST** `/api/collections/collectionIdOrName/confirm-email-change`

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Required token | String | The token from the change email request email. |
| Required password | String | The account password to confirm the email change. |

**Responses**

**204:**

```
null
```

**400:**

```json
{
  "status": 400,
  "message": "An error occurred while validating the submitted data.",
  "data": {
    "token": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

---

### Impersonate

Impersonate allows you to authenticate as a different user by generating a **nonrefreshable** auth token.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

// authenticate as superuser
await pb.collection("_superusers").authWithPassword("test@example.com", "1234567890");

// impersonate
// (the custom token duration is optional and must be in seconds)
const impersonateClient = pb.collection("users").impersonate("USER_RECORD_ID", 3600)

// log the impersonate token and user data
console.log(impersonateClient.authStore.token);
console.log(impersonateClient.authStore.record);

// send requests as the impersonated user
impersonateClient.collection("example").getFullList();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

// authenticate as superuser
await pb.collection("_superusers").authWithPassword("test@example.com", "1234567890");

// impersonate
// (the custom token duration is optional and must be in seconds)
final impersonateClient = pb.collection("users").impersonate("USER_RECORD_ID", 3600)

// log the impersonate token and user data
print(impersonateClient.authStore.token);
print(impersonateClient.authStore.record);

// send requests as the impersonated user
impersonateClient.collection("example").getFullList();
```

#### API details

> **POST** `/api/collections/collectionIdOrName/impersonate/id`
>
> Requires `Authorization:TOKEN`

**Path parameters**

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the auth collection. |
| id | String | ID of the auth record to impersonate. |

**Body Parameters**

| Param | Type | Description |
| --- | --- | --- |
| Optional duration | Number | Optional custom JWT duration for the `exp` claim (in seconds). If not set or 0, it fallbacks to the default collection auth token duration option. |

Body parameters could be sent as *JSON* or *multipart/form-data*.

**Query parameters**

| Param | Type | Description |
| --- | --- | --- |
| expand | String | Auto expand relations when returning the response. Ex.: `?expand=relField1,relField2.subRelField` Supports up to 6-levels depth nested relations expansion. The expanded relations will be appended to the record under the `expand` property (e.g. `"expand": {"relField1": {...}, ...}`). Only the relations to which the request user has permissions to **view** will be expanded. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,record.expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,record.description:excerpt(200,true)` |

**Responses**

**200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb2xsZWN0aW9uSWQiOiJfcGJjX2MwcHdrZXNjcXMiLCJleHAiOjE3MzAzNjgxMTUsImlkIjoicXkwMmMxdDBueDBvanFuIiwicmVmcmVzaGFibGUiOmZhbHNlLCJ0eXBlIjoiYXV0aCJ9.1JOaE54TyPdDLf0mb0T6roIYeh8Y1HfJvDlYZADMN4U",
  "record": {
    "id": "8171022dc95a4ed",
    "collectionId": "d2972397d45614e",
    "collectionName": "users",
    "created": "2022-06-24 06:24:18.434Z",
    "updated": "2022-06-24 06:24:18.889Z",
    "username": "test@example.com",
    "email": "test@example.com",
    "verified": false,
    "emailVisibility": true,
    "someCustomField": "example 123"
  }
}
```

**400:**

```json
{
  "status": 400,
  "message": "The request requires valid record authorization token to be set.",
  "data": {
    "duration": {
      "code": "validation_min_greater_equal_than_required",
      "message": "Must be no less than 0."
    }
  }
}
```

**401:**

```json
{
  "status": 401,
  "message": "An error occurred while validating the submitted data.",
  "data": {}
}
```

**403:**

```json
{
  "status": 403,
  "message": "The authorized record model is not allowed to perform this action.",
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
