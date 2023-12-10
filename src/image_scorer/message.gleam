import gleam/json
import gleam/dynamic

pub type Message {
  Broadcast(String)
  RatingType(String)
}

pub fn decode_type(json: BitArray) -> Result(Message, json.DecodeError) {
  json.decode_bits(
    from: json,
    using: dynamic.decode1(
      RatingType,
      dynamic.field("messageType", dynamic.string),
    ),
  )
}
