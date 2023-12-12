import gleam/dynamic.{decode2, field, int, string}
import gleam/result
import gleam/list
import image_scorer/error
import sqlight

pub type User {
  User(id: Int, hash: String)
  Hash(hash: String)
}

pub fn get_user_from_hash(conn, hash: String) {
  sqlight.query(
    "select user_id, hash from users where hash = ?",
    conn,
    [sqlight.text(hash)],
    expecting: decode2(
      User,
      field("user_id", of: int),
      field("hash", of: string),
    ),
  )
  |> single_user()
}

fn single_user(from: Result(List(User), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    let assert Ok(res) =
      l
      |> list.first()

    res
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}
