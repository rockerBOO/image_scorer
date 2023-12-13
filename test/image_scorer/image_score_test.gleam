import gleeunit
import gleeunit/should
import sqlight
import gleam/list
import gleam/option.{None, Some}
import image_scorer/db
import image_scorer/image_score

pub fn main() {
  gleeunit.main()
}

pub fn create_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(_) = image_score.create(conn, 1, 1, 9.0)
}

pub fn create_from_hash_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 9.0)
}

pub fn get_image_scores_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(v) = image_score.get_image_scores(conn, 1)

  v
  |> list.length()
  |> should.equal(0)

  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 9.0)
  let assert Ok(v) = image_score.get_image_scores(conn, 1)

  v
  |> list.length()
  |> should.equal(1)
}

pub fn get_image_score_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(v) = image_score.get_image_score(conn, 1)

  v
  |> should.equal(0.0)

  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 9.0)
  let assert Ok(v) = image_score.get_image_score(conn, 1)

  v
  |> should.equal(9.0)

  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 10.0)
  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 2.0)
  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 4.0)

  let assert Ok(v) = image_score.get_image_score(conn, 1)
  v
  |> should.equal(6.25)
}

pub fn get_image_score_by_hash_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(None) = image_score.get_image_score_by_hash(conn, "1234")

  let assert Ok(_) = image_score.create_from_hash(conn, "1234", 1, 9.0)
  let assert Ok(Some(v)) = image_score.get_image_score_by_hash(conn, "1234")

  v
  |> should.equal(9.0)
}
