import gleeunit
import gleeunit/should
import sqlight
import image_scorer/rating
import gleam/bit_array
import image_scorer/db
import image_scorer/message

pub fn main() {
  gleeunit.main()
}

// pub fn save_test() {
//   use conn <- sqlight.with_connection(":memory:")
//
//   let assert Ok(_) = db.create_tables(conn)
//
//   rating.save(conn, rating.ImageRating("image1", 42))
//   |> should.be_ok()
// }
//
// pub fn process_test() {
//   use conn <- sqlight.with_connection(":memory:")
//
//   let assert Ok(_) = db.create_tables(conn)
//
//   let json =
//     "{\"image\":\"image1\", \"rating\":42}"
//     |> bit_array.from_string()
//
//   rating.process(conn, json, rating.decode_image_rating)
//   |> should.be_ok()
// }
//
// pub fn decode_test() {
//   use conn <- sqlight.with_connection(":memory:")
//
//   let assert Ok(_) = db.create_tables(conn)
//
//   let json =
//     "{\"image\":\"image1\", \"rating\":42}"
//     |> bit_array.from_string()
//
//   rating.decode_image_rating(json)
//   |> should.be_ok()
//   |> should.equal(message.ImageRating("image1", 42))
// }
