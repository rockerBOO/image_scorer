import gleam/json
import sqlight
import glisten/socket

pub type Error {
  JsonError(json.DecodeError)
  SqlError(sqlight.Error)
  BitDecode(String)
  Socket(socket.SocketReason)
  Message(String)
  Invalid
}
