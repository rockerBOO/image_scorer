import sqlight
import gleam/result
import gleam/list
import gleam/option.{None}
import image_scorer/error

pub fn create_tables(conn) {
  let sql =
    "
create table if not exists images_preferences 
    (
      image_id INTEGER  not null, 
      other_id int not null, 
      user_id int not null, 
      created DATETIME not null,
      foreign key(image_id) references images(id)
      foreign key(user_id) references users(id)
      foreign key(other_id) references images(id)
    );
create unique index if not exists images_preferences_image_id_other_id_user_id on images_preferences (image_id, other_id, user_id);

create table if not exists images 
    (
      id INTEGER PRIMARY KEY, 
      hash text, 
      name text, 
      created datetime not null,
      UNIQUE(hash, name)
    );

create table if not exists user_image 
    (
      image_id int not null, user_id int not null, created datetime not null, 
      foreign key(image_id) references images(id)
    );

create table if not exists users 
    (
      id INTEGER PRIMARY KEY, 
      hash text, 
      created datetime not null
    );

create table if not exists image_scores 
    (
      id INTEGER PRIMARY KEY, 
      image_id int not null, 
      user_id int not null, 
      score real not null, 
      created datetime not null,
      foreign key(user_id) references users(id)
      foreign key(image_id) references image(id)
    );
create unique index if not exists image_scores_image_id_user_id on images_preferences (image_id, other_id);
"
  sqlight.exec(sql, conn)
}

pub fn single_int(from: Result(List(Int), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single_float(from: Result(List(Float), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single(from: Result(List(_), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn map_error(over: Result(a, sqlight.Error)) -> Result(a, error.Error) {
  over
  |> result.map_error(fn(err) { error.SqlError(err) })
}
