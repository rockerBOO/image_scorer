export function debounce(callback, delay) {
  let timeout;
  return function () {
    clearTimeout(timeout);
    timeout = setTimeout(callback, delay);
  };
}

export function shuffle(array) {
  let currentIndex = array.length,
    randomIndex;

  // While there remain elements to shuffle.
  while (currentIndex > 0) {
    // Pick a remaining element.
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    // And swap it with the current element.
    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex],
      array[currentIndex],
    ];
  }

  return array;
}

export function encode(message) {
  return new Blob([JSON.stringify(message, null, 2)], {
    type: "application/json",
  });
}

export async function decode(data) {
  return JSON.parse(await data.text());
}

// WebSocket
//
let websocket;
let wsBackoffRate = 1000;
let wsBackoffTotal = 0;
let wsBackoffCeil = 10_000;

export function connected() {
  return websocket && websocket.readyState == 1;
}

export async function send(v) {
  return websocket.send(v);
}

export function ws() {
  return websocket;
}

async function connect() {
  return new Promise((resolve) => {
    websocket = new WebSocket("ws://localhost:3030/ws");

    websocket.addEventListener("open", () => {
      websocket.send("Hello Server!");
      resolve(ws);
    });

    // ws.addEventListener("message", async (event) => {
    //   console.log("Message from server ", await decode(event.data));
    // });

    websocket.onclose = function (e) {
      console.log(
        "Socket is closed. Reconnect will be attempted in 1 second.",
        e.reason,
      );
      const start = Date.now();
      setTimeout(function () {
        const end = Date.now();
        if (wsBackoffTotal <= wsBackoffCeil) {
          wsBackoffTotal += (end - start) * wsBackoffRate;
        }
        return connect();
      }, Math.log(wsBackoffTotal));
    };

    websocket.onerror = function (err) {
      console.error("Socket encountered error: ", err.message, "Closing ws");
      websocket.close();
    };
  });
}
console.log("connecting..");
connect();
