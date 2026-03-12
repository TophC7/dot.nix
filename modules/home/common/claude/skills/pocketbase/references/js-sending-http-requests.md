# Sending HTTP Requests

## Overview

You can use the global `$http.send(config)` helper to send HTTP requests to external services.

This could be used for example to retrieve data from external data sources, to make custom requests to a payment
provider API, etc.

Below is a list with all currently supported config options and their defaults.

```javascript
// throws on timeout or network connectivity error
const res = $http.send({
    url:     "",
    method:  "GET",
    body:    "", // ex. JSON.stringify({"test": 123}) or new FormData()
    headers: {}, // ex. {"content-type": "application/json"}
    timeout: 120, // in seconds
})

console.log(res.headers)    // the response headers (ex. res.headers['X-Custom'][0])
console.log(res.cookies)    // the response cookies (ex. res.cookies.sessionId.value)
console.log(res.statusCode) // the response HTTP status code
console.log(res.body)       // the response body as plain bytes array
console.log(res.json)       // the response body as parsed json array or map
```

Here is an example that will enrich a single book record with some data based on its ISBN details from
openlibrary.org.

```javascript
onRecordCreateRequest((e) => {
    let isbn = e.record.get("isbn");

    // try to update with the published date from the openlibrary API
    try {
        const res = $http.send({
            url: "https://openlibrary.org/isbn/" + isbn + ".json",
            headers: {"content-type": "application/json"}
        })

        if (res.statusCode == 200) {
            e.record.set("published", res.json.publish_date)
        }
    } catch (err) {
        e.app.logger().error("Failed to retrieve book data", "error", err);
    }

    return e.next()
}, "books")
```

### multipart/form-data requests

In order to send `multipart/form-data` requests (ex. uploading files) the request
`body` must be a `FormData` instance.

PocketBase JSVM's `FormData` has the same APIs as its
[browser equivalent](https://developer.mozilla.org/en-US/docs/Web/API/FormData)
with the main difference that for file values instead of `Blob` it accepts
[`$filesystem.File`](/jsvm/modules/_filesystem.html).

```javascript
const formData = new FormData();

formData.append("title", "Hello world!")
formData.append("documents", $filesystem.fileFromBytes("doc1", "doc1.txt"))
formData.append("documents", $filesystem.fileFromBytes("doc2", "doc2.txt"))

const res = $http.send({
    url:    "https://...",
    method: "POST",
    body:   formData,
})

console.log(res.statusCode)
```

## Limitations

As of now there is no support for streamed responses or server-sent events (SSE). The
`$http.send` call blocks and returns the entire response body at once.

For this and other more advanced use cases you'll have to
[extend PocketBase with Go](/docs/go-overview/).
