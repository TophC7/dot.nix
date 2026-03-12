# Testing

PocketBase exposes several test mocks and stubs (eg. `tests.TestApp`,
`tests.ApiScenario`, `tests.MockMultipartData`, etc.) to help you write unit and
integration tests for your app.

You could find more information in the
[`github.com/pocketbase/pocketbase/tests`](https://pkg.go.dev/github.com/pocketbase/pocketbase/tests)
sub package, but here is a simple example.

## 1. Setup

Let's say that we have a custom API route `GET /my/hello` that requires superuser authentication:

```go
// main.go
package main

import (
    "log"
    "net/http"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
)

func bindAppHooks(app core.App) {
    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        se.Router.Get("/my/hello", func(e *core.RequestEvent) error {
            return e.JSON(http.StatusOK, "Hello world!")
        }).Bind(apis.RequireSuperuserAuth())

        return se.Next()
    })
}

func main() {
    app := pocketbase.New()

    bindAppHooks(app)

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

## 2. Prepare test data

Now we have to prepare our test/mock data. There are several ways you can approach this, but the easiest
one would be to start your application with a custom `test_pb_data` directory, e.g.:

```
./pocketbase serve --dir="./test_pb_data" --automigrate=0
```

Go to your browser and create the test data via the Dashboard (both collections and records). Once
completed you can stop the server (you could also commit `test_pb_data` to your repo).

## 3. Integration test

To test the example endpoint, we want to:

- ensure it handles only GET requests
- ensure that it can be accessed only by superusers
- check if the response body is properly set

Below is a simple integration test for the above test cases. We'll also use the test data created in the
previous step.

```go
// main_test.go
package main

import (
    "net/http"
    "testing"

    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tests"
)

const testDataDir = "./test_pb_data"

func generateToken(collectionNameOrId string, email string) (string, error) {
    app, err := tests.NewTestApp(testDataDir)
    if err != nil {
        return "", err
    }
    defer app.Cleanup()

    record, err := app.FindAuthRecordByEmail(collectionNameOrId, email)
    if err != nil {
        return "", err
    }

    return record.NewAuthToken()
}

func TestHelloEndpoint(t *testing.T) {
    recordToken, err := generateToken("users", "test@example.com")
    if err != nil {
        t.Fatal(err)
    }

    superuserToken, err := generateToken(core.CollectionNameSuperusers, "test@example.com")
    if err != nil {
        t.Fatal(err)
    }

    // set up the test ApiScenario app instance
    setupTestApp := func(t testing.TB) *tests.TestApp {
        testApp, err := tests.NewTestApp(testDataDir)
        if err != nil {
            t.Fatal(err)
        }
        // no need to cleanup since scenario.Test() will do that for us
        // defer testApp.Cleanup()

        bindAppHooks(testApp)

        return testApp
    }

    scenarios := []tests.ApiScenario{
        {
            Name:            "try with different http method, e.g. POST",
            Method:          http.MethodPost,
            URL:             "/my/hello",
            ExpectedStatus:  405,
            ExpectedContent: []string{"\"data\":{}"},
            TestAppFactory:  setupTestApp,
        },
        {
            Name:            "try as guest (aka. no Authorization header)",
            Method:          http.MethodGet,
            URL:             "/my/hello",
            ExpectedStatus:  401,
            ExpectedContent: []string{"\"data\":{}"},
            TestAppFactory:  setupTestApp,
        },
        {
            Name:   "try as authenticated app user",
            Method: http.MethodGet,
            URL:    "/my/hello",
            Headers: map[string]string{
                "Authorization": recordToken,
            },
            ExpectedStatus:  401,
            ExpectedContent: []string{"\"data\":{}"},
            TestAppFactory:  setupTestApp,
        },
        {
            Name:   "try as authenticated superuser",
            Method: http.MethodGet,
            URL:    "/my/hello",
            Headers: map[string]string{
                "Authorization": superuserToken,
            },
            ExpectedStatus:  200,
            ExpectedContent: []string{"Hello world!"},
            TestAppFactory:  setupTestApp,
        },
    }

    for _, scenario := range scenarios {
        scenario.Test(t)
    }
}
```
