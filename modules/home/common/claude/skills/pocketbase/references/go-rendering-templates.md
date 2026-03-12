## Overview

A common task when creating custom routes or emails is the need of generating HTML output.

There are plenty of Go template-engines available that you can use for this, but often for simple cases
the Go standard library `html/template` package should work just fine.

To make it slightly easier to load template files concurrently and on the fly, PocketBase also provides a
thin wrapper around the standard library in the
[`github.com/pocketbase/pocketbase/tools/template`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/template)
utility package.

```go
import "github.com/pocketbase/pocketbase/tools/template"

data := map[string]any{"name": "John"}

html, err := template.NewRegistry().LoadFiles(
    "views/base.html",
    "views/partial1.html",
    "views/partial2.html",
).Render(data)
```

The general flow when working with composed and nested templates is that you create "base" template(s)
that defines various placeholders using the
`{{template "placeholderName" .}}` or
`{{block "placeholderName" .}}default...{{end}}` actions.

Then in the partials, you define the content for those placeholders using the
`{{define "placeholderName"}}custom...{{end}}` action.

The dot object (**.**) in the above represents the data passed to the templates
via the `Render(data)` method.

By default the templates apply contextual (HTML, JS, CSS, URI) auto escaping so the generated template
content should be injection-safe. To render raw/verbatim trusted content in the templates you can use the
builtin `raw` function (e.g. `{{.content|raw}}`).

> ℹ️ For more information about the template syntax please refer to the
> [*html/template*](https://pkg.go.dev/html/template#hdr-A_fuller_picture)
> and
> [*text/template*](https://pkg.go.dev/text/template)
> package godocs.
> **Another great resource is also the Hashicorp's
> [Learn Go Template Syntax](https://developer.hashicorp.com/nomad/tutorials/templates/go-template-syntax)
> tutorial.**

## Example HTML page with layout

Consider the following app directory structure:

```html
myapp/
    views/
        layout.html
        hello.html
    main.go
```

We define the content for `layout.html` as:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <title>{{block "title" .}}Default app title{{end}}</title>
</head>
<body>
    Header...

    {{block "body" .}}
        Default app body...
    {{end}}

    Footer...
</body>
</html>
```

We define the content for `hello.html` as:

```html
{{define "title"}}
    Page 1
{{end}}

{{define "body"}}
    <p>Hello from {{.name}}</p>
{{end}}
```

Then to output the final page, we'll register a custom `/hello/:name` route:

```go
// main.go
package main

import (
    "log"
    "net/http"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/template"
)

func main() {
    app := pocketbase.New()

    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        // this is safe to be used by multiple goroutines
        // (it acts as store for the parsed templates)
        registry := template.NewRegistry()

        se.Router.GET("/hello/{name}", func(e *core.RequestEvent) error {
            name := e.Request.PathValue("name")

            html, err := registry.LoadFiles(
                "views/layout.html",
                "views/hello.html",
            ).Render(map[string]any{
                "name": name,
            })

            if err != nil {
                // or redirect to a dedicated 404 HTML page
                return e.NotFoundError("", err)
            }

            return e.HTML(http.StatusOK, html)
        })

        return se.Next()
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```
