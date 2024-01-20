# Dataset

Check image_scorer/db.gleam for up-to-date information about the DB.

## `images_preferences`

```
image_id INTEGER  not null,
other_id int not null,
user_id int not null,
created DATETIME not null,
```

## `images`

```
id INTEGER PRIMARY KEY,
hash text,
name text,
created datetime not null,
```

## `user_image`

```
image_id int not null, user_id int not null, created datetime not null,
```

## `users`

```
id INTEGER PRIMARY KEY,
hash text,
created datetime not null
```

## `images_scores`

```
id INTEGER PRIMARY KEY,
image_id int not null,
user_id int not null,
score real not null,
created datetime not null,
```
