import sqlight
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{decode4, element, int, string}
import gleam/result
import gleam/list
import gleam/io
import image_scorer/error

/// images:
/// id int (primary)
/// user_id int
/// hash text
/// name text
/// created datetime
///
/// user_image
/// image_id int
/// user_id int
pub type Image {
  Image(id: Int, hash: String, name: String, created: String)
  UserImage(id: Int, user_id: Int, hash: String, created: String)
  New(hash: String, user_id: Int)
  Id(id: Int)
  Hash(hash: String)
}

pub fn create(conn, hash: String, user_id: Int) {
  sqlight.query(
    "insert into images (hash, name, created) values (?, ?,  DateTime('now'));",
    on: conn,
    with: [sqlight.text(hash), sqlight.int(user_id)],
    expecting: decode4(
      Image,
      element(0, int),
      element(1, string),
      element(2, string),
      element(3, string),
    ),
  )
  |> result.map(fn(l) {
    l
    |> list.is_empty()
  })
  |> result.unwrap(False)
}

pub fn get_all_by_user(conn, user_id) {
  sqlight.query(
    "select images.id, images.hash, images.created from images join user_image on (user_image.image_id = images.id) where user_image.id = ?",
    on: conn,
    with: [sqlight.int(user_id)],
    expecting: decode4(
      Image,
      element(0, int),
      element(1, string),
      element(2, string),
      element(3, string),
    ),
  )
}

pub fn start_transaction(conn) {
  "BEGIN TRANSACTION;"
  |> sqlight.exec(conn)
}

pub fn commit(conn) {
  "COMMIT;"
  |> sqlight.exec(conn)
}

pub fn rollback(conn) {
  "ROLLBACK;"
  |> sqlight.exec(conn)
}

pub fn get_or_create(conn, hash, user_id) -> Result(Option(Image), error.Error) {
  case
    conn
    |> get_by_hash(hash)
  {
    Ok(None) -> {
      case
        conn
        |> create(hash, user_id)
      {
        True -> {
          let assert Ok(v) =
            conn
            |> get_by_hash(hash)
          Ok(v)
        }

        False -> {
          Error(error.Message("Could not create Image"))
        }
      }
    }
    Ok(res) -> Ok(res)
    Error(error) -> Error(error)
  }
}

pub fn get_by_hash(conn, hash) -> Result(Option(Image), error.Error) {
  sqlight.query(
    "select id, hash, name, created from images where hash = ?;",
    on: conn,
    with: [sqlight.text(hash)],
    expecting: decode4(
      Image,
      element(0, int),
      element(1, string),
      element(2, string),
      element(3, string),
    ),
  )
  |> single_image()
}

pub fn single_image(from) {
  from
  |> result.map(fn(result_list) {
    result_list
    |> list.first()
    |> option.from_result()
  })
  |> result.map_error(fn(e) { error.SqlError(e) })
}
