# JS Records

The most common task when extending PocketBase probably would be querying and working with your collection records.

You could find detailed documentation about all the supported Record model methods in [`core.Record`](/jsvm/interfaces/core.Record.html) type interface but below are some examples with the most common ones.

## Set field value

```javascript
// sets the value of a single record field
// (field type specific modifiers are also supported)
record.set("title", "example")
record.set("users+", "6jyr1y02438et52") // append to existing value

// populates a record from a data map
// (calls set() for each entry of the map)
record.load(data)
```

## Get field value

```javascript
// retrieve a single record field value
// (field specific modifiers are also supported)
record.get("someField")            // -> any (without cast)
record.getBool("someField")        // -> cast to bool
record.getString("someField")      // -> cast to string
record.getInt("someField")         // -> cast to int
record.getFloat("someField")       // -> cast to float64
record.getDateTime("someField")    // -> cast to types.DateTime
record.getStringSlice("someField") // -> cast to []string

// retrieve the new uploaded files
// (e.g. for inspecting and modifying the file(s) before save)
record.getUnsavedFiles("someFileField")

// unmarshal a single json field value into the provided result
let result = new DynamicModel({ ... })
record.unmarshalJSONField("someJsonField", result)

// retrieve a single or multiple expanded data
record.expandedOne("author")     // -> as null|Record
record.expandedAll("categories") // -> as []Record

// export all the public safe record fields in a plain object
// (note: "json" type field values are exported as raw bytes array)
record.publicExport()
```

## Auth accessors

```javascript
record.isSuperuser() // alias for record.collection().name == "_superusers"

record.email()         // alias for record.get("email")
record.setEmail(email) // alias for record.set("email", email)

record.verified()         // alias for record.get("verified")
record.setVerified(false) // alias for record.set("verified", false)

record.tokenKey()        // alias for record.get("tokenKey")
record.setTokenKey(key)  // alias for record.set("tokenKey", key)
record.refreshTokenKey() // alias for record.set("tokenKey:autogenerate", "")

record.validatePassword(pass)
record.setPassword(pass)   // alias for record.set("password", pass)
record.setRandomPassword() // sets cryptographically random 30 characters string as password
```

## Copies

```javascript
// returns a shallow copy of the current record model populated
// with its ORIGINAL db data state and everything else reset to the defaults
// (usually used for comparing old and new field values)
record.original()

// returns a shallow copy of the current record model populated
// with its LATEST data state and everything else reset to the defaults
// (aka. no expand, no custom fields and with default visibility flags)
record.fresh()

// returns a shallow copy of the current record model populated
// with its ALL collection and custom fields data, expand and visibility flags
record.clone()
```

## Hide/Unhide fields

Collection fields can be marked as "Hidden" from the Dashboard to prevent regular user access to the field values.

Record models provide an option to further control the fields serialization visibility in addition to the "Hidden" fields option using the [`record.hide(fieldNames...)`](/jsvm/interfaces/core.Record.html#hide) and [`record.unhide(fieldNames...)`](/jsvm/interfaces/core.Record.html#unhide) methods.

Often the `hide/unhide` methods are used in combination with the `onRecordEnrich` hook invoked on every record enriching (list, view, create, update, realtime change, etc.). For example:

```javascript
onRecordEnrich((e) => {
    // dynamically show/hide a record field depending on whether the current
    // authenticated user has a certain "role" (or any other field constraint)
    if (
        !e.requestInfo.auth ||
        (!e.requestInfo.auth.isSuperuser() && e.requestInfo.auth.get("role") != "staff")
    ) {
        e.record.hide("someStaffOnlyField")
    }

    e.next()
}, "articles")
```

> **Info:** For custom fields, not part of the record collection schema, it is required to call explicitly `record.withCustomData(true)` to allow them in the public serialization.

## Fetch records

##### Fetch single record

All single record retrieval methods throw an error if no record is found.

```javascript
// retrieve a single "articles" record by its id
let record = $app.findRecordById("articles", "RECORD_ID")

// retrieve a single "articles" record by a single key-value pair
let record = $app.findFirstRecordByData("articles", "slug", "test")

// retrieve a single "articles" record by a string filter expression
// (NB! use "{:placeholder}" to safely bind untrusted user input parameters)
let record = $app.findFirstRecordByFilter(
    "articles",
    "status = 'public' && category = {:category}",
    { "category": "news" },
)
```

##### Fetch multiple records

All multiple records retrieval methods return an empty array if no records are found.

```javascript
// retrieve multiple "articles" records by their ids
let records = $app.findRecordsByIds("articles", ["RECORD_ID1", "RECORD_ID2"])

// retrieve the total number of "articles" records in a collection with optional dbx expressions
let totalPending = $app.countRecords("articles", $dbx.hashExp({"status": "pending"}))

// retrieve multiple "articles" records with optional dbx expressions
let records = $app.findAllRecords("articles",
    $dbx.exp("LOWER(username) = {:username}", {"username": "John.Doe"}),
    $dbx.hashExp({"status": "pending"}),
)

// retrieve multiple paginated "articles" records by a string filter expression
// (NB! use "{:placeholder}" to safely bind untrusted user input parameters)
let records = $app.findRecordsByFilter(
    "articles",                                    // collection
    "status = 'public' && category = {:category}", // filter
    "-published",                                   // sort
    10,                                            // limit
    0,                                             // offset
    { "category": "news" },                        // optional filter params
)
```

##### Fetch auth records

```javascript
// retrieve a single auth record by its email
let user = $app.findAuthRecordByEmail("users", "test@example.com")

// retrieve a single auth record by JWT
// (you could also specify an optional list of accepted token types)
let user = $app.findAuthRecordByToken("YOUR_TOKEN", "auth")
```

##### Custom record query

In addition to the above query helpers, you can also create custom Record queries using [`$app.recordQuery(collection)`](/jsvm/functions/_app.recordQuery.html) method. It returns a SELECT DB builder that can be used with the same methods described in the [Database guide](/docs/js-database).

```javascript
function findTopArticle() {
    let record = new Record();

    $app.recordQuery("articles")
        .andWhere($dbx.hashExp({ "status": "active" }))
        .orderBy("rank ASC")
        .limit(1)
        .one(record)

    return record
}

let article = findTopArticle()
```

For retrieving **multiple** Record models with the `all()` executor, you can use `arrayOf(new Record)` to create an array placeholder in which to populate the resolved DB result.

```javascript
// the below is identical to
// $app.findRecordsByFilter("articles", "status = 'active'", '-published', 10)
// but allows more advanced use cases and filtering (aggregations, subqueries, etc.)
function findLatestArticles() {
    let records = arrayOf(new Record);

    $app.recordQuery("articles")
        .andWhere($dbx.hashExp({ "status": "active" }))
        .orderBy("published DESC")
        .limit(10)
        .all(records)

    return records
}

let articles = findLatestArticles()
```

## Create new record

##### Create new record programmatically

```javascript
let collection = $app.findCollectionByNameOrId("articles")

let record = new Record(collection)

record.set("title", "Lorem ipsum")
record.set("active", true)

// field type specific modifiers can also be used
record.set("slug:autogenerate", "post-")

// new files must be one or a slice of filesystem.File values
//
// note1: see all factories in /jsvm/modules/_filesystem.html
// note2: for reading files from a request event you can also use e.findUploadedFiles("fileKey")
let f1 = $filesystem.fileFromPath("/local/path/to/file1.txt")
let f2 = $filesystem.fileFromBytes("test content", "file2.txt")
let f3 = $filesystem.fileFromURL("https://example.com/file3.pdf")
record.set("documents", [f1, f2, f3])

// validate and persist
// (use saveNoValidate to skip fields validation)
$app.save(record);
```

##### Intercept create request

```javascript
onRecordCreateRequest((e) => {
    // ignore for superusers
    if (e.hasSuperuserAuth()) {
        return e.next()
    }

    // overwrite the submitted "status" field value
    e.record.set("status", "pending")

    // or you can also prevent the create event by returning an error
    let status = e.record.get("status")
    if (
        status != "pending" &&
        // guest or not an editor
        (!e.auth || e.auth.get("role") != "editor")
    ) {
        throw new BadRequestError("Only editors can set a status different from pending")
    }

    e.next()
}, "articles")
```

## Update existing record

##### Update existing record programmatically

```javascript
let record = $app.findRecordById("articles", "RECORD_ID")

record.set("title", "Lorem ipsum")

// delete existing record files by specifying their file names
record.set("documents-", ["file1_abc123.txt", "file3_abc123.txt"])

// append one or more new files to the already uploaded list
//
// note1: see all factories in /jsvm/modules/_filesystem.html
// note2: for reading files from a request event you can also use e.findUploadedFiles("fileKey")
let f1 = $filesystem.fileFromPath("/local/path/to/file1.txt")
let f2 = $filesystem.fileFromBytes("test content", "file2.txt")
let f3 = $filesystem.fileFromURL("https://example.com/file3.pdf")
record.set("documents+", [f1, f2, f3])

// validate and persist
// (use saveNoValidate to skip fields validation)
$app.save(record);
```

##### Intercept update request

```javascript
onRecordUpdateRequest((e) => {
    // ignore for superusers
    if (e.hasSuperuserAuth()) {
        return e.next()
    }

    // overwrite the submitted "status" field value
    e.record.set("status", "pending")

    // or you can also prevent the update event by returning an error
    let status = e.record.get("status")
    if (
        status != "pending" &&
        // guest or not an editor
        (!e.auth || e.auth.get("role") != "editor")
    ) {
        throw new BadRequestError("Only editors can set a status different from pending")
    }

    e.next()
}, "articles")
```

## Delete record

```javascript
let record = $app.findRecordById("articles", "RECORD_ID")

$app.delete(record)
```

## Transaction

To execute multiple queries in a transaction you can use [`$app.runInTransaction(fn)`](/jsvm/functions/_app.runInTransaction.html).

The DB operations are persisted only if the transaction completes without throwing an error.

It is safe to nest `runInTransaction` calls as long as you use the callback's `txApp` argument.

> **Info:** Inside the transaction function always use its `txApp` argument and not the original `$app` instance because we allow only a single writer/transaction at a time and it could result in a deadlock.
>
> To avoid performance issues, try to minimize slow/long running tasks such as sending emails, connecting to external services, etc. as part of the transaction.

```javascript
let titles = ["title1", "title2", "title3"]

let collection = $app.findCollectionByNameOrId("articles")

$app.runInTransaction((txApp) => {
    // create new record for each title
    for (let title of titles) {
        let record = new Record(collection)

        record.set("title", title)

        txApp.save(record)
    }
})
```

## Programmatically expanding relations

To expand record relations programmatically you can use [`$app.expandRecord(record, expands, customFetchFunc)`](/jsvm/functions/_app.expandRecord.html) for single or [`$app.expandRecords(records, expands, customFetchFunc)`](/jsvm/functions/_app.expandRecords.html) for multiple records.

Once loaded, you can access the expanded relations via [`record.expandedOne(relName)`](/jsvm/interfaces/core.Record.html#expandedOne) or [`record.expandedAll(relName)`](/jsvm/interfaces/core.Record.html#expandedAll) methods.

For example:

```javascript
let record = $app.findFirstRecordByData("articles", "slug", "lorem-ipsum")

// expand the "author" and "categories" relations
$app.expandRecord(record, ["author", "categories"], null)

// print the expanded records
console.log(record.expandedOne("author"))
console.log(record.expandedAll("categories"))
```

## Check if record can be accessed

To check whether a custom client request or user can access a single record, you can use the [`$app.canAccessRecord(record, requestInfo, rule)`](/jsvm/functions/_app.canAccessRecord.html) method.

Below is an example of creating a custom route to retrieve a single article and checking if the request satisfy the View API rule of the record collection:

```javascript
routerAdd("GET", "/articles/{slug}", (e) => {
    let slug = e.request.pathValue("slug")

    let record = e.app.findFirstRecordByData("articles", "slug", slug)

    let canAccess = e.app.canAccessRecord(record, e.requestInfo(), record.collection().viewRule)
    if (!canAccess) {
        throw new ForbiddenError()
    }

    return e.json(200, record)
})
```

## Generating and validating tokens

PocketBase Web APIs are fully stateless (aka. there are no sessions in the traditional sense) and an auth record is considered authenticated if the submitted request contains a valid `Authorization: TOKEN` header (see also [Builtin auth middlewares](/docs/js-routing/#builtin-middlewares) and [Retrieving the current auth state from a route](/docs/js-routing/#retrieving-the-current-auth-state)).

If you want to issue and verify manually a record JWT (auth, verification, password reset, etc.), you could do that using the record token type specific methods:

```javascript
let token = record.newAuthToken()

let token = record.newVerificationToken()

let token = record.newPasswordResetToken()

let token = record.newEmailChangeToken(newEmail)

let token = record.newFileToken() // for protected files

let token = record.newStaticAuthToken(optCustomDuration) // nonrenewable auth token
```

Each token type has its own secret and the token duration is managed via its type related collection auth option (the only exception is `newStaticAuthToken`).

To validate a record token you can use the [`$app.findAuthRecordByToken`](/jsvm/functions/_app.findAuthRecordByToken.html) method. The token related auth record is returned only if the token is not expired and its signature is valid.

Here is an example how to validate an auth token:

```javascript
let record = $app.findAuthRecordByToken("YOUR_TOKEN", "auth")
```
