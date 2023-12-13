import gleam/dynamic
import gleam/option.{Some}
import gleam/list
import gleam/result
import sqlight
import image_scorer/image

pub type Preference {
  Preference(image_id: Int, other_id: Int, user_id: Int, created: String)
  NewFromHash(hash: String, others: List(String))
}

pub fn get_by_hash(conn, hash, user_id) {
  sqlight.query(
    "select image_id, other_id from images_preferences join images on (images.id = images_preferences.image_id) where images.hash = ? and images_preferences.user_id = ?",
    on: conn,
    with: [sqlight.text(hash), sqlight.int(user_id)],
    expecting: dynamic.tuple2(dynamic.int, dynamic.int),
  )
}

pub fn save(conn, image_id, other_id, user_id) {
  sqlight.query(
    "insert into images_preferences (image_id, other_id, user_id, created) values (?, ?, ?, datetime('now'));",
    on: conn,
    with: [sqlight.int(image_id), sqlight.int(other_id), sqlight.int(user_id)],
    expecting: dynamic.decode4(
      Preference,
      dynamic.element(0, dynamic.int),
      dynamic.element(1, dynamic.int),
      dynamic.element(2, dynamic.int),
      dynamic.element(3, dynamic.string),
    ),
  )
  |> result.map(fn(v) {
    v
    |> list.first()
    |> option.from_result()
  })
}

pub fn save_by_hash(
  conn,
  image_hash: String,
  others_hashes: List(String),
  user_id: Int,
) {
  let assert Ok(Some(image.Image(image_id, _hash, _name, _created))) =
    image.get_or_create_by_hash(conn, image_hash, user_id)

  let others =
    others_hashes
    |> list.map(fn(hash) { image.get_or_create_by_hash(conn, hash, user_id) })

  others
  |> list.map(fn(other) {
    let assert Ok(Some(image.Image(other_id, _hash, _name, _created))) = other

    save(conn, image_id, other_id, user_id)
  })
}
