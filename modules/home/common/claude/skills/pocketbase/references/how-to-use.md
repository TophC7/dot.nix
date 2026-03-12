# How to use

The easiest way to use PocketBase is by interacting with its Web APIs directly from the client-side (e.g. mobile app or browser SPA).

It was designed with this exact use case in mind and it is also the reason why there are general purpose JSON APIs for listing, pagination, sorting, filtering, etc.

The access and filter controls for your data are usually done through the [collection API rules](/docs/api-rules-and-filters/).

For the cases when you need more specialized handling (sending emails, intercepting the default actions, creating new routes, etc.) you can [extend PocketBase with Go or JavaScript](/docs/use-as-framework/).

For interacting with the [Web APIs](/docs/api-records/) you can make use of the official SDK clients:

- **[JavaScript SDK](https://github.com/pocketbase/js-sdk)** (Browser, Node.js, React Native)
- **[Dart SDK](https://github.com/pocketbase/dart-sdk)** (Web, Mobile, Desktop, CLI)

> When used on the client-side, it is safe to have a single/global SDK instance for the entire lifecycle of your application.

---

## Web apps recommendation

Not everyone will agree with this, but if you are building a web app with PocketBase I recommend developing the frontend as a **traditional client-side SPA** and for the cases where additional server-side handling is needed (e.g. for payment webhooks, extra data server validations, etc.) you could try to:

- [Use PocketBase as Go/JS framework](/docs/use-as-framework) to create new routes or intercept existing.
- Create one-off Node.js/Bun/Deno/etc. server-side actions that will interact with PocketBase only as superuser and as pure data store (similar to traditional database interactions but over HTTP). In this case it is safe to have a global superuser client such as:

```javascript
// src/superuser.js
import PocketBase from "pocketbase"

const superuserClient = new PocketBase('https://example.com');

// disable autocancellation so that we can handle async requests from multiple users
superuserClient.autoCancellation(false);

// option 1: authenticate as superuser using email/password (could be filled with ENV params)
await superuserClient.collection('_superusers').authWithPassword(SUPERUSER_EMAIL, SUPERUSER_PASS, {
  // This will trigger auto refresh or auto reauthentication in case
  // the token has expired or is going to expire in the next 30 minutes.
  autoRefreshThreshold: 30 * 60
})

// option 2: OR authenticate as superuser via long-lived "API key"
// (see https://pocketbase.io/docs/authentication/#api-keys)
superuserClient.authStore.save('YOUR_GENERATED_SUPERUSER_TOKEN')

export default superuserClient;
```

Then you can directly import the file in your server-side actions and use the client as usual:

```javascript
import superuserClient from './src/superuser.js'

async function serverAction(req, resp) {
  ... do some extra data validations or handling ...

  // send a create request as superuser
  await superuserClient.collection('example').create({ ... })
}
```

---

## Why not JS SSR

Using PocketBase with meta framework such as SvelteKit, Nuxt, Next.js, etc. **in a JS SSR mode** is possible but it comes with many complications and you need to carefully evaluate whether the cost of having another backend (PocketBase) alongside your existing one (the Node.js server) is worth it.

You can read more about the potential problems in [JS SSR - issues and recommendations #5313](https://github.com/pocketbase/pocketbase/discussions/5313) but some of the common pitfalls are:

- Security issues caused by incorrectly initialized and shared JS SDK instance in a long-running server-side context.
- OAuth2 integration difficulties related to the server-side only OAuth2 flow (or its mixed "all-in-one" client-side handling and sharing a cookie with the server-side).
- Proxying realtime connections and essentially duplicating the same thing PocketBase already does.
- Performance bottlenecks caused by the default single-threaded Node.js process and the excessive resources utilization due to the server-side rendering and heavy back-and-forth requests communication between the different layers (`client<->Node.js<->PocketBase`).

This doesn't mean that using PocketBase with JS SSR is always a "bad thing" but based on the dozens reported issues so far I would recommend it only after careful evaluation and only to more experienced developers that have in-depth understanding of the used tools and their trade-offs. If you still want to use PocketBase to handle regular users authentication with a JS SSR meta framework, then you can find some JS SDK examples in the repo's [JS SSR integration section](https://github.com/pocketbase/js-sdk#ssr-integration).

---

## Why not htmx, Hotwire/Turbo, Unpoly, etc.

htmx, Hotwire/Turbo, Unpoly and other similar tools are commonly used for building server rendered applications but unfortunately they don't play well with the JSON APIs and fully stateless nature of PocketBase.

It is possible to use them with PocketBase but at the moment I don't recommend it because we lack the necessary helpers and utilities for building SSR-first applications, which means that you might have to create from scratch a lot of things on your own such as middlewares for handling cookies (*and eventually also taking care of CORS and CSRF*) or custom authentication endpoints and access controls (*the collection API rules apply only for the builtin JSON routes*).

In the future we could eventually provide official SSR support in terms of guides and middlewares for this use case but again - PocketBase wasn't designed with this in mind and you may want to reevaluate the tech stack of your application and switch to a traditional client-side SPA as mentioned earlier or use a different backend solution that might fit better with your use case.

---

## Mobile apps auth persistence

When building mobile apps with the JavaScript SDK or Dart SDK you'll have to specify a custom persistence store if you want to preserve the authentication between the various app activities and open/close state.

The SDKs come with a helper async storage implementation that allows you to hook any custom persistent layer (local file, SharedPreferences, key-value based database, etc.). Here is a minimal PocketBase SDKs initialization for React Native (JavaScript) and Flutter (Dart):

**JavaScript:**
```javascript
// Node.js and React Native doesn't have native EventSource implementation
// so in order to use the realtime subscriptions you'll need to load EventSource polyfill,
// for example: npm install react-native-sse --save
import eventsource from 'react-native-sse';

import AsyncStorage from '@react-native-async-storage/async-storage';

import PocketBase, { AsyncAuthStore } from 'pocketbase';

// load the polyfill
global.EventSource = eventsource;

// initialize the async store
const store = new AsyncAuthStore({
    save:    async (serialized) => AsyncStorage.setItem('pb_auth', serialized),
    initial: AsyncStorage.getItem('pb_auth'),
});

// initialize the PocketBase client
// (it is OK to have a single/global instance for the duration of your application)
const pb = new PocketBase('http://127.0.0.1:8090', store);

...

await pb.collection('users').authWithPassword('test@example.com', '1234567890');

console.log(pb.authStore.record)
```

**Dart:**
```dart
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// for simplicity we are using a simple SharedPreferences instance
// but you can also replace it with its safer EncryptedSharedPreferences alternative
final prefs = await SharedPreferences.getInstance();

// initialize the async store
final store = AsyncAuthStore(
 save:    (String data) async => prefs.setString('pb_auth', data),
 initial: prefs.getString('pb_auth'),
);

// initialize the PocketBase client
// (it is OK to have a single/global instance for the duration of your application)
final pb = PocketBase('http://127.0.0.1:8090', authStore: store);

...

await pb.collection('users').authWithPassword('test@example.com', '1234567890');

print(pb.authStore.record);
```

---

## React Native file upload on Android and iOS

At the time of writing, React Native on Android and iOS seems to have a non-standard `FormData` implementation and for uploading files on these platforms it requires the following special object syntax:

```javascript
{
  uri: "...",
  type: "...",
  name: "..."
}
```

Or in other words, you may have to apply a conditional handling similar to:

```javascript
const data = new FormData();

// result is the resolved promise of ImagePicker.launchImageLibraryAsync
let imageUri = result.assets[0].uri;

if (Platform.OS === 'web') {
  const req = await fetch(imageUri);
  const blob = await req.blob();
  data.append('avatar', blob); // regular File/Blob value
} else {
  // the below object format works only on Android and iOS
  // (FormData.set() also doesn't seem to be supported so we use FormData.append())
  data.append('avatar', {
    uri:  imageUri,
    type: 'image/*',
    name: imageUri.split('/').pop(),
  });
}

...

await pb.collection('example').create(data)
```

---

The next couple pages have a little bit more information about the basic PocketBase components like collections, records, authentication, relations, files handling, etc.
