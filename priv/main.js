
function debounce(callback, delay) {
  let timeout;
  return function () {
    clearTimeout(timeout);
    timeout = setTimeout(callback, delay);
  };
}

function shuffle(array) {
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

const loadingAnimation = () => {
  if (imageLoadTimeout) {
    clearTimeout(imageLoadTimeout);
  }
  imageEle.style.animation = "";
  imageEle.style.animation = null;
  imageEle.classList.add("loading");
  imageLoadTimeout = setTimeout(() => {
    imageEle.classList.remove("loading");
  }, 1000);
};

// observer = new MutationObserver((changes) => {
//   changes.forEach((e) => {
//     if (e.attributeName === "src") {
//       loadingAnimation();
//     }
//   });
// });
// observer.observe(imageEle, { attributes: true });

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += 1;

    if (imageIdx >= imagesList.length - 1) {
      imagesList = 0;
    }
    getScore(imagesList[imageIdx]);
    resolve();
  }).then(imageLoad);
}

async function decrement() {
  return new Promise((resolve, _reject) => {
    setTimeout(() => {
      imageIdx -= 1;
      if (imageIdx == -1) {
        imageIdx = imagesList.length - 1;
      }
      getScore(imagesList[imageIdx]);
      resolve();
    }, 500);
  }).then(imageLoad);
}

let imageLoadTimeout;

async function imageLoad() {
  return new Promise(() => {
    imageEle.src = imagesList[imageIdx];
  });
}

// manage how fast we can click to score to limit double clicks and rapid clicking
function clickRate() {
  setTimeout(() => {
    clickRated = false;
  }, 1000);
}

export function encode(message) {
  return new Blob([JSON.stringify(message, null, 2)], {
    type: "application/json",
  });
}

export async function decode(data) {
  return JSON.parse(await data.text());
}

async function placeScore(image, score) {
  if (!connected()) {
    return;
  }

  if (!image) {
    console.error("image wtf");
  }

  ws.send(encode({ messageType: "rate", image, rating: score }));
  return setScoreValue(score);
}

async function getScore(image) {
  if (!connected()) {
    return;
  }
  ws.send(encode({ messageType: "get_rating", image }));

  const listener = async (event) => {
    const { messageType, rating } = await decode(event.data);
    ws.removeEventListener("message", listener);
  };

  ws.addEventListener("message", listener);

  // Make sure we remove the listener if anything fails
  setTimeout(() => {
    ws.removeEventListener("message", listener);
  }, 5000);
}

// WebSocket
//
let ws;
let wsBackoffRate = 1000;
let wsBackoffTotal = 0;
let wsBackoffCeil = 10_000;

let connected = () => ws && ws.readyState == 1;

export async function send(v) {
    return ws.send(v) 
}

export function getWS() {
    return ws;
}

async function connect() {
  return new Promise((resolve) => {
    ws = new WebSocket("ws://localhost:3030/ws");

    ws.addEventListener("open", () => {
      ws.send("Hello Server!");
      resolve(ws);
    });

    // ws.addEventListener("message", async (event) => {
    //   console.log("Message from server ", await decode(event.data));
    // });

    ws.onclose = function (e) {
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

    ws.onerror = function (err) {
      console.error("Socket encountered error: ", err.message, "Closing ws");
      ws.close();
    };
  });
}
console.log('connecting..')
connect();


