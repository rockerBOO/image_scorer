import sqlight
import gleam/result
import gleam/list
import gleam/option.{None}
import image_scorer/error

pub fn create_tables(conn) {
  let sql =
    "create table if not exists images_preferences (image_id INTEGER PRIMARY KEY not null, other_id int not null, user_id int not null, rating REAL, created DATETIME);
create table if not exists images (id INTEGER PRIMARY KEY, hash text, name text, created datetime);
create table if not exists user_image (image_id int not null, user_id int not null, created datetime);
create table if not exists users (id INTEGER PRIMARY KEY, hash text, created datetime);
create table if not exists image_scores (id INTEGER PRIMARY KEY, image_id int not null, user_id int not null, score real not null, created datetime);"
  sqlight.exec(sql, conn)
}

pub fn single_int(from: Result(List(Int), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    let assert Ok(res) =
      l
      |> list.first()

    res
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single_float(from: Result(List(Float), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case l |> list.is_empty() {
      True -> None
      False -> l |> list.first() |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single(from: Result(List(_), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    let assert Ok(res) =
      l
      |> list.first()

    res
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn map_error(over: Result(a, sqlight.Error)) -> Result(a, error.Error) {
  over
  |> result.map_error(fn(err) { error.SqlError(err) })
}
