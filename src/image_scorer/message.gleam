import gleam/json
import image_scorer/preference
import gleam/dynamic

pub type Rating {
  ImageRating(image: String, rating: Int)
  Rating(rating: Int)
  Image(image: String)
}

pub type Prefer {
  Prefer(user_hash: String, image: preference.Image, others: List(preference.Image))
}

pub type Message {
  Broadcast(String)
  RatingType(String)
  PreferenceType(String)
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
