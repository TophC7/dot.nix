# Realtime API

The Realtime API is implemented via Server-Sent Events (SSE). Generally, it consists of 2 operations:

1. establish SSE connection
2. submit client subscriptions

SSE events are sent for **create**, **update** and **delete** record operations.

> **Note:**
>
> **You could subscribe to a single record or to an entire collection.**
>
> When you subscribe to a **single record**, the collection's **ViewRule** will be used to determine whether the subscriber has access to receive the event message.
>
> When you subscribe to an **entire collection**, the collection's **ListRule** will be used to determine whether the subscriber has access to receive the event message.

---

### Connect

> **GET** `/api/realtime`

Establishes a new SSE connection and immediately sends a `PB_CONNECT` SSE event with the created client ID.

**NB!** The user/superuser authorization happens during the first [Set subscriptions](#set-subscriptions) call.

If the connected client doesn't receive any new messages for 5 minutes, the server will send a disconnect signal (this is to prevent forgotten/leaked connections). The connection will be automatically reestablished if the client is still active (e.g. the browser tab is still open).

### Set subscriptions

> **POST** `/api/realtime`

Sets new active client's subscriptions (and auto unsubscribes from the previous ones).

If `Authorization` header is set, will authorize the client SSE connection with the associated user or superuser.

#### Body Parameters

| Param | Type | Description |
| --- | --- | --- |
| **Required** clientId | String | ID of the SSE client connection. |
| **Optional** subscriptions | Array\<String\> | The new client subscriptions to set in the format: `COLLECTION_ID_OR_NAME/*` or `COLLECTION_ID_OR_NAME/RECORD_ID`. You can also attach optional query and header parameters as serialized json to a single topic using the `options` query parameter, e.g.: `COLLECTION_ID_OR_NAME/RECORD_ID?options={"query": {"abc": "123"}, "headers": {"x-token": "..."}}` Leave empty to unsubscribe from everything. |

Body parameters could be sent as *JSON* or *multipart/form-data*.

#### Responses

**204**

```
(empty response)
```

**400**

```json
{
  "status": 400,
  "message": "Something went wrong while processing your request.",
  "data": {
    "clientId": {
      "code": "validation_required",
      "message": "Missing required value."
    }
  }
}
```

**403**

```json
{
  "status": 403,
  "message": "The current and the previous request authorization don't match.",
  "data": {}
}
```

**404**

```json
{
  "status": 404,
  "message": "Missing or invalid client id.",
  "data": {}
}
```

---

**All of this is seamlessly handled by the SDKs using just the `subscribe` and `unsubscribe` methods:**

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

// (Optionally) authenticate
await pb.collection('users').authWithPassword('test@example.com', '1234567890');

// Subscribe to changes in any record in the collection
pb.collection('example').subscribe('*', function (e) {
    console.log(e.action);
    console.log(e.record);
}, { /* other options like expand, custom headers, etc. */ });


// Subscribe to changes only in the specified record
pb.collection('example').subscribe('RECORD_ID', function (e) {
    console.log(e.action);
    console.log(e.record);
}, { /* other options like expand, custom headers, etc. */ });


// Unsubscribe
pb.collection('example').unsubscribe('RECORD_ID'); // remove all 'RECORD_ID' subscriptions
pb.collection('example').unsubscribe('*'); // remove all '*' topic subscriptions
pb.collection('example').unsubscribe(); // remove all subscriptions in the collection
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

// (Optionally) authenticate
await pb.collection('users').authWithPassword('test@example.com', '1234567890');

// Subscribe to changes in any record in the collection
pb.collection('example').subscribe('*', (e) {
    print(e.action);
    print(e.record);
}, /* other options like expand, custom headers, etc. */);


// Subscribe to changes only in the specified record
pb.collection('example').subscribe('RECORD_ID', (e) {
    print(e.action);
    print(e.record);
}, /* other options like expand, custom headers, etc. */);


// Unsubscribe
pb.collection('example').unsubscribe('RECORD_ID'); // remove all 'RECORD_ID' subscriptions
pb.collection('example').unsubscribe('*'); // remove all '*' topic subscriptions
pb.collection('example').unsubscribe(); // remove all subscriptions in the collection
```
