# Working with Relations

## Overview

Let's assume that we have the following collections structure:

![Collections relation diagram](/images/screenshots/relations-diagram.png)

- **posts** collection with `title` text field and `tags` multiple relation field pointing to **tags** collection.
- **tags** collection with `name` text field.
- **comments** collection with `post` single relation field pointing to **posts**, `user` single relation field pointing to **users**, and `message` text field.
- **users** auth collection with `name` text field.

## Setting relations

When creating or updating a record you can set relation field values to one or more record IDs from the related collection.

**JavaScript:**
```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

// create a post with tags
const post = await pb.collection('posts').create({
    title: 'Lorem ipsum...',
    tags: ['TAG_ID1', 'TAG_ID2', '...'],
})
```

**Dart:**
```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

// create a post with tags
final post = await pb.collection('posts').create(body: {
    'title': 'Lorem ipsum...',
    'tags': ['TAG_ID1', 'TAG_ID2', '...'],
})
```

If your relation field supports multiple values (aka. **Max Select option is >= 2**) you can use the `+` prefix/suffix field name modifier to respectively prepend/append new ids alongside the already existing ones. For example:

**JavaScript:**
```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const post = await pb.collection('posts').update('POST_ID', {
    // append
    'tags+': ['TAG_ID3', 'TAG_ID4'],

    // prepend
    '+tags': ['TAG_ID3', 'TAG_ID4'],
})
```

**Dart:**
```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final post = await pb.collection('posts').update('POST_ID', body: {
    // append
    'tags+': ['TAG_ID3', 'TAG_ID4'],

    // prepend
    '+tags': ['TAG_ID3', 'TAG_ID4'],
})
```

## Removing relations

To remove relation(s), you can use the `-` field name suffix modifier. For example:

**JavaScript:**
```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

...

const post = await pb.collection('posts').update('POST_ID', {
    // remove single tag
    'tags-': 'TAG_ID1',

    // remove multiple tags at once
    'tags-': ['TAG_ID1', 'TAG_ID2'],
})
```

**Dart:**
```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

...

final post = await pb.collection('posts').update('POST_ID', body: {
    // remove single tag
    'tags-': 'TAG_ID1',

    // remove multiple tags at once
    'tags-': ['TAG_ID1', 'TAG_ID2'],
})
```

## Expanding relations

You can also expand record relation fields directly in the returned response without making additional requests by using the `expand` query parameter, e.g. `?expand=user,post.tags`

> **ℹ️ Note:** Only the relations that the request client can **View** (aka. satisfies the relation collection's **View API Rule**) will be expanded.
>
> Nested relation references in `expand`, `filter` or `sort` are supported via dot-notation and up to 6-levels depth.

For example, to list all **comments** with their **user** relation expanded, we can do the following:

**JavaScript:**
```javascript
await pb.collection("comments").getList(1, 30, { expand: "user" })
```

**Dart:**
```dart
await pb.collection("comments").getList(perPage: 30, expand: "user")
```

```json
{
    "page": 1,
    "perPage": 30,
    "totalPages": 1,
    "totalItems": 20,
    "items": [
        {
            "id": "lmPJt4Z9CkLW36z",
            "collectionId": "BHKW36mJl3ZPt6z",
            "collectionName": "comments",
            "created": "2022-01-01 01:00:00.456Z",
            "updated": "2022-01-01 02:15:00.456Z",
            "post": "WyAw4bDrvws6gGl",
            "user": "FtHAW9feB5rze7D",
            "message": "Example message...",
            "expand": {
                "user": {
                    "id": "FtHAW9feB5rze7D",
                    "collectionId": "srmAo0hLxEqYF7F",
                    "collectionName": "users",
                    "created": "2022-01-01 00:00:00.000Z",
                    "updated": "2022-01-01 00:00:00.000Z",
                    "username": "users54126",
                    "verified": false,
                    "emailVisibility": false,
                    "name": "John Doe"
                }
            }
        },
        ...
    ]
}
```

### Back-relations

PocketBase supports also `filter`, `sort` and `expand` for **back-relations** - relations where the associated `relation` field is not in the main collection.

The following notation is used: `referenceCollection_via_relField` (ex. `comments_via_post`).

For example, let's list the **posts** that have at least one **comments** record containing the word *"hello"*:

**JavaScript:**
```javascript
await pb.collection("posts").getList(1, 30, {
    filter: "comments_via_post.message ?~ 'hello'"
    expand: "comments_via_post.user",
})
```

**Dart:**
```dart
await pb.collection("posts").getList(
    perPage: 30,
    filter: "comments_via_post.message ?~ 'hello'"
    expand: "comments_via_post.user",
)
```

```json
{
    "page": 1,
    "perPage": 30,
    "totalPages": 2,
    "totalItems": 45,
    "items": [
        {
            "id": "WyAw4bDrvws6gGl",
            "collectionId": "1rAwHJatkTNCUIN",
            "collectionName": "posts",
            "created": "2022-01-01 01:00:00.456Z",
            "updated": "2022-01-01 02:15:00.456Z",
            "title": "Lorem ipsum dolor sit...",
            "expand": {
                "comments_via_post": [
                    {
                        "id": "lmPJt4Z9CkLW36z",
                        "collectionId": "BHKW36mJl3ZPt6z",
                        "collectionName": "comments",
                        "created": "2022-01-01 01:00:00.456Z",
                        "updated": "2022-01-01 02:15:00.456Z",
                        "post": "WyAw4bDrvws6gGl",
                        "user": "FtHAW9feB5rze7D",
                        "message": "lorem ipsum...",
                        "expand": {
                            "user": {
                                "id": "FtHAW9feB5rze7D",
                                "collectionId": "srmAo0hLxEqYF7F",
                                "collectionName": "users",
                                "created": "2022-01-01 00:00:00.000Z",
                                "updated": "2022-01-01 00:00:00.000Z",
                                "username": "users54126",
                                "verified": false,
                                "emailVisibility": false,
                                "name": "John Doe"
                            }
                        }
                    },
                    {
                        "id": "tu4Z9CkLW36mPJz",
                        "collectionId": "BHKW36mJl3ZPt6z",
                        "collectionName": "comments",
                        "created": "2022-01-01 01:10:00.123Z",
                        "updated": "2022-01-01 02:39:00.456Z",
                        "post": "WyAw4bDrvws6gGl",
                        "user": "FtHAW9feB5rze7D",
                        "message": "hello...",
                        "expand": {
                            "user": {
                                "id": "FtHAW9feB5rze7D",
                                "collectionId": "srmAo0hLxEqYF7F",
                                "collectionName": "users",
                                "created": "2022-01-01 00:00:00.000Z",
                                "updated": "2022-01-01 00:00:00.000Z",
                                "username": "users54126",
                                "verified": false,
                                "emailVisibility": false,
                                "name": "John Doe"
                            }
                        }
                    },
                    ...
                ]
            }
        },
        ...
    ]
}
```

#### Back-relation caveats

> **ℹ️ Note:**
> - By default the back-relation reference is resolved as a dynamic *multiple* relation field, even when the back-relation field itself is marked as *single*.
>   This is because the main record could have more than one *single* back-relation reference (see in the above example that the `comments_via_post` expand is returned as array, although the original `comments.post` field is a *single* relation).
>   The only case where the back-relation will be treated as a *single* relation field is when there is `UNIQUE` index constraint defined on the relation field.
> - Back-relation `expand` is limited to max 1000 records per relation field. If you need to fetch larger number of back-related records a better approach could be to send a separate paginated `getList()` request to the back-related collection to avoid transferring large JSON payloads and to reduce the memory usage.
