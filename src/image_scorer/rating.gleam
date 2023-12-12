import gleam/dynamic.{decode2, field, int, list, string}
import gleam/json
import sqlight
import gleam/result
import image_scorer/error
import image_scorer/message
import image_scorer/db
import image_scorer/image

pub type ImageRating {
  ImageRating(id: Int, user_id: Int, hash: String, rating: Int, created: String)
  New(hash: String, user_id: Int, rating: Int)
  Rating(Int)
  Image(String)
  UserRating(image_id: Int, rating: Int)
}

pub fn save(conn: sqlight.Connection, image_rating: ImageRating) {
  let assert Ok(Image(image)) = image.get_by_hash(image_rating.hash)
  sqlight.query(
    "insert into image_scores (image_id, user_id, score, created) values (?, ?, now());",
    on: conn,
    with: [
      sqlight.int(image_rating.hash),
      sqlight.int(image_rating.user_id),
      sqlight.int(image_rating.rating),
    ],
    expecting: dynamic.int,
  )
}

pub fn process(
  conn: sqlight.Connection,
  json: BitArray,
  parse: fn(BitArray) -> Result(message.Rating, json.DecodeError),
) -> Result(ImageRating, error.Error) {
  case parse(json) {
    Ok(message.ImageRating(image, rating)) ->
      save(conn, ImageRating(image, rating))
    Error(err) -> Error(error.JsonError(err))
  }
}

pub fn get_score(
  conn: sqlight.Connection,
  image: String,
) -> Result(Int, error.Error) {
  sqlight.query(
    "select score from image_scores where image = ?",
    conn,
    [sqlight.text(image)],
    expecting: dynamic.field("score", dynamic.int),
  )
  |> db.single_int()
}

pub fn get_ratings_for_user(
  conn: sqlight.Connection,
  user_id: Int,
) -> Result(List(ImageRating), error.Error) {
  let assert Ok(user_ratings) =
    sqlight.query(
      "select image_id, score from image_scores where user_id = ?",
      conn,
      [sqlight.int(user_id)],
      expecting: dynamic.decode3(
        UserRating,
        dynamic.field("image_id", int),
        dynamic.field("score", int),
      ),
    )
    |> result.map(fn(res) {
      res
      |> list.map(fn(user_rating) {
        sqlight.query(
          "select hash from images where id = ?",
          conn,
          [sqlight.int(user_rating.image_id)],
          expecting: dynamic.decode1(Image, dynamic.field("id", int)),
        )
        |> list.fold(
          res,
          fn(b, a) { ImageRating(b.image_id, a.hash, b.rating) },
        )
      })
    })
  // let assert Ok(image) = |> result.map_error(fn(e) { error.SqlError(e) })
}

pub fn decode_image_rating(
  json: BitArray,
) -> Result(message.Rating, json.DecodeError) {
  json.decode_bits(
    from: json,
    using: dynamic.decode2(
      message.ImageRating,
      dynamic.field("image", of: dynamic.string),
      dynamic.field("rating", of: dynamic.int),
    ),
  )
}

pub fn decode_images(
  json: BitArray,
) -> Result(List(ImageRating), json.DecodeError) {
  json.decode_bits(
    from: json,
    using: list(decode2(
      ImageRating,
      field("image", of: string),
      field("rating", of: int),
    )),
  )
}

pub fn decode_image(json: BitArray) -> Result(message.Rating, json.DecodeError) {
  json.decode_bits(
    from: json,
    using: dynamic.decode1(
      message.Image,
      dynamic.field("image", of: dynamic.string),
    ),
  )
}
