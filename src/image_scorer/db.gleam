import sqlight
import gleam/erlang
import gleam/result
import gleam/list
import gleam/option.{None}
import image_scorer/error
import migrant

pub fn create_tables(conn) {
  let assert Ok(priv_directory) = erlang.priv_directory("image_scorer")
  let assert Ok(_) = migrant.migrate(conn, priv_directory <> "/migrations")
}

pub fn single_int(from: Result(List(Int), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single_float(from: Result(List(Float), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn single(from: Result(List(_), sqlight.Error)) {
  from
  |> result.map(fn(l) {
    case
      l
      |> list.is_empty()
    {
      True -> None
      False ->
        l
        |> list.first()
        |> option.from_result()
    }
  })
  |> result.map_error(fn(err) { error.SqlError(err) })
}

pub fn map_error(over: Result(a, sqlight.Error)) -> Result(a, error.Error) {
  over
  |> result.map_error(fn(err) { error.SqlError(err) })
}
