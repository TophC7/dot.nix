# Realtime

By default PocketBase sends realtime events only for Record create/update/delete operations (*and for the OAuth2 auth redirect*), but you are free to send custom realtime messages to the connected clients via the [`$app.subscriptionsBroker()`](/jsvm/functions/_app.subscriptionsBroker.html) instance.

[`$app.subscriptionsBroker().clients()`](/jsvm/interfaces/subscriptions.Broker.html#clients) returns all connected [`subscriptions.Client`](/jsvm/interfaces/subscriptions.Client.html) indexed by their unique connection id.

The current auth record associated with a client could be accessed through `client.get("auth")`

> ℹ️ Note that a single authenticated user could have more than one active realtime connection (aka. multiple clients). This could happen for example when opening the same app in different tabs, browsers, devices, etc.

Below you can find a minimal code sample that sends a JSON payload to all clients subscribed to the "example" topic:

```javascript
const message = new SubscriptionMessage({
    name: "example",
    data: JSON.stringify({ ... }),
});

// retrieve all clients (clients id indexed map)
const clients = $app.subscriptionsBroker().clients()

for (let clientId in clients) {
    if (clients[clientId].hasSubscription("example")) {
        clients[clientId].send(message)
    }
}
```

From the client-side, users can listen to the custom subscription topic by doing something like:

**JavaScript:**

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

await pb.realtime.subscribe('example', (e) => {
    console.log(e)
})
```

**Dart:**

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

await pb.realtime.subscribe('example', (e) {
    print(e)
})
```
