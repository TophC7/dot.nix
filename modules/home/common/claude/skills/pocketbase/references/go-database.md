# Go Database

[`core.App`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#App) is the main interface to interact with the database.

`App.DB()` returns a `dbx.Builder` that can run all kinds of SQL statements, including raw queries.

Most of the common DB operations are listed below, but you can find further information in the [dbx package godoc](https://pkg.go.dev/github.com/pocketbase/dbx).

> **Info:** For more details and examples how to interact with Record and Collection models programmatically you could also check [Collection operations](/docs/go-collections) and [Record operations](/docs/go-records) sections.

## Executing queries

To execute DB queries you can start with the `NewQuery("...")` statement and then call one of:

- ### `Execute()`

  For any query statement that is not meant to retrieve data:

  ```go
  res, err := app.DB().
      NewQuery("DELETE FROM articles WHERE status = 'archived'").
      Execute()
  ```

- ### `One()`

  To populate a single row into a struct:

  ```go
  type User struct {
      Id     string                  `db:"id" json:"id"`
      Status bool                    `db:"status" json:"status"`
      Age    int                     `db:"age" json:"age"`
      Roles  types.JSONArray[string] `db:"roles" json:"roles"`
  }

  user := User{}

  err := app.DB().
      NewQuery("SELECT id, status, age, roles FROM users WHERE id=1").
      One(&user)
  ```

- ### `All()`

  To populate multiple rows into a slice of structs:

  ```go
  type User struct {
      Id     string                  `db:"id" json:"id"`
      Status bool                    `db:"status" json:"status"`
      Age    int                     `db:"age" json:"age"`
      Roles  types.JSONArray[string] `db:"roles" json:"roles"`
  }

  users := []User{}

  err := app.DB().
      NewQuery("SELECT id, status, age, roles FROM users LIMIT 100").
      All(&users)
  ```

## Binding parameters

To prevent SQL injection attacks, you should use named parameters for any expression value that comes from user input. This could be done using the named `{:paramName}` placeholders in your SQL statement and then define the parameter values for the query with `Bind(params)`. For example:

```go
type Post struct {
    Name     string         `db:"name" json:"name"`
    Created  types.DateTime `db:"created" json:"created"`
}

posts := []Post{}

err := app.DB().
    NewQuery("SELECT name, created FROM posts WHERE created >= {:from} and created <= {:to}").
    Bind(dbx.Params{
        "from": "2023-06-25 00:00:00.000Z",
        "to":   "2023-06-28 23:59:59.999Z",
    }).
    All(&posts)
```

## Query builder

Instead of writing plain SQLs, you can also compose SQL statements programmatically using the db query builder.

Every SQL keyword has a corresponding query building method. For example, `SELECT` corresponds to `Select()`, `FROM` corresponds to `From()`, `WHERE` corresponds to `Where()`, and so on.

```go
users := []struct {
    Id    string `db:"id" json:"id"`
    Email string `db:"email" json:"email"`
}{}

app.DB().
    Select("id", "email").
    From("users").
    AndWhere(dbx.Like("email", "example.com")).
    Limit(100).
    OrderBy("created ASC").
    All(&users)
```

##### `Select()`, `AndSelect()`, `Distinct()`

The `Select(...cols)` method initializes a `SELECT` query builder. It accepts a list of the column names to be selected.

To add additional columns to an existing select query, you can call `AndSelect()`.

To select distinct rows, you can call `Distinct(true)`.

```go
app.DB().
    Select("id", "avatar as image").
    AndSelect("(firstName || ' ' || lastName) as fullName").
    Distinct(true)
    ...
```

##### `From()`

The `From(...tables)` method specifies which tables to select from (plain table names are automatically quoted).

```go
app.DB().
    Select("table1.id", "table2.name").
    From("table1", "table2")
    ...
```

##### `Join()`

The `Join(type, table, on)` method specifies a `JOIN` clause. It takes 3 parameters:

- `type` - join type string like `INNER JOIN`, `LEFT JOIN`, etc.
- `table` - the name of the table to be joined
- `on` - optional `dbx.Expression` as an `ON` clause

For convenience, you can also use the shortcuts `InnerJoin(table, on)`, `LeftJoin(table, on)`, `RightJoin(table, on)` to specify `INNER JOIN`, `LEFT JOIN` and `RIGHT JOIN`, respectively.

```go
app.DB().
    Select("users.*").
    From("users").
    InnerJoin("profiles", dbx.NewExp("profiles.user_id = users.id")).
    Join("FULL OUTER JOIN", "department", dbx.NewExp("department.id = {:id}", dbx.Params{ "id": "someId" }))
    ...
```

##### `Where()`, `AndWhere()`, `OrWhere()`

The `Where(exp)` method specifies the `WHERE` condition of the query.

You can also use `AndWhere(exp)` or `OrWhere(exp)` to append additional one or more conditions to an existing `WHERE` clause.

Each where condition accepts a single `dbx.Expression` (see below for full list).

```go
/*
SELECT users.*
FROM users
WHERE id = "someId" AND
    status = "public" AND
    name like "%john%" OR
    (
        role = "manager" AND
        fullTime IS TRUE AND
        experience > 10
    )
*/
app.DB().
    Select("users.*").
    From("users").
    Where(dbx.NewExp("id = {:id}", dbx.Params{ "id": "someId" })).
    AndWhere(dbx.HashExp{"status": "public"}).
    AndWhere(dbx.Like("name", "john")).
    OrWhere(dbx.And(
        dbx.HashExp{
            "role":     "manager",
            "fullTime": true,
        },
        dbx.NewExp("experience > {:exp}", dbx.Params{ "exp": 10 })
    ))
    ...
```

The following `dbx.Expression` methods are available:

- #### `dbx.NewExp(raw, optParams)`

  Generates an expression with the specified raw query fragment. Use the `optParams` to bind `dbx.Params` to the expression.

  ```go
  dbx.NewExp("status = 'public'")
  dbx.NewExp("total > {:min} AND total < {:max}", dbx.Params{ "min": 10, "max": 30 })
  ```

- #### `dbx.HashExp{k:v}`

  Generates a hash expression from a map whose keys are DB column names which need to be filtered according to the corresponding values.

  ```go
  // slug = "example" AND active IS TRUE AND tags in ("tag1", "tag2", "tag3") AND parent IS NULL
  dbx.HashExp{
      "slug":   "example",
      "active": true,
      "tags":   []any{"tag1", "tag2", "tag3"},
      "parent": nil,
  }
  ```

- #### `dbx.Not(exp)`

  Negates a single expression by wrapping it with `NOT()`.

  ```go
  // NOT(status = 1)
  dbx.Not(dbx.NewExp("status = 1"))
  ```

- #### `dbx.And(...exps)`

  Creates a new expression by concatenating the specified ones with `AND`.

  ```go
  // (status = 1 AND username like "%john%")
  dbx.And(
      dbx.NewExp("status = 1"),
      dbx.Like("username", "john"),
  )
  ```

- #### `dbx.Or(...exps)`

  Creates a new expression by concatenating the specified ones with `OR`.

  ```go
  // (status = 1 OR username like "%john%")
  dbx.Or(
      dbx.NewExp("status = 1"),
      dbx.Like("username", "john")
  )
  ```

- #### `dbx.In(col, ...values)`

  Generates an `IN` expression for the specified column and the list of allowed values.

  ```go
  // status IN ("public", "reviewed")
  dbx.In("status", "public", "reviewed")
  ```

- #### `dbx.NotIn(col, ...values)`

  Generates an `NOT IN` expression for the specified column and the list of allowed values.

  ```go
  // status NOT IN ("public", "reviewed")
  dbx.NotIn("status", "public", "reviewed")
  ```

- #### `dbx.Like(col, ...values)`

  Generates a `LIKE` expression for the specified column and the possible strings that the column should be like. If multiple values are present, the column should be like **all** of them.

  By default, each value will be surrounded by "%" to enable partial matching. Special characters like "%", "\", "_" will also be properly escaped. You may call `Escape(...pairs)` and/or `Match(left, right)` to change the default behavior.

  ```go
  // name LIKE "%test1%" AND name LIKE "%test2%"
  dbx.Like("name", "test1", "test2")

  // name LIKE "test1%"
  dbx.Like("name", "test1").Match(false, true)
  ```

- #### `dbx.NotLike(col, ...values)`

  Generates a `NOT LIKE` expression in similar manner as `Like()`.

  ```go
  // name NOT LIKE "%test1%" AND name NOT LIKE "%test2%"
  dbx.NotLike("name", "test1", "test2")

  // name NOT LIKE "test1%"
  dbx.NotLike("name", "test1").Match(false, true)
  ```

- #### `dbx.OrLike(col, ...values)`

  This is similar to `Like()` except that the column must be one of the provided values, aka. multiple values are concatenated with `OR` instead of `AND`.

  ```go
  // name LIKE "%test1%" OR name LIKE "%test2%"
  dbx.OrLike("name", "test1", "test2")

  // name LIKE "test1%" OR name LIKE "test2%"
  dbx.OrLike("name", "test1", "test2").Match(false, true)
  ```

- #### `dbx.OrNotLike(col, ...values)`

  This is similar to `NotLike()` except that the column must not be one of the provided values, aka. multiple values are concatenated with `OR` instead of `AND`.

  ```go
  // name NOT LIKE "%test1%" OR name NOT LIKE "%test2%"
  dbx.OrNotLike("name", "test1", "test2")

  // name NOT LIKE "test1%" OR name NOT LIKE "test2%"
  dbx.OrNotLike("name", "test1", "test2").Match(false, true)
  ```

- #### `dbx.Exists(exp)`

  Prefix with `EXISTS` the specified expression (usually a subquery).

  ```go
  // EXISTS (SELECT 1 FROM users WHERE status = 'active')
  dbx.Exists(dbx.NewExp("SELECT 1 FROM users WHERE status = 'active'"))
  ```

- #### `dbx.NotExists(exp)`

  Prefix with `NOT EXISTS` the specified expression (usually a subquery).

  ```go
  // NOT EXISTS (SELECT 1 FROM users WHERE status = 'active')
  dbx.NotExists(dbx.NewExp("SELECT 1 FROM users WHERE status = 'active'"))
  ```

- #### `dbx.Between(col, from, to)`

  Generates a `BETWEEN` expression with the specified range.

  ```go
  // age BETWEEN 3 and 99
  dbx.Between("age", 3, 99)
  ```

- #### `dbx.NotBetween(col, from, to)`

  Generates a `NOT BETWEEN` expression with the specified range.

  ```go
  // age NOT BETWEEN 3 and 99
  dbx.NotBetween("age", 3, 99)
  ```

##### `OrderBy()`, `AndOrderBy()`

The `OrderBy(...cols)` specifies the `ORDER BY` clause of the query.

A column name can contain "ASC" or "DESC" to indicate its ordering direction.

You can also use `AndOrderBy(...cols)` to append additional columns to an existing `ORDER BY` clause.

```go
app.DB().
    Select("users.*").
    From("users").
    OrderBy("created ASC", "updated DESC").
    AndOrderBy("title ASC")
    ...
```

##### `GroupBy()`, `AndGroupBy()`

The `GroupBy(...cols)` specifies the `GROUP BY` clause of the query.

You can also use `AndGroupBy(...cols)` to append additional columns to an existing `GROUP BY` clause.

```go
app.DB().
    Select("users.*").
    From("users").
    GroupBy("department", "level")
    ...
```

##### `Having()`, `AndHaving()`, `OrHaving()`

The `Having(exp)` specifies the `HAVING` clause of the query.

Similarly to `Where(exp)`, it accept a single `dbx.Expression` (see all available expressions listed above).

You can also use `AndHaving(exp)` or `OrHaving(exp)` to append additional one or more conditions to an existing `HAVING` clause.

```go
app.DB().
    Select("users.*").
    From("users").
    GroupBy("department", "level").
    Having(dbx.NewExp("sum(level) > {:sum}", dbx.Params{ sum: 10 }))
    ...
```

##### `Limit()`

The `Limit(number)` method specifies the `LIMIT` clause of the query.

```go
app.DB().
    Select("users.*").
    From("users").
    Limit(30)
    ...
```

##### `Offset()`

The `Offset(number)` method specifies the `OFFSET` clause of the query. Usually used together with `Limit(number)`.

```go
app.DB().
    Select("users.*").
    From("users").
    Offset(5).
    Limit(30)
    ...
```

## Transaction

To execute multiple queries in a transaction you can use [`app.RunInTransaction(fn)`](https://pkg.go.dev/github.com/pocketbase/pocketbase/core#BaseApp.RunInTransaction).

The DB operations are persisted only if the transaction returns `nil`.

It is safe to nest `RunInTransaction` calls as long as you use the callback's `txApp` argument.

> **Info:** Inside the transaction function always use its `txApp` argument and not the original `app` instance because we allow only a single writer/transaction at a time and it could result in a deadlock.
>
> To avoid performance issues, try to minimize slow/long running tasks such as sending emails, connecting to external services, etc. as part of the transaction.

```go
err := app.RunInTransaction(func(txApp core.App) error {
    // update a record
    record, err := txApp.FindRecordById("articles", "RECORD_ID")
    if err != nil {
        return err
    }
    record.Set("status", "active")
    if err := txApp.Save(record); err != nil {
        return err
    }

    // run a custom raw query (doesn't fire event hooks)
    rawQuery := "DELETE FROM articles WHERE status = 'pending'"
    if _, err := txApp.DB().NewQuery(rawQuery).Execute(); err != nil {
        return err
    }

    return nil
})
```
