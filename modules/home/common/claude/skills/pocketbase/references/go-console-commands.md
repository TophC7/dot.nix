# Console Commands

You can register custom console commands using
`app.RootCmd.AddCommand(cmd)`, where `cmd` is a
[cobra](https://pkg.go.dev/github.com/spf13/cobra) command.

Here is an example:

```go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/spf13/cobra"
)

func main() {
    app := pocketbase.New()

    app.RootCmd.AddCommand(&cobra.Command{
        Use: "hello",
        Run: func(cmd *cobra.Command, args []string) {
            log.Println("Hello world!")
        },
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

To run the command you can build your Go application and execute:

```
# or "go run main.go hello"
./myapp hello
```

> ℹ️ Keep in mind that the console commands execute in their own separate app process and run
> independently from the main `serve` command (aka. hook and realtime events between different
> processes are not shared with one another).
