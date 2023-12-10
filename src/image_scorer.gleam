import mist.{type Connection, type ResponseData}
import gleam/erlang/process
import gleam/bytes_builder
import gleam/otp/actor
import gleam/option.{None, Some}
import gleam/iterator
import gleam/result
import gleam/string
import gleam/int
import filepath
import gleam/list
import gleam/json.{string}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import sqlight
import gleam/erlang
import image_scorer/rating
import image_scorer/message

pub type Socket {
  State(sql_conn: sqlight.Connection)
}

pub fn main() {
  let selector = process.new_selector()
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  use conn <- sqlight.with_connection(":memory:")
  // let image_scores_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  let sql =
    "
  create table image_scores (image text, score int);

  -- insert into image_scores (image, score) values 
  -- ('abc.jpg', 3),
  -- ('b.jpg', 9),
  -- ('c.jpg', 6);
  "
  let assert Ok(Nil) = sqlight.exec(sql, conn)

  // let sql =
  //   "
  // select image, score from image_scores
  // where score > ?
  // "
  // let assert Ok([#("b.jpg", 9), #("c.jpg", 6)]) =
  //   sqlight.query(
  //     sql,
  //     on: conn,
  //     with: [sqlight.int(5)],
  //     expecting: image_scores_decoder,
  //   )

  let assert Ok(priv) = erlang.priv_directory("image_scorer")

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: fn(_conn) { #(State(sql_conn: conn), Some(selector)) },
            on_close: fn(_state) { io.println("goodbye!") },
            handler: handle_ws_message,
          )
        // ["echo"] -> echo_body(req)
        // ["chunk"] -> serve_chunk(req)
        ["images", ..rest] -> serve_image(req, rest)
        ["static", ..rest] -> serve_file(req, rest, priv)
        ["form"] -> handle_form(req, conn)
        ["index.html"] -> serve_index_file(req, priv)
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


fn handle_ws_message(state: Socket, conn, message) {
  case message {
    mist.Text(<<"ping":utf8>>) -> {
      let assert Ok(_) = mist.send_binary_frame(conn, <<"pong":utf8>>)
      actor.continue(state)
    }
    mist.Binary(json) -> {
      case message.decode_type(json) {
        Ok(message.RatingType("rating")) -> {
          case rating.process(state.sql_conn, json) {
            Ok(rating.ImageRating(image, _rating)) -> {
              io.debug(image)
              let assert Ok(_) = mist.send_binary_frame(conn, <<image:utf8>>)
            }
            Error(error) -> {
              io.debug(error)
              let assert Ok(_) = mist.send_binary_frame(conn, <<"ERROR":utf8>>)
            }
          }
        }
        Error(error) -> {
          io.debug(error)
          let assert Ok(_) = mist.send_binary_frame(conn, <<"ERROR":utf8>>)
        }
      }

      actor.continue(state)
    }
    mist.Text(_) | mist.Binary(_) -> {
      let assert Ok(_) =
        mist.send_binary_frame(conn, <<"text AND binary?":utf8>>)
      actor.continue(state)
    }
    mist.Custom(message.Broadcast(text)) -> {
      let assert Ok(_) = mist.send_binary_frame(conn, <<text:utf8>>)
      actor.continue(state)
    }
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn serve_image(
  _req: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  mist.send_file(
    list.append(["images"], path)
    |> list.fold("", filepath.join),
    offset: 0,
    limit: None,
  )
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
  let index = filepath.join(priv, "index.html")
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
    Error(_e) -> "application/octet-stream"
  }
}
