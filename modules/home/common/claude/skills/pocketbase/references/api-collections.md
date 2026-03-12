# API Collections

## List collections

Returns a paginated Collections list.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

// fetch a paginated collections list
const pageResult = await pb.collections.getList(1, 100, {
    filter: 'created >= "2022-01-01 00:00:00"',
});

// you can also fetch all collections at once via getFullList
const collections = await pb.collections.getFullList({ sort: '-created' });

// or fetch only the first collection that matches the specified filter
const collection = await pb.collections.getFirstListItem('type="auth"');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

// fetch a paginated collections list
final pageResult = await pb.collections.getList(
    page: 1,
    perPage: 100,
    filter: 'created >= "2022-01-01 00:00:00"',
);

// you can also fetch all collections at once via getFullList
final collections = await pb.collections.getFullList(sort: '-created');

// or fetch only the first collection that matches the specified filter
final collection = await pb.collections.getFirstListItem('type="auth"');
```

### API details

> **GET** `/api/collections`
>
> Requires `Authorization:TOKEN`

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| page | Number | The page (aka. offset) of the paginated list (*default to 1*). |
| perPage | Number | The max returned collections per page (*default to 30*). |
| sort | String | Specify the *ORDER BY* fields. Add `-` / `+` (default) in front of the attribute for DESC / ASC order, e.g.: `?sort=-created,id` **Supported collection sort fields:** `@random`, `id`, `created`, `updated`, `name`, `type`, `system` |
| filter | String | Filter expression to filter/search the returned collections list, e.g.: `?filter=(name~'abc' && created>'2022-01-01')` **Supported collection filter fields:** `id`, `created`, `updated`, `name`, `type`, `system`. The filter syntax follows the standard PocketBase filter rules. |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |
| skipTotal | Boolean | If it is set the `totalItems` and `totalPages` fields won't be populated in the response, which could help speed up the query for large datasets. |

### Responses

#### 200

```json
{
  "page": 1,
  "perPage": 2,
  "totalItems": 10,
  "totalPages": 5,
  "items": [
    {
      "id": "_pbc_344172009",
      "listRule": null,
      "viewRule": null,
      "createRule": null,
      "updateRule": null,
      "deleteRule": null,
      "name": "users",
      "type": "auth",
      "fields": [
        {
          "autogeneratePattern": "[a-z0-9]{15}",
          "hidden": false,
          "id": "text3208210256",
          "max": 15,
          "min": 15,
          "name": "id",
          "pattern": "^[a-z0-9]+$",
          "presentable": false,
          "primaryKey": true,
          "required": true,
          "system": true,
          "type": "text"
        },
        {
          "cost": 0,
          "hidden": true,
          "id": "password901924565",
          "max": 0,
          "min": 8,
          "name": "password",
          "pattern": "",
          "presentable": false,
          "required": true,
          "system": true,
          "type": "password"
        },
        {
          "autogeneratePattern": "[a-zA-Z0-9]{50}",
          "hidden": true,
          "id": "text2504183744",
          "max": 60,
          "min": 30,
          "name": "tokenKey",
          "pattern": "",
          "presentable": false,
          "primaryKey": false,
          "required": true,
          "system": true,
          "type": "text"
        },
        {
          "exceptDomains": null,
          "hidden": false,
          "id": "email3885137012",
          "name": "email",
          "onlyDomains": null,
          "presentable": false,
          "required": true,
          "system": true,
          "type": "email"
        },
        {
          "hidden": false,
          "id": "bool1547992806",
          "name": "emailVisibility",
          "presentable": false,
          "required": false,
          "system": true,
          "type": "bool"
        },
        {
          "hidden": false,
          "id": "bool256245529",
          "name": "verified",
          "presentable": false,
          "required": false,
          "system": true,
          "type": "bool"
        },
        {
          "autogeneratePattern": "",
          "hidden": false,
          "id": "text1579384326",
          "max": 255,
          "min": 0,
          "name": "name",
          "pattern": "",
          "presentable": false,
          "primaryKey": false,
          "required": false,
          "system": false,
          "type": "text"
        },
        {
          "hidden": false,
          "id": "file376926767",
          "maxSelect": 1,
          "maxSize": 0,
          "mimeTypes": [
            "image/jpeg",
            "image/png",
            "image/svg+xml",
            "image/gif",
            "image/webp"
          ],
          "name": "avatar",
          "presentable": false,
          "protected": false,
          "required": false,
          "system": false,
          "thumbs": null,
          "type": "file"
        },
        {
          "hidden": false,
          "id": "autodate2990389176",
          "name": "created",
          "onCreate": true,
          "onUpdate": false,
          "presentable": false,
          "system": false,
          "type": "autodate"
        },
        {
          "hidden": false,
          "id": "autodate3332085495",
          "name": "updated",
          "onCreate": true,
          "onUpdate": true,
          "presentable": false,
          "system": false,
          "type": "autodate"
        }
      ],
      "indexes": [
        "CREATE UNIQUE INDEX `idx_tokenKey__pbc_344172009` ON `users` (`tokenKey`)",
        "CREATE UNIQUE INDEX `idx_email__pbc_344172009` ON `users` (`email`) WHERE `email` != ''"
      ],
      "system": false,
      "authRule": "",
      "manageRule": null,
      "authAlert": {
        "enabled": true,
        "emailTemplate": {
          "subject": "Login from a new location",
          "body": "..."
        }
      },
      "oauth2": {
        "enabled": false,
        "mappedFields": {
          "id": "",
          "name": "name",
          "username": "",
          "avatarURL": "avatar"
        },
        "providers": [
            {
                "pkce": null,
                "name": "google",
                "clientId": "abc",
                "authURL": "",
                "tokenURL": "",
                "userInfoURL": "",
                "displayName": "",
                "extra": null
            }
        ]
      },
      "passwordAuth": {
        "enabled": true,
        "identityFields": [
          "email"
        ]
      },
      "mfa": {
        "enabled": false,
        "duration": 1800,
        "rule": ""
      },
      "otp": {
        "enabled": false,
        "duration": 180,
        "length": 8,
        "emailTemplate": {
          "subject": "OTP for {APP_NAME}",
          "body": "..."
        }
      },
      "authToken": {
        "duration": 604800
      },
      "passwordResetToken": {
        "duration": 1800
      },
      "emailChangeToken": {
        "duration": 1800
      },
      "verificationToken": {
        "duration": 259200
      },
      "fileToken": {
        "duration": 180
      },
      "verificationTemplate": {
        "subject": "Verify your {APP_NAME} email",
        "body": "..."
      },
      "resetPasswordTemplate": {
        "subject": "Reset your {APP_NAME} password",
        "body": "..."
      },
      "confirmEmailChangeTemplate": {
        "subject": "Confirm your {APP_NAME} new email address",
        "body": "..."
      }
    },
    {
      "id": "_pbc_2287844090",
      "listRule": null,
      "viewRule": null,
      "createRule": null,
      "updateRule": null,
      "deleteRule": null,
      "name": "posts",
      "type": "base",
      "fields": [
        {
          "autogeneratePattern": "[a-z0-9]{15}",
          "hidden": false,
          "id": "text3208210256",
          "max": 15,
          "min": 15,
          "name": "id",
          "pattern": "^[a-z0-9]+$",
          "presentable": false,
          "primaryKey": true,
          "required": true,
          "system": true,
          "type": "text"
        },
        {
          "autogeneratePattern": "",
          "hidden": false,
          "id": "text724990059",
          "max": 0,
          "min": 0,
          "name": "title",
          "pattern": "",
          "presentable": false,
          "primaryKey": false,
          "required": false,
          "system": false,
          "type": "text"
        },
        {
          "hidden": false,
          "id": "autodate2990389176",
          "name": "created",
          "onCreate": true,
          "onUpdate": false,
          "presentable": false,
          "system": false,
          "type": "autodate"
        },
        {
          "hidden": false,
          "id": "autodate3332085495",
          "name": "updated",
          "onCreate": true,
          "onUpdate": true,
          "presentable": false,
          "system": false,
          "type": "autodate"
        }
      ],
      "indexes": [],
      "system": false
    }
  ]
}
```

#### 400

```json
{
  "status": 400,
  "message": "Something went wrong while processing your request. Invalid filter.",
  "data": {}
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "Only superusers can perform this action.",
  "data": {}
}
```

---

## View collection

Returns a single Collection by its ID or name.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const collection = await pb.collections.getOne('demo');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final collection = await pb.collections.getOne('demo');
```

### API details

> **GET** `/api/collections/collectionIdOrName`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the collection to view. |

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

#### 200

```json
{
  "id": "_pbc_2287844090",
  "listRule": null,
  "viewRule": null,
  "createRule": null,
  "updateRule": null,
  "deleteRule": null,
  "name": "posts",
  "type": "base",
  "fields": [
    {
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "id": "text3208210256",
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-z0-9]+$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    },
    {
      "autogeneratePattern": "",
      "hidden": false,
      "id": "text724990059",
      "max": 0,
      "min": 0,
      "name": "title",
      "pattern": "",
      "presentable": false,
      "primaryKey": false,
      "required": false,
      "system": false,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "autodate2990389176",
      "name": "created",
      "onCreate": true,
      "onUpdate": false,
      "presentable": false,
      "system": false,
      "type": "autodate"
    },
    {
      "hidden": false,
      "id": "autodate3332085495",
      "name": "updated",
      "onCreate": true,
      "onUpdate": true,
      "presentable": false,
      "system": false,
      "type": "autodate"
    }
  ],
  "indexes": [],
  "system": false
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

#### 404

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

## Create collection

Creates a new Collection.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

// create base collection
const base = await pb.collections.create({
    name: 'exampleBase',
    type: 'base',
    fields: [
        {
            name: 'title',
            type: 'text',
            required: true,
            min: 10,
        },
        {
            name: 'status',
            type: 'bool',
        },
    ],
});

// create auth collection
const auth = await pb.collections.create({
    name: 'exampleAuth',
    type: 'auth',
    createRule: 'id = @request.auth.id',
    updateRule: 'id = @request.auth.id',
    deleteRule: 'id = @request.auth.id',
    fields: [
        {
            name: 'name',
            type: 'text',
        }
    ],
    passwordAuth: {
        enabled: true,
        identityFields: ['email']
    },
});

// create view collection
const view = await pb.collections.create({
    name: 'exampleView',
    type: 'view',
    listRule: '@request.auth.id != ""',
    viewRule: null,
    // the schema will be autogenerated from the below query
    viewQuery: 'SELECT id, name from posts',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

// create base collection
final base = await pb.collections.create(body: {
    'name': 'exampleBase',
    'type': 'base',
    'fields': [
        {
            'name': 'title',
            'type': 'text',
            'required': true,
            'min': 10,
        },
        {
            'name': 'status',
            'type': 'bool',
        },
    ],
});

// create auth collection
final auth = await pb.collections.create(body: {
    'name': 'exampleAuth',
    'type': 'auth',
    'createRule': 'id = @request.auth.id',
    'updateRule': 'id = @request.auth.id',
    'deleteRule': 'id = @request.auth.id',
    'fields': [
        {
            'name': 'name',
            'type': 'text',
        }
    ],
    'passwordAuth': {
        'enabled': true,
        'identityFields': ['email']
    },
});

// create view collection
final view = await pb.collections.create(body: {
    'name': 'exampleView',
    'type': 'view',
    'listRule': '@request.auth.id != ""',
    'viewRule': null,
    // the schema will be autogenerated from the below query
    'viewQuery': 'SELECT id, name from posts',
});
```

### API details

> **POST** `/api/collections`
>
> Requires `Authorization:TOKEN`

### Body Parameters

Body parameters could be sent as *JSON* or *multipart/form-data*.

```
{
    // 15 characters string to store as collection ID.
    // If not set, it will be auto generated.
    id (optional): string

    // Unique collection name (used as a table name for the records table).
    name (required):  string

    // Type of the collection.
    // If not set, the collection type will be "base" by default.
    type (optional): "base" | "view" | "auth"

    // List with the collection fields.
    // This field is optional and autopopulated for "view" collections based on the viewQuery.
    fields (required|optional): Array<Field>

    // The collection indexes and unique constraints.
    // Note that "view" collections don't support indexes.
    indexes (optional): Array<string>

    // Marks the collection as "system" to prevent being renamed, deleted or modify its API rules.
    system (optional): boolean

    // CRUD API rules
    listRule (optional):   null|string
    viewRule (optional):   null|string
    createRule (optional): null|string
    updateRule (optional): null|string
    deleteRule (optional): null|string

    // -------------------------------------------------------
    // view options
    // -------------------------------------------------------

    viewQuery (required):  string

    // -------------------------------------------------------
    // auth options
    // -------------------------------------------------------

    // API rule that gives admin-like permissions to allow fully managing the auth record(s),
    // e.g. changing the password without requiring to enter the old one, directly updating the
    // verified state or email, etc. This rule is executed in addition to the createRule and updateRule.
    manageRule (optional): null|string

    // API rule that could be used to specify additional record constraints applied after record
    // authentication and right before returning the auth token response to the client.
    //
    // For example, to allow only verified users you could set it to "verified = true".
    //
    // Set it to empty string to allow any Auth collection record to authenticate.
    //
    // Set it to null to disallow authentication altogether for the collection.
    authRule (optional): null|string

    // AuthAlert defines options related to the auth alerts on new device login.
    authAlert (optional): {
        enabled (optional): boolean
        emailTemplate (optional): {
            subject (required): string
            body (required):    string
        }
    }

    // OAuth2 specifies whether OAuth2 auth is enabled for the collection
    // and which OAuth2 providers are allowed.
    oauth2 (optional): {
        enabled (optional): boolean
        mappedFields (optional): {
            id (optional):        string
            name (optional):      string
            username (optional):  string
            avatarURL (optional): string
        }
        providers (optional): [
            {
                name (required):         string
                clientId (required):     string
                clientSecret (required): string
                authURL (optional):      string
                tokenURL (optional):     string
                userInfoURL (optional):  string
                displayName (optional):  string
                pkce (optional):         null|boolean
                extra (optional):        null|Object<string,any>
            }
        ]
    }

    // PasswordAuth defines options related to the collection password authentication.
    passwordAuth (optional): {
        enabled (optional):        boolean
        identityFields (required): Array<string>
    }

    // MFA defines options related to the Multi-factor authentication (MFA).
    mfa (optional):{
        enabled (optional):  boolean
        duration (required): number
        rule (optional):     string
    }

    // OTP defines options related to the One-time password authentication (OTP).
    otp (optional): {
        enabled (optional):  boolean
        duration (required): number
        length (required):   number
        emailTemplate (optional): {
            subject (required): string
            body (required):    string
        }
    }

    // Token configurations.
    authToken (optional): {
        duration (required): number
        secret (required):   string
    }
    passwordResetToken (optional): {
        duration (required): number
        secret (required):   string
    }
    emailChangeToken (optional): {
        duration (required): number
        secret (required):   string
    }
    verificationToken (optional): {
        duration (required): number
        secret (required):   string
    }
    fileToken (optional): {
        duration (required): number
        secret (required):   string
    }

    // Default email templates.
    verificationTemplate (optional): {
        subject (required): string
        body (required):    string
    }
    resetPasswordTemplate (optional): {
        subject (required): string
        body (required):    string
    }
    confirmEmailChangeTemplate (optional): {
        subject (required): string
        body (required):    string
    }
}
```

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

#### 200

```json
{
  "id": "_pbc_2287844090",
  "listRule": null,
  "viewRule": null,
  "createRule": null,
  "updateRule": null,
  "deleteRule": null,
  "name": "posts",
  "type": "base",
  "fields": [
    {
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "id": "text3208210256",
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-z0-9]+$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    },
    {
      "autogeneratePattern": "",
      "hidden": false,
      "id": "text724990059",
      "max": 0,
      "min": 0,
      "name": "title",
      "pattern": "",
      "presentable": false,
      "primaryKey": false,
      "required": false,
      "system": false,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "autodate2990389176",
      "name": "created",
      "onCreate": true,
      "onUpdate": false,
      "presentable": false,
      "system": false,
      "type": "autodate"
    },
    {
      "hidden": false,
      "id": "autodate3332085495",
      "name": "updated",
      "onCreate": true,
      "onUpdate": true,
      "presentable": false,
      "system": false,
      "type": "autodate"
    }
  ],
  "indexes": [],
  "system": false
}
```

#### 400

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "title": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## Update collection

Updates a single Collection by its ID or name.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

const collection = await pb.collections.update('demo', {
    name: 'new_demo',
    listRule: 'created > "2022-01-01 00:00:00"',
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '123456');

final collection = await pb.collections.update('demo', body: {
    'name': 'new_demo',
    'listRule': 'created > "2022-01-01 00:00:00"',
});
```

### API details

> **PATCH** `/api/collections/collectionIdOrName`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the collection to view. |

### Body Parameters

Body parameters could be sent as *JSON* or *multipart/form-data*.

```
{
    // Unique collection name (used as a table name for the records table).
    name (required):  string

    // List with the collection fields.
    // This field is optional and autopopulated for "view" collections based on the viewQuery.
    fields (required|optional): Array<Field>

    // The collection indexes and unique constriants.
    // Note that "view" collections don't support indexes.
    indexes (optional): Array<string>

    // Marks the collection as "system" to prevent being renamed, deleted or modify its API rules.
    system (optional): boolean

    // CRUD API rules
    listRule (optional):   null|string
    viewRule (optional):   null|string
    createRule (optional): null|string
    updateRule (optional): null|string
    deleteRule (optional): null|string

    // -------------------------------------------------------
    // view options
    // -------------------------------------------------------

    viewQuery (required):  string

    // -------------------------------------------------------
    // auth options
    // -------------------------------------------------------

    // API rule that gives admin-like permissions to allow fully managing the auth record(s),
    // e.g. changing the password without requiring to enter the old one, directly updating the
    // verified state or email, etc. This rule is executed in addition to the createRule and updateRule.
    manageRule (optional): null|string

    // API rule that could be used to specify additional record constraints applied after record
    // authentication and right before returning the auth token response to the client.
    //
    // For example, to allow only verified users you could set it to "verified = true".
    //
    // Set it to empty string to allow any Auth collection record to authenticate.
    //
    // Set it to null to disallow authentication altogether for the collection.
    authRule (optional): null|string

    // AuthAlert defines options related to the auth alerts on new device login.
    authAlert (optional): {
        enabled (optional): boolean
        emailTemplate (optional): {
            subject (required): string
            body (required):    string
        }
    }

    // OAuth2 specifies whether OAuth2 auth is enabled for the collection
    // and which OAuth2 providers are allowed.
    oauth2 (optional): {
        enabled (optional): boolean
        mappedFields (optional): {
            id (optional):        string
            name (optional):      string
            username (optional):  string
            avatarURL (optional): string
        }
        providers (optional): [
            {
                name (required):         string
                clientId (required):     string
                clientSecret (required): string
                authURL (optional):      string
                tokenURL (optional):     string
                userInfoURL (optional):  string
                displayName (optional):  string
                pkce (optional):         null|boolean
                extra (optional):        null|Object<string,any>
            }
        ]
    }

    // PasswordAuth defines options related to the collection password authentication.
    passwordAuth (optional): {
        enabled (optional):        boolean
        identityFields (required): Array<string>
    }

    // MFA defines options related to the Multi-factor authentication (MFA).
    mfa (optional):{
        enabled (optional):  boolean
        duration (required): number
        rule (optional):     string
    }

    // OTP defines options related to the One-time password authentication (OTP).
    otp (optional): {
        enabled (optional):  boolean
        duration (required): number
        length (required):   number
        emailTemplate (optional): {
            subject (required): string
            body (required):    string
        }
    }

    // Token configurations.
    authToken (optional): {
        duration (required): number
        secret (required):   string
    }
    passwordResetToken (optional): {
        duration (required): number
        secret (required):   string
    }
    emailChangeToken (optional): {
        duration (required): number
        secret (required):   string
    }
    verificationToken (optional): {
        duration (required): number
        secret (required):   string
    }
    fileToken (optional): {
        duration (required): number
        secret (required):   string
    }

    // Default email templates.
    verificationTemplate (optional): {
        subject (required): string
        body (required):    string
    }
    resetPasswordTemplate (optional): {
        subject (required): string
        body (required):    string
    }
    confirmEmailChangeTemplate (optional): {
        subject (required): string
        body (required):    string
    }
}
```

### Query parameters

| Param | Type | Description |
| --- | --- | --- |
| fields | String | Comma separated string of the fields to return in the JSON response *(by default returns all fields)*. Ex.: `?fields=*,expand.relField.name` In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)` Returns a short plain text version of the field string value. Ex.: `?fields=*,description:excerpt(200,true)` |

### Responses

#### 200

```json
{
  "id": "_pbc_2287844090",
  "listRule": null,
  "viewRule": null,
  "createRule": null,
  "updateRule": null,
  "deleteRule": null,
  "name": "posts",
  "type": "base",
  "fields": [
    {
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "id": "text3208210256",
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-z0-9]+$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    },
    {
      "autogeneratePattern": "",
      "hidden": false,
      "id": "text724990059",
      "max": 0,
      "min": 0,
      "name": "title",
      "pattern": "",
      "presentable": false,
      "primaryKey": false,
      "required": false,
      "system": false,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "autodate2990389176",
      "name": "created",
      "onCreate": true,
      "onUpdate": false,
      "presentable": false,
      "system": false,
      "type": "autodate"
    },
    {
      "hidden": false,
      "id": "autodate3332085495",
      "name": "updated",
      "onCreate": true,
      "onUpdate": true,
      "presentable": false,
      "system": false,
      "type": "autodate"
    }
  ],
  "indexes": [],
  "system": false
}
```

#### 400

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "email": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## Delete collection

Deletes a single Collection by its ID or name.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.collections.delete('demo');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.collections.delete('demo');
```

### API details

> **DELETE** `/api/collections/collectionIdOrName`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the collection to view. |

### Responses

#### 204

```
null
```

#### 400

```json
{
  "status": 400,
  "message": "Failed to delete collection. Make sure that the collection is not referenced by other collections.",
  "data": {}
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

#### 404

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

## Truncate collection

Deletes all the records of a single collection (including their related files and cascade delete enabled relations).

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.collections.truncate('demo');
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

await pb.collections.truncate('demo');
```

### API details

> **DELETE** `/api/collections/collectionIdOrName/truncate`
>
> Requires `Authorization:TOKEN`

### Path parameters

| Param | Type | Description |
| --- | --- | --- |
| collectionIdOrName | String | ID or name of the collection to truncate. |

### Responses

#### 204

```
null
```

#### 400

```json
{
  "status": 400,
  "message": "Failed to truncate collection (most likely due to required cascade delete record references).",
  "data": {}
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

#### 404

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

## Import collections

Bulk imports the provided *Collections* configuration.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const importData = [
    {
        name: 'collection1',
        schema: [
            {
                name: 'status',
                type: 'bool',
            },
        ],
    },
    {
        name: 'collection2',
        schema: [
            {
                name: 'title',
                type: 'text',
            },
        ],
    },
];

await pb.collections.import(importData, false);
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final importData = [
    CollectionModel(
        name: "collection1",
        schema: [
            SchemaField(name: "status", type: "bool"),
        ],
    ),
    CollectionModel(
        name: "collection2",
        schema: [
            SchemaField(name: "title", type: "text"),
        ],
    ),
];

await pb.collections.import(importData, deleteMissing: false);
```

### API details

> **PUT** `/api/collections/import`
>
> Requires `Authorization:TOKEN`

### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| **Required** collections | Array\<Collection\> | List of collections to import (replace and create). |
| *Optional* deleteMissing | Boolean | If *true* all existing collections and schema fields that are not present in the imported configuration **will be deleted**, including their related records data (default to *false*). |

Body parameters could be sent as *JSON* or *multipart/form-data*.

### Responses

#### 204

```
null
```

#### 400

```json
{
  "status": 400,
  "message": "An error occurred while submitting the form.",
  "data": {
    "collections": {
      "code": "collections_import_failure",
      "message": "Failed to import the collections configuration."
    }
  }
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

---

## Scaffolds

Returns an object with all of the collection types and their default fields *(used primarily in the Dashboard UI)*.

Only superusers can perform this action.

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

const scaffolds = await pb.collections.getScaffolds();
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.collection("_superusers").authWithPassword('test@example.com', '1234567890');

final scaffolds = await pb.collections.getScaffolds();
```

### API details

> **GET** `/api/collections/meta/scaffolds`
>
> Requires `Authorization:TOKEN`

### Responses

#### 200

```json
{
    "auth": {
        "id": "",
        "listRule": null,
        "viewRule": null,
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "",
        "type": "auth",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "cost": 0,
                "hidden": true,
                "id": "password901924565",
                "max": 0,
                "min": 8,
                "name": "password",
                "pattern": "",
                "presentable": false,
                "required": true,
                "system": true,
                "type": "password"
            },
            {
                "autogeneratePattern": "[a-zA-Z0-9]{50}",
                "hidden": true,
                "id": "text2504183744",
                "max": 60,
                "min": 30,
                "name": "tokenKey",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "exceptDomains": null,
                "hidden": false,
                "id": "email3885137012",
                "name": "email",
                "onlyDomains": null,
                "presentable": false,
                "required": true,
                "system": true,
                "type": "email"
            },
            {
                "hidden": false,
                "id": "bool1547992806",
                "name": "emailVisibility",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            },
            {
                "hidden": false,
                "id": "bool256245529",
                "name": "verified",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            }
        ],
        "indexes": [
            "CREATE UNIQUE INDEX `idx_tokenKey_hclGvwhtqG` ON `test` (`tokenKey`)",
            "CREATE UNIQUE INDEX `idx_email_eyxYyd3gp1` ON `test` (`email`) WHERE `email` != ''"
        ],
        "created": "",
        "updated": "",
        "system": false,
        "authRule": "",
        "manageRule": null,
        "authAlert": {
            "enabled": true,
            "emailTemplate": {
                "subject": "Login from a new location",
                "body": "..."
            }
        },
        "oauth2": {
            "providers": [],
            "mappedFields": {
                "id": "",
                "name": "",
                "username": "",
                "avatarURL": ""
            },
            "enabled": false
        },
        "passwordAuth": {
            "enabled": true,
            "identityFields": [
                "email"
            ]
        },
        "mfa": {
            "enabled": false,
            "duration": 1800,
            "rule": ""
        },
        "otp": {
            "enabled": false,
            "duration": 180,
            "length": 8,
            "emailTemplate": {
                "subject": "OTP for {APP_NAME}",
                "body": "..."
            }
        },
        "authToken": {
            "duration": 604800
        },
        "passwordResetToken": {
            "duration": 1800
        },
        "emailChangeToken": {
            "duration": 1800
        },
        "verificationToken": {
            "duration": 259200
        },
        "fileToken": {
            "duration": 180
        },
        "verificationTemplate": {
            "subject": "Verify your {APP_NAME} email",
            "body": "..."
        },
        "resetPasswordTemplate": {
            "subject": "Reset your {APP_NAME} password",
            "body": "..."
        },
        "confirmEmailChangeTemplate": {
            "subject": "Confirm your {APP_NAME} new email address",
            "body": "..."
        }
    },
    "base": {
        "id": "",
        "listRule": null,
        "viewRule": null,
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "",
        "type": "base",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            }
        ],
        "indexes": [],
        "created": "",
        "updated": "",
        "system": false
    },
    "view": {
        "id": "",
        "listRule": null,
        "viewRule": null,
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "",
        "type": "view",
        "fields": [],
        "indexes": [],
        "created": "",
        "updated": "",
        "system": false,
        "viewQuery": ""
    }
}
```

#### 401

```json
{
  "status": 401,
  "message": "The request requires valid record authorization token.",
  "data": {}
}
```

#### 403

```json
{
  "status": 403,
  "message": "The authorized record is not allowed to perform this action.",
  "data": {}
}
```

#### 404

```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```
