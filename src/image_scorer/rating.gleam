// import gleam/dynamic.{decode2, field, int, list, string}
// import gleam/json
// import gleam/option.{Some}
// import sqlight
// import gleam/result
// import image_scorer/error
// import image_scorer/message
// import image_scorer/db
// import image_scorer/image

// pub type ImageRating {
//   ImageRating(id: Int, user_id: Int, hash: String, rating: Int, created: String)
  // New(hash: String, user_id: Int, rating: Int)
  // Rating(Int)
  // Image(String)
  // UserRating(image_id: Int, rating: Int)
// }
//
// pub fn new(conn, image_id: Int, user_id: Int, score: Int) {
//   sqlight.query(
//     "insert into image_score (image_id, user_id, score, created) values (?, ?, ?, now())",
//     on: conn,
//     with: [sqlight.int(image_id), sqlight.int(user_id), sqlight.int(score)],
//     expecting: dynamic.int,
//   ) |> db.single_int()
// }

// pub fn save(conn: sqlight.Connection, image_rating: ImageRating) {
//   let assert Ok(Some(image.Image(image_id, hash, name, created))) = image.get_by_hash(conn, image_rating.hash)
//   sqlight.query(
//     "insert into image_scores (image_id, user_id, score, created) values (?, ?, now());",
//     on: conn,
//     with: [
//       sqlight.int(image_id),
//       sqlight.int(user_image.user_id),
//       sqlight.int(image_rating.rating),
//     ],
//     expecting: dynamic.int,
//   )
// }



// pub fn process(
//   conn: sqlight.Connection,
//   json: BitArray,
//   parse: fn(BitArray) -> Result(message.Rating, json.DecodeError),
// ) -> Result(ImageRating, error.Error) {
//   case parse(json) {
//     Ok(message.ImageRating(image, rating)) ->
//       save(conn, ImageRating(image, rating))
//     Error(err) -> Error(error.JsonError(err))
//   }
// }


// pub fn decode_image_rating(
//   json: BitArray,
// ) -> Result(message.Rating, json.DecodeError) {
//   json.decode_bits(
//     from: json,
//     using: dynamic.decode2(
//       message.ImageRating,
//       dynamic.field("image", of: dynamic.string),
//       dynamic.field("rating", of: dynamic.int),
//     ),
//   )
// }
//
// pub fn decode_images(
//   json: BitArray,
// ) -> Result(List(ImageRating), json.DecodeError) {
//   json.decode_bits(
//     from: json,
//     using: list(decode2(
//       ImageRating,
//       field("image", of: string),
//       field("rating", of: int),
//     )),
//   )
// }
//
// pub fn decode_image(json: BitArray) -> Result(message.Rating, json.DecodeError) {
//   json.decode_bits(
//     from: json,
//     using: dynamic.decode1(
//       message.Image,
//       dynamic.field("image", of: dynamic.string),
//     ),
//   )
// }
