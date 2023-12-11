import gleam/dynamic
import gleam/json
import sqlight
import gleam/io
import gleam/list
import gleam/result
import image_scorer/error
import image_scorer/message

pub type ImageRating {
  ImageRating(image: String, rating: Int)
  Rating(Int)
}

pub fn save(
  conn: sqlight.Connection,
  image_rating: ImageRating,
) -> Result(ImageRating, error.Error) {
  let sql = "insert into image_scores (image, score) values (?, ?);"
  let insert_id = dynamic.int
  let assert ImageRating(image, rating) = image_rating

  io.println("SAVE")
  io.debug(image)
  io.debug(rating)

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(image), sqlight.int(rating)],
      expecting: insert_id,
    )
  {
    Ok(_v) ->
      case sqlight.exec(sql, conn) {
        Ok(_) -> io.debug(Ok(ImageRating(image, rating)))
        Error(err) -> Error(error.SqlError(err))
      }
    Error(err) -> Error(error.SqlError(err))
  }
}

pub fn process(
  conn: sqlight.Connection,
  json: BitArray,
  parse: fn(BitArray) -> Result(message.Rating, json.DecodeError),
) -> Result(ImageRating, error.Error) {
  case parse(json) {
    Ok(message.ImageRating(image, rating)) ->
      save(conn, ImageRating(image, rating))
    Ok(message.Image(image)) -> get(conn, image)
    Error(err) -> Error(error.JsonError(err))
  }
}

pub fn get(
  conn: sqlight.Connection,
  image: String,
) -> Result(ImageRating, error.Error) {
  sqlight.query(
    "select score from image_scores where image = ?",
    conn,
    [sqlight.text(image)],
    expecting: dynamic.int,
  )
  |> result.map_error(fn(e) { io.debug(error.SqlError(e)) })
  |> result.map(fn(v) {
    Rating(
      v
      |> list.last
      |> result.unwrap(-1),
    )
  })
}

pub fn decode_image_rating(
  json: BitArray,
) -> Result(message.Rating, json.DecodeError) {
  io.debug(json)
  json.decode_bits(
    from: json,
    using: dynamic.decode2(
      message.ImageRating,
      dynamic.field("image", of: dynamic.string),
      dynamic.field("rating", of: dynamic.int),
    ),
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
