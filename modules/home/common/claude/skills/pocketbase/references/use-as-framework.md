# Use as Framework

One of the main features of PocketBase is that **it can be used as a framework** which enables you to write your own custom app business logic in [Go](/docs/go-overview) or [JavaScript](/docs/js-overview) and still have a portable backend at the end.

**Choose [Extend with Go](/docs/go-overview) if you are already familiar with the language or have the time to learn it.** As the primary PocketBase language, the Go APIs are better documented and you'll be able to integrate with any 3rd party Go library since you'll have more control over the application flow. The only drawback is that the Go APIs are slightly more verbose and it may require some time to get used to, especially if this is your first time working with Go.

**Choose [Extend with JavaScript](/docs/js-overview) if you don't intend to write too much custom code and want a quick way to explore the PocketBase capabilities.** The embedded JavaScript engine is a pluggable wrapper around the existing Go APIs, so most of the time the slight performance penalty will be negligible because it'll invoke the Go functions under the hood.
As a bonus, because the JS VM mirrors the Go APIs, you would be able migrate gradually without much code changes from JS -> Go at later stage in case you hit a bottleneck or want more control over the execution flow.

With both Go and JavaScript, you can:

- **Register custom routes:**

  **Go:**
  ```go
  app.OnServe().BindFunc(func(se *core.ServeEvent) error {
      se.Router.GET("/hello", func(e *core.RequestEvent) error {
          return e.String(http.StatusOK, "Hello world!")
      })

      return se.Next()
  })
  ```

  **JavaScript:**
  ```javascript
  routerAdd("GET", "/hello", (e) => {
      return e.string(200, "Hello world!")
  })
  ```

- **Bind to event hooks and intercept responses:**

  **Go:**
  ```go
  app.OnRecordCreateRequest("posts").BindFunc(func(e *core.RecordRequestEvent) error {
      // if not superuser, overwrite the newly submitted "posts" record status to pending
      if !e.HasSuperuserAuth() {
          e.Record.Set("status", "pending")
      }

      return e.Next()
  })
  ```

  **JavaScript:**
  ```javascript
  onRecordCreateRequest((e) => {
      // if not superuser, overwrite the newly submitted "posts" record status to pending
      if (!e.hasSuperuserAuth()) {
          e.record.set("status", "pending")
      }

      e.next()
  }, "posts")
  ```

- **Register custom console commands:**

  **Go:**
  ```go
  app.RootCmd.AddCommand(&cobra.Command{
      Use: "hello",
      Run: func(cmd *cobra.Command, args []string) {
          print("Hello world!")
      },
  })
  ```

  **JavaScript:**
  ```javascript
  $app.rootCmd.addCommand(new Command({
      use: "hello",
      run: (cmd, args) => {
          console.log("Hello world!")
      },
  }))
  ```

- and many more...

For further info, please check the related [Extend with Go](/docs/go-overview) or [Extend with JavaScript](/docs/js-overview) guides.
