# Sending Emails

PocketBase provides a simple abstraction for sending emails via the
`$app.newMailClient()` helper.

Depending on your configured mail settings (*Dashboard > Settings > Mail settings*) it will use the
`sendmail` command or a SMTP client.

## Send custom email

You can send your own custom emails from everywhere within the app (hooks, middlewares, routes, etc.) by
using `$app.newMailClient().send(message)`. Here is an example of sending a custom email after
user registration:

```go
onRecordCreateRequest((e) => {
    e.next()

    const message = new MailerMessage({
        from: {
            address: e.app.settings().meta.senderAddress,
            name:    e.app.settings().meta.senderName,
        },
        to:      [{address: e.record.email()}],
        subject: "YOUR_SUBJECT...",
        html:    "YOUR_HTML_BODY...",
        // bcc, cc and custom headers are also supported...
    })

    e.app.newMailClient().send(message)
}, "users")
```

## Overwrite system emails

If you want to overwrite the default system emails for forgotten password, verification, etc., you can
adjust the default templates available from the
*Dashboard > Collections > Edit collection > Options*.

Alternatively, you can also apply individual changes by binding to one of the
[mailer hooks](/docs/js-event-hooks/#mailer-hooks). Here is an example of appending a Record
field value to the subject using the `onMailerRecordPasswordResetSend` hook:

```javascript
onMailerRecordPasswordResetSend((e) => {
    // modify the subject
    e.message.subject += (" " + e.record.get("name"))

    e.next()
})
```
