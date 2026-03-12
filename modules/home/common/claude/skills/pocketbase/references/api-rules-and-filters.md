# API rules and filters

## API rules

**API Rules** are your collection access controls and data filters.

Each collection has **5 rules**, corresponding to the specific API action:

- `listRule`
- `viewRule`
- `createRule`
- `updateRule`
- `deleteRule`

Auth collections have an additional `options.manageRule` used to allow one user (it could be even from a different collection) to be able to fully manage the data of another user (ex. changing their email, password, etc.).

Each rule could be set to:

- **"locked"** - aka. `null`, which means that the action could be performed only by an authorized superuser (**this is the default**)
- **Empty string** - anyone will be able to perform the action (superusers, authorized users and guests)
- **Non-empty string** - only users (authorized or not) that satisfy the rule filter expression will be able to perform this action

> **Note:**
>
> **PocketBase API Rules act also as records filter!**
>
> Or in other words, you could for example allow listing only the "active" records of your collection, by using a simple filter expression such as: `status = "active"` (where "status" is a field defined in your Collection).
>
> Because of the above, the API will return 200 empty items response in case a request doesn't satisfy a `listRule`, 400 for unsatisfied `createRule` and 404 for unsatisfied `viewRule`, `updateRule` and `deleteRule`.
> All rules will return 403 in case they were "locked" (aka. superuser only) and the request client is not a superuser.
>
> The API Rules are ignored when the action is performed by an authorized superuser (**superusers can access everything**)!

## Filters syntax

You can find information about the available fields in your collection API rules tab:

![Collection API Rules filters screenshot](/images/screenshots/collection-rules.png)

There is autocomplete to help guide you while typing the rule filter expression, but in general you have access to **3 groups of fields**:

- **Your Collection schema fields**
  This includes all nested relation fields too, ex. `someRelField.status != "pending"`

- **`@request.*`**
  Used to access the current request data, such as query parameters, body/form fields, authorized user state, etc.
  - `@request.context` - the context where the rule is used (ex. `@request.context != "oauth2"`)
    The currently supported context values are `default`, `oauth2`, `otp`, `password`, `realtime`, `protectedFile`.
  - `@request.method` - the HTTP request method (ex. `@request.method = "GET"`)
  - `@request.headers.*` - the request headers as string values (ex. `@request.headers.x_token = "test"`)
    Note: All header keys are normalized to lowercase and "-" is replaced with "_" (for example "X-Token" is "x_token").
  - `@request.query.*` - the request query parameters as string values (ex. `@request.query.page = "1"`)
  - `@request.auth.*` - the current authenticated model (ex. `@request.auth.id != ""`)
  - `@request.body.*` - the submitted body parameters (ex. `@request.body.title != ""`)
    Note: Uploaded files are not part of the `@request.body` because they are evaluated separately (*this behavior may change in the future*).

- **`@collection.*`**

  This filter could be used to target other collections that are not directly related to the current one (aka. there is no relation field pointing to it) but both shares a common field value, like for example a category id:

  ```
  @collection.news.categoryId ?= categoryId && @collection.news.author ?= @request.auth.id
  ```

  In case you want to join the same collection multiple times but based on different criteria, you can define an alias by appending `:alias` suffix to the collection name.

  ```
  // see https://github.com/pocketbase/pocketbase/discussions/3805#discussioncomment-7634791
  @request.auth.id != "" &&
  @collection.courseRegistrations.user ?= id &&
  @collection.courseRegistrations:auth.user ?= @request.auth.id &&
  @collection.courseRegistrations.courseGroup ?= @collection.courseRegistrations:auth.courseGroup
  ```

## Filter syntax

The syntax basically follows the format `OPERAND OPERATOR OPERAND`, where:

- `OPERAND` - could be any of the above field literal, string (single or double quoted), number, null, true, false
- `OPERATOR` - is one of:

| Operator | Description |
|----------|-------------|
| `=` | Equal |
| `!=` | NOT equal |
| `>` | Greater than |
| `>=` | Greater than or equal |
| `<` | Less than |
| `<=` | Less than or equal |
| `~` | Like/Contains (you can use `%` as wildcard, e.g. `title ~ "%test%"`) |
| `!~` | NOT Like/Contains |
| `?=` | Any/At least one of Equal |
| `?!=` | Any/At least one of NOT equal |
| `?>` | Any/At least one of Greater than |
| `?>=` | Any/At least one of Greater than or equal |
| `?<` | Any/At least one of Less than |
| `?<=` | Any/At least one of Less than or equal |
| `?~` | Any/At least one of Like/Contains |
| `?!~` | Any/At least one of NOT Like/Contains |

To group and combine several expressions you can use parenthesis `(...)`, `&&` (AND) and `||` (OR) tokens:

```
(title = "test1" && status = "active") || (title = "test2" && status = "pending")
```

## Special identifiers and modifiers

##### @ macros

The following datetime macros are available and can be used as part of the filter expression:

```
// all macros are UTC based
// (for more complex date operation check the strftime() function)
@now        - the current datetime as string
@second     - @now second number (0-59)
@minute     - @now minute number (0-59)
@hour       - @now hour number (0-23)
@weekday    - @now weekday number (0-6)
@day        - @now day number
@month      - @now month number
@year       - @now year number
@yesterday  - the yesterday datetime relative to @now as string
@tomorrow   - the tomorrow datetime relative to @now as string
@todayStart - beginning of the current day as datetime string
@todayEnd   - end of the current day as datetime string
@monthStart - beginning of the current month as datetime string
@monthEnd   - end of the current month as datetime string
@yearStart  - beginning of the current year as datetime string
@yearEnd    - end of the current year as datetime string
```

For example:

```
@request.body.publicDate >= @now
```

##### :isset modifier

The `:isset` field modifier is available only for the `@request.*` fields and can be used to check whether the client submitted a specific data with the request. Here is for example a rule that disallows submitting a "role" field:

```
@request.body.role:isset = false
```

Note that `@request.body.*:isset` at the moment doesn't support checking for new uploaded files because they are evaluated separately and cannot be serialized (*this behavior may change in the future*).

##### :changed modifier

The `:changed` field modifier is available only for the `@request.body.*` fields and can be used to check whether the client submitted AND changed a specific record field with the request. Here is for example a rule that disallows changing a "role" field:

```
// the same as: (@request.body.role:isset = false || @request.body.role = role)
@request.body.role:changed = false
```

Note that `@request.body.*:changed` at the moment doesn't support checking for new uploaded files because they are evaluated separately and cannot be serialized (*this behavior may change in the future*).

##### :length modifier

The `:length` field modifier could be used to check the number of items in an array field (multiple `file`, `select`, `relation`).
Could be used with both the collection schema fields and the `@request.body.*` fields. For example:

```
// check example submitted data: {"someSelectField": ["val1", "val2"]}
@request.body.someSelectField:length > 1

// check existing record field length
someRelationField:length = 2
```

Note that `@request.body.*:length` at the moment doesn't support checking for new uploaded files because they are evaluated separately and cannot be serialized (*this behavior may change in the future*).

##### :each modifier

The `:each` field modifier works only with multiple `select`, `file` and `relation` type fields. It could be used to apply a condition on each item from the field array. For example:

```
// check if all submitted select options contain the "create" text
@request.body.someSelectField:each ~ "create"

// check if all existing someSelectField has "pb_" prefix
someSelectField:each ~ "pb_%"
```

Note that `@request.body.*:each` at the moment doesn't support checking for new uploaded files because they are evaluated separately and cannot be serialized (*this behavior may change in the future*).

##### :lower modifier

The `:lower` field modifier could be used to perform lower-case string comparisons. For example:

```
// check if the submitted lower-cased body "title" field is equal to "test" ("Test", "tEsT", etc.)
@request.body.title:lower = "test"

// match existing records with lower-cased "title" equal to "test" ("Test", "tEsT", etc.)
title:lower ~ "test"
```

Under the hood it uses the [SQLite `LOWER` scalar function](https://www.sqlite.org/lang_corefunc.html#lower) and by default works only for ASCII characters, unless the ICU extension is loaded.

##### geoDistance(lonA, latA, lonB, latB)

The `geoDistance(lonA, latA, lonB, latB)` function could be used to calculate the Haversine distance between 2 geographic points in kilometres.

The function is intended to be used primarily with the `geoPoint` field type, but the accepted arguments could be any plain number or collection field identifier. If the identifier cannot be resolved and converted to a numeric value, it resolves to `null`. Note that the `geoDistance` function always results in a single row/record value meaning that "any/at-least-one-of" type of constraint will be applied even if some of its arguments originate from a multiple relation field.

For example:

```
// offices that are less than 25km from my location (address is a geoPoint field in the offices collection)
geoDistance(address.lon, address.lat, 23.32, 42.69) < 25
```

##### strftime(format, [time-value, modifiers...])

The `strftime(format, [time-value, modifiers...])` returns a date string formatted according to the specified format argument.

The function is similar to the builtin SQLite [`strftime`](https://sqlite.org/lang_datefunc.html) with the main difference that NULL results will be normalized for consistency with the non-nullable PocketBase `text` and `date` fields.

The function accepts 1, 2 or 3+ arguments.

1. The first (**format**) argument must be a formatting string with valid substitution characters as listed in [https://sqlite.org/lang_datefunc.html](https://sqlite.org/lang_datefunc.html).
2. The second (**time-value**) argument is optional and must be either a date **string**, **number** or **collection field identifier** with value matching one of the formats listed in [https://sqlite.org/lang_datefunc.html#time_values](https://sqlite.org/lang_datefunc.html#time_values). If not set the function fallbacks to the current datetime.
3. The remaining (**modifiers**) optional arguments are expected to be string literals matching the listed modifiers in [https://sqlite.org/lang_datefunc.html#modifiers](https://sqlite.org/lang_datefunc.html#modifiers) (up to 8 max).

A match-all constraint will be also applied in case the time-value is an identifier as a result of a multi-value relation field. For example:

```
// requires ALL multiRel records to have "created" that match the formatted string "2026-01"
strftime('%Y-%m', multiRel.created) = "2026-01"

// requires ANY/AT-LEAST-ONE-OF multiRel records to have "created" that match the formatted string "2026-01"
strftime('%Y-%m', multiRel.created) ?= "2026-01"
```

## Examples

- Allow only registered users:

  ```
  @request.auth.id != ""
  ```

- Allow only registered users and return records that are either "active" or "pending":

  ```
  @request.auth.id != "" && (status = "active" || status = "pending")
  ```

- Allow only registered users who are listed in an *allowed_users* multi-relation field value:

  ```
  @request.auth.id != "" && allowed_users.id ?= @request.auth.id
  ```

- Allow access by anyone and return only the records where the *title* field value starts with "Lorem" (ex. "Lorem ipsum"):

  ```
  title ~ "Lorem%"
  ```
