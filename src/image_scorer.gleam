import mist.{type Connection, type ResponseData}
import gleam/erlang/process
import gleam/bytes_builder
import gleam/bit_array
import gleam/dynamic
import gleam/otp/actor
import gleam/option.{None, Some}
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import gleam/int
import filepath
import gleam/list
import gleam/json.{float, int, null, object, string}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import sqlight
import gleam/erlang
import image_scorer/message
import image_scorer/db
import image_scorer/error
import image_scorer/image_score
import image_scorer/preference
import image_scorer/image

pub type Socket {
  State(conn: sqlight.Connection, user_id: Int)
}

pub fn main() {
  let selector = process.new_selector()
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  use conn <- sqlight.with_connection("ratings.db")
  let assert Ok(_) = db.create_tables(conn)

  let assert Ok(priv) = erlang.priv_directory("image_scorer")

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: fn(_conn) {
              #(State(conn: conn, user_id: 1), Some(selector))
            },
            on_close: fn(_state) { io.println("goodbye!") },
            handler: handle_ws_message,
          )
        ["images", ..rest] -> serve_image(req, rest)
        ["static", ..rest] -> serve_file(req, rest, priv)
        ["form"] -> handle_form(req, conn)
        ["4_preference"] -> serve_file(req, ["4_preference/index.html"], priv)
        ["preference"] -> serve_file(req, ["2_preference/index.html"], priv)
        ["similarity"] -> serve_file(req, ["similarity/index.html"], priv)
        ["ratings"] -> serve_file(req, ["ratings/index.html"], priv)
        ["rate"] -> serve_file(req, ["rate/index.html"], priv)
        ["index"] -> serve_index_file(req, priv)
        ["api", ..rest] -> serve_api(req, conn, rest)
        [] -> serve_index_file(req, priv)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3030)
    |> mist.start_http

  io.println("Hello from image_scorer!")
  process.sleep_forever()
}

fn serve_api(
  _req: Request(Connection),
  _conn: sqlight.Connection,
  path: List(String),
) -> Response(ResponseData) {
  case path {
    ["image", "rate", score_str] -> {
      case int.parse(score_str) {
        Ok(_score) -> {
          // save_rating(conn, image, score)
          response.new(400)
          |> response.set_body(mist.Bytes(bytes_builder.new()))
        }
        Error(_) ->
          response.new(400)
          |> response.set_body(mist.Bytes(bytes_builder.new()))
      }
    }
    _ ->
      response.new(400)
      |> response.set_body(mist.Bytes(bytes_builder.new()))
  }

  let iter =
    ["one", "two", "three"]
    |> iterator.from_list
    |> iterator.map(bytes_builder.from_string)

  response.new(200)
  |> response.set_body(mist.Chunked(iter))
  |> response.set_header("content-type", "text/plain")
}

/// {messageType: "rate", image_hash: "91jdoks", score: 1}
fn process_new_score(conn, user_id, json) {
  let new_rating_decoder =
    dynamic.decode2(
      image_score.NewFromHash,
      dynamic.field("image_hash", dynamic.string),
      dynamic.field(
        "score",
        dynamic.any([
          dynamic.float,
          fn(x) {
            dynamic.int(x)
            |> result.map(fn(i) { int.to_float(i) })
          },
        ]),
      ),
    )

  let assert Ok(image_score.NewFromHash(hash, score)) =
    json.decode_bits(json, new_rating_decoder)

  // io.debug(hash)
  // io.debug(user_id)
  // io.debug(score)

  let assert Ok(_) = image_score.create_from_hash(conn, hash, user_id, score)

  let assert Ok(id_result) = image.get_id_by_hash(conn, hash)

  case
    id_result
    |> option.map(fn(id) { image_score.get_image_score(conn, id) })
  {
    Some(Ok(score)) ->
      Ok(
        object([
          #("messageType", string("get_image_score")),
          #("score", float(score)),
        ]),
      )
    Some(Error(error)) -> {
      io.println("Error getting score")
      io.debug(error)
      Error(error.Message("Error getting score"))
    }
    None ->
      Ok(
        object([
          #("messageType", string("get_image_score")),
          #("error", string("Could not make the result")),
        ]),
      )
  }
  // case image_score.get_image_score(conn, hash) {
  //   Ok(Some(score)) ->
  //     Ok(
  //       object([
  //         #("messageType", string("get_image_score")),
  //         #("score", float(score)),
  //       ]),
  //     )
  //   Ok(None) ->
  //     Ok(
  //       object([
  //         #("messageType", string("get_image_score")),
  //         #("error", string("No image to score")),
  //       ]),
  //     )
  //   Error(e) -> {
  //     io.debug(e)
  //     Ok(
  //       object([
  //         #("messageType", string("get_image_score")),
  //         #("error", string("Could not make the result")),
  //       ]),
  //     )
  //   }
  // }
}

/// {messageType: "prefer", image_hash: "91jdoks", others: [{ image_hash: "" }]}
pub fn process_new_preference(
  conn,
  user_id,
  json_bits,
) -> Result(json.Json, error.Error) {
  let decoder =
    dynamic.decode2(
      preference.NewFromHash,
      dynamic.field("image_hash", dynamic.string),
      dynamic.field("others", dynamic.list(dynamic.string)),
    )

  let assert Ok(preference.NewFromHash(hash, others)) =
    json.decode_bits(json_bits, decoder)

  let assert results =
    preference.save_by_hash(conn, hash, others, user_id)
    |> list.map(fn(res) {
      res
      |> result.map(fn(_v) {
        object([#("ok", string("scores saved successfully"))])
      })
      |> result.map_error(fn(_v) {
        object([#("ok", string("failed to save preference"))])
      })
    })
    |> list.map(fn(res) {
      res
      |> result.unwrap_both()
    })

  Ok(
    object([
      #("messageType", string("pick_preference")),
      #("results", json.preprocessed_array(results)),
    ]),
  )
  // case x {
  //   Ok(v) ->
  //     Ok(object([
  //       #("messageType", string("pick_preference")),
  //       #("ok", string("scores saved successfully")),
  //     ]))
  //   Error(e) -> {
  //     io.debug(e)
  //     Ok(object([
  //       #("messageType", string("get_image_score")),
  //       #("error", string("could not save the score")),
  //     ]))
  //   }
  // }
}

pub fn process_get_image_score(conn, json) -> Result(json.Json, error.Error) {
  let assert Ok(hash) =
    json
    |> json.decode_bits(dynamic.field("image_hash", dynamic.string))

  let assert Ok(image) = image.get_by_hash(conn, hash)

  let result = case image {
    Some(image.Image(id, _hash, _name, _created)) ->
      case image_score.get_image_score(conn, id) {
        Ok(0.0) -> None
        Ok(v) ->
          Some(
            v
            |> io.debug(),
          )
        Error(e) -> {
          io.debug(e)
          None
        }
      }
    Some(image.Hash(_)) -> None
    Some(image.Id(_)) -> None
    Some(image.New(_, _)) -> None
    Some(image.UserImage(_, _, _, _)) -> None
    None -> None
  }

  case result {
    Some(score) ->
      Ok(
        object([
          #("messageType", string("get_image_score")),
          #("score", float(score)),
        ]),
      )
    None ->
      Ok(
        object([#("messageType", string("get_image_score")), #("score", null())]),
      )
  }
}

// { messageType: "get_image_scores", image_hashes: ["91839d93"] }
pub fn process_get_images_score(conn, json) -> Result(json.Json, error.Error) {
  let decoder = dynamic.field("image_hashes", dynamic.list(dynamic.string))

  let assert Ok(hashes) = json.decode_bits(json, decoder)
  let image_scores =
    hashes
    |> list.map(fn(hash) { image_score.get_image_score_by_hash(conn, hash) })

  // |> result.unwrap(None)
  // let scores =
  //   image_scores
  //   |> list.filter(option.is_some)
  //   |> list.map(fn(v) {
  //     v
  //     |> option.unwrap(-1.0)
  //   })

  let scores =
    image_scores
    |> list.map(fn(res) {
      res
      |> result.map(fn(opt) {
        case opt {
          Some(v) -> json.float(v)
          None -> json.null()
        }
      })
      |> result.map_error(fn(e) {
        io.debug(e)
        json.null()
      })
      |> result.unwrap(json.null())
    })

  // io.debug(scores)
  Ok(
    object([
      #("messageType", string("get_image_scores")),
      #("scores", json.preprocessed_array(scores)),
    ]),
  )
  // Ok(object([
  //   #("messageType", string("get_image_scores")),
  //   #("scores", string("hi")),
  // ]))
}

// fn process_get_image_scores_for_user(
//   conn,
//   user_id,
//   json,
// ) -> Result(json.Json, error.Error) {
//   todo
// }

fn handle_error(
  err: Result(_, error.Error),
  send: fn(json.Json) -> Result(_, error.Error),
) -> Result(_, Nil) {
  err
  |> result.map_error(fn(err) {
    io.debug(err)
    let assert Ok(_) =
      object([
        #("message_type", string("prefer")),
        #("error", string("could not process")),
      ])
      |> send()
    err
  })
  |> result.nil_error()
}

fn handle_response(resp, send: fn(json.Json) -> Result(_, error.Error)) {
  io.println("HANDLE RESPONSE")
  resp
  |> result.then(fn(json) {
    let assert Ok(_) =
      json
      |> send()
  })
  |> handle_error(send)
}

fn handle_json_message(
  state: Socket,
  send: fn(json.Json) -> Result(Nil, error.Error),
  json: BitArray,
) {
  case message.decode_type(json) {
    Ok(message.RatingType("place_score")) ->
      process_new_score(state.conn, state.user_id, json)
      |> handle_response(send)

    Ok(message.RatingType("pick_preference")) ->
      process_new_preference(state.conn, state.user_id, json)
      |> handle_response(send)

    Ok(message.RatingType("get_images_score")) ->
      process_get_images_score(state.conn, json)
      |> handle_response(send)

    Ok(message.RatingType("get_image_score")) ->
      process_get_image_score(state.conn, json)
      |> handle_response(send)
    Ok(message.Broadcast(broadcast)) -> {
      io.debug(broadcast)
      let assert Ok(_) =
        send(
          object([
            #("message_type", string("broadcast")),
            #("error", string("invalid")),
          ]),
        )
      Error(Nil)
    }
    Ok(message.PreferenceType(preference_type)) -> {
      io.debug(preference_type)
      let assert Ok(_) =
        send(
          object([
            #("message_type", string("preference_type")),
            #("error", string("invalid")),
          ]),
        )
      Ok(Nil)
    }
    Ok(message.RatingType(rating)) -> {
      io.debug(rating)
      let assert Ok(_) =
        send(
          object([
            #("message_type", string("rating_type")),
            #("error", string("invalid")),
          ]),
        )
      Ok(Nil)
    }

    // Ok(message.RatingType("get_score")) ->
    //   process_new_preference(state.conn, json)
    //   |> handle_response(send)
    //
    // Ok(message.RatingType("get_image_scores")) ->
    //   process_new_preference(state.conn, json)
    //   |> handle_response(send)
    //
    // Ok(message.RatingType("get_image_scores_for_user")) ->
    //   process_new_preference(state.conn, state.user_id, json)
    //   |> handle_response(send)
    Error(error) -> {
      io.println("Unhandled")
      io.debug(error)
      let assert Ok(_) =
        send(
          object([
            #("message_type", string("unhandled")),
            #("error", string("invalid")),
          ]),
        )
      Error(Nil)
    }
  }
}

pub fn encode_bit_array(json_input: json.Json) -> BitArray {
  bit_array.from_string(json.to_string(json_input))
}

fn handle_ws_message(state: Socket, conn, message) {
  let send = fn(message: json.Json) -> Result(_, error.Error) {
    function.curry2(mist.send_binary_frame)(conn)(
      message
      |> encode_bit_array,
    )
    |> result.map_error(fn(e) { error.Socket(e) })
  }
  case message {
    mist.Text(<<"ping":utf8>>) -> {
      let assert Ok(_) = send(object([#("message_type", string("pong"))]))
      actor.continue(state)
    }
    mist.Custom(message.Broadcast(text)) -> {
      let assert Ok(_) =
        send(
          object([
            #("message_type", string("broadcast")),
            #("text", string(text)),
          ]),
        )
      actor.continue(state)
    }
    mist.Custom(message.PreferenceType(_)) -> {
      io.println("Unhandled preference type")
      actor.continue(state)
    }
    mist.Custom(message.RatingType(_)) -> {
      io.println("Unhandled rating type")
      actor.continue(state)
    }
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)

    mist.Binary(json) -> {
      let assert Ok(_) = handle_json_message(state, send, json)
      actor.continue(state)
    }
    mist.Text(_) | mist.Binary(_) -> {
      let assert Ok(_) =
        send(object([#("message_type", string("text AND binary?"))]))
      actor.continue(state)
    }
  }
}

fn serve_image(
  _req: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  let filepath =
    list.append(["images"], path)
    |> list.fold("", filepath.join)
  mist.send_file(filepath, offset: 0, limit: None)
  |> result.map(fn(file) {
    response.new(200)
    |> response.prepend_header("content-type", guess_content_type(filepath))
    |> response.set_body(file)
  })
  |> result.lazy_unwrap(fn() {
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn serve_file(
  _req: Request(Connection),
  path: List(String),
  priv: String,
) -> Response(ResponseData) {
  let requested_file =
    list.concat([[priv], path])
    |> list.fold("", filepath.join)
  mist.send_file(string.concat(["/", requested_file]), offset: 0, limit: None)
  |> result.map(fn(file) {
    let content_type = guess_content_type(requested_file)
    response.new(200)
    |> response.prepend_header("content-type", content_type)
    |> response.set_body(file)
  })
  |> result.lazy_unwrap(fn() {
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn serve_index_file(
  _req: Request(Connection),
  priv: String,
) -> Response(ResponseData) {
  let index = filepath.join(priv, "scores/index.html")
  // Omitting validation for brevity
  mist.send_file(index, offset: 0, limit: None)
  |> result.map(fn(file) {
    response.new(200)
    |> response.prepend_header("content-type", "text/html")
    |> response.set_body(file)
  })
  |> result.lazy_unwrap(fn() {
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn handle_form(
  req: Request(Connection),
  _conn: sqlight.Connection,
) -> Response(ResponseData) {
  let _req = mist.read_body(req, 1024 * 1024 * 30)
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.new()))
}

fn guess_content_type(path: String) -> String {
  case
    string.split(path, ".")
    |> list.last
  {
    Ok("html") -> "text/html"
    Ok("jpg") -> "image/jpeg"
    Ok("png") -> "image/png"
    Ok("webp") -> "image/webp"
    Ok("css") -> "text/css"
    Ok("js") -> "text/javascript"
    Ok("json") -> "application/json"
    Ok(unhandled) -> {
      io.println_error("Unhandled content type " <> unhandled)
      "application/octet-stream"
    }
    Error(_e) -> "application/octet-stream"
  }
}
