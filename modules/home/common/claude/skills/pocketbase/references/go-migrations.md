# Go Migrations

PocketBase comes with a builtin DB and data migration utility, allowing you to version your DB structure, create collections programmatically, initialize default settings, etc.

Because the migrations are regular Go functions, besides applying schema changes, they could be used also to adjust existing data to fit the new schema or any other app specific logic that you want to run only once.

And as a bonus, being `.go` files also ensure that the migrations will be embedded seamlessly in your final executable.

## Quick setup

##### 0. Register the migrate command

*You can find all available config options in the [`migratecmd`](https://pkg.go.dev/github.com/pocketbase/pocketbase/plugins/migratecmd) subpackage.*

```go
// main.go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/plugins/migratecmd"
    "github.com/pocketbase/pocketbase/tools/osutils"

    // enable once you have at least one migration
    // _ "yourpackage/migrations"
)

func main() {
    app := pocketbase.New()

    migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
        // enable auto creation of migration files when making collection changes in the Dashboard
        // (the IsProbablyGoRun check is to enable it only during development)
        Automigrate: osutils.IsProbablyGoRun(),
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

##### 1. Create new migration

To create a new blank migration you can run `migrate create`.

```
// Since the "create" command makes sense only during development,
// it is expected the user to be in the app working directory
// and to be using "go run"

[root@dev app]$ go run . migrate create "your_new_migration"
```

```go
// migrations/1655834400_your_new_migration.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(app core.App) error {
        // add up queries...

        return nil
    }, func(app core.App) error {
        // add down queries...

        return nil
    })
}
```

The above will create a new blank migration file inside the default command `migrations` directory.

Each migration file should have a single `m.Register(upFunc, downFunc)` call.

In the migration file, you are expected to write your "upgrade" code in the `upFunc` callback.
The `downFunc` is optional and it should contain the "downgrade" operations to revert the changes made by the `upFunc`.
Both callbacks accept a transactional `core.App` instance.

> **Info:** You can explore the [Database guide](/docs/go-database), [Collection operations](/docs/go-collections) and [Record operations](/docs/go-records) for more details how to interact with the database. You can also find [some examples](#examples) further below in this guide.

##### 2. Load migrations

**To make your application aware of the registered migrations, you have to import the above `migrations` package in one of your `main` package files:**

```go
package main

import _ "yourpackage/migrations"

// ...
```

##### 3. Run migrations

**New unapplied migrations are automatically executed when the application server starts, aka. on `serve`.**

Alternatively, you can also apply new migrations manually by running `migrate up`.
To revert the last applied migration(s), you can run `migrate down [number]`.

*When manually applying or reverting migrations, the `serve` process needs to be restarted so that it can refresh its cached collections state.*

## Collections snapshot

The `migrate collections` command generates a full snapshot of your current collections configuration without having to type it manually. Similar to the `migrate create` command, this will generate a new migration file in the `migrations` directory.

```
// Since the "collections" command makes sense only during development,
// it is expected the user to be in the app working directory
// and to be using "go run"

[root@dev app]$ go run . migrate collections
```

By default the collections snapshot is imported in *extend* mode, meaning that collections and fields that don't exist in the snapshot are preserved. If you want the snapshot to *delete* missing collections and fields, you can edit the generated file and change the last argument of `ImportCollectionsByMarshaledJSON` method to `true`.

## Migrations history

All applied migration filenames are stored in the internal `_migrations` table.
During local development often you might end up making various collection changes to test different approaches.
When `Automigrate` is enabled this could lead in a migration history with unnecessary intermediate steps that may not be wanted in the final migration history.

To avoid the clutter and to prevent applying the intermediate steps in production, you can remove (or squash) the unnecessary migration files manually and then update the local migrations history by running:

```
[root@dev app]$ go run . migrate history-sync
```

The above command will remove any entry from the `_migrations` table that doesn't have a related migration file associated with it.

## Examples

##### Executing raw SQL statements

```go
// migrations/1687801090_set_pending_status.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    m "github.com/pocketbase/pocketbase/migrations"
)

// set a default "pending" status to all empty status articles
func init() {
    m.Register(func(app core.App) error {
        _, err := app.DB().NewQuery("UPDATE articles SET status = 'pending' WHERE status = ''").Execute()
        return err
    }, nil)
}
```

##### Initialize default application settings

```go
// migrations/1687801090_initial_settings.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(app core.App) error {
        settings := app.Settings()

        // for all available settings fields you could check
        // https://github.com/pocketbase/pocketbase/blob/develop/core/settings_model.go#L121-L130
        settings.Meta.AppName = "test"
        settings.Meta.AppURL = "https://example.com"
        settings.Logs.MaxDays = 2
        settings.Logs.LogAuthId = true
        settings.Logs.LogIP = false

        return app.Save(settings)
    }, nil)
}
```

##### Creating initial superuser

*For all supported record methods, you can refer to [Record operations](/docs/go-records).*

*You can also create the initial super user using the `./pocketbase superuser create EMAIL PASS` command.*

```go
// migrations/1687801090_initial_superuser.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(app core.App) error {
        superusers, err := app.FindCollectionByNameOrId(core.CollectionNameSuperusers)
        if err != nil {
            return err
        }

        record := core.NewRecord(superusers)

        // note: the values can be eventually loaded via os.Getenv(key)
        // or from a special local config file
        record.Set("email", "test@example.com")
        record.Set("password", "1234567890")

        return app.Save(record)
    }, func(app core.App) error { // optional revert operation
        record, _ := app.FindAuthRecordByEmail(core.CollectionNameSuperusers, "test@example.com")
        if record == nil {
            return nil // probably already deleted
        }

        return app.Delete(record)
    })
}
```

##### Creating collection programmatically

*For all supported collection methods, you can refer to [Collection operations](/docs/go-collections).*

```go
// migrations/1687801090_create_clients_collection.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/types"

    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(app core.App) error {
        // init a new auth collection with the default system fields and auth options
        collection := core.NewAuthCollection("clients")

        // restrict the list and view rules for record owners
        collection.ListRule = types.Pointer("id = @request.auth.id")
        collection.ViewRule = types.Pointer("id = @request.auth.id")

        // add extra fields in addition to the default ones
        collection.Fields.Add(
            &core.TextField{
                Name:     "company",
                Required: true,
                Max:      100,
            },
            &core.URLField{
                Name:        "website",
                Presentable: true,
            },
        )

        // disable password auth and enable OTP only
        collection.PasswordAuth.Enabled = false
        collection.OTP.Enabled = true

        collection.AddIndex("idx_clients_company", false, "company", "")

        return app.Save(collection)
    }, func(app core.App) error { // optional revert operation
        collection, err := app.FindCollectionByNameOrId("clients")
        if err != nil {
            return err
        }

        return app.Delete(collection)
    })
}
```
