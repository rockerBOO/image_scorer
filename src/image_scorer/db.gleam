import sqlight
import gleam/result
import gleam/list
import image_scorer/error

pub fn create_tables(conn) {
  let sql =
    "create table if not exists images_preferences (image_id INTEGER PRIMARY KEY, other_id int, user_id int, rating REAL, created DATETIME);
create table if not exists images (id INTEGER PRIMARY KEY, hash text, name text, created datetime);
create table if not exists users (id INTEGER PRIMARY KEY, hash text, created datetime);
create table if not exists image_scores (id INTEGER PRIMARY KEY, image_id int, user_id int, score real, created datetime);"
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

pub fn map_error(over: Result(a, sqlight.Error)) -> Result(a, error.Error) {
  over
  |> result.map_error(fn(err) { error.SqlError(err) })
}
