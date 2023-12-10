import gleam/dynamic
import gleam/json
import sqlight
import gleam/io
import image_scorer/error

pub type RatingMessage {
  ImageRating(image: String, rating: Int)
}

pub fn save(
  conn: sqlight.Connection,
  image: String,
  rating: Int,
) -> Result(RatingMessage, error.Error) {
  let sql = "insert into image_scores (image, score) values (?, ?);"
  let insert_id = dynamic.int

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
        Ok(_) -> Ok(ImageRating(image, rating))
        Error(err) -> Error(error.SqlError(err))
      }
    Error(err) -> Error(error.SqlError(err))
  }
}

pub fn process(
  conn: sqlight.Connection,
  json: BitArray,
) -> Result(RatingMessage, error.Error) {
  case decode(json) {
    Ok(ImageRating(image, rating)) -> io.debug(save(conn, image, rating))
    Ok(v) -> {
      io.debug(v)
      Error(error.Invalid)
    }
    Error(err) -> io.debug(Error(error.JsonError(err)))
  }
}

pub fn decode(json: BitArray) -> Result(RatingMessage, json.DecodeError) {
  json.decode_bits(
    from: json,
    using: dynamic.decode2(
      ImageRating,
      dynamic.field("image", of: dynamic.string),
      dynamic.field("rating", of: dynamic.int),
    ),
  )
}
