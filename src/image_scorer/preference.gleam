import gleam/dynamic
// import gleam/json
import sqlight
// import gleam/pair
import gleam/list
import gleam/result
import image_scorer/error
import image_scorer/db
import image_scorer/user

// import image_scorer/error
// import image_scorer/message

pub fn get_user_id_from_hash(conn, hash) {
  sqlight.query(
    "select id form images where hash = ?",
    on: conn,
    with: [sqlight.text(hash)],
    expecting: dynamic.int,
  )
  |> db.single_int()
}

pub type Image {
  Image(file: String, hash: String)
}

pub type Preference {
  Preference(image: Image, others: List(Image))
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

pub fn set_preference(conn, user_hash: String, image: Image, others: List(Image)) {
  let assert Ok(image_id) =
    conn
    |> get_image_id_from_hash(image.hash)

  let assert Ok(user_id) =
    conn
    |> get_user_id_from_hash(user_hash)

  others
  |> list.map(fn(other) {
    conn
    |> get_image_id_from_hash(other.hash)
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
