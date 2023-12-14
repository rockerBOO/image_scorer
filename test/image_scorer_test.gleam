import gleeunit
import gleeunit/should
import gleam/json
import sqlight
import image_scorer/db
import image_scorer

pub fn main() {
  gleeunit.main()
}

pub fn process_get_images_score_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let json_message =
    json.object([
      #("messageType", json.string("get_images_score")),
      #("image_hashes", json.array(["1234"], json.string)),
    ])
    |> image_scorer.encode_bit_array()

  let assert Ok(json_response) =
    image_scorer.process_get_images_score(conn, json_message)

  json_response
  |> json.to_string()
  |> should.equal("{\"messageType\":\"get_image_scores\",\"scores\":[null]}")
}

pub fn process_new_preference_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let json_message =
    json.object([
      #("messageType", json.string("pick_preference")),
      #("image_hash", json.string("1234")),
      #("others", json.array(["1238", "3928"], json.string)),
    ])
    |> image_scorer.encode_bit_array()

  let assert Ok(json_response) =
    image_scorer.process_new_preference(conn, 1, json_message)

  json_response
  |> json.to_string()
  |> should.equal(
    "{\"messageType\":\"pick_preference\",\"results\":[{\"ok\":\"scores saved successfully\"},{\"ok\":\"scores saved successfully\"}]}",
  )
}

pub fn process_get_image_score_test() {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) = db.create_tables(conn)

  let json_message =
    json.object([
      #("messageType", json.string("get_image_score")),
      #("image_hash", json.string("1234")),
    ])
    |> image_scorer.encode_bit_array()

  let assert Ok(json_response) =
    image_scorer.process_get_image_score(conn, json_message)

  json_response
  |> json.to_string()
  |> should.equal(
    "{\"messageType\":\"get_image_score\",\"score\":null}",
  )
}
