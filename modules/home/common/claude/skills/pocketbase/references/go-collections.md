Collections are usually managed via the Dashboard interface, but there are some situations where you may
want to create or edit a collection programmatically (usually as part of a
[DB migration](/docs/go-migrations)). You can find all available Collection related operations
and methods in
[`core.App`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#App)
and
[`core.Collection`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#Collection),
but below are listed some of the most common ones:

## Fetch collections

##### Fetch single collection

All single collection retrieval methods return `nil` and `sql.ErrNoRows` error if no
collection is found.

```go
collection, err := app.FindCollectionByNameOrId("example")
```

##### Fetch multiple collections

All multiple collections retrieval methods return empty slice and `nil` error if no collections
are found.

```go
allCollections, err := app.FindAllCollections()

authAndViewCollections, err := app.FindAllCollections(core.CollectionTypeAuth, core.CollectionTypeView)
```

##### Custom collection query

In addition to the above query helpers, you can also create custom Collection queries using
[`CollectionQuery()`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#CollectionQuery)
method. It returns a SELECT DB builder that can be used with the same methods described in the
[Database guide](/docs/go-database).

```go
import (
    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase/core"
)

...

func FindSystemCollections(app core.App) ([]*core.Collection, error) {
    collections := []*core.Collection{}

    err := app.CollectionQuery().
        AndWhere(dbx.HashExp{"system": true}).
        OrderBy("created DESC").
        All(&collections)

    if err != nil {
        return nil, err
    }

    return collections, nil
}
```

## Collection properties

```go
Id      string
Name    string
Type    string // "base", "view", "auth"
System  bool // !prevent collection rename, deletion and rules change of internal collections like _superusers
Fields  core.FieldsList
Indexes types.JSONArray[string]
Created types.DateTime
Updated types.DateTime

// CRUD rules
ListRule   *string
ViewRule   *string
CreateRule *string
UpdateRule *string
DeleteRule *string

// "view" type specific options
// (see https://github.com/pocketbase/pocketbase/blob/master/core/collection_model_view_options.go)
ViewQuery string

// "auth" type specific options
// (see https://github.com/pocketbase/pocketbase/blob/master/core/collection_model_auth_options.go)
AuthRule                   *string
ManageRule                 *string
AuthAlert                  core.AuthAlertConfig
OAuth2                     core.OAuth2Config
PasswordAuth               core.PasswordAuthConfig
MFA                        core.MFAConfig
OTP                        core.OTPConfig
AuthToken                  core.TokenConfig
PasswordResetToken         core.TokenConfig
EmailChangeToken           core.TokenConfig
VerificationToken          core.TokenConfig
FileToken                  core.TokenConfig
VerificationTemplate       core.EmailTemplate
ResetPasswordTemplate      core.EmailTemplate
ConfirmEmailChangeTemplate core.EmailTemplate
```

## Field definitions

- [`core.BoolField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BoolField)
- [`core.NumberField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#NumberField)
- [`core.TextField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#TextField)
- [`core.EmailField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#EmailField)
- [`core.URLField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#URLField)
- [`core.EditorField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#EditorField)
- [`core.DateField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#DateField)
- [`core.AutodateField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#AutodateField)
- [`core.SelectField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#SelectField)
- [`core.FileField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#FileField)
- [`core.RelationField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#RelationField)
- [`core.JSONField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#JSONField)
- [`core.GeoPointField`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#GeoPointField)

## Create new collection

```go
import (
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/types"
)

...

// core.NewAuthCollection("example")
// core.NewViewCollection("example")
collection := core.NewBaseCollection("example")

// set rules
collection.ViewRule = types.Pointer("@request.auth.id != ''")
collection.CreateRule = types.Pointer("@request.auth.id != '' && @request.body.user = @request.auth.id")
collection.UpdateRule = types.Pointer(`
    @request.auth.id != '' &&
    user = @request.auth.id &&
    (@request.body.user:isset = false || @request.body.user = @request.auth.id)
`)

// add text field
collection.Fields.Add(&core.TextField{
    Name:     "title",
    Required: true,
    Max:      100,
})

// add relation field
usersCollection, err := app.FindCollectionByNameOrId("users")
if err != nil {
    return err
}
collection.Fields.Add(&core.RelationField{
    Name:          "user",
    Required:      true,
    Max:           100,
    CascadeDelete: true,
    CollectionId:  usersCollection.Id,
})

// add autodate/timestamp fields (created/updated)
collection.Fields.Add(&core.AutodateField{
    Name:     "created",
    OnCreate: true,
})
collection.Fields.Add(&core.AutodateField{
    Name:     "updated",
    OnCreate: true,
    OnUpdate: true,
})

// or: collection.Indexes = []string{"CREATE UNIQUE INDEX idx_example_user ON example (user)"}
collection.AddIndex("idx_example_user", true, "user", "")

// validate and persist
// (use SaveNoValidate to skip fields validation)
err = app.Save(collection)
if err != nil {
    return err
}
```

## Update existing collection

```go
import (
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/types"
)

...

collection, err := app.FindCollectionByNameOrId("example")
if err != nil {
    return err
}

// change rule
collection.DeleteRule = types.Pointer("@request.auth.id != ''")

// add new editor field
collection.Fields.Add(&core.EditorField{
    Name:     "description",
    Required: true,
})

// change existing field
// (returns a pointer and direct modifications are allowed without the need of reinsert)
titleField := collection.Fields.GetByName("title").(*core.TextField)
titleField.Min = 10

// or: collection.Indexes = append(collection.Indexes, "CREATE INDEX idx_example_title ON example (title)")
collection.AddIndex("idx_example_title", false, "title", "")

// validate and persist
// (use SaveNoValidate to skip fields validation)
err = app.Save(collection)
if err != nil {
    return err
}
```

## Delete collection

```go
collection, err := app.FindCollectionByNameOrId("example")
if err != nil {
    return err
}

err = app.Delete(collection)
if err != nil {
    return err
}
```
