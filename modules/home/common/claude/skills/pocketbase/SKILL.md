---
name: pocketbase
description: Comprehensive reference for PocketBase -- an open-source Go backend framework with an embedded SQLite database, realtime subscriptions, built-in authentication, file storage, and an admin dashboard. This skill covers the full REST API, JavaScript and Dart SDKs, Go framework extension, and operational concerns.
---

# PocketBase Documentation Skill

## When to Use This Skill

Activate this skill when the user request involves any of the following:

**Direct triggers:**

- Building or configuring a PocketBase backend
- Writing client code that talks to a PocketBase instance (JavaScript SDK, Dart SDK, or raw HTTP)
- Extending PocketBase with custom Go code (hooks, commands, routes, migrations)
- Managing PocketBase collections, records, authentication, files, or backups
- Deploying or operating a PocketBase instance in production
- Troubleshooting PocketBase API errors or SDK issues

**Keyword triggers:**

- "pocketbase", "pb.", "PocketBase", "pocket base"
- Collection names such as `_superusers`, `_externalAuths`, `_mfas`, `_otps`
- SDK methods such as `authWithPassword`, `authWithOAuth2`, `subscribe`, `getFullList`
- API paths containing `/api/collections`, `/api/records`, `/api/backups`, `/api/realtime`
- Go packages: `github.com/pocketbase/pocketbase`, `github.com/pocketbase/dbx`

**Do NOT use this skill for:**

- General Go programming unrelated to PocketBase
- Generic SQLite questions that do not involve PocketBase internals
- Other BaaS platforms (Firebase, Supabase, Appwrite)

---

## Key Concepts

### What is PocketBase?

PocketBase is a single-binary backend that bundles:

- An embedded SQLite database for data storage
- A REST API for CRUD operations on collections and records
- Realtime change notifications via Server-Sent Events (SSE)
- Built-in authentication (email/password, OAuth2, OTP)
- File upload and storage with configurable S3 or local filesystem
- An auto-generated admin dashboard
- A Go framework for extending with custom logic

It can be used as a standalone executable or imported as a Go package for deep
customization.

### Collections

Collections are the equivalent of database tables. Each collection defines a schema
of typed fields. There are three collection types:

- **Base** -- standard data collections with customizable fields
- **Auth** -- extends base with authentication fields (email, password, verified, etc.)
- **View** -- read-only collections backed by a SQL view query

Special system collections include `_superusers`, `_externalAuths`, `_mfas`, and
`_otps`.

### Records

Records are rows within a collection. Every record has system fields (`id`,
`created`, `updated`, `collectionId`, `collectionName`) plus any user-defined fields.
Records are managed through the Records API or the Go/JS app-level helpers.

### Authentication

PocketBase supports multiple auth methods configurable per auth collection:

- **Password authentication** -- email/username + password
- **OAuth2** -- third-party providers (Google, GitHub, Apple, etc.)
- **OTP** -- one-time password sent via email
- **Auth refresh** -- extend a valid token

Authentication is stateless and token-based. Tokens are JWTs and are never stored
server-side. "Logout" is simply discarding the token client-side
(`pb.authStore.clear()`).

Superusers (`_superusers` collection) bypass all API rules and can access everything.

### API Rules

Each collection has five configurable rules that control access:

- **listRule** -- who can list records
- **viewRule** -- who can view a single record
- **createRule** -- who can create records
- **updateRule** -- who can update records
- **deleteRule** -- who can delete records

Rules are filter expressions evaluated against `@request.auth`. Setting a rule to
`null` means only superusers can perform that action. An empty string `""` means
anyone can perform it.

### Realtime (SSE)

PocketBase uses Server-Sent Events for realtime subscriptions. Clients subscribe to
collection-level or record-level changes and receive events for `create`, `update`,
and `delete` actions. The collection's `listRule` determines access for subscribers.

### Files

Files are attached to records via file-type fields. Upload happens through the
Records API (create/update). Downloaded files are served at a predictable URL pattern.
A short-lived file token is required for protected files.

### Hooks and Events

When extending PocketBase with Go, you can bind to lifecycle events:

- **App hooks** -- `OnBootstrap`, `OnServe`, `OnTerminate`
- **Record hooks** -- `OnRecordCreate`, `OnRecordUpdate`, `OnRecordDelete`, etc.
- **Realtime hooks** -- `OnRealtimeConnect`, `OnRealtimeSubscribe`
- **Mail hooks** -- `OnMailerSend`, `OnRecordRequestVerification`

Hooks use `BindFunc` and must call `e.Next()` to continue the chain.

### Extending with Go

PocketBase can be imported as a Go framework. Common extension patterns:

- Adding custom CLI commands via Cobra
- Registering custom HTTP routes
- Binding to event hooks for business logic
- Running database migrations
- Executing raw SQL and transactions

### Backups

PocketBase supports creating, restoring, uploading, downloading, and deleting
backup ZIP files. All backup operations require superuser authorization.

---

## Quick Reference

### 1. JavaScript SDK -- Initialize and Authenticate

```javascript
import PocketBase from 'pocketbase'

const pb = new PocketBase('http://127.0.0.1:8090')

// Authenticate as superuser
await pb.collection('_superusers').authWithPassword('test@example.com', '1234567890')

// Authenticate as regular user
await pb.collection('users').authWithPassword('user@example.com', 'securepassword')
```

### 2. Dart SDK -- Initialize and Authenticate

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

// Authenticate as superuser
await pb.collection("_superusers").authWithPassword(
    'test@example.com',
    '1234567890',
);

// Authenticate as regular user
await pb.collection("users").authWithPassword(
    'user@example.com',
    'securepassword',
);
```

### 3. CRUD Operations (JavaScript SDK)

```javascript
// Create a record
const record = await pb.collection('posts').create({
  title: 'Hello World',
  body: 'This is my first post.'
})

// Read a single record
const post = await pb.collection('posts').getOne('RECORD_ID')

// List records with filtering
const results = await pb.collection('posts').getList(1, 20, {
  filter: 'status = "active"',
  sort: '-created'
})

// Update a record
await pb.collection('posts').update('RECORD_ID', {
  title: 'Updated Title'
})

// Delete a record
await pb.collection('posts').delete('RECORD_ID')
```

### 4. Realtime Subscriptions (JavaScript SDK)

```javascript
// Subscribe to all changes in a collection
pb.collection('example').subscribe('*', function (e) {
  console.log(e.action) // "create", "update", or "delete"
  console.log(e.record)
})

// Subscribe to a specific record
pb.collection('example').subscribe('RECORD_ID', function (e) {
  console.log(e.action)
  console.log(e.record)
})

// Unsubscribe from everything
pb.collection('example').unsubscribe()
```

### 5. Backup Operations (JavaScript SDK)

```javascript
// List all backups
const backups = await pb.backups.getFullList()

// Create a new backup
await pb.backups.create('my_backup.zip')

// Restore from backup
await pb.backups.restore('my_backup.zip')

// Delete a backup
await pb.backups.delete('my_backup.zip')

// Download a backup (requires file token)
const token = await pb.files.getToken()
const url = pb.backups.getDownloadUrl(token, 'my_backup.zip')
```

### 6. File Uploads (JavaScript SDK)

```javascript
// Upload files when creating a record
const record = await pb.collection('example').create({
  title: 'Hello world!',
  documents: [new File(['content 1...'], 'file1.txt'), new File(['content 2...'], 'file2.txt')]
})

// Get a file URL for display
const url = pb.files.getURL(record, record.documents[0])
```

### 7. Go -- Extending with Custom Commands

```go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/spf13/cobra"
)

func main() {
    app := pocketbase.New()

    app.RootCmd.AddCommand(&cobra.Command{
        Use: "hello",
        Run: func(cmd *cobra.Command, args []string) {
            log.Println("Hello world!")
        },
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### 8. Go -- Event Hooks

```go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/core"
)

func main() {
    app := pocketbase.New()

    app.OnBootstrap().BindFunc(func(e *core.BootstrapEvent) error {
        if err := e.Next(); err != nil {
            return err
        }
        // e.App is fully initialized here
        return nil
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### 9. Go -- SQL Transactions

```go
err := app.RunInTransaction(func(txApp core.App) error {
    // Find and update a record within a transaction
    record, err := txApp.FindRecordById("articles", "RECORD_ID")
    if err != nil {
        return err
    }

    record.Set("status", "active")
    if err := txApp.Save(record); err != nil {
        return err
    }

    // Raw query (does not fire event hooks)
    rawQuery := "DELETE FROM articles WHERE status = 'pending'"
    if _, err := txApp.DB().NewQuery(rawQuery).Execute(); err != nil {
        return err
    }

    return nil
})
```

### 10. Go -- Collection Queries with dbx

```go
import (
    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase/core"
)

func FindSystemCollections(app core.App) ([]*core.Collection, error) {
    collections := []*core.Collection{}

    err := app.CollectionQuery().
        AndWhere(dbx.HashExp{"system": true}).
        OrderBy("created DESC").
        All(&collections)

    if err != nil {
        return nil, err
    }

    return collections, nil
}
```

---

## API Reference

All API endpoints are served under the base URL of the PocketBase instance
(e.g., `http://127.0.0.1:8090`). Endpoints that require authorization expect an
`Authorization: TOKEN` header with a valid superuser or user auth token.

### Backups API

Manage server backup files. All backup endpoints require superuser authorization.

| Method | Endpoint                    | Description                     |
| ------ | --------------------------- | ------------------------------- |
| GET    | `/api/backups`              | List all available backup files |
| POST   | `/api/backups`              | Create a new backup             |
| POST   | `/api/backups/upload`       | Upload an existing backup file  |
| DELETE | `/api/backups/:key`         | Delete a backup by key          |
| POST   | `/api/backups/:key/restore` | Restore the app from a backup   |
| GET    | `/api/backups/:key`         | Download a backup file          |

**Notes:**

- The `create` endpoint accepts an optional `name` parameter in format `[a-z0-9_-].zip`
- Only one backup or restore operation can run at a time
- Body parameters can be sent as JSON or `multipart/form-data`

### Collections API

Manage collection schemas and configuration.

| Method | Endpoint                              | Description                           |
| ------ | ------------------------------------- | ------------------------------------- |
| GET    | `/api/collections`                    | List collections (paginated)          |
| GET    | `/api/collections/:idOrName`          | View a single collection              |
| POST   | `/api/collections`                    | Create a new collection               |
| PATCH  | `/api/collections/:idOrName`          | Update an existing collection         |
| DELETE | `/api/collections/:idOrName`          | Delete a collection                   |
| DELETE | `/api/collections/:idOrName/truncate` | Delete all records in a collection    |
| PUT    | `/api/collections/import`             | Bulk import collection configurations |
| GET    | `/api/collections/meta/scaffolds`     | Get collection type scaffolds         |

### Records API

Perform CRUD operations on collection records.

| Method | Endpoint                                       | Description                |
| ------ | ---------------------------------------------- | -------------------------- |
| GET    | `/api/collections/:idOrName/records`           | List records (paginated)   |
| GET    | `/api/collections/:idOrName/records/:recordId` | View a single record       |
| POST   | `/api/collections/:idOrName/records`           | Create a new record        |
| PATCH  | `/api/collections/:idOrName/records/:recordId` | Update a record            |
| DELETE | `/api/collections/:idOrName/records/:recordId` | Delete a record            |
| POST   | `/api/batch`                                   | Batch create/update/delete |

**Common query parameters:**

- `filter` -- filter expression (e.g., `status = "active" && created > "2024-01-01"`)
- `sort` -- comma-separated fields, prefix `-` for descending (e.g., `-created,title`)
- `expand` -- comma-separated relation fields to expand inline
- `fields` -- comma-separated fields to return (supports `:excerpt(maxLength)`)
- `page` and `perPage` -- pagination controls

### Auth API

Authentication endpoints for auth-type collections.

| Method | Endpoint                                            | Description                    |
| ------ | --------------------------------------------------- | ------------------------------ |
| GET    | `/api/collections/:idOrName/auth-methods`           | List available auth methods    |
| POST   | `/api/collections/:idOrName/auth-with-password`     | Authenticate with password     |
| POST   | `/api/collections/:idOrName/auth-with-oauth2`       | Authenticate with OAuth2       |
| POST   | `/api/collections/:idOrName/request-otp`            | Request a one-time password    |
| POST   | `/api/collections/:idOrName/auth-with-otp`          | Authenticate with OTP          |
| POST   | `/api/collections/:idOrName/auth-refresh`           | Refresh an auth token          |
| POST   | `/api/collections/:idOrName/request-verification`   | Request email verification     |
| POST   | `/api/collections/:idOrName/confirm-verification`   | Confirm email verification     |
| POST   | `/api/collections/:idOrName/request-password-reset` | Request password reset         |
| POST   | `/api/collections/:idOrName/confirm-password-reset` | Confirm password reset         |
| POST   | `/api/collections/:idOrName/request-email-change`   | Request email change           |
| POST   | `/api/collections/:idOrName/confirm-email-change`   | Confirm email change           |
| POST   | `/api/collections/:idOrName/impersonate/:id`        | Impersonate a user (superuser) |

### Files API

Serve and manage record file attachments.

| Method | Endpoint                                             | Description                       |
| ------ | ---------------------------------------------------- | --------------------------------- |
| GET    | `/api/files/:collectionIdOrName/:recordId/:filename` | Download/serve a file             |
| POST   | `/api/files/token`                                   | Generate a short-lived file token |

**Notes:**

- Files are uploaded/updated/deleted through the Records API, not a separate endpoint
- Protected files require a file token query parameter for access
- The `thumb` query parameter supports on-the-fly image transformations

### Realtime API

Server-Sent Events (SSE) for live data subscriptions.

| Method | Endpoint        | Description                           |
| ------ | --------------- | ------------------------------------- |
| GET    | `/api/realtime` | Establish an SSE connection           |
| POST   | `/api/realtime` | Set active subscriptions for a client |

**Subscription format:**

- `COLLECTION_ID_OR_NAME/*` -- subscribe to all records in a collection
- `COLLECTION_ID_OR_NAME/RECORD_ID` -- subscribe to a specific record

**Notes:**

- Authorization happens during the first "Set subscriptions" call
- Idle connections are disconnected after 5 minutes (auto-reconnects if client is active)
- The collection's `listRule` governs subscriber access

### Settings API

Manage application-level settings. All endpoints require superuser authorization.

| Method | Endpoint                                     | Description                          |
| ------ | -------------------------------------------- | ------------------------------------ |
| GET    | `/api/settings`                              | Get all settings                     |
| PATCH  | `/api/settings`                              | Update settings                      |
| POST   | `/api/settings/test/s3`                      | Test S3 storage connection           |
| POST   | `/api/settings/test/email`                   | Test email delivery                  |
| POST   | `/api/settings/apple/generate-client-secret` | Generate Apple Sign-In client secret |

### Logs API

Access request and application logs. All endpoints require superuser authorization.

| Method | Endpoint          | Description                   |
| ------ | ----------------- | ----------------------------- |
| GET    | `/api/logs`       | List logs (paginated)         |
| GET    | `/api/logs/:id`   | View a single log entry       |
| GET    | `/api/logs/stats` | Get aggregated log statistics |

### Crons API

Manage scheduled jobs. All endpoints require superuser authorization.

| Method | Endpoint            | Description                 |
| ------ | ------------------- | --------------------------- |
| GET    | `/api/crons`        | List registered cron jobs   |
| POST   | `/api/crons/:jobId` | Manually trigger a cron job |

**Built-in cron jobs:**

- `__pbDBOptimize__` -- daily database optimization
- `__pbMFACleanup__` -- hourly MFA cleanup
- `__pbOTPCleanup__` -- hourly OTP cleanup
- `__pbLogsCleanup__` -- logs cleanup every 6 hours

### Health Check API

| Method | Endpoint      | Description                    |
| ------ | ------------- | ------------------------------ |
| GET    | `/api/health` | Check if the server is running |

### Common Response Codes

| Code | Meaning                                                     |
| ---- | ----------------------------------------------------------- |
| 200  | Success with response body                                  |
| 204  | Success with no response body                               |
| 400  | Bad request (validation error, operation in progress, etc.) |
| 401  | Missing or invalid authorization token                      |
| 403  | Authorized user lacks permission for this action            |
| 404  | Resource not found                                          |

---

## Reference Files

The documentation is organized into individual topic files under `references/`.
See `references/index.md` for the full navigation index.

### Getting Started

- `references/how-to-use.md` -- initial setup and usage guide
- `references/collections.md` -- collection types, schemas, and configuration
- `references/authentication.md` -- auth model, token lifecycle, superuser behavior
- `references/files-handling.md` -- file uploads, serving, and storage
- `references/working-with-relations.md` -- relation fields and data modeling
- `references/going-to-production.md` -- deployment and operational guidance
- `references/use-as-framework.md` -- using PocketBase as a Go framework

### API Reference

- `references/api-health.md` -- server health check
- `references/api-collections.md` -- collection CRUD, import, truncate, and scaffolds
- `references/api-records.md` -- record CRUD, batch operations, and query parameters
- `references/api-rules-and-filters.md` -- access control expressions and filter syntax
- `references/api-realtime.md` -- SSE connection and subscription management
- `references/api-files.md` -- file serving and token generation
- `references/api-backups.md` -- backup management endpoints
- `references/api-settings.md` -- application configuration endpoints
- `references/api-logs.md` -- request log querying and statistics
- `references/api-crons.md` -- scheduled job management

### Go SDK

- `references/go-overview.md` -- getting started with Go extension
- `references/go-collections.md` -- collection management in Go
- `references/go-records.md` -- record operations in Go
- `references/go-record-proxy.md` -- typed record proxy pattern
- `references/go-database.md` -- raw SQL, query builder (dbx), and transactions
- `references/go-realtime.md` -- realtime event handling in Go
- `references/go-routing.md` -- custom HTTP routes and middleware
- `references/go-event-hooks.md` -- lifecycle event hooks (record, auth, mail, etc.)
- `references/go-migrations.md` -- programmatic schema migrations
- `references/go-console-commands.md` -- custom CLI commands via Cobra
- `references/go-logging.md` -- logging configuration and usage
- `references/go-sending-emails.md` -- email delivery from Go
- `references/go-rendering-templates.md` -- HTML template rendering
- `references/go-filesystem.md` -- filesystem and S3 storage helpers
- `references/go-jobs-scheduling.md` -- cron job scheduling in Go
- `references/go-testing.md` -- testing utilities and patterns
- `references/go-miscellaneous.md` -- additional Go helpers and utilities

### JavaScript SDK

- `references/js-overview.md` -- getting started with JavaScript extensions
- `references/js-collections.md` -- collection management in JS
- `references/js-records.md` -- record operations in JS
- `references/js-database.md` -- database access from JS
- `references/js-realtime.md` -- realtime event handling in JS
- `references/js-routing.md` -- custom routes from JS
- `references/js-event-hooks.md` -- lifecycle event hooks in JS
- `references/js-migrations.md` -- schema migrations in JS
- `references/js-console-commands.md` -- custom CLI commands in JS
- `references/js-logging.md` -- logging from JS
- `references/js-sending-emails.md` -- email delivery from JS
- `references/js-sending-http-requests.md` -- outbound HTTP requests from JS
- `references/js-rendering-templates.md` -- template rendering in JS
- `references/js-filesystem.md` -- filesystem access from JS
- `references/js-jobs-scheduling.md` -- cron job scheduling in JS

---

## Working with This Skill

### For Beginners

If you are new to PocketBase, start with these topics in order:

1. **What is PocketBase?** -- read the Key Concepts section above
2. **Set up a project** -- download the binary or add the Go module dependency
3. **Create collections** -- use the admin dashboard at `/_/` or the Collections API
4. **Authenticate** -- use `authWithPassword` from the JavaScript or Dart SDK
5. **Perform CRUD** -- create, read, update, and delete records via the SDK
6. **Add realtime** -- subscribe to collection changes for live updates

### For Intermediate Users

Once comfortable with the basics, explore:

- **API rules** -- configure fine-grained access control on each collection
- **File uploads** -- attach files to records and serve them via the Files API
- **Expand relations** -- use `expand` to inline related records in responses
- **Batch operations** -- use `/api/batch` for atomic multi-record changes
- **Backup management** -- automate backup creation and restoration
- **OAuth2 integration** -- configure third-party login providers
- **OTP authentication** -- add passwordless email login

### For Advanced Users

Deep customization through the Go framework:

- **Custom commands** -- add CLI commands via Cobra (`app.RootCmd.AddCommand`)
- **Event hooks** -- bind to record, auth, realtime, and mail lifecycle events
- **Custom routes** -- register HTTP handlers on the PocketBase router
- **Transactions** -- use `app.RunInTransaction` for atomic operations
- **Raw SQL** -- execute queries directly with `app.DB().NewQuery()`
- **Migrations** -- manage schema changes programmatically (Go or JS)
- **Collection queries** -- use the `dbx` query builder for complex lookups
- **Custom auth** -- implement custom authentication flows with hooks

### Tips for Effective Use

- Use the `fields` parameter to limit response payloads and improve performance
- Always call `e.Next()` inside Go hook functions to continue the event chain
- Prefer `RunInTransaction` over multiple separate writes for data consistency
- Use `expand` sparingly on large datasets to avoid performance degradation
- Protected file downloads require a fresh file token from `POST /api/files/token`
- The admin dashboard at `/_/` provides a visual interface for all management tasks
