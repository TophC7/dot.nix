# Jobs Scheduling

If you have tasks that need to be performed periodically, you could set up crontab-like jobs with the
builtin `app.Cron()`
*(it returns an app scoped [`cron.Cron`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/cron#Cron) value)*.

The jobs scheduler is started automatically on app `serve`, so all you have to do is register a
handler with
[`app.Cron().Add(id, cronExpr, handler)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/cron#Cron.Add)
or
[`app.Cron().MustAdd(id, cronExpr, handler)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/cron#Cron.MustAdd)
(*the latter panic if the cron expression is not valid*).

Each scheduled job runs in its own goroutine and must have:

- **id** - identifier for the scheduled job; could be used to replace or remove an existing job
- **cron expression** - e.g. `0 0 * * *` (*supports numeric list, steps, ranges or macros: `@yearly`, `@annually`, `@monthly`, `@weekly`, `@daily`, `@midnight`, `@hourly`*)
- **handler** - the function that will be executed every time when the job runs

Here is one minimal example:

```go
// main.go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
)

func main() {
    app := pocketbase.New()

    // prints "Hello!" every 2 minutes
    app.Cron().MustAdd("hello", "*/2 * * * *", func() {
        log.Println("Hello!")
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

To remove already registered cron job you can call
[`app.Cron().Remove(id)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/cron#Cron.Remove)

All registered app level cron jobs can be also previewed and triggered from the
*Dashboard > Settings > Crons* section.

> **Warning** Keep in mind that the `app.Cron()` is also used for running the system scheduled jobs
> like the logs cleanup or auto backups (the jobs id is in the format `__pb*__`) and
> replacing these system jobs or calling `RemoveAll()`/`Stop()` could have unintended
> side-effects.
>
> If you want more advanced control you can initialize your own cron instance independent from the
> application via `cron.New()`.
