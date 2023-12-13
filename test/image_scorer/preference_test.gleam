import gleeunit
import gleeunit/should
import sqlight
import gleam/list
import gleam/result
import gleam/io
import image_scorer/db
import image_scorer/preference

pub fn main() {
  gleeunit.main()
}

pub fn save_by_hash_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let user_id = 1

  preference.save_by_hash(conn, "1234", ["2345", "2942", "2492"], user_id)
  |> list.any(fn(res) {
    io.debug(res)
    |> result.is_error()
  })
  |> should.be_false()
}

pub fn get_by_hash_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let user_id = 1

  let assert Ok(v) = preference.get_by_hash(conn, "1234", user_id)

  v
  |> list.is_empty()
  |> should.be_true()

  preference.save_by_hash(conn, "1234", ["2345", "2942", "2492"], user_id)
  |> list.any(fn(res) {
    res
    |> result.is_error()
  })
  |> should.be_false()

  let assert Ok(v) = preference.get_by_hash(conn, "1234", user_id)
  io.debug(v)
}
