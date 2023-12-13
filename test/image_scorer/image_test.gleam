import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import sqlight
import gleam/io
import image_scorer/db
import image_scorer/image

pub fn main() {
  gleeunit.main()
}

pub fn image_get_or_create_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(Some(_)) =
    conn
    |> image.get_or_create("1234", 1)
}

pub fn create_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let assert True = image.create(conn, "1234", 1)
}

pub fn get_by_hash_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)
  let assert True = image.create(conn, "1234", 1)
  let assert Ok(Some(_)) = image.get_by_hash(conn, "1234")
}

pub fn single_image_test() {
  let assert Ok(Some(image.Image(id, hash, name, created))) =
    Ok([image.Image(1, "abc", "1234", "2023")])
    |> image.single_image()

  id
  |> should.equal(1)
  hash
  |> should.equal("abc")
  name
  |> should.equal("1234")
  created
  |> should.equal("2023")
}

pub fn single_image_test2() {
  let assert Ok(Some(image.Image(id, _hash, _name, _created))) =
    Ok([
      image.Image(1, "abc", "1234", "2023"),
      image.Image(2, "def", "5678", "2023"),
    ])
    |> image.single_image()

  id
  |> should.equal(1)
}

pub fn single_image_test4() {
  let assert Error(_) =
    Ok([image.Image(1, "abc", "", "2023")])
    |> image.single_image()
}

pub fn single_image_test5() {
  let assert Ok(None) = image.single_image(Ok([]))
}
