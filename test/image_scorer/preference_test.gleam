import gleeunit
import gleeunit/should
import sqlight
import gleam/list
import gleam/result
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
    res
    |> result.is_error()
  })
  |> should.be_false()
}

pub fn save_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  preference.save(conn, 1, 1, 1)
  |> should.be_ok()

  preference.save(conn, 1, 1, 1)
  |> should.be_error()

  preference.save(conn, 1, 2, 1)
  |> should.be_ok()

  preference.save(conn, 2, 2, 1)
  |> should.be_ok()

  preference.save(conn, 2, 2, 1)
  |> should.be_error()

  preference.save(conn, 2, 3, 1)
  |> should.be_ok()

  preference.save(conn, 2, 5, 1)
  |> should.be_ok()
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

  v
  |> list.is_empty()
  |> should.be_false()
}
