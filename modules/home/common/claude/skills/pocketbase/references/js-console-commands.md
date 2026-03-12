# Console Commands

You can register custom console commands using
`app.rootCmd.addCommand(cmd)`, where `cmd` is a
[Command](/jsvm/classes/Command.html) instance.

Here is an example:

```go
$app.rootCmd.addCommand(new Command({
    use: "hello",
    run: (cmd, args) => {
        console.log("Hello world!")
    },
}))
```

To run the command you can execute:

```
./pocketbase hello
```

> **ℹ️ Note:**
> Keep in mind that the console commands execute in their own separate app process and run
> independently from the main `serve` command (aka. hook and realtime events between different
> processes are not shared with one another).
