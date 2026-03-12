# Collections

## Overview

**Collections** represent your application data. Under the hood they are backed by plain SQLite tables that are generated automatically with the collection **name** and **fields** (columns).

Single entry of a collection is called **record** (a single row in the SQL table).

You can manage your **collections** from the Dashboard, with the Web APIs using the [client-side SDKs](/docs/how-to-use/) (*superusers only*) or programmatically via the [Go](/docs/go-migrations/)/[JavaScript](/docs/js-migrations/) migrations.

Similarly, you can manage your **records** from the Dashboard, with the Web APIs using the [client-side SDKs](/docs/how-to-use/) or programmatically via the [Go](/docs/go-records/)/[JavaScript](/docs/js-records/) Record operations.

Here is what a collection edit panel looks like in the Dashboard:

![Collection panel screenshot](/images/screenshots/collection-panel.png)

Currently there are 3 collection types: **Base**, **View** and **Auth**.

### Base collection

**Base collection** is the default collection type and it could be used to store any application data (articles, products, posts, etc.).

### View collection

**View collection** is a read-only collection type where the data is populated from a plain SQL `SELECT` statement, allowing users to perform aggregations or any other custom queries in general.

For example, the following query will create a read-only collection with 3 *posts* fields - *id*, *name* and *totalComments*:

```sql
SELECT
    posts.id,
    posts.name,
    count(comments.id) as totalComments
FROM posts
LEFT JOIN comments on comments.postId = posts.id
GROUP BY posts.id
```

> **ℹ️ Note:** View collections don't receive realtime events because they don't have create/update/delete operations.

### Auth collection

**Auth collection** has everything from the **Base collection** but with some additional special fields to help you manage your app users and also provide various authentication options.

Each Auth collection has the following special system fields: `email`, `emailVisibility`, `verified`, `password` and `tokenKey`.
They cannot be renamed or deleted but can be configured using their specific field options. For example you can make the user email required or optional.

You can have as many Auth collections as you want (users, managers, staffs, members, clients, etc.) each with their own set of fields, separate login and records managing endpoints.

You can build all sort of different access controls:

- **Role (Group)**
  For example, you could attach a "role" `select` field to your Auth collection with the following options: "employee" and "staff". And then in some of your other collections you could define the following rule to allow only "staff":
  `@request.auth.role = "staff"`

- **Relation (Ownership)**
  Let's say that you have 2 collections - "posts" base collection and "users" auth collection. In your "posts" collection you can create "author" `relation` field pointing to the "users" collection. To allow access to only the "author" of the record(s), you could use a rule like:
  `@request.auth.id != "" && author = @request.auth.id`
  Nested relation fields look ups, including back-relations, are also supported, for example:
  `someRelField.anotherRelField.author = @request.auth.id`

- **Managed**
  In addition to the default "List", "View", "Create", "Update", "Delete" API rules, Auth collections have also a special "Manage" API rule that could be used to allow one user (it could be even from a different collection) to be able to fully manage the data of another user (e.g. changing their email, password, etc.).

- **Mixed**
  You can build a mixed approach based on your unique use-case. Multiple rules can be grouped with parenthesis `()` and combined with `&&` (AND) and `||` (OR) operators:
  `@request.auth.id != "" && (@request.auth.role = "staff" || author = @request.auth.id)`

## Fields

> **ℹ️ Note:** All collection fields *(with exception of the `JSONField`)* are **non-nullable and use a zero-default** for their respective type as fallback value when missing (empty string for `text`, 0 for `number`, etc.).
>
> All field specific modifiers are supported both in the Web APIs and via the record Get/Set methods.

### BoolField

BoolField defines `bool` type field to store a single `false` (default) or `true` value.

### NumberField

NumberField defines `number` type field for storing numeric/float64 value: `0` (default), `2`, `-1`, `1.5`.

The following additional set modifiers are available:

- `fieldName**+**` adds number to the already existing record value.
- `fieldName**-**` subtracts number from the already existing record value.

### TextField

TextField defines `text` type field for storing string values: `""` (default), `"example"`.

The following additional set modifiers are available:

- `fieldName:autogenerate` autogenerate a field value if the `AutogeneratePattern` field option is set.
  For example, submitting: `{"slug:autogenerate":"abc-"}` will result in `"abc-[random]"` `slug` field value.

### EmailField

EmailField defines `email` type field for storing a single email string address: `""` (default), `"john@example.com"`.

### URLField

URLField defines `url` type field for storing a single URL string value: `""` (default), `"https://example.com"`.

### EditorField

EditorField defines `editor` type field to store HTML formatted text: `""` (default), `<p>example</p>`.

### DateField

DateField defines `date` type field to store a single datetime string value: `""` (default), `"2022-01-01 00:00:00.000Z"`.

All PocketBase dates at the moment follows the RFC3399 format `Y-m-d H:i:s.uZ` (e.g. `2024-11-10 18:45:27.123Z`).

Dates are compared as strings, meaning that when using the filters with a date field you'll have to specify the full datetime string format. For example to target a single day (e.g. November 19, 2024) you can use something like:
`created >= '2024-11-19 00:00:00.000Z' && created <= '2024-11-19 23:59:59.999Z'`

### AutodateField

AutodateField defines an `autodate` type field and it is similar to the DateField but its value is auto set on record create/update.

This field is usually used for defining timestamp fields like "created" and "updated".

### SelectField

SelectField defines `select` type field for storing single or multiple string values from a predefined list.

It is usually intended for handling enums-like values such as `pending/public/private` statuses, simple `client/staff/manager/admin` roles, etc.

For **single** `select` *(the `MaxSelect` option is <= 1)* the field value is a string: `""`, `"optionA"`.

For **multiple** `select` *(the `MaxSelect` option is >= 2)* the field value is an array: `[]`, `["optionA", "optionB"]`.

The following additional set modifiers are available:

- `fieldName+` appends one or more values to the existing one.
- `+fieldName` prepends one or more values to the existing one.
- `fieldName-` subtracts/removes one or more values from the existing one.

For example: `{"permissions+": "optionA", "roles-": ["staff", "editor"]}`

### FileField

FileField defines `file` type field for managing record file(s).

PocketBase stores in the database only the file name. The file itself is stored either on the local disk or in S3, depending on your application storage settings.

For **single** `file` *(the `MaxSelect` option is <= 1)* the stored value is a string: `""`, `"file1_Ab24ZjL.png"`.

For **multiple** `file` *(the `MaxSelect` option is >= 2)* the stored value is an array: `[]`, `["file1_Ab24ZjL.png", "file2_Frq24ZjL.txt"]`.

The following additional set modifiers are available:

- `fieldName+` appends one or more files to the existing field value.
- `+fieldName` prepends one or more files to the existing field value.
- `fieldName-` deletes one or more files from the existing field value.

For example: `{"documents+": new File(...), "documents-": ["file1_Ab24ZjL.txt", "file2_Frq24ZjL.txt"]}`

You can find more detailed information in the [Files upload and handling](/docs/files-handling/) guide.

### RelationField

RelationField defines `relation` type field for storing single or multiple collection record references.

For **single** `relation` *(the `MaxSelect` option is <= 1)* the field value is a string: `""`, `"RECORD_ID"`.

For **multiple** `relation` *(the `MaxSelect` option is >= 2)* the field value is an array: `[]`, `["RECORD_ID1", "RECORD_ID2"]`.

The following additional set modifiers are available:

- `fieldName+` appends one or more ids to the existing one.
- `+fieldName` prepends one or more ids to the existing one.
- `fieldName-` subtracts/removes one or more ids from the existing one.

For example: `{"users+": "USER_ID", "categories-": ["CAT_ID1", "CAT_ID2"]}`

### JSONField

JSONField defines `json` type field for storing any serialized JSON value, including `null` (default).

### GeoPoint

GeoPoint defines `geoPoint` type field for storing geographic coordinates (longitude, latitude) as a serialized json object. For example: `{"lon":12.34,"lat":56.78}`.

The default/zero value of a `geoPoint` is the "Null Island", aka. `{"lon":0,"lat":0}`.

When extending PocketBase with Go/JSVM, the `geoPoint` field value could be set as `types.GeoPoint` instance or a regular map with `lon` and `lat` keys:

**Go:**
```go
// set types.GeoPoint
record.Set("address", types.GeoPoint{Lon:12.34, Lat:45.67})

// set map[string]any
record.Set("address", map[string]any{"lon":12.34, "lat":45.67})

// retrieve the field value as types.GeoPoint struct
address := record.GetGeoPoint("address")
```

**JavaScript:**
```javascript
record.set("address", {"lon":12.34, "lat":45.67})

const address = record.get("address")
```
