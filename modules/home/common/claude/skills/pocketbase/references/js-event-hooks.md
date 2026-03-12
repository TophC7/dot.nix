# JS Event Hooks

You can extend the default PocketBase behavior with custom server-side code using the exposed JavaScript app event hooks.

Throwing an error or not calling `e.next()` inside a handler function stops the hook execution chain.

> **Info:** All hook handler functions share the same `function(e){}` signature and expect the user to call `e.next()` if they want to proceed with the execution chain.

## App hooks

### onBootstrap

`onBootstrap` hook is triggered when initializing the main application resources (db, app settings, etc).

Note that attempting to access the database before the `e.next()` call will result in an error.

```javascript
onBootstrap((e) => {
    e.next()

    // e.app
})
```

### onSettingsReload

`onSettingsReload` hook is triggered every time when the `$app.settings()` is being replaced with a new state.

Calling `e.app.settings()` after `e.next()` returns the new state.

```javascript
onSettingsReload((e) => {
    e.next()

    // e.app.settings()
})
```

### onBackupCreate

`onBackupCreate` is triggered on each `$app.createBackup` call.

```javascript
onBackupCreate((e) => {
    // e.app
    // e.name    - the name of the backup to create
    // e.exclude - list of pb_data dir entries to exclude from the backup
})
```

### onBackupRestore

`onBackupRestore` is triggered before app backup restore (aka. on `$app.restoreBackup` call).

```javascript
onBackupRestore((e) => {
    // e.app
    // e.name    - the name of the backup to restore
    // e.exclude - list of dir entries to exclude from the backup
})
```

### onTerminate

`onTerminate` hook is triggered when the app is in the process of being terminated (ex. on `SIGTERM` signal).
Note that the app could be terminated abruptly without awaiting the hook completion.

```javascript
onTerminate((e) => {
    // e.app
    // e.isRestart
})
```

## Mailer hooks

### onMailerSend

`onMailerSend` hook is triggered every time when a new email is being sent using the `$app.newMailClient()` instance.

It allows intercepting the email message or to use a custom mailer client.

```javascript
onMailerSend((e) => {
    // e.app
    // e.mailer
    // e.message

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

### onMailerRecordAuthAlertSend

`onMailerRecordAuthAlertSend` hook is triggered when sending a new device login auth alert email, allowing you to intercept and customize the email message that is being sent.

```javascript
onMailerRecordAuthAlertSend((e) => {
    // e.app
    // e.mailer
    // e.message
    // e.record
    // e.meta.info

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

### onMailerRecordPasswordResetSend

`onMailerRecordPasswordResetSend` hook is triggered when sending a password reset email to an auth record, allowing you to intercept and customize the email message that is being sent.

```javascript
onMailerRecordPasswordResetSend((e) => {
    // e.app
    // e.mailer
    // e.message
    // e.record
    // e.meta.token

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

### onMailerRecordVerificationSend

`onMailerRecordVerificationSend` hook is triggered when sending a verification email to an auth record, allowing you to intercept and customize the email message that is being sent.

```javascript
onMailerRecordVerificationSend((e) => {
    // e.app
    // e.mailer
    // e.message
    // e.record
    // e.meta.token

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

### onMailerRecordEmailChangeSend

`onMailerRecordEmailChangeSend` hook is triggered when sending a confirmation new address email to an auth record, allowing you to intercept and customize the email message that is being sent.

```javascript
onMailerRecordEmailChangeSend((e) => {
    // e.app
    // e.mailer
    // e.message
    // e.record
    // e.meta.token
    // e.meta.newEmail

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

### onMailerRecordOTPSend

`onMailerRecordOTPSend` hook is triggered when sending an OTP email to an auth record, allowing you to intercept and customize the email message that is being sent.

```javascript
onMailerRecordOTPSend((e) => {
    // e.app
    // e.mailer
    // e.message
    // e.record
    // e.meta.otpId
    // e.meta.password

    // ex. change the mail subject
    e.message.subject = "new subject"

    e.next()
})
```

## Realtime hooks

### onRealtimeConnectRequest

`onRealtimeConnectRequest` hook is triggered when establishing the SSE client connection.

Any execution after e.next() of a hook handler happens after the client disconnects.

```javascript
onRealtimeConnectRequest((e) => {
    // e.app
    // e.client
    // e.idleTimeout
    // and all RequestEvent fields...

    e.next()
})
```

### onRealtimeSubscribeRequest

`onRealtimeSubscribeRequest` hook is triggered when updating the client subscriptions, allowing you to further validate and modify the submitted change.

```javascript
onRealtimeSubscribeRequest((e) => {
    // e.app
    // e.client
    // e.subscriptions
    // and all RequestEvent fields...

    e.next()
})
```

### onRealtimeMessageSend

`onRealtimeMessageSend` hook is triggered when sending an SSE message to a client.

```javascript
onRealtimeMessageSend((e) => {
    // e.app
    // e.client
    // e.message
    // and all original connect RequestEvent fields...

    e.next()
})
```

## Record model hooks

> **Info:** These are lower level Record model hooks and could be triggered from anywhere (custom console command, scheduled cron job, when calling `e.save(record)`, etc.) and therefore they have no access to the request context!
>
> If you want to intercept the builtin Web APIs and to access their request body, query parameters, headers or the request auth state, then please use the designated [Record `*Request` hooks](#request-hooks).

### onRecordEnrich

`onRecordEnrich` is triggered every time when a record is enriched - as part of the builtin Record responses, during realtime message serialization, or when `apis.enrichRecord` is invoked.

It could be used for example to redact/hide or add computed temporary Record model props only for the specific request info.

```javascript
onRecordEnrich((e) => {
    // hide one or more fields
    e.record.hide("role")

    // add new custom field for registered users
    if (e.requestInfo.auth?.collection()?.name == "users") {
        e.record.withCustomData(true) // for security custom props require to be enabled explicitly
        e.record.set("computedScore", e.record.get("score") * e.requestInfo.auth.get("base"))
    }

    e.next()
}, "posts")
```

### onRecordValidate

`onRecordValidate` is a Record proxy model hook of `onModelValidate`.

`onRecordValidate` is called every time when a Record is being validated, e.g. triggered by `$app.validate()` or `$app.save()`.

```javascript
// fires for every record
onRecordValidate((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordValidate((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

#### Record model create hooks

### onRecordCreate

`onRecordCreate` is a Record proxy model hook of `onModelCreate`.

`onRecordCreate` is triggered every time when a new Record is being created, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Record validation and the INSERT DB statement.

Operations AFTER the `e.next()` execute after the Record validation and the INSERT DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Record is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onRecordAfterCreateSuccess` or `onRecordAfterCreateError` hooks.

```javascript
// fires for every record
onRecordCreate((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordCreate((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordCreateExecute

`onRecordCreateExecute` is a Record proxy model hook of `onModelCreateExecute`.

`onRecordCreateExecute` is triggered after successful Record validation and right before the model INSERT DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onRecordCreate` -> `onRecordValidate` (skipped with `$app.saveNoValidate()`) -> `onRecordCreateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Record is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onRecordAfterCreateSuccess` or `onRecordAfterCreateError` hooks.

```javascript
// fires for every record
onRecordCreateExecute((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordCreateExecute((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterCreateSuccess

`onRecordAfterCreateSuccess` is a Record proxy model hook of `onModelAfterCreateSuccess`.

`onRecordAfterCreateSuccess` is triggered after each successful Record DB create persistence.

> **Warning:** Note that when a Record is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every record
onRecordAfterCreateSuccess((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterCreateSuccess((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterCreateError

`onRecordAfterCreateError` is a Record proxy model hook of `onModelAfterCreateError`.

`onRecordAfterCreateError` is triggered after each failed Record DB create persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every record
onRecordAfterCreateError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterCreateError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
}, "users", "articles")
```

#### Record model update hooks

### onRecordUpdate

`onRecordUpdate` is a Record proxy model hook of `onModelUpdate`.

`onRecordUpdate` is triggered every time when a new Record is being updated, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Record validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Record validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Record is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onRecordAfterUpdateSuccess` or `onRecordAfterUpdateError` hooks.

```javascript
// fires for every record
onRecordUpdate((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordUpdate((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordUpdateExecute

`onRecordUpdateExecute` is a Record proxy model hook of `onModelUpdateExecute`.

`onRecordUpdateExecute` is triggered after successful Record validation and right before the model UPDATE DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onRecordUpdate` -> `onRecordValidate` (skipped with `$app.saveNoValidate()`) -> `onRecordUpdateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Record is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onRecordAfterUpdateSuccess` or `onRecordAfterUpdateError` hooks.

```javascript
// fires for every record
onRecordUpdateExecute((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordUpdateExecute((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterUpdateSuccess

`onRecordAfterUpdateSuccess` is a Record proxy model hook of `onModelAfterUpdateSuccess`.

`onRecordAfterUpdateSuccess` is triggered after each successful Record DB update persistence.

> **Warning:** Note that when a Record is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every record
onRecordAfterUpdateSuccess((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterUpdateSuccess((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterUpdateError

`onRecordAfterUpdateError` is a Record proxy model hook of `onModelAfterUpdateError`.

`onRecordAfterUpdateError` is triggered after each failed Record DB update persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every record
onRecordAfterUpdateError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterUpdateError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
}, "users", "articles")
```

#### Record model delete hooks

### onRecordDelete

`onRecordDelete` is a Record proxy model hook of `onModelDelete`.

`onRecordDelete` is triggered every time when a new Record is being deleted, e.g. triggered by `$app.delete()`.

Operations BEFORE the `e.next()` execute before the Record validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Record validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Record is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted deleted events, you can bind to `onRecordAfterDeleteSuccess` or `onRecordAfterDeleteError` hooks.

```javascript
// fires for every record
onRecordDelete((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordDelete((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordDeleteExecute

`onRecordDeleteExecute` is a Record proxy model hook of `onModelDeleteExecute`.

`onRecordDeleteExecute` is triggered after the internal delete checks and right before the Record the model DELETE DB statement execution.

Usually it is triggered as part of the `$app.delete()` in the following firing order:
`onRecordDelete` -> internal delete checks -> `onRecordDeleteExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Record is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onRecordAfterDeleteSuccess` or `onRecordAfterDeleteError` hooks.

```javascript
// fires for every record
onRecordDeleteExecute((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordDeleteExecute((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterDeleteSuccess

`onRecordAfterDeleteSuccess` is a Record proxy model hook of `onModelAfterDeleteSuccess`.

`onRecordAfterDeleteSuccess` is triggered after each successful Record DB delete persistence.

> **Warning:** Note that when a Record is deleted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every record
onRecordAfterDeleteSuccess((e) => {
    // e.app
    // e.record

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterDeleteSuccess((e) => {
    // e.app
    // e.record

    e.next()
}, "users", "articles")
```

### onRecordAfterDeleteError

`onRecordAfterDeleteError` is a Record proxy model hook of `onModelAfterDeleteError`.

`onRecordAfterDeleteError` is triggered after each failed Record DB delete persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.delete()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every record
onRecordAfterDeleteError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
})

// fires only for "users" and "articles" records
onRecordAfterDeleteError((e) => {
    // e.app
    // e.record
    // e.error

    e.next()
}, "users", "articles")
```

## Collection model hooks

> **Info:** These are lower level Collection model hooks and could be triggered from anywhere (custom console command, scheduled cron job, when calling `e.save(collection)`, etc.) and therefore they have no access to the request context!
>
> If you want to intercept the builtin Web APIs and to access their request body, query parameters, headers or the request auth state, then please use the designated [Collection `*Request` hooks](#collection-request-hooks).

### onCollectionValidate

`onCollectionValidate` is a Collection proxy model hook of `onModelValidate`.

`onCollectionValidate` is called every time when a Collection is being validated, e.g. triggered by `$app.validate()` or `$app.save()`.

```javascript
// fires for every collection
onCollectionValidate((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionValidate((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

#### Collection mode create hooks

### onCollectionCreate

`onCollectionCreate` is a Collection proxy model hook of `onModelCreate`.

`onCollectionCreate` is triggered every time when a new Collection is being created, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Collection validation and the INSERT DB statement.

Operations AFTER the `e.next()` execute after the Collection validation and the INSERT DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Collection is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onCollectionAfterCreateSuccess` or `onCollectionAfterCreateError` hooks.

```javascript
// fires for every collection
onCollectionCreate((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionCreate((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionCreateExecute

`onCollectionCreateExecute` is a Collection proxy model hook of `onModelCreateExecute`.

`onCollectionCreateExecute` is triggered after successful Collection validation and right before the model INSERT DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onCollectionCreate` -> `onCollectionValidate` (skipped with `$app.saveNoValidate()`) -> `onCollectionCreateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Collection is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onCollectionAfterCreateSuccess` or `onCollectionAfterCreateError` hooks.

```javascript
// fires for every collection
onCollectionCreateExecute((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionCreateExecute((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterCreateSuccess

`onCollectionAfterCreateSuccess` is a Collection proxy model hook of `onModelAfterCreateSuccess`.

`onCollectionAfterCreateSuccess` is triggered after each successful Collection DB create persistence.

> **Warning:** Note that when a Collection is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every collection
onCollectionAfterCreateSuccess((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterCreateSuccess((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterCreateError

`onCollectionAfterCreateError` is a Collection proxy model hook of `onModelAfterCreateError`.

`onCollectionAfterCreateError` is triggered after each failed Collection DB create persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every collection
onCollectionAfterCreateError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterCreateError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
}, "users", "articles")
```

#### Collection mode update hooks

### onCollectionUpdate

`onCollectionUpdate` is a Collection proxy model hook of `onModelUpdate`.

`onCollectionUpdate` is triggered every time when a new Collection is being updated, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Collection validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Collection validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Collection is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onCollectionAfterUpdateSuccess` or `onCollectionAfterUpdateError` hooks.

```javascript
// fires for every collection
onCollectionUpdate((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionUpdate((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionUpdateExecute

`onCollectionUpdateExecute` is a Collection proxy model hook of `onModelUpdateExecute`.

`onCollectionUpdateExecute` is triggered after successful Collection validation and right before the model UPDATE DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onCollectionUpdate` -> `onCollectionValidate` (skipped with `$app.saveNoValidate()`) -> `onCollectionUpdateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Collection is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onCollectionAfterUpdateSuccess` or `onCollectionAfterUpdateError` hooks.

```javascript
// fires for every collection
onCollectionUpdateExecute((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionUpdateExecute((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterUpdateSuccess

`onCollectionAfterUpdateSuccess` is a Collection proxy model hook of `onModelAfterUpdateSuccess`.

`onCollectionAfterUpdateSuccess` is triggered after each successful Collection DB update persistence.

> **Warning:** Note that when a Collection is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every collection
onCollectionAfterUpdateSuccess((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterUpdateSuccess((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterUpdateError

`onCollectionAfterUpdateError` is a Collection proxy model hook of `onModelAfterUpdateError`.

`onCollectionAfterUpdateError` is triggered after each failed Collection DB update persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every collection
onCollectionAfterUpdateError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterUpdateError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
}, "users", "articles")
```

#### Collection mode delete hooks

### onCollectionDelete

`onCollectionDelete` is a Collection proxy model hook of `onModelDelete`.

`onCollectionDelete` is triggered every time when a new Collection is being deleted, e.g. triggered by `$app.delete()`.

Operations BEFORE the `e.next()` execute before the Collection validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Collection validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Collection is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted deleted events, you can bind to `onCollectionAfterDeleteSuccess` or `onCollectionAfterDeleteError` hooks.

```javascript
// fires for every collection
onCollectionDelete((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionDelete((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionDeleteExecute

`onCollectionDeleteExecute` is a Collection proxy model hook of `onModelDeleteExecute`.

`onCollectionDeleteExecute` is triggered after the internal delete checks and right before the Collection the model DELETE DB statement execution.

Usually it is triggered as part of the `$app.delete()` in the following firing order:
`onCollectionDelete` -> internal delete checks -> `onCollectionDeleteExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Collection is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onCollectionAfterDeleteSuccess` or `onCollectionAfterDeleteError` hooks.

```javascript
// fires for every collection
onCollectionDeleteExecute((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionDeleteExecute((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterDeleteSuccess

`onCollectionAfterDeleteSuccess` is a Collection proxy model hook of `onModelAfterDeleteSuccess`.

`onCollectionAfterDeleteSuccess` is triggered after each successful Collection DB delete persistence.

> **Warning:** Note that when a Collection is deleted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

```javascript
// fires for every collection
onCollectionAfterDeleteSuccess((e) => {
    // e.app
    // e.collection

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterDeleteSuccess((e) => {
    // e.app
    // e.collection

    e.next()
}, "users", "articles")
```

### onCollectionAfterDeleteError

`onCollectionAfterDeleteError` is a Collection proxy model hook of `onModelAfterDeleteError`.

`onCollectionAfterDeleteError` is triggered after each failed Collection DB delete persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.delete()` failure
> - **delayed** on transaction rollback

```javascript
// fires for every collection
onCollectionAfterDeleteError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
})

// fires only for "users" and "articles" collections
onCollectionAfterDeleteError((e) => {
    // e.app
    // e.collection
    // e.error

    e.next()
}, "users", "articles")
```

## Request hooks

> **Info:** The request hooks are triggered only when the corresponding API request endpoint is accessed.

#### Record CRUD request hooks

### onRecordsListRequest

`onRecordsListRequest` hook is triggered on each API Records list request. Could be used to validate or modify the response before returning it to the client.

> **Warning:** Note that if you want to hide existing or add new computed Record fields prefer using the [onRecordEnrich](#onrecordenrich) hook because it is less error-prone and it is triggered by all builtin Record responses (including when sending realtime Record events).

```javascript
// fires for every collection
onRecordsListRequest((e) => {
    // e.app
    // e.collection
    // e.records
    // e.result
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "articles" collections
onRecordsListRequest((e) => {
    // e.app
    // e.collection
    // e.records
    // e.result
    // and all RequestEvent fields...

    e.next()
}, "users", "articles")
```

### onRecordViewRequest

`onRecordViewRequest` hook is triggered on each API Record view request. Could be used to validate or modify the response before returning it to the client.

> **Warning:** Note that if you want to hide existing or add new computed Record fields prefer using the [onRecordEnrich](#onrecordenrich) hook because it is less error-prone and it is triggered by all builtin Record responses (including when sending realtime Record events).

```javascript
// fires for every collection
onRecordViewRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "articles" collections
onRecordViewRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "articles")
```

### onRecordCreateRequest

`onRecordCreateRequest` hook is triggered on each API Record create request. Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
// fires for every collection
onRecordCreateRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "articles" collections
onRecordCreateRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "articles")
```

### onRecordUpdateRequest

`onRecordUpdateRequest` hook is triggered on each API Record update request. Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
// fires for every collection
onRecordUpdateRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "articles" collections
onRecordUpdateRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "articles")
```

### onRecordDeleteRequest

`onRecordDeleteRequest` hook is triggered on each API Record delete request. Could be used to additionally validate the request data or implement completely different delete behavior.

```javascript
// fires for every collection
onRecordDeleteRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "articles" collections
onRecordDeleteRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "articles")
```

#### Record auth request hooks

### onRecordAuthRequest

`onRecordAuthRequest` hook is triggered on each successful API record authentication request (sign-in, token refresh, etc.). Could be used to additionally validate or modify the authenticated record data and token.

```javascript
// fires for every auth collection
onRecordAuthRequest((e) => {
    // e.app
    // e.record
    // e.token
    // e.meta
    // e.authMethod
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordAuthRequest((e) => {
    // e.app
    // e.record
    // e.token
    // e.meta
    // e.authMethod
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordAuthRefreshRequest

`onRecordAuthRefreshRequest` hook is triggered on each Record auth refresh API request (right before generating a new auth token).

Could be used to additionally validate the request data or implement completely different auth refresh behavior.

```javascript
// fires for every auth collection
onRecordAuthRefreshRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordAuthRefreshRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordAuthWithPasswordRequest

`onRecordAuthWithPasswordRequest` hook is triggered on each Record auth with password API request.

**`e.record` could be `null` if no matching identity is found, allowing you to manually locate a different Record model (by reassigning `e.record`).**

```javascript
// fires for every auth collection
onRecordAuthWithPasswordRequest((e) => {
    // e.app
    // e.collection
    // e.record (could be null)
    // e.identity
    // e.identityField
    // e.password
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordAuthWithPasswordRequest((e) => {
    // e.app
    // e.collection
    // e.record (could be null)
    // e.identity
    // e.identityField
    // e.password
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordAuthWithOAuth2Request

`onRecordAuthWithOAuth2Request` hook is triggered on each Record OAuth2 sign-in/sign-up API request (after token exchange and before external provider linking).

If `e.record` is not set, then the OAuth2 request will try to create a new auth record. To assign or link a different existing record model you can change the `e.record` field.

```javascript
// fires for every auth collection
onRecordAuthWithOAuth2Request((e) => {
    // e.app
    // e.collection
    // e.providerName
    // e.providerClient
    // e.record (could be null)
    // e.oauth2User
    // e.createData
    // e.isNewRecord
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordAuthWithOAuth2Request((e) => {
    // e.app
    // e.collection
    // e.providerName
    // e.providerClient
    // e.record (could be null)
    // e.oauth2User
    // e.createData
    // e.isNewRecord
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordRequestPasswordResetRequest

`onRecordRequestPasswordResetRequest` hook is triggered on each Record request password reset API request.

Could be used to additionally validate the request data or implement completely different password reset behavior.

```javascript
// fires for every auth collection
onRecordRequestPasswordResetRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordRequestPasswordResetRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordConfirmPasswordResetRequest

`onRecordConfirmPasswordResetRequest` hook is triggered on each Record confirm password reset API request.

Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
// fires for every auth collection
onRecordConfirmPasswordResetRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordConfirmPasswordResetRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordRequestVerificationRequest

`onRecordRequestVerificationRequest` hook is triggered on each Record request verification API request.

Could be used to additionally validate the loaded request data or implement completely different verification behavior.

```javascript
// fires for every auth collection
onRecordRequestVerificationRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordRequestVerificationRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordConfirmVerificationRequest

`onRecordConfirmVerificationRequest` hook is triggered on each Record confirm verification API request.

Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
// fires for every auth collection
onRecordConfirmVerificationRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordConfirmVerificationRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordRequestEmailChangeRequest

`onRecordRequestEmailChangeRequest` hook is triggered on each Record request email change API request.

Could be used to additionally validate the request data or implement completely different request email change behavior.

```javascript
// fires for every auth collection
onRecordRequestEmailChangeRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.newEmail
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordRequestEmailChangeRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.newEmail
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordConfirmEmailChangeRequest

`onRecordConfirmEmailChangeRequest` hook is triggered on each Record confirm email change API request.

Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
// fires for every auth collection
onRecordConfirmEmailChangeRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.newEmail
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordConfirmEmailChangeRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.newEmail
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordRequestOTPRequest

`onRecordRequestOTPRequest` hook is triggered on each Record request OTP API request.

**`e.record` could be `null` if no user with the requested email is found, allowing you to manually create a new Record or locate a different Record model (by reassigning `e.record`).**

```javascript
// fires for every auth collection
onRecordRequestOTPRequest((e) => {
    // e.app
    // e.collection
    // e.record (could be null)
    // e.password
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordRequestOTPRequest((e) => {
    // e.app
    // e.collection
    // e.record (could be null)
    // e.password
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

### onRecordAuthWithOTPRequest

`onRecordAuthWithOTPRequest` hook is triggered on each Record auth with OTP API request.

```javascript
// fires for every auth collection
onRecordAuthWithOTPRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.otp
    // and all RequestEvent fields...

    e.next()
})

// fires only for "users" and "managers" auth collections
onRecordAuthWithOTPRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.otp
    // and all RequestEvent fields...

    e.next()
}, "users", "managers")
```

#### Batch request hooks

### onBatchRequest

`onBatchRequest` hook is triggered on each API batch request.

Could be used to additionally validate or modify the submitted batch requests.

This hook will also fire the corresponding `onRecordCreateRequest`, `onRecordUpdateRequest`, `onRecordDeleteRequest` hooks, where `e.app` is the batch transactional app.

```javascript
onBatchRequest((e) => {
    // e.app
    // e.batch
    // and all RequestEvent fields...

    e.next()
})
```

#### File request hooks

### onFileDownloadRequest

`onFileDownloadRequest` hook is triggered before each API File download request. Could be used to validate or modify the file response before returning it to the client.

```javascript
onFileDownloadRequest((e) => {
    // e.app
    // e.collection
    // e.record
    // e.fileField
    // e.servedPath
    // e.servedName
    // and all RequestEvent fields...

    e.next()
})
```

### onFileTokenRequest

`onFileTokenRequest` hook is triggered on each auth file token API request.

```javascript
// fires for every auth model
onFileTokenRequest((e) => {
    // e.app
    // e.record
    // e.token
    // and all RequestEvent fields...

    e.next();
})

// fires only for "users"
onFileTokenRequest((e) => {
    // e.app
    // e.record
    // e.token
    // and all RequestEvent fields...

    e.next();
}, "users")
```

#### Collection request hooks

### onCollectionsListRequest

`onCollectionsListRequest` hook is triggered on each API Collections list request. Could be used to validate or modify the response before returning it to the client.

```javascript
onCollectionsListRequest((e) => {
    // e.app
    // e.collections
    // e.result
    // and all RequestEvent fields...

    e.next()
})
```

### onCollectionViewRequest

`onCollectionViewRequest` hook is triggered on each API Collection view request. Could be used to validate or modify the response before returning it to the client.

```javascript
onCollectionViewRequest((e) => {
    // e.app
    // e.collection
    // and all RequestEvent fields...

    e.next()
})
```

### onCollectionCreateRequest

`onCollectionCreateRequest` hook is triggered on each API Collection create request. Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
onCollectionCreateRequest((e) => {
    // e.app
    // e.collection
    // and all RequestEvent fields...

    e.next()
})
```

### onCollectionUpdateRequest

`onCollectionUpdateRequest` hook is triggered on each API Collection update request. Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
onCollectionUpdateRequest((e) => {
    // e.app
    // e.collection
    // and all RequestEvent fields...

    e.next()
})
```

### onCollectionDeleteRequest

`onCollectionDeleteRequest` hook is triggered on each API Collection delete request. Could be used to additionally validate the request data or implement completely different delete behavior.

```javascript
onCollectionDeleteRequest((e) => {
    // e.app
    // e.collection
    // and all RequestEvent fields...

    e.next()
})
```

### onCollectionsImportRequest

`onCollectionsImportRequest` hook is triggered on each API collections import request. Could be used to additionally validate the imported collections or to implement completely different import behavior.

```javascript
onCollectionsImportRequest((e) => {
    // e.app
    // e.collectionsData
    // e.deleteMissing

    e.next()
})
```

#### Settings request hooks

### onSettingsListRequest

`onSettingsListRequest` hook is triggered on each API Settings list request. Could be used to validate or modify the response before returning it to the client.

```javascript
onSettingsListRequest((e) => {
    // e.app
    // e.settings
    // and all RequestEvent fields...

    e.next()
})
```

### onSettingsUpdateRequest

`onSettingsUpdateRequest` hook is triggered on each API Settings update request. Could be used to additionally validate the request data or implement completely different persistence behavior.

```javascript
onSettingsUpdateRequest((e) => {
    // e.app
    // e.oldSettings
    // e.newSettings
    // and all RequestEvent fields...

    e.next()
})
```

## Base model hooks

> **Info:** The Model hooks are fired for all PocketBase structs that implements the Model DB interface - Record, Collection, Log, etc.
>
> For convenience, if you want to listen to only the Record or Collection DB model events without doing manual type assertion, you can use the [onRecord*](#record-model-hooks) and [onCollection*](#collection-model-hooks) proxy hooks above.

### onModelValidate

`onModelValidate` is called every time when a Model is being validated, e.g. triggered by `$app.validate()` or `$app.save()`.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelValidate((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelValidate((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

#### Base model create hooks

### onModelCreate

`onModelCreate` is triggered every time when a new Model is being created, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Model validation and the INSERT DB statement.

Operations AFTER the `e.next()` execute after the Model validation and the INSERT DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Model is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onModelAfterCreateSuccess` or `onModelAfterCreateError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelCreate((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelCreate((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelCreateExecute

`onModelCreateExecute` is triggered after successful Model validation and right before the model INSERT DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onModelCreate` -> `onModelValidate` (skipped with `$app.saveNoValidate()`) -> `onModelCreateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Model is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onModelAfterCreateSuccess` or `onModelAfterCreateError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelCreateExecute((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelCreateExecute((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterCreateSuccess

`onModelAfterCreateSuccess` is triggered after each successful Model DB create persistence.

> **Warning:** Note that when a Model is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterCreateSuccess((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterCreateSuccess((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterCreateError

`onModelAfterCreateError` is triggered after each failed Model DB create persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterCreateError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterCreateError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
}, "users", "articles")
```

#### Base model update hooks

### onModelUpdate

`onModelUpdate` is triggered every time when a new Model is being updated, e.g. triggered by `$app.save()`.

Operations BEFORE the `e.next()` execute before the Model validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Model validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Model is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onModelAfterUpdateSuccess` or `onModelAfterUpdateError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelUpdate((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelUpdate((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelUpdateExecute

`onModelUpdateExecute` is triggered after successful Model validation and right before the model UPDATE DB statement execution.

Usually it is triggered as part of the `$app.save()` in the following firing order:
`onModelUpdate` -> `onModelValidate` (skipped with `$app.saveNoValidate()`) -> `onModelUpdateExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Model is persisted in the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onModelAfterUpdateSuccess` or `onModelAfterUpdateError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelUpdateExecute((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelUpdateExecute((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterUpdateSuccess

`onModelAfterUpdateSuccess` is triggered after each successful Model DB update persistence.

> **Warning:** Note that when a Model is persisted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterUpdateSuccess((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterUpdateSuccess((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterUpdateError

`onModelAfterUpdateError` is triggered after each failed Model DB update persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.save()` failure
> - **delayed** on transaction rollback

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterUpdateError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterUpdateError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
}, "users", "articles")
```

#### Base model delete hooks

### onModelDelete

`onModelDelete` is triggered every time when a new Model is being deleted, e.g. triggered by `$app.delete()`.

Operations BEFORE the `e.next()` execute before the Model validation and the UPDATE DB statement.

Operations AFTER the `e.next()` execute after the Model validation and the UPDATE DB statement.

> **Warning:** Note that successful execution doesn't guarantee that the Model is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted deleted events, you can bind to `onModelAfterDeleteSuccess` or `onModelAfterDeleteError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelDelete((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelDelete((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelDeleteExecute

`onModelDeleteExecute` is triggered after the internal delete checks and right before the Model the model DELETE DB statement execution.

Usually it is triggered as part of the `$app.delete()` in the following firing order:
`onModelDelete` -> internal delete checks -> `onModelDeleteExecute`

> **Warning:** Note that successful execution doesn't guarantee that the Model is deleted from the database since its wrapping transaction may not have been committed yet. If you want to listen to only the actual persisted events, you can bind to `onModelAfterDeleteSuccess` or `onModelAfterDeleteError` hooks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelDeleteExecute((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelDeleteExecute((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterDeleteSuccess

`onModelAfterDeleteSuccess` is triggered after each successful Model DB delete persistence.

> **Warning:** Note that when a Model is deleted as part of a transaction, this hook is delayed and executed only AFTER the transaction has been committed. This hook is NOT triggered in case the transaction fails/rollbacks.

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterDeleteSuccess((e) => {
    // e.app
    // e.model

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterDeleteSuccess((e) => {
    // e.app
    // e.model

    e.next()
}, "users", "articles")
```

### onModelAfterDeleteError

`onModelAfterDeleteError` is triggered after each failed Model DB delete persistence.

> **Warning:** Note that the execution of this hook is either immediate or delayed depending on the error:
> - **immediate** on `$app.delete()` failure
> - **delayed** on transaction rollback

**For convenience, if you want to listen to only the Record or Collection models events without doing manual type assertion, you can use the equivalent `onRecord*` and `onCollection*` proxy hooks.**

```javascript
// fires for every model
onModelAfterDeleteError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
})

// fires only for "users" and "articles" models
onModelAfterDeleteError((e) => {
    // e.app
    // e.model
    // e.error

    e.next()
}, "users", "articles")
```
