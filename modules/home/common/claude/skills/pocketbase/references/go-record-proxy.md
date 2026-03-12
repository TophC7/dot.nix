The available [`core.Record` and its helpers](/docs/go-records)
are usually the recommended way to interact with your data, but in case you want a typed access to your record
fields you can create a helper struct that embeds
[`core.BaseRecordProxy`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseRecordProxy)
*(which implements the `core.RecordProxy` interface)* and define your collection fields as
getters and setters.

By implementing the `core.RecordProxy` interface you can use your custom struct as part of a
`RecordQuery` result like a regular record model. In addition, every DB change through the proxy
struct will trigger the corresponding record validations and hooks. This ensures that other parts of your app,
including 3rd party plugins, that don't know or use your custom struct will still work as expected.

Below is a sample `Article` record proxy implementation:

```go
// article.go
package main

import (
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/types"
)

// ensures that the Article struct satisfy the core.RecordProxy interface
var _ core.RecordProxy = (*Article)(nil)

type Article struct {
    core.BaseRecordProxy
}

func (a *Article) Title() string {
    return a.GetString("title")
}

func (a *Article) SetTitle(title string) {
    a.Set("title", title)
}

func (a *Article) Slug() string {
    return a.GetString("slug")
}

func (a *Article) SetSlug(slug string) {
    a.Set("slug", slug)
}

func (a *Article) Created() types.DateTime {
    return a.GetDateTime("created")
}

func (a *Article) Updated() types.DateTime {
    return a.GetDateTime("updated")
}
```

Accessing and modifying the proxy records is the same as for the regular records. Continuing with the
above `Article` example:

```go
func FindArticleBySlug(app core.App, slug string) (*Article, error) {
    article := &Article{}

    err := app.RecordQuery("articles").
        AndWhere(dbx.NewExp("LOWER(slug)={:slug}", dbx.Params{
            "slug": strings.ToLower(slug), // case insensitive match
        })).
        Limit(1).
        One(article)

    if err != nil {
        return nil, err
    }

    return article, nil
}

...

article, err := FindArticleBySlug(app, "example")
if err != nil {
    return err
}

// change the title
article.SetTitle("Lorem ipsum...")

// persist the change while also triggering the original record validations and hooks
err = app.Save(article)
if err != nil {
    return err
}
```

If you have an existing `*core.Record` value you can also load it into your proxy using the
`SetProxyRecord` method:

```go
// fetch regular record
record, err := app.FindRecordById("articles", "RECORD_ID")
if err != nil {
    return err
}

// load into proxy
article := &Article{}
article.SetProxyRecord(record)
```
