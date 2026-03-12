PocketBase routing is built on top of the standard Go
[`net/http.ServeMux`](https://pkg.go.dev/net/http#ServeMux).
The router can be accessed via the `app.OnServe()` hook allowing you to register custom endpoints
and middlewares.

## Routes

### Registering new routes

Every route has a path, handler function and eventually middlewares attached to it. For example:

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // register "GET /hello/{name}" route (allowed for everyone)
    se.Router.GET("/hello/{name}", func(e *core.RequestEvent) error {
        name := e.Request.PathValue("name")

        return e.String(http.StatusOK, "Hello " + name)
    })

    // register "POST /api/myapp/settings" route (allowed only for authenticated users)
    se.Router.POST("/api/myapp/settings", func(e *core.RequestEvent) error {
        // do something ...
        return e.JSON(http.StatusOK, map[string]bool{"success": true})
    }).Bind(apis.RequireAuth())

    return se.Next()
})
```

There are several routes registration methods available, but the most common ones are:

```go
se.Router.GET(path, action)
se.Router.POST(path, action)
se.Router.PUT(path, action)
se.Router.PATCH(path, action)
se.Router.DELETE(path, action)

// If you want to handle any HTTP method define only a path (e.g. "/example")
// OR if you want to specify a custom one add it as prefix to the path (e.g. "TRACE /example")
se.Router.Any(pattern, action)
```

The router also supports creating groups for routes that share the same base path and middlewares. For
example:

```go
g := se.Router.Group("/api/myapp")

// group middleware
g.Bind(apis.RequireAuth())

// group routes
g.GET("", action1)
g.GET("/example/{id}", action2)
g.PATCH("/example/{id}", action3).BindFunc(
    /* custom route specific middleware func */
)

// nested group
sub := g.Group("/sub")
sub.GET("/sub1", action4)
```

The example registers the following endpoints
(all require authenticated user access):

- GET /api/myapp -> action1
- GET /api/myapp/example/{id} -> action2
- PATCH /api/myapp/example/{id} -> action3
- GET /api/myapp/example/sub/sub1 -> action4

Each router group and route could define [middlewares](#middlewares) in a similar manner to the
regular app hooks via the `Bind/BindFunc` methods, allowing you to perform various BEFORE or AFTER
action operations (e.g. inspecting request headers, custom access checks, etc.).

### Path parameters and matching rules

Because PocketBase routing is based on top of the Go standard router mux, we follow the same pattern
matching rules. Below you could find a short overview but for more details please refer to
[`net/http.ServeMux`](https://pkg.go.dev/net/http#ServeMux).

In general, a route pattern looks like `[METHOD ][HOST]/[PATH]`
(*the METHOD prefix is added automatically when using the designated `GET()`,
`POST()`, etc. methods*).

Route paths can include parameters in the format `{paramName}`.
You can also use `{paramName...}` format to specify a parameter that targets more than one path
segment.

**A pattern ending with a trailing slash `/` acts as anonymous wildcard and matches any requests
that begins with the defined route. If you want to have a trailing slash but to indicate the end of the
URL then you need to end the path with the special
`{$}` parameter.**

> **Info:** If your route path starts with `/api/`
> consider combining it with your unique app name like `/api/myapp/...` to avoid collisions
> with system routes.

Here are some examples:

```go
// match "GET example.com/index.html"
se.Router.GET("example.com/index.html")

// match "GET /index.html" (for any host)
se.Router.GET("/index.html")

// match "GET /static/", "GET /static/a/b/c", etc.
se.Router.GET("/static/")

// match "GET /static/", "GET /static/a/b/c", etc.
// (similar to the above but with a named wildcard parameter)
se.Router.GET("/static/{path...}")

// match only "GET /static/" (if no "/static" is registered, it is 301 redirected)
se.Router.GET("/static/{$}")

// match "GET /customers/john", "GET /customers/jane", etc.
se.Router.GET("/customers/{name}")
```

---

In the following examples `e` is usually
[`*core.RequestEvent`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#RequestEvent) value.

---

### Reading path parameters

```go
id := e.Request.PathValue("id")
```

### Retrieving the current auth state

The request auth state can be accessed (or set) via the `RequestEvent.Auth` field.

```go
authRecord := e.Auth

isGuest := e.Auth == nil

// the same as "e.Auth != nil && e.Auth.IsSuperuser()"
isSuperuser := e.HasSuperuserAuth()
```

Alternatively you could also access the request data from the summarized request info instance
(*usually used in hooks like the `OnRecordEnrich` where there is no direct access to the request*).

```go
info, err := e.RequestInfo()

authRecord := info.Auth

isGuest := info.Auth == nil

// the same as "info.Auth != nil && info.Auth.IsSuperuser()"
isSuperuser := info.HasSuperuserAuth()
```

### Reading query parameters

```go
// retrieve the first value of the "search" query param
search := e.Request.URL.Query().Get("search")

// or via the parsed request info
info, err := e.RequestInfo()
search := info.Query["search"]

// in case of array query params (e.g. search=123&search=456)
arr := e.Request.URL.Query()["search"] // []string{"123", "456"}
```

### Reading request headers

```go
token := e.Request.Header.Get("Some-Header")

// or via the parsed request info
// (the header value is always normalized per the @request.headers.* API rules format)
info, err := e.RequestInfo()
token := info.Headers["some_header"]
```

### Writing response headers

```go
e.Response.Header().Set("Some-Header", "123")
```

### Retrieving uploaded files

```go
// retrieve the uploaded files and parse the found multipart data into a ready-to-use []*filesystem.File
files, err := e.FindUploadedFiles("document")

// or retrieve the raw single multipart/form-data file and header
mf, mh, err := e.Request.FormFile("document")
```

### Reading request body

Body parameters can be read either via
[`e.BindBody`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#Event.BindBody)
OR through the parsed request info (*requires manual type assertions*).

The `e.BindBody` argument must be a pointer to a struct or `map[string]any`.
The following struct tags are supported
(*the specific binding rules and which one will be used depend on the request Content-Type*):

- `json` (json body)- uses the builtin Go JSON package for unmarshaling.
- `xml` (xml body) - uses the builtin Go XML package for unmarshaling.
- `form` (form data) - utilizes the custom
  [`router.UnmarshalRequestData`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#UnmarshalRequestData)
  method.

**NB! When binding structs make sure that they don't have public fields that shouldn't be bindable and it is
advisable such fields to be unexported or define a separate struct with just the safe bindable fields.**

```go
// read/scan the request body fields into a typed struct
data := struct {
    // unexported to prevent binding
    somethingPrivate string

    Title       string `json:"title" form:"title"`
    Description string `json:"description" form:"description"`
    Active      bool   `json:"active" form:"active"`
}{}
if err := e.BindBody(&data); err != nil {
    return e.BadRequestError("Failed to read request data", err)
}

// alternatively, read the body via the parsed request info
info, err := e.RequestInfo()
title, ok := info.Body["title"].(string)
```

### Writing response body

*For all supported methods, you can refer to
[`router.Event`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#Event).*

```go
// send response with JSON body
// (it also provides a generic response fields picker/filter if the "fields" query parameter is set)
e.JSON(http.StatusOK, map[string]any{"name": "John"})

// send response with string body
e.String(http.StatusOK, "Lorem ipsum...")

// send response with HTML body
// (check also the "Rendering templates" section)
e.HTML(http.StatusOK, "<h1>Hello!</h1>")

// redirect
e.Redirect(http.StatusTemporaryRedirect, "https://example.com")

// send response with no body
e.NoContent(http.StatusNoContent)

// serve a single file
e.FileFS(os.DirFS("..."), "example.txt")

// stream the specified reader
e.Stream(http.StatusOK, "application/octet-stream", reader)

// send response with blob (bytes slice) body
e.Blob(http.StatusOK, "application/octet-stream", []byte{ ... })
```

### Reading the client IP

```go
// The IP of the last client connecting to your server.
// The returned IP is safe and can be always trusted.
// When behind a reverse proxy (e.g. nginx) this method returns the IP of the proxy.
ip := e.RemoteIP()

// The "real" IP of the client based on the configured Settings.TrustedProxy header(s).
// If such headers are not set, it fallbacks to e.RemoteIP().
ip := e.RealIP()
```

### Request store

The `core.RequestEvent` comes with a local store that you can use to share custom data between
[middlewares](#middlewares) and the route action.

```go
// store for the duration of the request
e.Set("someKey", 123)

// retrieve later
val := e.Get("someKey").(int) // 123
```

## Middlewares

### Registering middlewares

Middlewares allow inspecting, intercepting and filtering route requests.

All middleware functions share the same signature with the route actions (aka.
`func(e *core.RequestEvent) error`) but expect the user to call `e.Next()` if they
want to proceed with the execution chain.

Middlewares can be registered *globally*, on *group* and on *route* level using the
`Bind`
and `BindFunc` methods.

Here is a minimal example of what a global middleware looks like:

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // register a global middleware
    se.Router.BindFunc(func(e *core.RequestEvent) error {
        if e.Request.Header.Get("Something") == "" {
            return e.BadRequestError("Something header value is missing!", nil)
        }
        return e.Next()
    })

    return se.Next()
})
```

[`RouterGroup.Bind(middlewares...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#RouterGroup.Bind)
/
[`Route.Bind(middlewares...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#Route.Bind)
registers one or more middleware handlers.
Similar to the other app hooks, a middleware handler has 3 fields:

- `Id` *(optional)* - the name of the middleware (could be used as argument for
  `Unbind`)
- `Priority` *(optional)* - the execution order of the middleware (if empty fallbacks to
  the order of registration in the code)
- `Func` *(required)* - the middleware handler function

Often you don't need to specify the `Id` or `Priority` of the middleware and for
convenience you can instead use directly
[`RouterGroup.BindFunc(funcs...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#RouterGroup.BindFunc)
/
[`Route.BindFunc(funcs...)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tools/router#Route.BindFunc).

Below is a slightly more advanced example showing all options and the execution sequence (*2,0,1,3,4*):

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // attach global middleware
    se.Router.BindFunc(func(e *core.RequestEvent) error {
        println(0)
        return e.Next()
    })

    g := se.Router.Group("/sub")

    // attach group middleware
    g.BindFunc(func(e *core.RequestEvent) error {
        println(1)
        return e.Next()
    })

    // attach group middleware with an id and custom priority
    g.Bind(&hook.Handler[*core.RequestEvent]{
        Id: "something",
        Func: func(e *core.RequestEvent) error {
            println(2)
            return e.Next()
        },
        Priority: -1,
    })

    // attach middleware to a single route
    //
    // "GET /sub/hello" should print the sequence: 2,0,1,3,4
    g.GET("/hello", func(e *core.RequestEvent) error {
        println(4)
        return e.String(200, "Hello!")
    }).BindFunc(func(e *core.RequestEvent) error {
        println(3)
        return e.Next()
    })

    return se.Next()
})
```

### Removing middlewares

To remove a registered middleware from the execution chain for a specific group or route you can make use
of the
`Unbind(id)` method.

Note that only middlewares that have a non-empty `Id` can be removed.

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // global middleware
    se.Router.Bind(&hook.Handler[*core.RequestEvent]{
        Id: "test",
        Func: func(e *core.RequestEvent) error {
            // ...
            return e.Next()
        },
    )

    // "GET /A" invokes the "test" middleware
    se.Router.GET("/A", func(e *core.RequestEvent) error {
        return e.String(200, "A")
    })

    // "GET /B" doesn't invoke the "test" middleware
    se.Router.GET("/B", func(e *core.RequestEvent) error {
        return e.String(200, "B")
    }).Unbind("test")

    return se.Next()
})
```

### Builtin middlewares

The
[`apis`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis)
package exposes several middlewares that you can use as part of your application.

```go
// Require the request client to be unauthenticated (aka. guest).
// Example: Route.Bind(apis.RequireGuestOnly())
apis.RequireGuestOnly()

// Require the request client to be authenticated
// (optionally specify a list of allowed auth collection names, default to any).
// Example: Route.Bind(apis.RequireAuth())
apis.RequireAuth(optCollectionNames...)

// Require the request client to be authenticated as superuser
// (this is an alias for apis.RequireAuth(core.CollectionNameSuperusers)).
// Example: Route.Bind(apis.RequireSuperuserAuth())
apis.RequireSuperuserAuth()

// Require the request client to be authenticated as superuser OR
// regular auth record with id matching the specified route parameter (default to "id").
// Example: Route.Bind(apis.RequireSuperuserOrOwnerAuth(""))
apis.RequireSuperuserOrOwnerAuth(ownerIdParam)

// Changes the global 32MB default request body size limit (set it to 0 for no limit).
// Note that system record routes have dynamic body size limit based on their collection field types.
// Example: Route.Bind(apis.BodyLimit(10 << 20))
apis.BodyLimit(limitBytes)

// Compresses the HTTP response using Gzip compression scheme.
// Example: Route.Bind(apis.Gzip())
apis.Gzip()

// Instructs the activity logger to log only requests that have failed/returned an error.
// Example: Route.Bind(apis.SkipSuccessActivityLog())
apis.SkipSuccessActivityLog()
```

### Default globally registered middlewares

The below list is mostly useful for users that may want to plug their own custom middlewares before/after
the priority of the default global ones, for example: registering a custom auth loader before the rate
limiter with `apis.DefaultRateLimitMiddlewarePriority - 1` so that the rate limit can be applied
properly based on the loaded auth state.

All PocketBase applications have the below internal middlewares registered out of the box (*sorted by their priority*):

- **WWW redirect**
  `apis.DefaultWWWRedirectMiddlewareId`
  `apis.DefaultWWWRedirectMiddlewarePriority`
  *Performs www -> non-www redirect(s) if the request host matches with one of the values in
  certificate host policy.*

- **CORS**
  `apis.DefaultCorsMiddlewareId`
  `apis.DefaultCorsMiddlewarePriority`
  *By default all origins are allowed (PocketBase is stateless and doesn't rely on cookies) and can
  be configured with the `--origins`
  flag but for more advanced customization it can be also replaced entirely by binding with
  `apis.CORS(config)` middleware or registering your own custom one in its place.*

- **Activity logger**
  `apis.DefaultActivityLoggerMiddlewareId`
  `apis.DefaultActivityLoggerMiddlewarePriority`
  *Saves request information into the logs auxiliary database.*

- **Auto panic recover**
  `apis.DefaultPanicRecoverMiddlewareId`
  `apis.DefaultPanicRecoverMiddlewarePriority`
  *Default panic-recover handler.*

- **Auth token loader**
  `apis.DefaultLoadAuthTokenMiddlewareId`
  `apis.DefaultLoadAuthTokenMiddlewarePriority`
  *Loads the auth token from the `Authorization` header and populates the related auth
  record into the request event (aka. `e.Auth`).*

- **Security response headers**
  `apis.DefaultSecurityHeadersMiddlewareId`
  `apis.DefaultSecurityHeadersMiddlewarePriority`
  *Adds default common security headers (`X-XSS-Protection`,
  `X-Content-Type-Options`,
  `X-Frame-Options`) to the response (can be overwritten by other middlewares or from
  inside the route action).*

- **Rate limit**
  `apis.DefaultRateLimitMiddlewareId`
  `apis.DefaultRateLimitMiddlewarePriority`
  *Rate limits client requests based on the configured app settings (it does nothing if the rate
  limit option is not enabled).*

- **Body limit**
  `apis.DefaultBodyLimitMiddlewareId`
  `apis.DefaultBodyLimitMiddlewarePriority`
  *Applies a default max ~32MB request body limit for all custom routes ( system record routes have
  dynamic body size limit based on their collection field types). Can be overwritten on group/route
  level by simply rebinding the `apis.BodyLimit(limitBytes)` middleware.*

## Error response

PocketBase has a global error handler and every returned error from a route or middleware will be safely
converted by default to a generic `ApiError` to avoid accidentally leaking sensitive
information (the original raw error message will be visible only in the *Dashboard > Logs* or when
in `--dev` mode).

To make it easier returning formatted JSON error responses, the request event provides several
`ApiError` methods.
Note that `ApiError.RawData()` will be returned in the response only if it is a map of
`router.SafeErrorItem`/`validation.Error` items.

```go
import validation "github.com/go-ozzo/ozzo-validation/v4"

se.Router.GET("/example", func(e *core.RequestEvent) error {
    ...

    // construct ApiError with custom status code and validation data error
    return e.Error(500, "something went wrong", map[string]validation.Error{
        "title": validation.NewError("invalid_title", "Invalid or missing title"),
    })

    // if message is empty string, a default one will be set
    return e.BadRequestError(optMessage, optData)      // 400 ApiError
    return e.UnauthorizedError(optMessage, optData)    // 401 ApiError
    return e.ForbiddenError(optMessage, optData)       // 403 ApiError
    return e.NotFoundError(optMessage, optData)        // 404 ApiError
    return e.TooManyRequestsError(optMessage, optData) // 429 ApiError
    return e.InternalServerError(optMessage, optData)  // 500 ApiError
})
```

This is not very common but if you want to return `ApiError` outside of request related
handlers, you can use the below
`apis.*` factories:

```go
import (
    validation "github.com/go-ozzo/ozzo-validation/v4"
    "github.com/pocketbase/pocketbase/apis"
)


app.OnRecordCreate().BindFunc(func(e *core.RecordEvent) error {
    ...

    // construct ApiError with custom status code and validation data error
    return apis.NewApiError(500, "something went wrong", map[string]validation.Error{
        "title": validation.NewError("invalid_title", "Invalid or missing title"),
    })

    // if message is empty string, a default one will be set
    return apis.NewBadRequestError(optMessage, optData)      // 400 ApiError
    return apis.NewUnauthorizedError(optMessage, optData)    // 401 ApiError
    return apis.NewForbiddenError(optMessage, optData)       // 403 ApiError
    return apis.NewNotFoundError(optMessage, optData)        // 404 ApiError
    return apis.NewTooManyRequestsError(optMessage, optData) // 429 ApiError
    return apis.NewInternalServerError(optMessage, optData)  // 500 ApiError
})
```

## Helpers

### Serving static directory

[`apis.Static()`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#Static)
serves static directory content from `fs.FS` instance.

Expects the route to have a `{path...}` wildcard parameter.

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // serves static files from the provided dir (if exists)
    se.Router.GET("/{path...}", apis.Static(os.DirFS("/path/to/public"), false))

    return se.Next()
})
```

### Auth response

[`apis.RecordAuthResponse()`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#RecordAuthResponse)
writes standardized JSON record auth response (aka. token + record data) into the specified request body.
Could be used as a return result from a custom auth route.

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    se.Router.POST("/phone-login", func(e *core.RequestEvent) error {
        data := struct {
            Phone    string `json:"phone" form:"phone"`
            Password string `json:"password" form:"password"`
        }{}
        if err := e.BindBody(&data); err != nil {
            return e.BadRequestError("Failed to read request data", err)
        }

        record, err := e.App.FindFirstRecordByData("users", "phone", data.Phone)
        if err != nil || !record.ValidatePassword(data.Password) {
            // return generic 400 error as a basic enumeration protection
            return e.BadRequestError("Invalid credentials", err)
        }

        return apis.RecordAuthResponse(e, record, "phone", nil)
    })

    return se.Next()
})
```

### Enrich record(s)

[`apis.EnrichRecord()`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#EnrichRecord)
and
[`apis.EnrichRecords()`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#EnrichRecords)
helpers parses the request context and enrich the provided record(s) by:

- expands relations (if `defaultExpands` and/or `?expand` query parameter is set)
- ensures that the emails of the auth record and its expanded auth relations are visible only for the
  current logged superuser, record owner or record with manage access

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    se.Router.GET("/custom-article", func(e *core.RequestEvent) error {
        records, err := e.App.FindRecordsByFilter("article", "status = 'active'", "-created", 40, 0)
        if err != nil {
            return e.NotFoundError("No active articles", err)
        }

        // enrich the records with the "categories" relation as default expand
        err = apis.EnrichRecords(e, records, "categories")
        if err != nil {
            return err
        }

        return e.JSON(http.StatusOK, records)
    })

    return se.Next()
})
```

### Go http.Handler wrappers

If you want to register standard Go `http.Handler` function and middlewares, you can use
[`apis.WrapStdHandler(handler)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#WrapStdHandler)
and
[`apis.WrapStdMiddleware(func)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/apis#WrapStdMiddleware)
functions.

## Sending request to custom routes using the SDKs

The official PocketBase SDKs expose the internal `send()` method that could be used to send requests
to your custom route(s).

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

await pb.send("/hello", {
    // for other options check
    // https://developer.mozilla.org/en-US/docs/Web/API/fetch#options
    query: { "abc": 123 },
});
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

await pb.send("/hello", query: { "abc": 123 })
```
