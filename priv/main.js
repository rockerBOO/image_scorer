const imageHashes = new Map();

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

export function getFilename(file) {
  return file.split("/").pop();
}

export async function hashFile(file) {
  const filename = getFilename(file);
  if (imageHashes.has(filename)) {
    return imageHashes.get(filename);
  }

  let data = await fetch(file).then((res) => {
    if (!res.ok) {
      throw new Error("Invalid file " + file);
    }
    return res.blob();
  });

  const hashBuffer = await crypto.subtle.digest(
    "SHA-1",
    await data.arrayBuffer(),
  );
  const hash = uint8ToHex(Array.from(new Uint8Array(hashBuffer)));

  imageHashes.set(getFilename(file), hash);
  return hash;
}

function uint8ToHex(uint8array) {
  return uint8array.map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function syncMessage(message, timeout = 5000) {
  if (!connected()) {
    return;
  }

  return new Promise((resolve) => {
    console.log("Sending...", message);
    ws().send(encode(message));

    const listener = async (event) => {
      resolve(await decode(event.data));
      ws().removeEventListener("message", listener);
    };

    ws().addEventListener("message", listener);

    // Make sure we remove the listener if anything fails
    setTimeout(() => {
      ws().removeEventListener("message", listener);
    }, timeout);
  });
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

export async function trySyncMessage(message, timeout = 5000) {
  if (connected()) {
    return syncMessage(message);
  }

	console.log("not connected!")

  return new Promise(async (resolve, reject) => {
    // reject if we wait too long
    const timeoutHandle = setTimeout(() => {
      reject();
    }, timeout);

    console.log("Trying to connect...");
    // await connect();

    // Clear rejection
    clearTimeout(timeoutHandle);

    // send message
    resolve(syncMessage(message));
  });
}

export async function send(v) {
  return websocket.send(v);
}

export function ws() {
  return websocket;
}

function connect() {
  console.log("connecting..");

  return new Promise((resolve) => {
    websocket = new WebSocket("ws://localhost:3030/ws");

    websocket.addEventListener("open", () => {
      websocket.send("Hello Server!");
      resolve(websocket);
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

await connect();
