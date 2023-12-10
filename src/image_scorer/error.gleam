import gleam/json
import sqlight

pub type Error {
  JsonError(json.DecodeError)
  SqlError(sqlight.Error)
  Invalid
}
