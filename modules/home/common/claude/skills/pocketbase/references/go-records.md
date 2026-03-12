The most common task when using PocketBase as framework probably would be querying and working with your collection records.

You could find detailed documentation about all the supported Record model methods in [`core.Record`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Record) but below are some examples with the most common ones.

## Set field value

```go
// sets the value of a single record field
// (field type specific modifiers are also supported)
record.Set("title", "example")
record.Set("users+", "6jyr1y02438et52") // append to existing value

// populates a record from a data map
// (calls Set for each entry of the map)
record.Load(data)
```

## Get field value

```go
// retrieve a single record field value
// (field specific modifiers are also supported)
record.Get("someField")            // -> any (without cast)
record.GetBool("someField")        // -> cast to bool
record.GetString("someField")      // -> cast to string
record.GetInt("someField")         // -> cast to int
record.GetFloat("someField")       // -> cast to float64
record.GetDateTime("someField")    // -> cast to types.DateTime
record.GetStringSlice("someField") // -> cast to []string

// retrieve the new uploaded files
// (e.g. for inspecting and modifying the file(s) before save)
record.GetUnsavedFiles("someFileField")

// unmarshal a single "json" field value into the provided result
record.UnmarshalJSONField("someJSONField", &result)

// retrieve a single or multiple expanded data
record.ExpandedOne("author")     // -> nil|*core.Record
record.ExpandedAll("categories") // -> []*core.Record

// export all the public safe record fields as map[string]any
// (note: "json" type field values are exported as types.JSONRaw bytes slice)
record.PublicExport()
```

## Auth accessors

```go
record.IsSuperuser() // alias for record.Collection().Name == "_superusers"

record.Email()         // alias for record.Get("email")
record.SetEmail(email) // alias for record.Set("email", email)

record.Verified()         // alias for record.Get("verified")
record.SetVerified(false) // alias for record.Set("verified", false)

record.TokenKey()        // alias for record.Get("tokenKey")
record.SetTokenKey(key)  // alias for record.Set("tokenKey", key)
record.RefreshTokenKey() // alias for record.Set("tokenKey:autogenerate", "")

record.ValidatePassword(pass)
record.SetPassword(pass)   // alias for record.Set("password", pass)
record.SetRandomPassword() // sets cryptographically random 30 characters string as password
```

## Copies

```go
// returns a shallow copy of the current record model populated
// with its ORIGINAL db data state and everything else reset to the defaults
// (usually used for comparing old and new field values)
record.Original()

// returns a shallow copy of the current record model populated
// with its LATEST data state and everything else reset to the defaults
// (aka. no expand, no custom fields and with default visibility flags)
record.Fresh()

// returns a shallow copy of the current record model populated
// with its ALL collection and custom fields data, expand and visibility flags
record.Clone()
```

## Hide/Unhide fields

Collection fields can be marked as "Hidden" from the Dashboard to prevent regular user access to the field values.

Record models provide an option to further control the fields serialization visibility in addition to the "Hidden" fields option using the [`record.Hide(fieldNames...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Record.Hide) and [`record.Unhide(fieldNames...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Record.Unhide) methods.

Often the `Hide/Unhide` methods are used in combination with the `OnRecordEnrich` hook invoked on every record enriching (list, view, create, update, realtime change, etc.). For example:

```go
app.OnRecordEnrich("articles").BindFunc(func(e *core.RecordEnrichEvent) error {
    // dynamically show/hide a record field depending on whether the current
    // authenticated user has a certain "role" (or any other field constraint)
    if e.RequestInfo.Auth == nil ||
        (!e.RequestInfo.Auth.IsSuperuser() && e.RequestInfo.Auth.GetString("role") != "staff") {
        e.Record.Hide("someStaffOnlyField")
    }

    return e.Next()
})
```

> ℹ️ For custom fields, not part of the record collection schema, it is required to call explicitly `record.WithCustomData(true)` to allow them in the public serialization.

## Fetch records

### Fetch single record

All single record retrieval methods return `nil` and `sql.ErrNoRows` error if no record is found.

```go
// retrieve a single "articles" record by its id
record, err := app.FindRecordById("articles", "RECORD_ID")

// retrieve a single "articles" record by a single key-value pair
record, err := app.FindFirstRecordByData("articles", "slug", "test")

// retrieve a single "articles" record by a string filter expression
// (NB! use "{:placeholder}" to safely bind untrusted user input parameters)
record, err := app.FindFirstRecordByFilter(
    "articles",
    "status = 'public' && category = {:category}",
    dbx.Params{ "category": "news" },
)
```

### Fetch multiple records

All multiple records retrieval methods return empty slice and `nil` error if no records are found.

```go
// retrieve multiple "articles" records by their ids
records, err := app.FindRecordsByIds("articles", []string{"RECORD_ID1", "RECORD_ID2"})

// retrieve the total number of "articles" records in a collection with optional dbx expressions
totalPending, err := app.CountRecords("articles", dbx.HashExp{"status": "pending"})

// retrieve multiple "articles" records with optional dbx expressions
records, err := app.FindAllRecords("articles",
    dbx.NewExp("LOWER(username) = {:username}", dbx.Params{"username": "John.Doe"}),
    dbx.HashExp{"status": "pending"},
)

// retrieve multiple paginated "articles" records by a string filter expression
// (NB! use "{:placeholder}" to safely bind untrusted user input parameters)
records, err := app.FindRecordsByFilter(
    "articles",                                    // collection
    "status = 'public' && category = {:category}", // filter
    "-published",                                   // sort
    10,                                            // limit
    0,                                             // offset
    dbx.Params{ "category": "news" },              // optional filter params
)
```

### Fetch auth records

```go
// retrieve a single auth record by its email
user, err := app.FindAuthRecordByEmail("users", "test@example.com")

// retrieve a single auth record by JWT
// (you could also specify an optional list of accepted token types)
user, err := app.FindAuthRecordByToken("YOUR_TOKEN", core.TokenTypeAuth)
```

### Custom record query

In addition to the above query helpers, you can also create custom Record queries using [`RecordQuery(collection)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#RecordQuery) method. It returns a SELECT DB builder that can be used with the same methods described in the [Database guide](/docs/go-database).

```go
import (
    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase/core"
)

...

func FindActiveArticles(app core.App) ([]*core.Record, error) {
    records := []*core.Record{}

    err := app.RecordQuery("articles").
        AndWhere(dbx.HashExp{"status": "active"}).
        OrderBy("published DESC").
        Limit(10).
        All(&records)

    if err != nil {
        return nil, err
    }

    return records, nil
}
```

## Create new record

### Create new record programmatically

```go
import (
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/filesystem"
)

...

collection, err := app.FindCollectionByNameOrId("articles")
if err != nil {
    return err
}

record := core.NewRecord(collection)

record.Set("title", "Lorem ipsum")
record.Set("active", true)

// field type specific modifiers can also be used
record.Set("slug:autogenerate", "post-")

// new files must be one or a slice of *filesystem.File values
//
// note1: see all factories in https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/filesystem#File
// note2: for reading files from a request event you can also use e.FindUploadedFiles("fileKey")
f1, _ := filesystem.NewFileFromPath("/local/path/to/file1.txt")
f2, _ := filesystem.NewFileFromBytes([]byte{"test content"}, "file2.txt")
f3, _ := filesystem.NewFileFromURL(context.Background(), "https://example.com/file3.pdf")
record.Set("documents", []*filesystem.File{f1, f2, f3})

// validate and persist
// (use SaveNoValidate to skip fields validation)
err = app.Save(record);
if err != nil {
    return err
}
```

### Intercept create request

```go
import (
    "github.com/pocketbase/pocketbase/core"
)

...

app.OnRecordCreateRequest("articles").BindFunc(func(e *core.RecordRequestEvent) error {
    // ignore for superusers
    if e.HasSuperuserAuth() {
        return e.Next()
    }

    // overwrite the submitted "status" field value
    e.Record.Set("status", "pending")

    // or you can also prevent the create event by returning an error
    status := e.Record.GetString("status")
    if (status != "pending" &&
        // guest or not an editor
        (e.Auth == nil || e.Auth.GetString("role") != "editor")) {
        return e.BadRequestError("Only editors can set a status different from pending", nil)
    }

    return e.Next()
})
```

## Update existing record

### Update existing record programmatically

```go
record, err := app.FindRecordById("articles", "RECORD_ID")
if err != nil {
    return err
}

record.Set("title", "Lorem ipsum")

// delete existing record files by specifying their file names
record.Set("documents-", []string{"file1_abc123.txt", "file3_abc123.txt"})

// append one or more new files to the already uploaded list
//
// note1: see all factories in https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/filesystem#File
// note2: for reading files from a request event you can also use e.FindUploadedFiles("fileKey")
f1, _ := filesystem.NewFileFromPath("/local/path/to/file1.txt")
f2, _ := filesystem.NewFileFromBytes([]byte{"test content"}, "file2.txt")
f3, _ := filesystem.NewFileFromURL(context.Background(), "https://example.com/file3.pdf")
record.Set("documents+", []*filesystem.File{f1, f2, f3})

// validate and persist
// (use SaveNoValidate to skip fields validation)
err = app.Save(record);
if err != nil {
    return err
}
```

### Intercept update request

```go
import (
    "github.com/pocketbase/pocketbase/core"
)

...

app.OnRecordUpdateRequest("articles").Add(func(e *core.RecordRequestEvent) error {
    // ignore for superusers
    if e.HasSuperuserAuth() {
        return e.Next()
    }

    // overwrite the submitted "status" field value
    e.Record.Set("status", "pending")

    // or you can also prevent the update event by returning an error
    status := e.Record.GetString("status")
    if (status != "pending" &&
        // guest or not an editor
        (e.Auth == nil || e.Auth.GetString("role") != "editor")) {
        return e.BadRequestError("Only editors can set a status different from pending", nil)
    }

    return e.Next()
})
```

## Delete record

```go
record, err := app.FindRecordById("articles", "RECORD_ID")
if err != nil {
    return err
}

err = app.Delete(record)
if err != nil {
    return err
}
```

## Transaction

To execute multiple queries in a transaction you can use [`app.RunInTransaction(fn)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.RunInTransaction).

The DB operations are persisted only if the transaction returns `nil`.

It is safe to nest `RunInTransaction` calls as long as you use the callback's `txApp` argument.

> ℹ️ Inside the transaction function always use its `txApp` argument and not the original `app` instance because we allow only a single writer/transaction at a time and it could result in a deadlock.
>
> To avoid performance issues, try to minimize slow/long running tasks such as sending emails, connecting to external services, etc. as part of the transaction.

```go
import (
    "github.com/pocketbase/pocketbase/core"
)

...

titles := []string{"title1", "title2", "title3"}

collection, err := app.FindCollectionByNameOrId("articles")
if err != nil {
    return err
}

// create new record for each title
app.RunInTransaction(func(txApp core.App) error {
    for _, title := range titles {
        record := core.NewRecord(collection)
        record.Set("title", title)

        if err := txApp.Save(record); err != nil {
            return err
        }
    }

    return nil
})
```

## Programmatically expanding relations

To expand record relations programmatically you can use [`app.ExpandRecord(record, expands, optFetchFunc)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.ExpandRecord) for single or [`app.ExpandRecords(records, expands, optFetchFunc)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.ExpandRecords) for multiple records.

Once loaded, you can access the expanded relations via [`record.ExpandedOne(relName)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Record.ExpandedOne) or [`record.ExpandedAll(relName)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Record.ExpandedAll).

For example:

```go
record, err := app.FindFirstRecordByData("articles", "slug", "lorem-ipsum")
if err != nil {
    return err
}

// expand the "author" and "categories" relations
errs := app.ExpandRecord(record, []string{"author", "categories"}, nil)
if len(errs) > 0 {
    return fmt.Errorf("failed to expand: %v", errs)
}

// print the expanded records
log.Println(record.ExpandedOne("author"))
log.Println(record.ExpandedAll("categories"))
```

## Check if record can be accessed

To check whether a custom client request or user can access a single record, you can use the [`app.CanAccessRecord(record, requestInfo, rule)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.CanAccessRecord) method.

Below is an example of creating a custom route to retrieve a single article and checking if the request satisfy the View API rule of the record collection:

```go
package main

import (
    "log"
    "net/http"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/core"
)

func main() {
    app := pocketbase.New()

    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        se.Router.GET("/articles/{slug}", func(e *core.RequestEvent) error {
            slug := e.Request.PathValue("slug")

            record, err := e.App.FindFirstRecordByData("articles", "slug", slug)
            if err != nil {
                return e.NotFoundError("Missing or invalid slug", err)
            }

            info, err := e.RequestInfo()
            if err != nil {
                return e.BadRequestError("Failed to retrieve request info", err)
            }

            canAccess, err := e.App.CanAccessRecord(record, info, record.Collection().ViewRule)
            if !canAccess {
                return e.ForbiddenError("", err)
            }

            return e.JSON(http.StatusOK, record)
        })

        return se.Next()
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

## Generating and validating tokens

PocketBase Web APIs are fully stateless (aka. there are no sessions in the traditional sense) and an auth record is considered authenticated if the submitted request contains a valid `Authorization: TOKEN` header *(see also [Builtin auth middlewares](/docs/go-routing/#builtin-middlewares) and [Retrieving the current auth state from a route](/docs/go-routing/#retrieving-the-current-auth-state))*.

If you want to issue and verify manually a record JWT (auth, verification, password reset, etc.), you could do that using the record token type specific methods:

```go
token, err := record.NewAuthToken()

token, err := record.NewVerificationToken()

token, err := record.NewPasswordResetToken()

token, err := record.NewEmailChangeToken(newEmail)

token, err := record.NewFileToken() // for protected files

token, err := record.NewStaticAuthToken(optCustomDuration) // nonrenewable auth token
```

Each token type has its own secret and the token duration is managed via its type related collection auth option (*the only exception is `NewStaticAuthToken`*).

To validate a record token you can use the [`app.FindAuthRecordByToken`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.FindAuthRecordByToken) method. The token related auth record is returned only if the token is not expired and its signature is valid.

Here is an example how to validate an auth token:

```go
record, err := app.FindAuthRecordByToken("YOUR_TOKEN", core.TokenTypeAuth)
```
