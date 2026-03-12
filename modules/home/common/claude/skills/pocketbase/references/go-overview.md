## Getting started

PocketBase can be used as regular Go package that exposes various helpers and hooks to help you implement your own custom portable application.

A new PocketBase instance is created via [`pocketbase.New()`](https://pkg.go.dev/github.com/pocketbase/pocketbase#New) or [`pocketbase.NewWithConfig(config)`](https://pkg.go.dev/github.com/pocketbase/pocketbase#NewWithConfig).

Once created you can register your custom business logic via the available [event hooks](/docs/go-event-hooks/) and call [`app.Start()`](https://pkg.go.dev/github.com/pocketbase/pocketbase#PocketBase.Start) to start the application.

Below is a minimal example:

0. [Install Go 1.23+](https://go.dev/doc/install)

1. Create a new project directory with `main.go` file inside it.

   As a reference, you can also explore the prebuilt executable [`example/base/main.go`](https://github.com/pocketbase/pocketbase/blob/master/examples/base/main.go) file.

   ```go
   package main

   import (
       "log"
       "os"

       "github.com/pocketbase/pocketbase"
       "github.com/pocketbase/pocketbase/apis"
       "github.com/pocketbase/pocketbase/core"
   )

   func main() {
       app := pocketbase.New()

       app.OnServe().BindFunc(func(se *core.ServeEvent) error {
           // serves static files from the provided public dir (if exists)
           se.Router.GET("/{path...}", apis.Static(os.DirFS("./pb_public"), false))

           return se.Next()
       })

       if err := app.Start(); err != nil {
           log.Fatal(err)
       }
   }
   ```

2. To init the dependencies, run `go mod init myapp && go mod tidy`.

3. To start the application, run `go run . serve`.

4. To build a statically linked executable, run `go build` and then you can start the created executable with `./myapp serve`.

## Custom SQLite driver

> **Note:**
> **The general recommendation is to use the builtin SQLite setup** but if you need more advanced configuration or extensions like ICU, FTS5, etc. you'll have to specify a custom driver/build.
>
> Note that PocketBase by default doesn't require CGO because it uses the pure Go SQLite port [modernc.org/sqlite](https://pkg.go.dev/modernc.org/sqlite), but this may not be the case when using a custom SQLite driver!

PocketBase v0.23+ added support for defining a `DBConnect` function as app configuration to load custom SQLite builds and drivers compatible with the standard Go `database/sql`.

**The `DBConnect` function is called twice** - once for `pb_data/data.db` (the main database file) and second time for `pb_data/auxiliary.db` (used for logs and other ephemeral system meta information).

If you want to load your custom driver conditionally and fallback to the default handler, then you can call [`core.DefaultDBConnect`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#DefaultDBConnect).

*As a side-note, if you are not planning to use `core.DefaultDBConnect` fallback as part of your custom driver registration you can exclude the default pure Go driver with `go build -tags no_default_driver` to reduce the binary size a little (~4MB).*

Below are some minimal examples with commonly used external SQLite drivers:

### github.com/mattn/go-sqlite3

This is a CGO driver and requires to build your application with `CGO_ENABLED=1`.

*For all available options please refer to the [`github.com/mattn/go-sqlite3`](https://github.com/mattn/go-sqlite3) README.*

```go
package main

import (
    "database/sql"
    "log"

    "github.com/mattn/go-sqlite3"
    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase"
)

// register a new driver with default PRAGMAs and the same query
// builder implementation as the already existing sqlite3 builder
func init() {
    // initialize default PRAGMAs for each new connection
    sql.Register("pb_sqlite3",
        &sqlite3.SQLiteDriver{
            ConnectHook: func(conn *sqlite3.SQLiteConn) error {
                _, err := conn.Exec(`
                    PRAGMA busy_timeout       = 10000;
                    PRAGMA journal_mode       = WAL;
                    PRAGMA journal_size_limit = 200000000;
                    PRAGMA synchronous        = NORMAL;
                    PRAGMA foreign_keys       = ON;
                    PRAGMA temp_store         = MEMORY;
                    PRAGMA cache_size         = -32000;
                `, nil)

                return err
            },
        },
    )

    dbx.BuilderFuncMap["pb_sqlite3"] = dbx.BuilderFuncMap["sqlite3"]
}

func main() {
    app := pocketbase.NewWithConfig(pocketbase.Config{
        DBConnect: func(dbPath string) (*dbx.DB, error) {
            return dbx.Open("pb_sqlite3", dbPath)
        },
    })

    // any custom hooks or plugins...

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### github.com/ncruces/go-sqlite3

*For all available options please refer to the [`github.com/ncruces/go-sqlite3`](https://github.com/ncruces/go-sqlite3) README.*

```go
package main

import (
    "log"

    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase"

    _ "github.com/ncruces/go-sqlite3/driver"
    _ "github.com/ncruces/go-sqlite3/embed"
)

func main() {
    app := pocketbase.NewWithConfig(pocketbase.Config{
        DBConnect: func(dbPath string) (*dbx.DB, error) {
            const pragmas = "?_pragma=busy_timeout(10000)&_pragma=journal_mode(WAL)&_pragma=journal_size_limit(200000000)&_pragma=synchronous(NORMAL)&_pragma=foreign_keys(ON)&_pragma=temp_store(MEMORY)&_pragma=cache_size(-32000)"

            return dbx.Open("sqlite3", "file:"+dbPath+pragmas)
        },
    })

    // custom hooks and plugins...

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```
