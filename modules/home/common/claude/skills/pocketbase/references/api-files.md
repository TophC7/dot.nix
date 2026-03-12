# API - Files

Files are uploaded, updated or deleted via the [Records API](/docs/api-records).

The File API is usually used to fetch/download a file resource (with support for basic image manipulations, like generating thumbs).

---

## Download / Fetch file

Downloads a single file resource (aka. the URL address to the file). Example:

```html
<img src="http://example.com/api/files/demo/1234abcd/test.png" alt="Test image" />
```

### API details

> **GET** `/api/files/collectionIdOrName/recordId/filename`

### Path parameters

| Param | Type | Description |
|-------|------|-------------|
| collectionIdOrName | String | ID or name of the collection whose record model contains the file resource. |
| recordId | String | ID of the record model that contains the file resource. |
| filename | String | Name of the file resource. |

### Query parameters

| Param | Type | Description |
|-------|------|-------------|
| thumb | String | Get the thumb of the requested file. The following thumb formats are supported: **WxH** (e.g. 100x300) - crop to WxH viewbox (from center), **WxHt** (e.g. 100x300t) - crop to WxH viewbox (from top), **WxHb** (e.g. 100x300b) - crop to WxH viewbox (from bottom), **0xH** (e.g. 0x300) - resize to H height preserving the aspect ratio, **Wx0** (e.g. 100x0) - resize to W width preserving the aspect ratio. If the thumb size is not defined in the file schema field options or the file resource is not an image (jpg, png, gif, webp), then the original file resource is returned unmodified. |
| token | String | Optional **file token** for granting access to **protected file(s)**. For an example, you can check ["Files upload and handling"](/docs/files-handling/#protected-files). |
| download | Boolean | If it is set to a truthy value (*1*, *t*, *true*) the file will be served with `Content-Disposition: attachment` header instructing the browser to ignore the file preview for pdf, images, videos, etc. and to directly download the file. |

### Responses

**200**
```
[file resource]
```

**400**
```json
{
  "status": 400,
  "message": "Filesystem initialization failure.",
  "data": {}
}
```

**404**
```json
{
  "status": 404,
  "message": "The requested resource wasn't found.",
  "data": {}
}
```

---

## Generate protected file token

Generates a **short-lived file token** for accessing **protected file(s)**.

The client must be superuser or auth record authenticated (aka. have regular authorization token sent with the request).

### API details

> **POST** `/api/files/token`
>
> Requires `Authorization:TOKEN`

### Responses

**200**
```json
{
    "token": "..."
}
```

**400**
```json
{
  "status": 400,
  "message": "Failed to generate file token.",
  "data": {}
}
```
