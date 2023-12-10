import gleam/json
import gleam/dynamic

pub type Rating {
  ImageRating(image: String, rating: Int)
  Rating(rating: Int)
  Image(image: String)
}

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
