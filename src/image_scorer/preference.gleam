import gleam/dynamic
// import gleam/json
import sqlight
// import gleam/pair
import gleam/list
import gleam/result
import image_scorer/error
import image_scorer/db


pub type Preference {
  NewFromHash(hash: String, others: List(String))
}

pub fn get_user_id_from_hash(conn, hash) {
  sqlight.query(
    "select id form images where hash = ?",
    on: conn,
    with: [sqlight.text(hash)],
    expecting: dynamic.int,
  )
  |> db.single_int()
}

pub fn get_image_id_from_hash(conn, hash) -> Result(Int, error.Error) {
  sqlight.query(
    "select id form images where hash = ?",
    on: conn,
    with: [sqlight.text(hash)],
    expecting: dynamic.field("id", of: dynamic.int),
  )
  |> db.single_int()
}

pub fn save_by_hash(
  conn,
  user_id: Int,
  image_hash: String,
  others: List(String),
) {
  let assert Ok(image_id) =
    conn
    |> get_image_id_from_hash(image_hash)

  others
  |> list.map(fn(other_hash) {
    conn
    |> get_image_id_from_hash(other_hash)
  })
  |> list.map(fn(id) {
    id
    |> result.map(fn(other_id) {
      sqlight.query(
        "insert into images_preference (image_id, other_id, user_id, rating, created) values (?, ?, ?, ?, ?);",
        on: conn,
        with: [
          sqlight.int(image_id),
          sqlight.int(other_id),
          sqlight.int(user_id),
          sqlight.text("now()"),
        ],
        expecting: dynamic.int,
      )
      |> db.map_error()
    })
  })
  |> result.all()
}
