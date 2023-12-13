import sqlight
import gleam/result
import gleam/dynamic.{float, int, string}
import gleam/list
import gleam/io
import gleam/option.{None, Some, type Option}
import gleam/int
import gleam/float
import image_scorer/db
import image_scorer/error
import image_scorer/image

pub type ImageScore {
  ImageScore(image_id: Int, user_id: Int, score: Float, created: String)
  NewFromHash(hash: String, score: Float)
  ScoreHash(hash: String, score: Float)
  ImageScores(List(ImageScore))
}

pub fn create(conn, image_id: Int, user_id: Int, score: Float) {
  sqlight.query(
    "insert into image_scores (image_id, user_id, score, created) values (?, ?, ?, DateTime('now'))",
    on: conn,
    with: [sqlight.int(image_id), sqlight.int(user_id), sqlight.float(score)],
    expecting: dynamic.dynamic,
  )
  |> result.map(list.is_empty)
}

pub fn create_from_hash(conn, hash: String, user_id: Int, score: Float) {
  let assert Ok(Some(image.Image(id, _hash, _name, _created))) =
    image.get_or_create(conn, hash, user_id)

  sqlight.query(
    "insert into image_scores (image_id, user_id, score, created) values (?, ?, ?, DateTime('now'))",
    on: conn,
    with: [sqlight.int(id), sqlight.int(user_id), sqlight.float(score)],
    expecting: dynamic.dynamic,
  )
  |> result.map(list.is_empty)
}

pub fn get_image_scores(
  conn: sqlight.Connection,
  image_id: Int,
) -> Result(List(Float), error.Error) {
  sqlight.query(
    "select score from image_scores where image_id = ?",
    conn,
    [sqlight.int(image_id)],
    expecting: dynamic.element(0, dynamic.float),
  )
  |> result.map_error(fn(e) { error.SqlError(e) })
}

/// gets the average score from all scores
pub fn get_image_score(conn, image_id) {
  let assert Ok(scores) = get_image_scores(conn, image_id)
  let length =
    scores
    |> list.length()

  case length {
    0 -> Ok(0.)
    l ->
      scores
      |> float.sum()
      |> float.divide(
        l
        |> int.to_float(),
      )
  }
}

pub fn get_image_score_by_hash(
  conn: sqlight.Connection,
  hash: String,
) -> Result(Option(Float), error.Error) {
  sqlight.query(
    "select score from image_scores join images on (images.id = image_scores.image_id) where images.hash = ?",
    conn,
    [sqlight.text(hash)],
    expecting: dynamic.element(0, dynamic.float),
  )
  |> db.single_float()
}

pub fn get_image_score_for_user(
  conn: sqlight.Connection,
  image_id: Int,
  user_id: Int,
) -> Result(Option(Float), error.Error) {
  sqlight.query(
    "select score from image_scores where image_id = ? and user_id = ?",
    conn,
    [sqlight.int(image_id), sqlight.int(user_id)],
    expecting: dynamic.field("score", dynamic.float),
  )
  |> db.single_float()
}

pub fn get_image_scores_for_user(conn, user_id: Int) {
  sqlight.query(
    "select image_id, user_id, score, created from image_scores where user_id = ?",
    conn,
    [sqlight.int(user_id)],
    expecting: dynamic.decode4(ImageScore, int, int, float, string),
  )
}
