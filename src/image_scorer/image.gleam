import sqlight
import gleam/option.{None, Option, Some}
import gleam/dynamic
import gleam/result
import gleam/list
import image_scorer/db
import image_scorer/error

pub type Image {
  Image(id: Int, hash: String, created: String)
  New(hash: String, user_id: Int)
  Id(id: Int)
  Hash(hash: String)
}

pub fn new(conn, hash, user_id) {
  sqlight.query(
    "select id from images where hash = ? and user_id = ?",
    on: conn,
    with: [sqlight.text(hash), sqlight.int(user_id)],
    expecting: dynamic.int,
  )
  |> db.single_int()
}

pub fn get_or_create(conn, hash, user_id) {
  case
    conn
    |> get_by_hash(hash, user_id)
  {
    // Make a new result
    None -> {
      conn
      |> new(hash, user_id)
      conn
      |> get_by_hash(hash, user_id)
    }
    Some(res) -> res
  }
}

pub fn get_by_hash(conn, hash, user_id) {
  sqlight.query(
    "select id from images where hash = ? and user_id = ?",
    on: conn,
    with: [sqlight.text(hash), sqlight.int(user_id)],
    expecting: dynamic.int,
  )
  |> single_image()
}

pub fn single_image(from) -> Result(Option(Image), error.Error) {
  from
  |> result.map(fn(l) {
    l
    |> list.first()
    |> result.map(fn(res) { Some(res) })
    |> result.unwrap(None)
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}
